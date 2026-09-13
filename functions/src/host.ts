import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

const db = admin.firestore();
const auth = admin.auth();

const MODERATION_URL = 'https://api.openai.com/v1/moderations';

// ----------------------------------------------------------------
// 1. VERIFY SESSION CODE — no auth required
// ----------------------------------------------------------------
export const verifySessionCode = functions
  .region('europe-west1')
  .https.onCall(async (data) => {
    const code = (data?.sessionCode ?? '').toString().trim().toUpperCase();
    if (!code) {
      throw new functions.https.HttpsError('invalid-argument', 'Code required');
    }

    // Find a session with this code, still valid
    const snap = await db
      .collection('sessions')
      .where('sessionCode', '==', code)
      .where('status', 'in', ['scheduled', 'on_air'])
      .limit(1)
      .get();

    if (snap.empty) {
      throw new functions.https.HttpsError('not-found', 'Invalid or expired code');
    }

    const doc = snap.docs[0];
    const s = doc.data();

    // Issue a custom token scoped to this session
    const customToken = await auth.createCustomToken(`host_${doc.id}`, {
      role: 'host_session',
      sessionId: doc.id,
      radioId: s.radioId,
    });

    return {
      customToken,
      sessionId: doc.id,
      programName: s.programName ?? '',
      hostName: s.hostName ?? '',
    };
  });

// ----------------------------------------------------------------
// 2. SUBMIT COMMENT — listener, moderated
// ----------------------------------------------------------------
export const submitComment = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    }

    const sessionId = (data?.sessionId ?? '').toString();
    const text = (data?.text ?? '').toString().trim();

    if (!sessionId || !text) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing fields');
    }
    if (text.length > 500) {
      throw new functions.https.HttpsError('invalid-argument', 'Comment too long (max 500 chars)');
    }

    // Validate session
    const sessionRef = db.collection('sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Session not found');
    }
    const s = sessionDoc.data()!;
    if (s.status !== 'on_air') {
      throw new functions.https.HttpsError('failed-precondition', 'Session not on air');
    }
    if (s.allowComments === false) {
      throw new functions.https.HttpsError('failed-precondition', 'Comments disabled');
    }

    // Moderation
    const moderation = await moderateText(text);
    if (!moderation.passed) {
      return { success: false, reason: 'moderation', categories: moderation.categories };
    }

    // Get user profile for display name
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    const userData = userDoc.data() ?? {};

    const commentRef = db.collection('comments').doc();
    await commentRef.set({
      sessionId,
      radioId: s.radioId,
      userId: context.auth.uid,
      userName: userData.displayName ?? 'Listener',
      text,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
      hostReply: null,
      hostReplyAt: null,
      replyingSince: null,
      moderationPassed: true,
      moderationCategories: [],
      pinned: false,
    });

    await sessionRef.update({
      commentsCount: admin.firestore.FieldValue.increment(1),
      engagementCount: admin.firestore.FieldValue.increment(1),
    });

    return { success: true, commentId: commentRef.id };
  });

// ----------------------------------------------------------------
// 3. SUBMIT CALL REQUEST
// ----------------------------------------------------------------
export const submitCallRequest = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    }

    const sessionId = (data?.sessionId ?? '').toString();
    const phone = (data?.phone ?? '').toString().trim();

    if (!sessionId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing session');
    }

    const sessionRef = db.collection('sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Session not found');
    }
    const s = sessionDoc.data()!;
    if (s.status !== 'on_air') {
      throw new functions.https.HttpsError('failed-precondition', 'Session not on air');
    }
    if (s.allowCalls === false) {
      throw new functions.https.HttpsError('failed-precondition', 'Calls disabled');
    }

    // Prevent duplicate active call
    const existing = await db
      .collection('calls')
      .where('sessionId', '==', sessionId)
      .where('userId', '==', context.auth.uid)
      .where('status', 'in', ['pending', 'accepted', 'held'])
      .limit(1)
      .get();
    if (!existing.empty) {
      throw new functions.https.HttpsError('already-exists', 'You already have a call in progress');
    }

    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    const userData = userDoc.data() ?? {};

    const callRef = db.collection('calls').doc();
    await callRef.set({
      sessionId,
      radioId: s.radioId,
      userId: context.auth.uid,
      userName: userData.displayName ?? 'Listener',
      userPhone: phone || userData.phone || '',
      status: 'pending',
      requestedAt: admin.firestore.FieldValue.serverTimestamp(),
      acceptedAt: null,
      heldAt: null,
      holdCount: 0,
      lastActionBy: 'listener',
    });

    await sessionRef.update({
      callsCount: admin.firestore.FieldValue.increment(1),
      engagementCount: admin.firestore.FieldValue.increment(1),
    });

    return { success: true, callId: callRef.id };
  });

// ----------------------------------------------------------------
// 4. SET COMMENT REPLYING — host toggles the "Replying" tag
// ----------------------------------------------------------------
export const setCommentReplying = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    assertHostSession(context);
    const commentId = (data?.commentId ?? '').toString();
    const replying = data?.replying === true;

    const commentRef = db.collection('comments').doc(commentId);
    const commentDoc = await commentRef.get();
    if (!commentDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Comment not found');
    }
    const c = commentDoc.data()!;
    if (c.sessionId !== context.auth!.token.sessionId) {
      throw new functions.https.HttpsError('permission-denied', 'Not your session');
    }

    if (replying) {
      // Only allow if status is pending
      if (c.status !== 'pending') {
        return { success: false, reason: 'not_pending' };
      }
      await commentRef.update({
        status: 'replying',
        replyingSince: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      if (c.status === 'replying') {
        await commentRef.update({
          status: 'pending',
          replyingSince: null,
        });
      }
    }

    return { success: true };
  });

// ----------------------------------------------------------------
// 5. REPLY TO COMMENT
// ----------------------------------------------------------------
export const replyToComment = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    assertHostSession(context);
    const commentId = (data?.commentId ?? '').toString();
    const reply = (data?.reply ?? '').toString().trim();

    if (!reply) {
      throw new functions.https.HttpsError('invalid-argument', 'Reply required');
    }
    if (reply.length > 500) {
      throw new functions.https.HttpsError('invalid-argument', 'Reply too long');
    }

    const commentRef = db.collection('comments').doc(commentId);
    const commentDoc = await commentRef.get();
    if (!commentDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Comment not found');
    }
    const c = commentDoc.data()!;
    if (c.sessionId !== context.auth!.token.sessionId) {
      throw new functions.https.HttpsError('permission-denied', 'Not your session');
    }

    // Moderate the reply too (defensive)
    const moderation = await moderateText(reply);
    if (!moderation.passed) {
      return { success: false, reason: 'moderation', categories: moderation.categories };
    }

    await commentRef.update({
      status: 'replied',
      hostReply: reply,
      hostReplyAt: admin.firestore.FieldValue.serverTimestamp(),
      replyingSince: null,
    });

    return { success: true };
  });

// ----------------------------------------------------------------
// 6. UPDATE CALL STATUS — host actions
// ----------------------------------------------------------------
export const updateCallStatus = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in');
    }

    const role = context.auth.token.role;
    if (role !== 'host_session' && role !== 'technician') {
      throw new functions.https.HttpsError('permission-denied', 'Not authorized');
    }

    const callId = (data?.callId ?? '').toString();
    const next = (data?.status ?? '').toString();

    const allowed = ['accepted', 'held', 'declined', 'ended'];
    if (!allowed.includes(next)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid status');
    }

    const callRef = db.collection('calls').doc(callId);
    const callDoc = await callRef.get();
    if (!callDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Call not found');
    }
    const c = callDoc.data()!;

    if (role === 'host_session' && c.sessionId !== context.auth.token.sessionId) {
      throw new functions.https.HttpsError('permission-denied', 'Not your session');
    }

    // Only one accepted call at a time
    if (next === 'accepted') {
      const other = await db
        .collection('calls')
        .where('sessionId', '==', c.sessionId)
        .where('status', '==', 'accepted')
        .limit(1)
        .get();
      if (!other.empty) {
        return { success: false, reason: 'another_on_call' };
      }
    }

    const update: any = {
      status: next,
      lastActionBy: role === 'host_session' ? 'host' : 'technician',
    };

    if (next === 'accepted') {
      update.acceptedAt = admin.firestore.FieldValue.serverTimestamp();
      update.heldAt = null;
    }
    if (next === 'held') {
      update.heldAt = admin.firestore.FieldValue.serverTimestamp();
      update.holdCount = admin.firestore.FieldValue.increment(1);
    }
    if (next === 'ended') {
      update.endedAt = admin.firestore.FieldValue.serverTimestamp();
    }

    await callRef.update(update);
    return { success: true };
  });

// ----------------------------------------------------------------
// 7. SCHEDULED — drop calls held > 5 min
// ----------------------------------------------------------------
export const holdExpiredCalls = functions
  .region('europe-west1')
  .pubsub.schedule('every 1 minutes')
  .timeZone('Africa/Douala')
  .onRun(async () => {
    const cutoff = new Date(Date.now() - 5 * 60 * 1000);
    const snap = await db
      .collection('calls')
      .where('status', '==', 'held')
      .where('heldAt', '<', cutoff)
      .get();

    const batch = db.batch();
    snap.docs.forEach((d) => {
      batch.update(d.ref, {
        status: 'dropped',
        lastActionBy: 'system',
        droppedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();
    functions.logger.info(`Dropped ${snap.size} held calls`);
  });

// ----------------------------------------------------------------
// 8. SCHEDULED — reset stale "replying" tags
// ----------------------------------------------------------------
export const resetStaleReplying = functions
  .region('europe-west1')
  .pubsub.schedule('every 1 minutes')
  .timeZone('Africa/Douala')
  .onRun(async () => {
    const cutoff = new Date(Date.now() - 60 * 1000);
    const snap = await db
      .collection('comments')
      .where('status', '==', 'replying')
      .where('replyingSince', '<', cutoff)
      .get();

    const batch = db.batch();
    snap.docs.forEach((d) => {
      batch.update(d.ref, { status: 'pending', replyingSince: null });
    });
    await batch.commit();
    functions.logger.info(`Reset ${snap.size} stale replying tags`);
  });

// ----------------------------------------------------------------
// 9. CLEAR SESSION CODE ON END
// ----------------------------------------------------------------
export const clearSessionCodeOnEnd = functions
  .region('europe-west1')
  .firestore.document('sessions/{id}')
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status !== 'ended' && after.status === 'ended') {
      await change.after.ref.update({ sessionCode: null });
    }
  });

// ----------------------------------------------------------------
// HELPERS
// ----------------------------------------------------------------
function assertHostSession(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  }
  if (context.auth.token.role !== 'host_session') {
    throw new functions.https.HttpsError('permission-denied', 'Host only');
  }
}

async function moderateText(text: string): Promise<{ passed: boolean; categories: string[] }> {
  try {
    const apiKey = functions.config().openai?.key;
    if (!apiKey) {
      // No key configured → allow (assume upstream moderation elsewhere)
      return { passed: true, categories: [] };
    }

    const res = await axios.post(
      MODERATION_URL,
      { input: text, model: 'omni-moderation-latest' },
      {
        headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
        timeout: 5000,
      },
    );

    const result = res.data?.results?.[0];
    if (!result) return { passed: true, categories: [] };

    return {
      passed: !result.flagged,
      categories: Object.entries(result.categories ?? {})
        .filter(([, v]) => v === true)
        .map(([k]) => k),
    };
  } catch (e) {
    functions.logger.error('Moderation failed', e);
    // Fail-open — better to allow than block during an outage
    return { passed: true, categories: [] };
  }
}
