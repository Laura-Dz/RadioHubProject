import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const rtdb = admin.app().database('https://radiohub12-default-rtdb.europe-west1.firebasedatabase.app');

// ----------------------------------------------------------------
// CREATE POLL — host only
// ----------------------------------------------------------------
export const createPoll = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth || context.auth.token.role !== 'host_session') {
      throw new functions.https.HttpsError('permission-denied', 'Host only');
    }

    const sessionId = context.auth.token.sessionId as string;
    const question = (data?.question ?? '').toString().trim();
    const options = (data?.options ?? []) as string[];
    const closeAfterSeconds = Number(data?.closeAfterSeconds ?? 0);

    if (!question || question.length > 200) {
      throw new functions.https.HttpsError('invalid-argument', 'Question required (max 200)');
    }
    if (!Array.isArray(options) || options.length < 2 || options.length > 4) {
      throw new functions.https.HttpsError('invalid-argument', 'Need 2–4 options');
    }
    const cleaned = options.map((o) => String(o).trim()).filter((o) => o.length > 0);
    if (cleaned.length < 2) {
      throw new functions.https.HttpsError('invalid-argument', 'Options cannot be empty');
    }

    // Close any previous active poll for this session
    const existing = await db
      .collection('polls')
      .where('sessionId', '==', sessionId)
      .where('status', '==', 'active')
      .get();
    const batch = db.batch();
    existing.docs.forEach((d) => batch.update(d.ref, { status: 'closed' }));

    const closesAt = closeAfterSeconds > 0
      ? admin.firestore.Timestamp.fromDate(new Date(Date.now() + closeAfterSeconds * 1000))
      : null;

    const ref = db.collection('polls').doc();
    const voteCounts = Object.fromEntries(cleaned.map((_, i) => [String(i), 0]));
    const optionsList = cleaned.map((text, index) => ({ index, text }));

    batch.set(ref, {
      radioId: context.auth.token.radioId ?? '',
      sessionId,
      question,
      options: optionsList,
      createdBy: context.auth.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'active',
      closesAt,
      totalVotes: 0,
      voteCounts,
    });
    await batch.commit();

    // Sync to Realtime Database (WebSocket instant delivery)
    try {
      await rtdb.ref(`polls/${sessionId}`).set({
        id: ref.id,
        pollId: ref.id,
        radioId: context.auth.token.radioId ?? '',
        sessionId,
        question,
        options: optionsList,
        createdBy: context.auth.uid,
        createdAt: admin.database.ServerValue.TIMESTAMP,
        status: 'active',
        closesAt: closesAt ? closesAt.toMillis() : null,
        totalVotes: 0,
        voteCounts,
      });
    } catch (e) {
      console.error('RTDB createPoll sync error:', e);
    }

    return { success: true, pollId: ref.id };
  });

// ----------------------------------------------------------------
// VOTE — any authenticated listener
// ----------------------------------------------------------------
export const votePoll = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    }

    const pollId = (data?.pollId ?? '').toString();
    const optionIndex = Number(data?.optionIndex ?? -1);

    if (!pollId) {
      throw new functions.https.HttpsError('invalid-argument', 'Poll ID required');
    }
    if (optionIndex < 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid option');
    }

    const pollRef = db.collection('polls').doc(pollId);
    const voteRef = pollRef.collection('votes').doc(context.auth.uid);

    let targetSessionId = '';
    await db.runTransaction(async (tx) => {
      const pollDoc = await tx.get(pollRef);
      if (!pollDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Poll not found');
      }
      const poll = pollDoc.data()!;
      targetSessionId = poll.sessionId || '';
      if (poll.status !== 'active') {
        throw new functions.https.HttpsError('failed-precondition', 'Poll closed');
      }
      if (poll.closesAt && poll.closesAt.toDate() < new Date()) {
        throw new functions.https.HttpsError('failed-precondition', 'Poll expired');
      }
      const maxIndex = (poll.options?.length ?? 0) - 1;
      if (optionIndex > maxIndex) {
        throw new functions.https.HttpsError('invalid-argument', 'Invalid option');
      }

      const existing = await tx.get(voteRef);
      if (existing.exists) {
        throw new functions.https.HttpsError('already-exists', 'You already voted');
      }

      tx.set(voteRef, {
        optionIndex,
        votedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(pollRef, {
        [`voteCounts.${optionIndex}`]: admin.firestore.FieldValue.increment(1),
        totalVotes: admin.firestore.FieldValue.increment(1),
      });
    });

    // Sync to Realtime Database
    try {
      if (targetSessionId) {
        const pollRtdb = rtdb.ref(`polls/${targetSessionId}`);
        await Promise.all([
          pollRtdb.child('totalVotes').set(admin.database.ServerValue.increment(1)),
          pollRtdb.child(`voteCounts/${optionIndex}`).set(admin.database.ServerValue.increment(1)),
          pollRtdb.child(`votes/${context.auth.uid}`).set({
            optionIndex,
            votedAt: admin.database.ServerValue.TIMESTAMP,
          }),
        ]);
      }
    } catch (e) {
      console.error('RTDB votePoll sync error:', e);
    }

    return { success: true };
  });

// ----------------------------------------------------------------
// CLOSE POLL — host only
// ----------------------------------------------------------------
export const closePoll = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth || context.auth.token.role !== 'host_session') {
      throw new functions.https.HttpsError('permission-denied', 'Host only');
    }
    const pollId = (data?.pollId ?? '').toString();
    if (!pollId) throw new functions.https.HttpsError('invalid-argument', 'Poll ID required');

    const ref = db.collection('polls').doc(pollId);
    const doc = await ref.get();
    if (!doc.exists) throw new functions.https.HttpsError('not-found', 'Not found');
    const sessionId = doc.data()!.sessionId;
    if (sessionId !== context.auth.token.sessionId) {
      throw new functions.https.HttpsError('permission-denied', 'Not your session');
    }

    await ref.update({ status: 'closed' });

    // Sync to Realtime Database
    try {
      if (sessionId) {
        await rtdb.ref(`polls/${sessionId}`).update({ status: 'closed' });
      }
    } catch (e) {
      console.error('RTDB closePoll sync error:', e);
    }

    return { success: true };
  });
