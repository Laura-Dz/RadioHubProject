import 'package:flutter/material.dart';
import '../../../core/services/announcement_service.dart';
import '../../../core/services/channels_service.dart';
import '../../../core/models/radio_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../announcements/my_announcements_screen.dart';

class AnnouncementsTab extends StatefulWidget {
  const AnnouncementsTab({Key? key}) : super(key: key);

  @override
  State<AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<AnnouncementsTab> {
  final AnnouncementService _service = AnnouncementService();
  final ChannelsService _channelsService = ChannelsService();
  final TextEditingController _draftController = TextEditingController();

  int _step = 1;
  bool _loading = false;

  // Station Selection
  String _selectedRadioId = 'radio_1';
  String _selectedRadioName = 'Radio Sunshine';
  List<RadioModel> _stations = [];

  // Category & Payment
  String _category = 'Birthday';
  String _paymentMethod = 'MoMo';

  // Date and Period
  DateTime _startDate = DateTime.now();
  int _diffusionDays = 7;
  int _diffusionsPerDay = 1;

  DateTime get _endDate => _startDate.add(Duration(days: _diffusionDays));

  // AI Notor 1
  String _finalText = '';
  int _wordCount = 0;
  int _durationSeconds = 30;

  // AI Notor 2
  double _baseTariff = 0.0;
  double _transferFee = 0.0;
  double _finalPrice = 0.0;

  String? _submittedRefId;

  final List<String> _categories = [
    'Birthday',
    'Anniversary',
    'Congratulations',
    'Condolence',
    'Promotional',
    'Event',
    'General',
  ];

  final List<int> _periodOptions = [1, 3, 7, 14, 30];
  final List<int> _diffusionsPerDayOptions = [1, 2, 3];

  final List<Map<String, String>> _fallbackRadios = [
    {'id': 'radio_1', 'name': 'Radio Sunshine'},
    {'id': 'radio_2', 'name': 'City Beat FM'},
    {'id': 'radio_3', 'name': 'Capital Sound'},
  ];

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  void _loadStations() {
    _channelsService.streamAllRadios().listen((radios) {
      if (radios.isNotEmpty && mounted) {
        setState(() {
          _stations = radios;
          if (!_stations.any((r) => r.id == _selectedRadioId)) {
            _selectedRadioId = _stations.first.id;
            _selectedRadioName = _stations.first.name;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _step = 1;
      _submittedRefId = null;
      _draftController.clear();
      _finalText = '';
      _baseTariff = 0.0;
      _transferFee = 0.0;
      _finalPrice = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radio Announcements',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Draft, enhance with AI, select schedule, & hold payment in escrow.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white),
                    tooltip: 'My Announcements',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyAnnouncementsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step Indicator Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _stepDot(1, 'Details'),
                  _stepLine(1),
                  _stepDot(2, 'AI Text'),
                  _stepLine(2),
                  _stepDot(3, 'Tariff & Pay'),
                  _stepLine(3),
                  _stepDot(4, 'Escrow'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Step Content Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _stepTitle(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Step $_step of 4',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (_step == 1) _buildStep1(),
                  if (_step == 2) _buildStep2(),
                  if (_step == 3) _buildStep3(),
                  if (_step == 4) _buildStep4(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 1: return 'Announcement Details & Schedule';
      case 2: return 'AI Notor 1 — Broadcast Ready Text';
      case 3: return 'AI Notor 2 — Tariff & Escrow Payment';
      case 4: return 'Announcement Submitted';
      default: return '';
    }
  }

  Widget _stepDot(int stepNumber, String label) {
    final isActive = _step >= stepNumber;
    final isCurrent = _step == stepNumber;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? AppColors.primary : Colors.grey.shade300,
          child: Text(
            '$stepNumber',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int stepNumber) {
    final isDone = _step > stepNumber;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
        color: isDone ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }

  // STEP 1: Station, Category, Start Date & Period, Message Draft
  Widget _buildStep1() {
    final radioItems = _stations.isNotEmpty
        ? _stations.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList()
        : _fallbackRadios.map((r) => DropdownMenuItem(value: r['id'], child: Text(r['name']!))).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Radio Station Picker
        const Text('Radio Station', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedRadioId,
          items: radioItems,
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _selectedRadioId = v;
                if (_stations.isNotEmpty) {
                  final found = _stations.firstWhere((r) => r.id == v, orElse: () => _stations.first);
                  _selectedRadioName = found.name;
                } else {
                  final found = _fallbackRadios.firstWhere((r) => r['id'] == v, orElse: () => _fallbackRadios.first);
                  _selectedRadioName = found['name']!;
                }
              });
            }
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.radio, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Category
        const Text('Announcement Category', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _category,
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _category = v!),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Date selection before period (Start Date)
        const Text('Start Date', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickStartDate,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  _formatDate(_startDate),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const Text('Choose Date', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Diffusion Period (Days)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Diffusion Period', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('$_diffusionDays days', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _periodOptions.map((days) {
            final isSelected = _diffusionDays == days;
            return ChoiceChip(
              label: Text('$days ${days == 1 ? "day" : "days"}'),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.15),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _diffusionDays = days);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // 5. Broadcasts per day
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Broadcasts per Day', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('${_diffusionsPerDay}x / day', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _diffusionsPerDayOptions.map((count) {
            final isSelected = _diffusionsPerDay == count;
            return ChoiceChip(
              label: Text('${count}x / day'),
              selected: isSelected,
              selectedColor: AppColors.primary.withOpacity(0.15),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _diffusionsPerDay = count);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // 6. Schedule summary box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Broadcast Window: ${_formatDate(_startDate)}  ➔  ${_formatDate(_endDate)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_diffusionDays days · ${_diffusionDays * _diffusionsPerDay} total broadcasts on $_selectedRadioName',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 7. Message Draft
        const Text('Your Announcement Draft', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _draftController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'e.g. Happy birthday to our beloved mother Amina! We wish you good health and prosperity.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),

        // Submit Step 1 Action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _runAiEnhancement,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: _loading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enhance with AI Notor 1'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: AI Notor 1 Output
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text('AI Notor 1 formatted your message for radio broadcast standards.', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Broadcast Ready Text:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: _finalText,
          maxLines: 4,
          onChanged: (v) => _finalText = v,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Station: $_selectedRadioName')),
            Chip(label: Text('Word Count: $_wordCount')),
            Chip(label: Text('Duration: ${_durationSeconds}s')),
            Chip(label: Text('Schedule: ${_diffusionDays}d (${_diffusionDays * _diffusionsPerDay}x)')),
            Chip(label: Text('${_formatDate(_startDate)} - ${_formatDate(_endDate)}')),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _calculatePrice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Calculate Price (AI Notor 2)'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: AI Notor 2 Price Breakdown & Payment
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Station & Schedule Overview
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.radio, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(_selectedRadioName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(_category, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(height: 14),
              Text(
                '📅 ${_formatDate(_startDate)}  ➔  ${_formatDate(_endDate)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '$_diffusionDays days · ${_diffusionDays * _diffusionsPerDay} total broadcasts (${_durationSeconds}s each)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Tariff Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              _priceRow('Base Tariff (to Radio)', '${_baseTariff.toStringAsFixed(0)} XAF'),
              const Divider(height: 16),
              _priceRow('Transfer Fee (4%)', '${_transferFee.toStringAsFixed(0)} XAF'),
              const Divider(height: 16),
              _priceRow('Total Price', '${_finalPrice.toStringAsFixed(0)} XAF', bold: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Select Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: ['MoMo', 'OM', 'Ecobank', 'Card'].map((m) => Expanded(
            child: RadioListTile<String>(
              value: m,
              groupValue: _paymentMethod,
              title: Text(m, style: const TextStyle(fontSize: 12)),
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 2),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Pay & Hold in Escrow (${_finalPrice.toStringAsFixed(0)} XAF)'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 4: Escrow Confirmation
  Widget _buildStep4() {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 56),
        const SizedBox(height: 12),
        const Text('Announcement Submitted!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              if (_submittedRefId != null) ...[
                Text('Ref: $_submittedRefId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
              ],
              Text('Station: $_selectedRadioName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Schedule: ${_formatDate(_startDate)} - ${_formatDate(_endDate)} ($_diffusionDays days)', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              Text('Status: In Escrow (${_finalPrice.toStringAsFixed(0)} XAF held)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Your payment of ${_finalPrice.toStringAsFixed(0)} XAF is securely held in escrow until validated by $_selectedRadioName. If rejected, your base tariff will be refunded directly to your wallet.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetForm,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Create Another'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyAnnouncementsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('My Announcements'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: bold ? 16 : 13, fontWeight: FontWeight.bold, color: bold ? AppColors.primary : Colors.black87)),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _runAiEnhancement() async {
    if (_draftController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your announcement text draft.')),
      );
      return;
    }
    setState(() => _loading = true);
    final res = await _service.suggestImprovedText(text: _draftController.text.trim(), category: _category);
    setState(() {
      _finalText = res['improved_text'] ?? _draftController.text.trim();
      _wordCount = (res['word_count'] as int?) ?? _finalText.split(' ').length;
      _durationSeconds = (res['estimated_duration_seconds'] as int?) ?? 30;
      _loading = false;
      _step = 2;
    });
  }

  Future<void> _calculatePrice() async {
    setState(() => _loading = true);
    final totalDiffusions = _diffusionDays * _diffusionsPerDay;
    final res = await _service.calculatePrice(
      wordCount: _wordCount,
      durationSeconds: _durationSeconds,
      diffusionCount: totalDiffusions,
    );
    setState(() {
      _baseTariff = (res['base_tariff'] as num).toDouble();
      _transferFee = (res['transfer_fee'] as num).toDouble();
      _finalPrice = (res['final_price'] as num).toDouble();
      _loading = false;
      _step = 3;
    });
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final totalDiffusions = _diffusionDays * _diffusionsPerDay;
    final id = await _service.submitAnnouncementRequest(
      radioId: _selectedRadioId,
      radioName: _selectedRadioName,
      listenerId: 'listener_123',
      listenerName: 'Laura Listener',
      listenerEmail: 'laura@example.com',
      category: _category,
      originalText: _draftController.text.trim(),
      finalText: _finalText,
      wordCount: _wordCount,
      durationSeconds: _durationSeconds,
      diffusionCount: totalDiffusions,
      baseTariff: _baseTariff,
      transferFee: _transferFee,
      finalPrice: _finalPrice,
      paymentMethod: _paymentMethod,
      startDate: _startDate,
      endDate: _endDate,
      diffusionPeriodDays: _diffusionDays,
      diffusionsPerDay: _diffusionsPerDay,
    );
    setState(() {
      _submittedRefId = id.isNotEmpty ? id : null;
      _loading = false;
      _step = 4;
    });
  }
}
