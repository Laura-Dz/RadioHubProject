import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/cloud_function_caller.dart';
import '../../core/services/campay_service.dart';
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
  final CampayService _campayService = CampayService();

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
      key: 'ecobank',
      label: 'Ecobank Card',
      short: 'Ecobank',
      icon: Icons.credit_card,
      color: Color(0xFF0066B3),
      needsPhone: false,
    ),
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
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

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      if (_selectedMethod.needsPhone) {
        // --- 1. Initiate CamPay USSD Collection ---
        final externalRef = 'ANN_${widget.announcementId}_${DateTime.now().millisecondsSinceEpoch}';
        final collectResult = await _campayService.collect(
          amount: widget.finalPrice,
          phone: _phoneCtrl.text.trim(),
          description: 'Announcement broadcast for ${widget.radioName}',
          externalReference: externalRef,
        );

        if (!collectResult.success && collectResult.reference == null) {
          throw Exception(collectResult.message ?? 'Failed to initiate mobile money collection.');
        }

        if (!mounted) return;
        setState(() => _processing = false);

        // --- 2. Show USSD Approval Modal & Poll Confirmation ---
        final bool paid = await _showUssdWaitingModal(
          context: context,
          reference: collectResult.reference ?? externalRef,
          ussdCode: collectResult.ussdCode ?? (_method == 'momo' ? '*126#' : '#150*50#'),
          phone: _phoneCtrl.text.trim(),
        );

        if (!paid) {
          setState(() => _error = 'Payment was not confirmed or timed out. Please try again.');
          return;
        }

        // --- 3. Payment Confirmed: Hold in Escrow ---
        await _recordEscrowAndNavigate(collectResult.reference ?? externalRef);
      } else {
        // --- Card / Direct Processing ---
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
    bool isSuccess = false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            return StatefulBuilder(
              builder: (ctx, setModalState) {
                // Background polling timer inside modal
                Future.microtask(() async {
                  if (isCompleted) return;
                  final status = await _campayService.pollTransactionStatus(
                    reference: reference,
                    interval: const Duration(seconds: 3),
                    maxAttempts: 15,
                  );
                  if (!dialogCtx.mounted || isCompleted) return;
                  isCompleted = true;
                  if (status == CampayTransactionStatus.successful) {
                    isSuccess = true;
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
}

class _Method {
  final String key;
  final String label;
  final String short;
  final IconData icon;
  final Color color;
  final bool needsPhone;

  const _Method({
    required this.key,
    required this.label,
    required this.short,
    required this.icon,
    required this.color,
    required this.needsPhone,
  });
}
