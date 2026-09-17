import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/constants/app_colors.dart';
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
  final _fns = FirebaseFunctions.instanceFor(region: 'europe-west1');

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
      final callable = _fns.httpsCallable('processAnnouncementPayment');
      final res = await callable.call({
        'announcementId': widget.announcementId,
        'paymentMethod': _method,
        'phone': _phoneCtrl.text.trim(),
      });

      final data = Map<String, dynamic>.from(res.data);
      if (data['success'] != true) {
        throw Exception('Payment failed');
      }

      if (!mounted) return;

      // Navigate to confirmation
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AnnouncementSubmittedScreen(
            announcementId: widget.announcementId,
            radioName: widget.radioName,
            reference: (data['reference'] ?? '').toString(),
            amount: widget.finalPrice,
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      setState(() => _error = e.message ?? 'Payment failed');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
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
