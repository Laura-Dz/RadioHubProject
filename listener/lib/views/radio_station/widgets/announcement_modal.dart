import 'package:flutter/material.dart';
import '../../../core/services/announcement_service.dart';
import '../../../view_models/radio_station_view_model.dart';
import '../../../core/theme/app_colors.dart';

class AnnouncementModal extends StatefulWidget {
  final RadioStationViewModel viewModel;
  final VoidCallback onRequestSubmitted;

  const AnnouncementModal({
    Key? key,
    required this.viewModel,
    required this.onRequestSubmitted,
  }) : super(key: key);

  @override
  State<AnnouncementModal> createState() => _AnnouncementModalState();
}

class _AnnouncementModalState extends State<AnnouncementModal> {
  final AnnouncementService _service = AnnouncementService();
  final TextEditingController _draftController = TextEditingController();

  int _step = 1;
  bool _loading = false;

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

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radio = widget.viewModel.radio;
    final radioName = radio?.name ?? 'Radio Station';

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.campaign, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Announcement for $radioName',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Step $_step of 4', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            if (_step == 1) _buildStep1(),
            if (_step == 2) _buildStep2(),
            if (_step == 3) _buildStep3(),
            if (_step == 4) _buildStep4(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _category,
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _category = v!),
          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        ),
        const SizedBox(height: 16),

        // Date selection before period (Start Date)
        const Text('Start Date', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickStartDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
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
                const Text('Change', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Diffusion Period (Days)
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

        // Diffusions per day
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

        // Schedule summary banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(0.6),
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
                      'Schedule: ${_formatDate(_startDate)}  ➔  ${_formatDate(_endDate)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_diffusionDays days · ${_diffusionDays * _diffusionsPerDay} total broadcasts',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Your Message Draft', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _draftController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Type your message (e.g. Wishing happy birthday to...)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
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
              Expanded(child: Text('AI Notor 1 formatted your message for radio broadcast.', style: TextStyle(fontSize: 12))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text('Broadcast Ready Text:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: _finalText,
          maxLines: 4,
          onChanged: (v) => _finalText = v,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Word Count: $_wordCount')),
            Chip(label: Text('Duration: ${_durationSeconds}s')),
            Chip(label: Text('Schedule: ${_diffusionDays}d (${_diffusionDays * _diffusionsPerDay}x)')),
            Chip(label: Text('${_formatDate(_startDate)} - ${_formatDate(_endDate)}')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => setState(() => _step = 1),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
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

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Schedule summary box
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.bottom(12),
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
                  const Icon(Icons.radio, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(widget.viewModel.radio?.name ?? 'Radio Station', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(_category, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(height: 12),
              Text(
                '📅 ${_formatDate(_startDate)}  ➔  ${_formatDate(_endDate)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '$_diffusionDays days · ${_diffusionDays * _diffusionsPerDay} broadcasts (${_durationSeconds}s each)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Tariff breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              _priceRow('Base Tariff', '${_baseTariff.toStringAsFixed(0)} XAF'),
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
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
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

  Widget _buildStep4() {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 52),
        const SizedBox(height: 12),
        const Text('Announcement Submitted!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
          child: Column(
            children: [
              if (_submittedRefId != null) ...[
                Text('Ref: $_submittedRefId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
              ],
              Text('Schedule: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 2),
              Text('Status: In Escrow (${_finalPrice.toStringAsFixed(0)} XAF held)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your base payment is securely held in escrow until validated by the radio station admin. If rejected, your base tariff will be refunded directly to your wallet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onRequestSubmitted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Done'),
          ),
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
    if (_draftController.text.trim().isEmpty) return;
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
      radioId: widget.viewModel.radio?.id ?? 'radio_1',
      radioName: widget.viewModel.radio?.name ?? 'Radio Sunshine',
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
