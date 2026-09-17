import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

/**
 * Creates a technician account in one atomic operation:
 *   1. Firebase Auth user (with the password the radio admin chose)
 *   2. /users/{uid} document with radioId + role
 *   3. Custom claims { role, radioId }
 *
 * Only callable by a signed-in radio admin.
 */
export const createTechnicianAccount = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    // 1. Auth check
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    }

    const callerSnap = await db.collection('users').doc(context.auth.uid).get();
    const caller = callerSnap.data();
    if (!caller || caller.role !== 'radio_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only radio admins can create staff');
    }

    const {
      radioId, radioName, name, email, phone, bio, password,
    } = data;

    if (!radioId || !email || !password || password.length < 6) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing or invalid fields');
    }

    // 2. Enforce: admin can only create staff for their own radio
    if (caller.radioId !== radioId) {
      throw new functions.https.HttpsError('permission-denied', 'Radio mismatch');
    }

    try {
      // 3. Create Auth user
      const userRecord = await auth.createUser({
        email,
        password,
        displayName: name,
      });

      // 4. Claims
      await auth.setCustomUserClaims(userRecord.uid, {
        role: 'technician',
        radioId: radioId,
      });

      // 5. User doc
      await db.collection('users').doc(userRecord.uid).set({
        uid: userRecord.uid,
        authUid: userRecord.uid,
        displayName: name,
        name: name,
        email,
        phone: phone ?? '',
        bio: bio ?? '',
        role: 'technician',
        radioId: radioId,
        radioName: radioName,
        status: 'active',
        isActive: true,
        createdBy: context.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, uid: userRecord.uid };
    } catch (err: any) {
      functions.logger.error('createTechnicianAccount failed', err);
      if (err.code === 'auth/email-already-exists') {
        return { success: false, error: 'This email is already registered.' };
      }
      return { success: false, error: err.message ?? 'Creation failed' };
    }
  });

/**
 * Callable function: Host joins a session with a session code.
 *
 * Validates the session code against active sessions in Firestore.
 * Returns a custom Auth token scoped to the session, allowing the
 * Host app to authenticate temporarily without a permanent account.
 */
export const joinSession = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    const { sessionCode, hostName } = data;

    if (!sessionCode) {
      throw new functions.https.HttpsError('invalid-argument', 'Session code is required.');
    }

    // Find active session with this code
    const sessionSnap = await db
      .collection('sessions')
      .where('sessionCode', '==', sessionCode.trim().toUpperCase())
      .where('status', '==', 'active')
      .limit(1)
      .get();

    if (sessionSnap.empty) {
      throw new functions.https.HttpsError(
        'not-found',
        'Invalid or expired session code. Ask your technician for an active code.',
      );
    }

    const sessionDoc = sessionSnap.docs[0];
    const session = sessionDoc.data();

    // Generate a temporary anonymous-like custom token for the host
    const hostUid = `host_${sessionDoc.id}_${Date.now()}`;
    const customToken = await auth.createCustomToken(hostUid, {
      role: 'host_session',
      sessionId: sessionDoc.id,
      radioId: session.radioId,
      hostName: hostName || 'Guest Host',
    });

    // Record host joined in the session doc
    await sessionDoc.ref.update({
      hostJoinedAt: admin.firestore.FieldValue.serverTimestamp(),
      hostName: hostName || 'Guest Host',
      hostUid: hostUid,
    });

    return {
      token: customToken,
      sessionId: sessionDoc.id,
      radioId: session.radioId,
      programTitle: session.programTitle ?? '',
      startTime: session.startTime,
    };
  });

export const joinSessionWithCode = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    const { sessionCode } = data;
    if (!sessionCode || typeof sessionCode !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'Session code required');
    }

    // Find a live session with this code
    const snap = await db
      .collection('sessions')
      .where('sessionCode', '==', sessionCode.trim().toUpperCase())
      .where('status', '==', 'live')
      .limit(1)
      .get();

    if (snap.empty) {
      throw new functions.https.HttpsError('not-found', 'Invalid or expired code');
    }

    const session = snap.docs[0];
    const s = session.data();

    // Issue a scoped custom token for the host
    const customToken = await auth.createCustomToken(
      `host_${session.id}`,
      {
        role: 'host_session',
        sessionId: session.id,
        radioId: s.radioId,
      },
    );

    return {
      customToken,
      sessionId: session.id,
      programName: s.programName,
      hostName: s.hostName,
    };
  });

export * from './host';
export * from './listener';
export * from './announcements';
export * from './polls';


