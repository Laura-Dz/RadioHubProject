import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../view_models/radio_admin_view_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/subscription_plan_service.dart';

class SubscriptionPaymentDialog extends StatefulWidget {
  final SubscriptionPlan plan;

  const SubscriptionPaymentDialog({Key? key, required this.plan}) : super(key: key);

  @override
  State<SubscriptionPaymentDialog> createState() => _SubscriptionPaymentDialogState();
}

class _SubscriptionPaymentDialogState extends State<SubscriptionPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  String _method = 'MoMo'; // 'MoMo', 'OrangeMoney', 'CreditCard'
  bool _useDefault = true;

  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  bool _saveAsDefault = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _getDefaultPhone(RadioAdminViewModel vm) {
    if (vm.radioProfile?.contactPhone?.isNotEmpty == true) {
      return vm.radioProfile!.contactPhone!;
    }
    return '+237 671 234 567';
  }

  String _getDefaultCard() {
    return '•••• •••• •••• 4242 (Visa)';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final defaultPhone = _getDefaultPhone(vm);
    final defaultCard = _getDefaultCard();

    final isCard = _method == 'CreditCard';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.payment_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay for ${widget.plan.label} Plan',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Station broadcasting license & hosting',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _isProcessing ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount Summary Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Amount to Pay', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.plan.amount.toStringAsFixed(0)} ${widget.plan.currency}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.plan.days} Days License',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment Method Selection
                  const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _buildMethodChip(
                        id: 'MoMo',
                        title: 'MTN MoMo',
                        icon: Icons.phone_android_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildMethodChip(
                        id: 'OrangeMoney',
                        title: 'Orange Money',
                        icon: Icons.phone_iphone_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildMethodChip(
                        id: 'CreditCard',
                        title: 'Card / Ecobank',
                        icon: Icons.credit_card_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Account / Card Section Header
                  Text(
                    isCard ? 'Card Information' : 'Mobile Money Number',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),

                  // Option 1: Use Default Account / Card
                  InkWell(
                    onTap: () => setState(() => _useDefault = true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _useDefault ? AppColors.primary.withOpacity(0.04) : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _useDefault ? AppColors.primary : AppColors.border,
                          width: _useDefault ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _useDefault ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: _useDefault ? AppColors.primary : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isCard ? 'Use default card on file' : 'Use default registered number',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Default', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCard ? defaultCard : '$defaultPhone (Radio Contact)',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isCard ? Icons.credit_card : Icons.phone_android,
                            color: _useDefault ? AppColors.primary : Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Option 2: Enter Number or Card
                  InkWell(
                    onTap: () => setState(() => _useDefault = false),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !_useDefault ? AppColors.primary.withOpacity(0.04) : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !_useDefault ? AppColors.primary : AppColors.border,
                          width: !_useDefault ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !_useDefault ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: !_useDefault ? AppColors.primary : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCard ? 'Enter a new card' : 'Enter another phone number',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCard ? 'Visa, MasterCard, or Ecobank Card' : 'Provide custom MTN MoMo / Orange Money number',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit_note_rounded,
                            color: !_useDefault ? AppColors.primary : Colors.grey.shade400,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Input space when NOT using default
                  if (!_useDefault) ...[
                    const SizedBox(height: 14),
                    if (isCard) ...[
                      // Card Inputs
                      TextFormField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Card Number',
                          hintText: '4111 2222 3333 4444',
                          prefixIcon: const Icon(Icons.credit_card, size: 20, color: AppColors.primary),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) {
                          if (_useDefault) return null;
                          if (v == null || v.trim().replaceAll(' ', '').length < 12) {
                            return 'Please enter a valid card number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expiryController,
                              keyboardType: TextInputType.datetime,
                              decoration: InputDecoration(
                                labelText: 'Expiry (MM/YY)',
                                hintText: '12/28',
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: (v) {
                                if (_useDefault) return null;
                                if (v == null || v.trim().length < 4) return 'MM/YY';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _cvvController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'CVV',
                                hintText: '123',
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: (v) {
                                if (_useDefault) return null;
                                if (v == null || v.trim().length < 3) return '3-4 digits';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Cardholder Name (Optional)',
                          hintText: 'e.g. Jean Dupont',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ] else ...[
                      // Phone Number Input for MoMo / OrangeMoney
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: _method == 'MoMo' ? 'MTN MoMo Phone Number' : 'Orange Money Phone Number',
                          hintText: 'e.g. +237 671 234 567 or 6XXXXXXXX',
                          prefixIcon: Icon(
                            _method == 'MoMo' ? Icons.phone_android : Icons.phone_iphone,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) {
                          if (_useDefault) return null;
                          if (v == null || v.trim().length < 8) {
                            return 'Please enter a valid mobile money number';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _saveAsDefault,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() => _saveAsDefault = v ?? false),
                        ),
                        Text(
                          isCard ? 'Save card for future billing' : 'Save number for future billing',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isProcessing ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : () => _submitPayment(defaultPhone, defaultCard),
                        icon: _isProcessing
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(_isProcessing ? 'Processing...' : 'Pay & Activate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodChip({
    required String id,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _method == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _method = id),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitPayment(String defaultPhone, String defaultCard) async {
    if (!_useDefault && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    String paymentAccount;
    if (_useDefault) {
      paymentAccount = _method == 'CreditCard' ? defaultCard : defaultPhone;
    } else {
      if (_method == 'CreditCard') {
        final rawCard = _cardNumberController.text.trim().replaceAll(' ', '');
        final last4 = rawCard.length >= 4 ? rawCard.substring(rawCard.length - 4) : rawCard;
        paymentAccount = '•••• •••• •••• $last4 (${_expiryController.text.trim()})';
      } else {
        paymentAccount = _phoneController.text.trim();
      }
    }

    try {
      await context.read<RadioAdminViewModel>().paySubscription(
        plan: widget.plan,
        paymentMethod: _method,
        paymentAccount: paymentAccount,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.plan.label} Subscription activated with $paymentAccount!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
