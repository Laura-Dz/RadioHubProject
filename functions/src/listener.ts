import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const deleteListenerAccount = functions
  .region('europe-west1')
  .https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    }
    const uid = context.auth.uid;

    // Delete user doc + subcollections (comments, calls, listening history)
    const batch = admin.firestore().batch();

    // Users doc
    batch.delete(admin.firestore().collection('users').doc(uid));

    // Comments authored by the user — mark hidden, keep for host records
    const comments = await admin
      .firestore()
      .collection('comments')
      .where('userId', '==', uid)
      .get();
    comments.docs.forEach((c) => {
      batch.update(c.ref, { status: 'hidden', hiddenReason: 'user_deleted' });
    });

    await batch.commit();

    // Delete auth
    await admin.auth().deleteUser(uid);

    return { success: true };
  });
