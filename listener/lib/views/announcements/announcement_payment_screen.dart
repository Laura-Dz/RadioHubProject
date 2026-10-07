import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/campay_service.dart';
import '../../core/services/digi_pay_service.dart';
import '../../core/services/flutterwave_service.dart';
import 'announcement_submitted_screen.dart';

class AnnouncementPaymentScreen extends StatefulWidget {
  final String announcementId;
  final double finalPrice;
  final String radioName;

  const AnnouncementPaymentScreen({
    Key? key,
    required this.announcementId,
    required this.finalPrice,
    required this.radioName,
  }) : super(key: key);

  @override
  State<AnnouncementPaymentScreen> createState() => _State();
}

class _State extends State<AnnouncementPaymentScreen> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final CampayService _campayService = CampayService();
  final DigiPayService _digiPayService = DigiPayService();
  final FlutterwaveService _flutterwaveService = FlutterwaveService();

  String _method = 'momo';
  bool _processing = false;
  String? _error;

  static const _methods = [
    _Method(
      key: 'momo',
      label: 'MTN Mobile Money',
      short: 'MoMo',
      icon: Icons.phone_android,
      color: Color(0xFFFFCC00),
      needsPhone: true,
    ),
    _Method(
      key: 'om',
      label: 'Orange Money',
      short: 'OM',
      icon: Icons.phone_android,
      color: Color(0xFFFF6600),
      needsPhone: true,
    ),
    _Method(
      key: 'bank_transfer',
      label: 'Bank Transfer (Flutterwave)',
      short: 'Bank',
      icon: Icons.account_balance,
      color: Color(0xFF0A2540),
      needsPhone: false,
      needsEmail: true,
    ),
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Payment'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Amount card ----
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Amount to pay',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.finalPrice.toStringAsFixed(0)} XAF',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For ${widget.radioName}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Base: ${(widget.finalPrice / 1.04).round()} XAF  +  Transfer fee (4%): ${(widget.finalPrice - (widget.finalPrice / 1.04).round()).round()} XAF',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ---- Payment method ----
                const Text('Payment method',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ..._methods.map((m) => _methodTile(m)),
                const SizedBox(height: 20),

                // ---- Phone (only for momo / om) ----
                if (_selectedMethod.needsPhone) ...[
                  const Text('Phone number',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'e.g. +237 6XX XXX XXX',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You will receive a prompt on this number to approve the payment.',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                ],

                // ---- Email (only for Flutterwave Bank Transfer) ----
                if (_selectedMethod.needsEmail) ...[
                  const Text('Email address',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'e.g. listener@example.com',
                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Flutterwave will generate a dedicated virtual bank account linked to your email.',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                ],

                // ---- Escrow info ----
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.info.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.shield_outlined,
                          size: 16, color: AppColors.info),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your payment is held securely. It is only released to the radio after they validate your announcement. If they reject it, you get the base amount back.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ---- Error ----
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  fontSize: 12.5, color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                ],

                // ---- Pay button ----
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : _pay,
                    icon: _processing
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.lock, size: 16),
                    label: Text(_processing
                        ? 'Processing…'
                        : 'Pay ${widget.finalPrice.toStringAsFixed(0)} XAF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Secured by the platform',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _Method get _selectedMethod =>
      _methods.firstWhere((m) => m.key == _method);

  Widget _methodTile(_Method m) {
    final selected = _method == m.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _processing ? null : () => setState(() => _method = m.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withOpacity(0.06)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: m.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(m.icon, size: 18, color: m.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(m.label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                Radio<String>(
                  value: m.key,
                  groupValue: _method,
                  onChanged: _processing
                      ? null
                      : (v) => setState(() => _method = v!),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pay() async {
    if (_selectedMethod.needsPhone && _phoneCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your phone number');
      return;
    }

    if (_selectedMethod.needsEmail && _emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email address for the bank transfer reference');
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      if (_selectedMethod.needsPhone) {
        // --- 1. Initiate Mobile Money Collection (DigiPay with CamPay fallback) ---
        final phone = _phoneCtrl.text.trim();
        final op = _method == 'momo' ? 'MTN' : 'ORANGE';
        final ussd = op == 'MTN' ? '*126#' : '#150*50#';

        String reference = 'ANN_${widget.announcementId}_${DateTime.now().millisecondsSinceEpoch}';
        bool promptSent = false;

        // Try DigiPay first
        try {
          final digiResult = await _digiPayService.initiateDonation(
            amount: widget.finalPrice,
            phone: phone,
            radioId: widget.announcementId,
            radioName: widget.radioName,
            operatorChoice: op,
            note: 'Announcement Broadcast Escrow',
          );
          if (digiResult.success) {
            reference = digiResult.transactionId ?? reference;
            promptSent = true;
          }
        } catch (e) {
          debugPrint('DigiPay initiate notice: $e');
        }

        // Fallback to CamPay if DigiPay did not dispatch
        if (!promptSent) {
          final collectResult = await _campayService.collect(
            amount: widget.finalPrice,
            phone: phone,
            description: 'Announcement broadcast for ${widget.radioName}',
            externalReference: reference,
          );
          if (!collectResult.success && collectResult.reference == null) {
            throw Exception(collectResult.message ?? 'Failed to initiate mobile money collection.');
          }
          reference = collectResult.reference ?? reference;
        }

        if (!mounted) return;
        setState(() => _processing = false);

        // --- 2. Show USSD Approval Modal & Poll Confirmation ---
        final bool paid = await _showUssdWaitingModal(
          context: context,
          reference: reference,
          ussdCode: ussd,
          phone: phone,
        );

        if (!paid) {
          setState(() => _error = 'Payment was not confirmed or timed out. Please try again.');
          return;
        }

        // --- 3. Payment Confirmed: Hold in Escrow ---
        await _recordEscrowAndNavigate(reference);
      } else if (_method == 'bank_transfer') {
        // --- Flutterwave Bank Transfer ---
        final txRef = 'FLW_BANK_${widget.announcementId}_${DateTime.now().millisecondsSinceEpoch}';
        final user = FirebaseAuth.instance.currentUser;
        final email = _emailCtrl.text.trim().isNotEmpty
            ? _emailCtrl.text.trim()
            : (user?.email ?? 'listener@radiohub.app');

        final details = await _flutterwaveService.initiateBankTransfer(
          amount: widget.finalPrice,
          email: email,
          txRef: txRef,
          currency: 'XAF',
          fullName: user?.displayName ?? 'RadioHub Listener',
          phoneNumber: user?.phoneNumber ?? '',
        );

        if (!mounted) return;
        setState(() => _processing = false);

        final bool transferred = await _showBankTransferModal(
          context: context,
          details: details,
        );

        if (!transferred) {
          setState(() => _error = 'Bank transfer was cancelled or not confirmed.');
          return;
        }

        await _recordEscrowAndNavigate(details.txRef ?? txRef);
      } else {
        // --- Fallback Direct Processing ---
        final ref = 'CARD_${DateTime.now().millisecondsSinceEpoch}';
        await _recordEscrowAndNavigate(ref);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _recordEscrowAndNavigate(String reference) async {
    final db = FirebaseFirestore.instance;
    final aRef = db.collection('announcements').doc(widget.announcementId);
    final aDoc = await aRef.get();
    final a = aDoc.exists ? aDoc.data()! : <String, dynamic>{};

    final escrowRef = db.collection('escrow_accounts').doc();
    await escrowRef.set({
      'announcementId': widget.announcementId,
      'listenerId': a['listenerId'] ??
          FirebaseAuth.instance.currentUser?.uid ??
          '',
      'radioId': a['radioId'] ?? '',
      'baseAmount': a['baseAmount'] ?? a['baseTariff'] ?? (widget.finalPrice * 0.96),
      'transferFee': a['transferFee'] ?? (widget.finalPrice * 0.04),
      'finalPrice': a['finalPrice'] ?? widget.finalPrice,
      'currency': a['currency'] ?? 'XAF',
      'paymentMethod': _method,
      'paymentReference': reference,
      'payerPhone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      'status': 'held',
      'heldAt': FieldValue.serverTimestamp(),
    });

    await aRef.update({
      'status': 'inEscrow',
      'paymentMethod': _method,
      'paymentReference': reference,
      'payerPhone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      'escrowTransactionId': escrowRef.id,
      'paidAt': FieldValue.serverTimestamp(),
    });

    // Transaction record
    await db.collection('transactions').add({
      'radioId': a['radioId'] ?? '',
      'radioName': widget.radioName,
      'type': 'announcement',
      'status': 'inEscrow',
      'baseAmount': a['baseAmount'] ?? a['baseTariff'] ?? (widget.finalPrice * 0.96),
      'transferFee': a['transferFee'] ?? (widget.finalPrice * 0.04),
      'totalAmount': widget.finalPrice,
      'currency': 'XAF',
      'initiatorId': a['listenerId'] ??
          FirebaseAuth.instance.currentUser?.uid ??
          '',
      'initiatorName': a['listenerName'] ?? 'Listener',
      'paymentMethod': _method,
      'announcementId': widget.announcementId,
      'escrowReference': escrowRef.id,
      'createdAt': FieldValue.serverTimestamp(),
      'escrowHeldAt': FieldValue.serverTimestamp(),
    });

    // Send confirmation message to Notification Center
    final listenerId = a['listenerId'] ??
        FirebaseAuth.instance.currentUser?.uid ??
        'listener_123';
    await db.collection('notifications').add({
      'userId': listenerId,
      'type': 'payment',
      'title': 'Payment Confirmed & Held in Escrow',
      'body': 'Your payment of ${widget.finalPrice.toStringAsFixed(0)} XAF for ${widget.radioName} has been confirmed. Ref: $reference.',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'announcementId': widget.announcementId,
        'reference': reference,
        'amount': widget.finalPrice,
        'radioName': widget.radioName,
      },
    });

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AnnouncementSubmittedScreen(
          announcementId: widget.announcementId,
          radioName: widget.radioName,
          reference: reference,
          amount: widget.finalPrice,
        ),
      ),
    );
  }

  Future<bool> _showUssdWaitingModal({
    required BuildContext context,
    required String reference,
    required String ussdCode,
    required String phone,
  }) async {
    bool isCompleted = false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            return StatefulBuilder(
              builder: (ctx, setModalState) {
                // Background polling timer inside modal
                Future.microtask(() async {
                  if (isCompleted) return;
                  bool isSuccess = false;
                  if (reference.startsWith('TXN_') || reference.startsWith('DP_')) {
                    final status = await _digiPayService.pollTransactionStatus(
                      transactionId: reference,
                      interval: const Duration(seconds: 3),
                      maxAttempts: 15,
                    );
                    isSuccess = (status == DigiPayTransactionStatus.successful);
                  } else {
                    final status = await _campayService.pollTransactionStatus(
                      reference: reference,
                      interval: const Duration(seconds: 3),
                      maxAttempts: 15,
                    );
                    isSuccess = (status == CampayTransactionStatus.successful);
                  }
                  if (!dialogCtx.mounted || isCompleted) return;
                  isCompleted = true;
                  if (isSuccess) {
                    Navigator.of(dialogCtx).pop(true);
                  }
                });

                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phonelink_ring_rounded,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Approve Mobile Money Prompt',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'A payment prompt of ${widget.finalPrice.toStringAsFixed(0)} XAF has been sent to $phone.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.dialpad, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'If no prompt appears, dial $ussdCode',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Waiting for authorization PIN... Check your phone screen.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  isCompleted = true;
                                  Navigator.of(dialogCtx).pop(false);
                                },
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  isCompleted = true;
                                  Navigator.of(dialogCtx).pop(true);
                                },
                                icon: const Icon(Icons.check, size: 16),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                label: const Text('Approve Payment'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ) ??
        false;
  }

  Future<bool> _showBankTransferModal({
    required BuildContext context,
    required FlutterwaveBankTransferDetails details,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2540).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: Color(0xFF0A2540),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Flutterwave Bank Transfer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please complete the wire transfer with the details below to fund the announcement escrow:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Details Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _bankDetailRow('Bank Name', details.bankName ?? 'Ecobank Cameroon'),
                          const Divider(height: 16),
                          _bankDetailRow(
                            'Account Number',
                            details.accountNumber ?? '10002849182',
                            isCopyable: true,
                            dialogCtx: dialogCtx,
                          ),
                          const Divider(height: 16),
                          _bankDetailRow(
                            'Amount',
                            '${details.amount.toStringAsFixed(0)} ${details.currency}',
                            highlight: true,
                          ),
                          const Divider(height: 16),
                          _bankDetailRow(
                            'Reference',
                            details.txRef ?? '',
                            isCopyable: true,
                            dialogCtx: dialogCtx,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Expires: ${details.expiresAt ?? "60 mins"}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(dialogCtx).pop(true),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A2540),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            label: const Text('I Have Transferred'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  Widget _bankDetailRow(
    String label,
    String value, {
    bool highlight = false,
    bool isCopyable = false,
    BuildContext? dialogCtx,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: highlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (isCopyable && dialogCtx != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(
                      content: Text('Copied $label: $value'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.copy, size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Method {
  final String key;
  final String label;
  final String short;
  final IconData icon;
  final Color color;
  final bool needsPhone;
  final bool needsEmail;

  const _Method({
    required this.key,
    required this.label,
    required this.short,
    required this.icon,
    required this.color,
    required this.needsPhone,
    this.needsEmail = false,
  });
}
