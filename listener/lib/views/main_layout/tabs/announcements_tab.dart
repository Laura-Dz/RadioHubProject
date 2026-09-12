import 'package:flutter/material.dart';
import '../../../core/services/announcement_service.dart';
import '../../../core/theme/app_colors.dart';

class AnnouncementsTab extends StatefulWidget {
  const AnnouncementsTab({Key? key}) : super(key: key);

  @override
  State<AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<AnnouncementsTab> {
  final AnnouncementService _service = AnnouncementService();

  int _currentStep = 0;
  bool _loading = false;

  // Form Fields
  String _selectedRadioId = 'radio_1';
  String _selectedRadioName = 'Radio Sunshine';
  String _selectedCategory = 'Birthday';
  final _draftController = TextEditingController();

  // Step 2 AI Text Output
  String _finalText = '';
  int _wordCount = 0;
  int _durationSeconds = 30;

  // Step 3 AI Price Output
  double _baseTariff = 0.0;
  double _transferFee = 0.0;
  double _finalPrice = 0.0;

  // Step 4 Payment Method
  String _paymentMethod = 'MoMo';

  // Step 5 Result
  String? _submittedId;

  final List<Map<String, String>> _radios = [
    {'id': 'radio_1', 'name': 'Radio Sunshine'},
    {'id': 'radio_2', 'name': 'City Beat FM'},
    {'id': 'radio_3', 'name': 'Capital Sound'},
  ];

  final List<String> _categories = [
    'Birthday',
    'Anniversary',
    'Congratulations',
    'Condolence',
    'Promotional',
    'Event',
    'General',
  ];

  final List<String> _paymentMethods = [
    'MoMo',
    'OM',
    'Ecobank',
    'Credit Card',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.campaign, color: Colors.white, size: 36),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI-Powered Radio Announcement',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Draft, enhance with AI, calculate cost, & broadcast on your favorite station.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stepper Widget
            Theme(
              data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
              child: Stepper(
                currentStep: _currentStep,
                physics: const NeverScrollableScrollPhysics(),
                onStepContinue: _nextStep,
                onStepCancel: _currentStep > 0 && _submittedId == null ? () => setState(() => _currentStep--) : null,
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        if (_submittedId == null)
                          ElevatedButton(
                            onPressed: _loading ? null : details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _loading
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(_currentStep == 3 ? 'Pay & Submit' : (_currentStep == 4 ? 'Done' : 'Next Step')),
                          ),
                        if (details.onStepCancel != null) ...[
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Back'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: [
                  // STEP 1: Radio & Message Draft
                  Step(
                    title: const Text('Station & Message Draft'),
                    subtitle: const Text('Select radio station and category'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Radio Station', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedRadioId,
                          items: _radios.map((r) => DropdownMenuItem(value: r['id'], child: Text(r['name']!))).toList(),
                          onChanged: (v) => setState(() {
                            _selectedRadioId = v!;
                            _selectedRadioName = _radios.firstWhere((r) => r['id'] == v)['name']!;
                          }),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        const Text('Announcement Category', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        const Text('Your Announcement Draft', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _draftController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Happy 30th Birthday to my dear friend Sarah! Wishing you the best year ahead.',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // STEP 2: AI Notor 1 Text Improvement
                  Step(
                    title: const Text('AI Notor 1 — Text Enhancement'),
                    subtitle: const Text('AI-optimized version'),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('AI Notor 1 has enhanced your message for broadcasting quality.',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Enhanced Broadcast Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: _finalText,
                          maxLines: 4,
                          onChanged: (v) => _finalText = v,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _chip('Word Count', '$_wordCount words'),
                            const SizedBox(width: 8),
                            _chip('Est. Duration', '${_durationSeconds}s'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // STEP 3: AI Notor 2 Price Calculation
                  Step(
                    title: const Text('AI Notor 2 — Price Breakdown'),
                    subtitle: const Text('Tariff + 4% transfer fee'),
                    isActive: _currentStep >= 2,
                    state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                    content: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _priceRow('Base Tariff (to Radio Station)', '${_baseTariff.toStringAsFixed(0)} XAF'),
                          const Divider(height: 20),
                          _priceRow('System Transfer Fee (4%)', '${_transferFee.toStringAsFixed(0)} XAF'),
                          const Divider(height: 20),
                          _priceRow('Total Price', '${_finalPrice.toStringAsFixed(0)} XAF', isTotal: true),
                        ],
                      ),
                    ),
                  ),

                  // STEP 4: Payment Method Selection
                  Step(
                    title: const Text('Payment Method'),
                    subtitle: const Text('Select payment option'),
                    isActive: _currentStep >= 3,
                    state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                    content: Column(
                      children: _paymentMethods.map((m) => RadioListTile<String>(
                        value: m,
                        groupValue: _paymentMethod,
                        title: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(m == 'MoMo' || m == 'OM' ? 'Instant Mobile Money' : 'Bank Transfer / Card'),
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                      )).toList(),
                    ),
                  ),

                  // STEP 5: Confirmation & Status
                  Step(
                    title: const Text('Confirmation & Escrow Status'),
                    subtitle: const Text('Request submitted'),
                    isActive: _currentStep >= 4,
                    state: StepState.complete,
                    content: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 28),
                              SizedBox(width: 8),
                              Text('Request Submitted!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Ref ID: ${_submittedId ?? "N/A"}'),
                          const SizedBox(height: 4),
                          const Text('Status: In Escrow (Pending Validation)'),
                          const SizedBox(height: 12),
                          const Text(
                            'Your base payment is securely held in escrow until validated by the Radio Admin. If rejected, your base tariff will be automatically refunded.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 15 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: FontWeight.bold, color: isTotal ? AppColors.primary : Colors.black87)),
      ],
    );
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      if (_draftController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your announcement text draft.')),
        );
        return;
      }
      setState(() => _loading = true);

      // Call AI Notor 1
      final aiRes = await _service.suggestImprovedText(
        text: _draftController.text.trim(),
        category: _selectedCategory,
      );
      setState(() {
        _finalText = aiRes['improved_text'] ?? _draftController.text.trim();
        _wordCount = (aiRes['word_count'] as int?) ?? _finalText.split(' ').length;
        _durationSeconds = (aiRes['estimated_duration_seconds'] as int?) ?? 30;
        _loading = false;
        _currentStep = 1;
      });
    } else if (_currentStep == 1) {
      setState(() => _loading = true);

      // Call AI Notor 2
      final priceRes = await _service.calculatePrice(
        wordCount: _wordCount,
        durationSeconds: _durationSeconds,
        diffusionCount: 1,
      );
      setState(() {
        _baseTariff = (priceRes['base_tariff'] as num).toDouble();
        _transferFee = (priceRes['transfer_fee'] as num).toDouble();
        _finalPrice = (priceRes['final_price'] as num).toDouble();
        _loading = false;
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      setState(() => _loading = true);

      // Submit to Firestore & Escrow
      final reqId = await _service.submitAnnouncementRequest(
        radioId: _selectedRadioId,
        radioName: _selectedRadioName,
        listenerId: 'listener_123',
        listenerName: 'Laura Listener',
        listenerEmail: 'laura@example.com',
        category: _selectedCategory,
        originalText: _draftController.text.trim(),
        finalText: _finalText,
        wordCount: _wordCount,
        durationSeconds: _durationSeconds,
        diffusionCount: 1,
        baseTariff: _baseTariff,
        transferFee: _transferFee,
        finalPrice: _finalPrice,
        paymentMethod: _paymentMethod,
      );

      setState(() {
        _submittedId = reqId;
        _loading = false;
        _currentStep = 4;
      });
    } else if (_currentStep == 4) {
      // Reset form
      setState(() {
        _currentStep = 0;
        _submittedId = null;
        _draftController.clear();
      });
    }
  }
}

