import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/radio_model.dart';
import '../../../core/services/digi_pay_service.dart';
import '../../../core/services/flutterwave_service.dart';

enum DonationPaymentMethod {
  mobileMoney,
  bankTransfer,
}

enum DonationStep {
  form,
  confirming,
  bankTransferDetails,
  success,
  failed,
}

class DonationSheet extends StatefulWidget {
  final RadioModel radio;
  final double? initialAmount;

  const DonationSheet({
    Key? key,
    required this.radio,
    this.initialAmount,
  }) : super(key: key);

  @override
  State<DonationSheet> createState() => _DonationSheetState();
}

class _DonationSheetState extends State<DonationSheet> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _customAmountController = TextEditingController();
  final _noteController = TextEditingController();

  final List<double> _presetAmounts = [500, 1000, 2500, 5000, 10000];
  late double _selectedAmount;
  bool _isCustomAmount = false;
  DonationPaymentMethod _paymentMethod = DonationPaymentMethod.mobileMoney;
  String _selectedOperator = 'MTN'; // 'MTN' or 'ORANGE'

  DonationStep _currentStep = DonationStep.form;
  String? _statusMessage;
  String? _ussdCode;
  String? _transactionId;
  int _pollAttempt = 0;
  bool _isVerifyingBankTransfer = false;
  FlutterwaveBankTransferDetails? _bankTransferDetails;

  final DigiPayService _digiPayService = DigiPayService();
  final FlutterwaveService _flutterwaveService = FlutterwaveService();

  @override
  void initState() {
    super.initState();
    _selectedAmount = widget.initialAmount ?? 1000;
    if (!_presetAmounts.contains(_selectedAmount)) {
      _isCustomAmount = true;
      _customAmountController.text = _selectedAmount.toInt().toString();
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      if (user.email != null && user.email!.isNotEmpty) {
        _emailController.text = user.email!;
      }
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        _phoneController.text = user.phoneNumber!.replaceAll('+237', '');
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _customAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _effectiveAmount {
    if (_isCustomAmount) {
      return double.tryParse(_customAmountController.text.trim()) ?? 0;
    }
    return _selectedAmount;
  }

  Future<void> _handleInitiateDonation() async {
    final amount = _effectiveAmount;
    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum donation amount is 100 XAF'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_paymentMethod == DonationPaymentMethod.bankTransfer) {
      await _handleInitiateBankTransfer();
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Cameroon phone number (e.g. 671234567)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _currentStep = DonationStep.confirming;
      _statusMessage = 'Connecting to DigiPay...';
      _pollAttempt = 0;
    });

    final donorName = _nameController.text.trim().isEmpty ? 'Anonymous' : _nameController.text.trim();

    try {
      final initResult = await _digiPayService.initiateDonation(
        amount: amount,
        phone: phone,
        radioId: widget.radio.id,
        radioName: widget.radio.name,
        donorName: donorName,
        operatorChoice: _selectedOperator,
        note: _noteController.text.trim(),
      );

      if (!initResult.success) {
        setState(() {
          _currentStep = DonationStep.failed;
          _statusMessage = initResult.message ?? 'Payment initiation failed';
        });
        return;
      }

      setState(() {
        _transactionId = initResult.transactionId;
        _ussdCode = initResult.ussdCode ?? (_selectedOperator == 'MTN' ? '*126#' : '#150*50#');
        _statusMessage = 'Payment request sent! Please authorize the prompt on your phone ($_ussdCode)';
      });

      // Poll transaction status
      final finalStatus = await _digiPayService.pollTransactionStatus(
        transactionId: initResult.transactionId!,
        interval: const Duration(seconds: 2),
        maxAttempts: 15,
        onTick: (attempt, status) {
          if (mounted) {
            setState(() {
              _pollAttempt = attempt;
              if (attempt > 3) {
                _statusMessage = 'Awaiting your mobile PIN confirmation on $_selectedOperator ($_ussdCode)...';
              }
            });
          }
        },
      );

      if (finalStatus == DigiPayTransactionStatus.successful) {
        // Record successful donation in Firestore
        await _digiPayService.recordDonation(
          radioId: widget.radio.id,
          radioName: widget.radio.name,
          amount: amount,
          transactionId: initResult.transactionId!,
          paymentMethod: 'DigiPay ($_selectedOperator)',
          donorName: donorName,
          donorPhone: phone,
          note: _noteController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _currentStep = DonationStep.success;
            _statusMessage = 'Donation successful! Thank you for supporting ${widget.radio.name}.';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentStep = DonationStep.failed;
            _statusMessage = 'Transaction was not completed or was cancelled.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentStep = DonationStep.failed;
          _statusMessage = 'An unexpected error occurred: $e';
        });
      }
    }
  }

  Future<void> _handleInitiateBankTransfer() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address to receive bank transfer details'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final amount = _effectiveAmount;
    setState(() {
      _currentStep = DonationStep.confirming;
      _statusMessage = 'Generating Flutterwave Bank Escrow Account...';
    });

    final donorName = _nameController.text.trim().isEmpty ? 'Anonymous Donor' : _nameController.text.trim();
    final cleanRadioId = widget.radio.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final radioPrefix = cleanRadioId.substring(0, cleanRadioId.length > 5 ? 5 : cleanRadioId.length);
    final txRef = 'DON_FLW_${radioPrefix}_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final details = await _flutterwaveService.initiateBankTransfer(
        amount: amount,
        email: email,
        txRef: txRef,
        currency: 'XAF',
        fullName: donorName,
        phoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _bankTransferDetails = details;
          _transactionId = details.txRef ?? txRef;
          _currentStep = DonationStep.bankTransferDetails;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentStep = DonationStep.failed;
          _statusMessage = 'Could not generate bank transfer details: $e';
        });
      }
    }
  }

  Future<void> _handleVerifyBankTransfer() async {
    if (_bankTransferDetails == null) return;
    setState(() {
      _isVerifyingBankTransfer = true;
    });

    try {
      final donorName = _nameController.text.trim().isEmpty ? 'Anonymous Donor' : _nameController.text.trim();
      final txRef = _bankTransferDetails!.txRef ?? _transactionId!;

      final status = await _flutterwaveService.verifyTransaction(txRef);

      // In sandbox/test environment or if verified:
      if (status == FlutterwaveStatus.successful || _bankTransferDetails!.isSimulated) {
        await _digiPayService.recordDonation(
          radioId: widget.radio.id,
          radioName: widget.radio.name,
          amount: _effectiveAmount,
          transactionId: txRef,
          paymentMethod: 'Bank Transfer (Flutterwave)',
          donorName: donorName,
          donorPhone: _phoneController.text.trim(),
          note: _noteController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _isVerifyingBankTransfer = false;
            _currentStep = DonationStep.success;
            _statusMessage = 'Bank transfer confirmed! Thank you for supporting ${widget.radio.name}.';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isVerifyingBankTransfer = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment not yet detected by Flutterwave. Please verify once your bank confirms the transfer.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingBankTransfer = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_currentStep == DonationStep.form) _buildFormStep(),
            if (_currentStep == DonationStep.confirming) _buildConfirmingStep(),
            if (_currentStep == DonationStep.bankTransferDetails) _buildBankTransferStep(),
            if (_currentStep == DonationStep.success) _buildSuccessStep(),
            if (_currentStep == DonationStep.failed) _buildFailedStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support ${widget.radio.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Non-Profit Station',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '• DigiPay & Flutterwave',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Info Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '100% of your voluntary contribution directly funds broadcast production and community programs.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Select Amount
        const Text(
          'Select Donation Amount (XAF)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._presetAmounts.map((amt) {
              final isSelected = !_isCustomAmount && _selectedAmount == amt;
              return ChoiceChip(
                label: Text('${amt.toInt()} XAF'),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.background,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _isCustomAmount = false;
                      _selectedAmount = amt;
                      _customAmountController.clear();
                    });
                  }
                },
              );
            }),
            ChoiceChip(
              label: const Text('Other Amount'),
              selected: _isCustomAmount,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.background,
              labelStyle: TextStyle(
                color: _isCustomAmount ? Colors.white : AppColors.textPrimary,
                fontWeight: _isCustomAmount ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: _isCustomAmount ? AppColors.primary : AppColors.border,
                ),
              ),
              onSelected: (val) {
                if (val) {
                  setState(() => _isCustomAmount = true);
                }
              },
            ),
          ],
        ),

        if (_isCustomAmount) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Enter amount in XAF (e.g. 15000)',
              prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
              suffixText: 'XAF',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],

        const SizedBox(height: 18),

        // Payment Method Selector
        const Text(
          'Payment Gateway',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _paymentMethod = DonationPaymentMethod.mobileMoney),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _paymentMethod == DonationPaymentMethod.mobileMoney
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _paymentMethod == DonationPaymentMethod.mobileMoney
                          ? AppColors.primary
                          : AppColors.border,
                      width: _paymentMethod == DonationPaymentMethod.mobileMoney ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.phone_android_rounded,
                        color: _paymentMethod == DonationPaymentMethod.mobileMoney
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mobile Money',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _paymentMethod == DonationPaymentMethod.mobileMoney
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'DigiPay / CamPay',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _paymentMethod = DonationPaymentMethod.bankTransfer),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _paymentMethod == DonationPaymentMethod.bankTransfer
                        ? const Color(0xFF0A2540).withOpacity(0.08)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _paymentMethod == DonationPaymentMethod.bankTransfer
                          ? const Color(0xFF0A2540)
                          : AppColors.border,
                      width: _paymentMethod == DonationPaymentMethod.bankTransfer ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        color: _paymentMethod == DonationPaymentMethod.bankTransfer
                            ? const Color(0xFF0A2540)
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bank Transfer',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _paymentMethod == DonationPaymentMethod.bankTransfer
                              ? const Color(0xFF0A2540)
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Flutterwave Wire',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (_paymentMethod == DonationPaymentMethod.mobileMoney) ...[
          // Operator Selection
          const Text(
            'Mobile Money Operator',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedOperator = 'MTN'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedOperator == 'MTN'
                          ? const Color(0xFFFFCC00).withOpacity(0.15)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedOperator == 'MTN' ? const Color(0xFFFFCC00) : AppColors.border,
                        width: _selectedOperator == 'MTN' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFCC00),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'MTN MoMo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedOperator = 'ORANGE'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedOperator == 'ORANGE'
                          ? const Color(0xFFFF6600).withOpacity(0.15)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedOperator == 'ORANGE' ? const Color(0xFFFF6600) : AppColors.border,
                        width: _selectedOperator == 'ORANGE' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6600),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Orange Money',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Phone input
          const Text(
            'Phone Number',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: const Text(
                  '🇨🇲 +237',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
              hintText: '6XXXXXXXX',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (val) {
              final op = DigiPayService.detectOperator(val);
              if (op != _selectedOperator) {
                setState(() => _selectedOperator = op);
              }
            },
          ),
        ] else ...[
          // Bank Transfer Email & Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2540).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0A2540).withOpacity(0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF0A2540), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Direct Bank Transfer powered by Flutterwave. Generates an Ecobank / UBA escrow account.',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Email Address (for transfer details)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              hintText: 'e.g. donor@gmail.com',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Phone Number (Optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              hintText: 'Optional contact number',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Optional Name & Note
        TextFormField(
          controller: _nameController,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Your Name (Optional)',
            hintText: 'e.g. Samuel M.',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _noteController,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Encouragement message (Optional)',
            hintText: 'e.g. Love the morning community show!',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),

        const SizedBox(height: 20),

        // Submit Button
        ElevatedButton.icon(
          onPressed: _handleInitiateDonation,
          icon: Icon(
            _paymentMethod == DonationPaymentMethod.bankTransfer
                ? Icons.account_balance_rounded
                : Icons.volunteer_activism_rounded,
            size: 20,
          ),
          label: Text(
            _paymentMethod == DonationPaymentMethod.bankTransfer
                ? 'Donate ${_effectiveAmount.toInt()} XAF via Bank Transfer'
                : 'Donate ${_effectiveAmount.toInt()} XAF via DigiPay',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _paymentMethod == DonationPaymentMethod.bankTransfer
                ? const Color(0xFF0A2540)
                : AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildBankTransferStep() {
    final details = _bankTransferDetails;
    if (details == null) {
      return _buildFailedStep();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A2540).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_rounded, color: Color(0xFF0A2540), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bank Wire Instructions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Direct Transfer via Flutterwave Escrow',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2540).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0A2540).withOpacity(0.15)),
            ),
            child: const Text(
              'Transfer the exact amount to the virtual escrow account below via your banking app or counter transfer:',
              style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.35),
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildBankInfoRow('Bank Name', details.bankName ?? 'Ecobank Cameroon'),
                const Divider(height: 18),
                _buildBankInfoRow(
                  'Account Number',
                  details.accountNumber ?? '10002849182',
                  isCopyable: true,
                ),
                const Divider(height: 18),
                _buildBankInfoRow(
                  'Amount',
                  '${_effectiveAmount.toInt()} XAF',
                  highlight: true,
                ),
                const Divider(height: 18),
                _buildBankInfoRow(
                  'Reference / Narration',
                  details.txRef ?? _transactionId ?? '',
                  isCopyable: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Account expires: ${details.expiresAt ?? "in 60 minutes"}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _isVerifyingBankTransfer ? null : _handleVerifyBankTransfer,
            icon: _isVerifyingBankTransfer
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              _isVerifyingBankTransfer ? 'Verifying Transfer...' : 'I Have Transferred / Verify',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A2540),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),

          TextButton(
            onPressed: () {
              setState(() {
                _currentStep = DonationStep.form;
              });
            },
            child: const Text('Back to Donation Form'),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(String label, String value, {bool isCopyable = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: highlight ? 14.5 : 13,
                fontWeight: FontWeight.bold,
                color: highlight ? AppColors.secondary : AppColors.textPrimary,
              ),
            ),
            if (isCopyable) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied to clipboard'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmingStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Authorizing via DigiPay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            _statusMessage ?? 'Please check your phone for the mobile money prompt.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
          ),
          if (_ussdCode != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dialpad, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Manual USSD fallback: dial $_ussdCode',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Attempt $_pollAttempt of 15',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 18),
          const Text(
            'Donation Received!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for your generous gift of ${_effectiveAmount.toInt()} XAF to ${widget.radio.name}.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          if (_transactionId != null) ...[
            const SizedBox(height: 10),
            Text(
              'Reference: $_transactionId',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Not Completed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage ?? 'The transaction could not be verified.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = DonationStep.form;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
