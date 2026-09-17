import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

const db = admin.firestore();

// ----------------------------------------------------------------
// ENHANCE TEXT — OpenAI
// ----------------------------------------------------------------
export const enhanceAnnouncementText = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    }

    const category = (data?.category ?? 'general').toString();
    const text = (data?.text ?? '').toString().trim();

    if (!text) {
      throw new functions.https.HttpsError('invalid-argument', 'Text required');
    }
    if (text.length > 500) {
      throw new functions.https.HttpsError('invalid-argument', 'Text too long');
    }

    const apiKey = functions.config().openai?.key || process.env.OPENAI_API_KEY;
    if (!apiKey) {
      // No key configured — return the original
      return { enhanced: text };
    }

    try {
      const res = await axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
          model: 'gpt-4o-mini',
          messages: [
            {
              role: 'system',
              content:
                'You improve short radio announcement messages. Keep the meaning, tone and language. Stay concise — do not exceed 80 words. Return only the improved text.',
            },
            {
              role: 'user',
              content: `Category: ${category}\nDraft: ${text}`,
            },
          ],
          max_tokens: 200,
          temperature: 0.5,
        },
        {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            'Content-Type': 'application/json',
          },
          timeout: 8000,
        },
      );

      const enhanced = res.data?.choices?.[0]?.message?.content?.trim();
      return { enhanced: enhanced || text };
    } catch (e) {
      functions.logger.error('AI enhancement failed', e);
      return { enhanced: text };
    }
  });

// ----------------------------------------------------------------
// SUBMIT REQUEST
// ----------------------------------------------------------------
export const submitAnnouncementRequest = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    }

    const radioId = (data?.radioId ?? '').toString();
    const radioName = (data?.radioName ?? '').toString();
    const category = (data?.category ?? '').toString().trim().toLowerCase();
    const isCustomCategory = data?.isCustomCategory === true;
    const originalText = (data?.originalText ?? '').toString();
    const finalText = (data?.finalText ?? '').toString().trim();
    const priority = (data?.priority ?? 'standard').toString();
    const diffusionsPerDay = Number(data?.diffusionsPerDay ?? 1);
    const days = Number(data?.days ?? 1);

    // Validate
    if (!radioId || !finalText || !category) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing fields');
    }
    if (finalText.length > 500) {
      throw new functions.https.HttpsError('invalid-argument', 'Message too long');
    }
    if (diffusionsPerDay < 1 || diffusionsPerDay > 10) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid diffusions/day');
    }
    if (days < 1 || days > 30) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid days');
    }
    if (!['standard', 'high', 'priority'].includes(priority)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid priority');
    }

    // Fetch tariff for the category
    const tariffSnap = await db
      .collection('announcement_tariffs')
      .where('radioId', '==', radioId)
      .where('category', '==', category)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    let ratePerUnit = 0;
    if (!tariffSnap.empty) {
      ratePerUnit = Number(tariffSnap.docs[0].data().ratePer15SecUnit ?? 0);
    } else {
      // Fallback to "general" tariff
      const fallback = await db
        .collection('announcement_tariffs')
        .where('radioId', '==', radioId)
        .where('category', '==', 'general')
        .where('isActive', '==', true)
        .limit(1)
        .get();
      if (!fallback.empty) {
        ratePerUnit = Number(fallback.docs[0].data().ratePer15SecUnit ?? 0);
      }
    }

    if (ratePerUnit <= 0) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'No tariff configured for this category. Contact the radio.',
      );
    }

    // Compute units from word count
    const wordCount = finalText.split(/\s+/).filter((w: string) => w.length > 0).length;
    // ~2.5 words/sec, 15 sec per unit
    const units = Math.max(1, Math.ceil(wordCount / (2.5 * 15)));

    // Base = rate × units × diffusions × days
    const baseAmount = ratePerUnit * units * diffusionsPerDay * days;
    const transferFee = baseAmount * 0.04;
    const finalPrice = baseAmount + transferFee;

    // Get listener profile
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    const userData = userDoc.data() ?? {};

    // Write request
    const ref = db.collection('announcements').doc();
    await ref.set({
      radioId,
      radioName,
      listenerId: context.auth.uid,
      listenerName: userData.displayName ?? 'Listener',
      listenerEmail: userData.email ?? '',
      category,
      isCustomCategory,
      originalText,
      finalText,
      priority,
      diffusionsPerDay,
      days,
      wordCount,
      units,
      ratePerUnit,
      baseAmount,
      transferFee,
      finalPrice,
      currency: 'XAF',
      status: 'pendingPayment',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      announcementId: ref.id,
      baseAmount,
      transferFee,
      finalPrice,
      units,
    };
  });

// ----------------------------------------------------------------
// PROCESS PAYMENT — mock payment gateway + escrow hold
// ----------------------------------------------------------------
export const processAnnouncementPayment = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
    }

    const announcementId = (data?.announcementId ?? '').toString();
    const paymentMethod = (data?.paymentMethod ?? '').toString().toLowerCase();
    const phone = (data?.phone ?? '').toString().trim();

    if (!announcementId || !paymentMethod) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing fields');
    }
    if (!['momo', 'om', 'ecobank'].includes(paymentMethod)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid payment method');
    }
    if (['momo', 'om'].includes(paymentMethod) && !phone) {
      throw new functions.https.HttpsError('invalid-argument', 'Phone number required');
    }

    // Fetch the announcement
    const ref = db.collection('announcements').doc(announcementId);
    const doc = await ref.get();
    if (!doc.exists) {
      throw new functions.https.HttpsError('not-found', 'Announcement not found');
    }

    const a = doc.data()!;

    // Only the owner can pay
    if (a.listenerId !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied', 'Not your announcement');
    }
    if (a.status !== 'pendingPayment') {
      throw new functions.https.HttpsError('failed-precondition', 'Already processed');
    }

    // --- SIMULATED PAYMENT GATEWAY ---
    // In production this would call Flutterwave / CinetPay / etc.
    // For now we simulate a successful transaction reference.
    const reference = `${paymentMethod.toUpperCase()}_${Date.now()}_${Math.random()
      .toString(36)
      .substring(2, 8)
      .toUpperCase()}`;

    // --- ESCROW HOLD ---
    const escrowRef = db.collection('escrow_accounts').doc();
    await escrowRef.set({
      announcementId,
      listenerId: a.listenerId,
      radioId: a.radioId,
      baseAmount: a.baseAmount,
      transferFee: a.transferFee,
      finalPrice: a.finalPrice,
      currency: a.currency,
      paymentMethod,
      paymentReference: reference,
      payerPhone: phone || null,
      status: 'held',
      heldAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // --- UPDATE ANNOUNCEMENT ---
    await ref.update({
      status: 'pendingValidation',
      paymentMethod,
      paymentReference: reference,
      payerPhone: phone || null,
      escrowTransactionId: escrowRef.id,
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // --- TRANSACTION LOG ---
    await db.collection('transactions').add({
      radioId: a.radioId,
      radioName: a.radioName,
      type: 'announcement',
      status: 'inEscrow',
      baseAmount: a.baseAmount,
      transferFee: a.transferFee,
      totalAmount: a.finalPrice,
      currency: a.currency,
      initiatorId: a.listenerId,
      initiatorName: a.listenerName,
      paymentMethod,
      announcementId,
      escrowReference: escrowRef.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      escrowHeldAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // --- NOTIFY RADIO ADMIN ---
    await db.collection('notifications').add({
      radioId: a.radioId,
      recipientRole: 'radio_admin',
      type: 'announcement_pending',
      title: 'New announcement awaiting validation',
      body: `${a.listenerName} · ${a.category}`,
      data: { announcementId },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      reference,
      escrowId: escrowRef.id,
    };
  });
