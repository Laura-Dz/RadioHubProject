import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../view_models/announcement_view_model.dart';
import '../../core/models/announcement_request.dart';
import '../../core/constants/app_colors.dart';

class CreateAnnouncementModal extends StatefulWidget {
  final String radioId;
  final String radioName;
  final String listenerName;

  const CreateAnnouncementModal({
    Key? key,
    required this.radioId,
    required this.radioName,
    required this.listenerName,
  }) : super(key: key);

  @override
  State<CreateAnnouncementModal> createState() => _CreateAnnouncementModalState();
}

class _CreateAnnouncementModalState extends State<CreateAnnouncementModal> {
  int _step = 1;
  late final TextEditingController _messageCtrl;
  late final TextEditingController _customDaysCtrl;
  late final TextEditingController _customDiffusionsCtrl;

  DateTime _startDate = DateTime.now();
  String _paymentMethod = 'MoMo';

  @override
  void initState() {
    super.initState();
    _messageCtrl = TextEditingController();
    _customDaysCtrl = TextEditingController(text: '1');
    _customDiffusionsCtrl = TextEditingController(text: '1');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AnnouncementViewModel>();
      vm.reset();
      vm.loadTariffs(widget.radioId);
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _customDaysCtrl.dispose();
    _customDiffusionsCtrl.dispose();
    super.dispose();
  }

  void _onMessageChanged(String val, AnnouncementViewModel vm) {
    vm.setMessage(val);
  }

  Future<void> _runGeminiAmeliorate(AnnouncementViewModel vm) async {
    FocusScope.of(context).unfocus();
    final res = await vm.ameliorateWithGemini(radioName: widget.radioName);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ AI enhanced version ready! You can switch between AI and Original text.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _submit(AnnouncementViewModel vm) async {
    final user = FirebaseAuth.instance.currentUser;
    final listenerId = user?.uid ?? 'guest';

    final res = await vm.submit(
      radioId: widget.radioId,
      radioName: widget.radioName,
      listenerId: listenerId,
      listenerName: widget.listenerName.isNotEmpty ? widget.listenerName : 'Listener',
    );

    if (res != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Announcement submitted to ${widget.radioName} and held in escrow!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnnouncementViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF242438) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textMuted = isDark ? Colors.white60 : AppColors.textSecondary;
    final inputBg = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F6FA);

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Grab Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.campaign, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Announcement',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        Text(
                          widget.radioName,
                          style: TextStyle(fontSize: 12, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: textColor,
                    onPressed: vm.submitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 4-Step Progress Indicator Bar
            _buildStepIndicator(isDark),

            Divider(height: 1, color: isDark ? Colors.white12 : AppColors.divider),

            // Step Content
            Expanded(
              child: vm.loadingTariffs
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        16,
                        18,
                        MediaQuery.of(context).viewInsets.bottom + 20,
                      ),
                      child: _buildCurrentStep(vm, isDark, cardBg, textColor, textMuted, inputBg),
                    ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // ================= STEP INDICATOR =================

  Widget _buildStepIndicator(bool isDark) {
    final steps = ['Details', 'Schedule', 'Tariff', 'Confirm'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(steps.length, (i) {
          final stepNum = i + 1;
          final isActive = _step == stepNum;
          final isDone = _step > stepNum;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDone || isActive
                          ? AppColors.primary
                          : (isDark ? Colors.white12 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(
    AnnouncementViewModel vm,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color textMuted,
    Color inputBg,
  ) {
    switch (_step) {
      case 1:
        return _buildStep1Details(vm, isDark, cardBg, textColor, textMuted, inputBg);
      case 2:
        return _buildStep2Schedule(vm, isDark, cardBg, textColor, textMuted, inputBg);
      case 3:
        return _buildStep3Tariff(vm, isDark, cardBg, textColor, textMuted, inputBg);
      case 4:
        return _buildStep4Summary(vm, isDark, cardBg, textColor, textMuted, inputBg);
      default:
        return _buildStep1Details(vm, isDark, cardBg, textColor, textMuted, inputBg);
    }
  }

  // ================= STEP 1: DETAILS & AI OPTION =================

  Widget _buildStep1Details(
    AnnouncementViewModel vm,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color textMuted,
    Color inputBg,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Step 1 of 4: Announcement Details', 'Select category and write your message.', textColor, textMuted),
        const SizedBox(height: 14),

        // Category Selector
        Text('Announcement Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 6),
        _buildCategoryDropdown(vm, inputBg, textColor, textMuted),
        const SizedBox(height: 16),

        // Message Text Area
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your Message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
            Text('${vm.wordCount} words', style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _messageCtrl,
          maxLines: 4,
          maxLength: 500,
          style: TextStyle(color: textColor, fontSize: 14),
          onChanged: (val) => _onMessageChanged(val, vm),
          decoration: InputDecoration(
            hintText: 'Type your announcement message here...',
            hintStyle: TextStyle(fontSize: 13, color: textMuted),
            filled: true,
            fillColor: inputBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),

        // AI Enhancement Action Row directly under text box
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: vm.enhancing || _messageCtrl.text.trim().isEmpty ? null : () => _runGeminiAmeliorate(vm),
              icon: vm.enhancing
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 16),
              label: Text(vm.enhancing ? 'Enhancing...' : 'Enhance text with AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            if (vm.enhancedText.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: () => vm.setUseEnhancedText(!vm.useEnhancedText),
                icon: Icon(vm.useEnhancedText ? Icons.undo : Icons.auto_awesome, size: 16),
                label: Text(vm.useEnhancedText ? 'Use Original Text' : 'Use AI Enhanced Text'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: vm.useEnhancedText ? AppColors.gold : AppColors.primary,
                  side: BorderSide(color: vm.useEnhancedText ? AppColors.gold : AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 14),

        // Live Word Count & Duration Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricColumn('Word Count', '${vm.wordCount} words', Icons.short_text, textColor, textMuted),
              Container(width: 1, height: 30, color: isDark ? Colors.white12 : Colors.grey.shade300),
              _metricColumn('Est. Duration', '~${vm.estimatedDurationSeconds.toStringAsFixed(0)} sec', Icons.timer_outlined, textColor, textMuted),
              Container(width: 1, height: 30, color: isDark ? Colors.white12 : Colors.grey.shade300),
              _metricColumn('Billing Units', '${vm.calculatedUnits} x 15s', Icons.grid_3x3, textColor, textMuted),
            ],
          ),
        ),

        if (vm.useEnhancedText && vm.enhancedText.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Active text: AI Broadcast-Polished Version\n"${vm.message}"',
                    style: TextStyle(fontSize: 12, color: textColor, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: vm.message.trim().isNotEmpty
                ? () => setState(() => _step = 2)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Next: Schedule & Priority →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  // ================= STEP 2: SCHEDULE & PRIORITY =================

  Widget _buildStep2Schedule(
    AnnouncementViewModel vm,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color textMuted,
    Color inputBg,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Step 2 of 4: Schedule & Priority', 'Set start date, broadcast period, repetitions, and priority.', textColor, textMuted),
        const SizedBox(height: 14),

        // Start Date
        Text('Start Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (picked != null) setState(() => _startDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white12 : AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(_startDate), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Diffusion Period (Days) with manual entry + preset chips
        Text('Diffusion Period (Total Days)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [1, 3, 7, 14, 30].map((d) {
            final sel = vm.days == d;
            return ChoiceChip(
              label: Text('$d day${d > 1 ? 's' : ''}'),
              selected: sel,
              selectedColor: AppColors.primary,
              backgroundColor: inputBg,
              labelStyle: TextStyle(color: sel ? Colors.white : textColor, fontWeight: FontWeight.w600, fontSize: 12),
              onSelected: (_) {
                vm.setDays(d);
                _customDaysCtrl.text = d.toString();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Custom Days: ', style: TextStyle(fontSize: 12, color: textMuted)),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              height: 38,
              child: TextField(
                controller: _customDaysCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.border)),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed >= 1) vm.setDays(parsed);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Daily Broadcasts / Repetitions per day
        Text('Broadcasts Per Day', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [1, 2, 3, 5].map((n) {
            final sel = vm.diffusionsPerDay == n;
            return ChoiceChip(
              label: Text('$n / day'),
              selected: sel,
              selectedColor: AppColors.primary,
              backgroundColor: inputBg,
              labelStyle: TextStyle(color: sel ? Colors.white : textColor, fontWeight: FontWeight.w600, fontSize: 12),
              onSelected: (_) {
                vm.setDiffusionsPerDay(n);
                _customDiffusionsCtrl.text = n.toString();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Custom Broadcasts/Day: ', style: TextStyle(fontSize: 12, color: textMuted)),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              height: 38,
              child: TextField(
                controller: _customDiffusionsCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.border)),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed >= 1) vm.setDiffusionsPerDay(parsed);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Broadcast Priority
        Text('Broadcast Priority Rate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 6),
        Row(
          children: AnnouncementPriority.values.map((p) {
            final sel = vm.priority == p;
            return Expanded(
              child: GestureDetector(
                onTap: () => vm.setPriority(p),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary.withOpacity(0.15) : inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? AppColors.primary : (isDark ? Colors.white12 : AppColors.border), width: sel ? 1.8 : 1.0),
                  ),
                  child: Column(
                    children: [
                      Text(p.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sel ? AppColors.primary : textColor)),
                      const SizedBox(height: 2),
                      Text('${p.multiplier}x rate', style: TextStyle(fontSize: 10, color: textMuted)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('← Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Next: Tariff & Payment →', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= STEP 3: TARIFF & PAYMENT =================

  Widget _buildStep3Tariff(
    AnnouncementViewModel vm,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color textMuted,
    Color inputBg,
  ) {
    final totalBroadcasts = vm.diffusionsPerDay * vm.days;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Step 3 of 4: Tariff Breakdown & Payment', 'Transparent pricing estimate and escrow calculation.', textColor, textMuted),
        const SizedBox(height: 14),

        // Tariff Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _priceRow('Base Tariff Rate', '${(vm.baseAmount / (totalBroadcasts * vm.priority.multiplier * vm.units)).toStringAsFixed(0)} XAF / unit', textColor, textMuted),
              _priceRow('Words / Billing Units', '${vm.wordCount} words (${vm.units} x 15s unit)', textColor, textMuted),
              _priceRow('Total Airings', '$totalBroadcasts broadcasts ($totalBroadcasts x ${vm.units} units)', textColor, textMuted),
              _priceRow('Priority Multiplier', '${vm.priority.label} (${vm.priority.multiplier}x)', textColor, textMuted),
              const Divider(height: 16),
              _priceRow('Base Amount', '${vm.baseAmount.toStringAsFixed(0)} XAF', textColor, textMuted, isBold: true),
              _priceRow('Escrow Transfer Fee (4%)', '${vm.transferFee.toStringAsFixed(0)} XAF', textColor, textMuted),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Price (Escrow)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                  Text(
                    '${vm.finalPrice.toStringAsFixed(0)} XAF',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment Method Selector
        Text('Select Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
        const SizedBox(height: 8),
        Row(
          children: ['MoMo', 'OM', 'Credit Card'].map((m) {
            final sel = _paymentMethod == m;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _paymentMethod = m),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary.withOpacity(0.12) : inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? AppColors.primary : (isDark ? Colors.white12 : AppColors.border), width: sel ? 1.8 : 1.0),
                  ),
                  child: Center(
                    child: Text(
                      m,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: sel ? AppColors.primary : textColor),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 2),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('← Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 4),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Next: Review & Confirm →', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= STEP 4: SUMMARY & SUBMIT =================

  Widget _buildStep4Summary(
    AnnouncementViewModel vm,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color textMuted,
    Color inputBg,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Step 4 of 4: Review & Submit', 'Confirm announcement details before securing payment in escrow.', textColor, textMuted),
        const SizedBox(height: 14),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryItem('Radio Station', widget.radioName, textColor, textMuted),
              _summaryItem('Category', vm.selectedCategory ?? 'General', textColor, textMuted),
              _summaryItem('Message Source', vm.useEnhancedText ? '✨ Gemini AI Enhanced' : 'Original Draft', textColor, textMuted),
              _summaryItem('Text Preview', '"${vm.message}"', textColor, textMuted, isItalic: true),
              _summaryItem('Start Date', _formatDate(_startDate), textColor, textMuted),
              _summaryItem('Duration & Airings', '${vm.days} days x ${vm.diffusionsPerDay} diffusions/day', textColor, textMuted),
              _summaryItem('Payment Method', _paymentMethod, textColor, textMuted),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Final Escrow Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                  Text('${vm.finalPrice.toStringAsFixed(0)} XAF', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: AppColors.success, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Escrow Protection Active: Payment is held safely until the station validates your announcement.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: vm.submitting ? null : () => setState(() => _step = 3),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('← Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: vm.submitting ? null : () => _submit(vm),
                icon: vm.submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock, size: 18),
                label: Text(vm.submitting ? 'Submitting...' : 'Submit & Pay ${vm.finalPrice.toStringAsFixed(0)} XAF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= HELPER WIDGETS =================

  Widget _buildSectionHeader(String title, String subtitle, Color textColor, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: textMuted)),
      ],
    );
  }

  Widget _buildCategoryDropdown(AnnouncementViewModel vm, Color inputBg, Color textColor, Color textMuted) {
    if (vm.tariffs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(12)),
        child: Text('General Announcement (500 XAF / 15s)', style: TextStyle(fontSize: 13, color: textColor)),
      );
    }

    return DropdownButtonFormField<String>(
      value: vm.selectedCategory,
      isExpanded: true,
      dropdownColor: inputBg,
      style: TextStyle(color: textColor, fontSize: 13.5, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      ),
      items: vm.tariffs.map((t) {
        final name = t.category.isNotEmpty ? t.category[0].toUpperCase() + t.category.substring(1) : t.category;
        return DropdownMenuItem(
          value: t.category,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: TextStyle(color: textColor)),
              Text('${t.ratePerUnit.toStringAsFixed(0)} XAF/15s', style: TextStyle(fontSize: 11.5, color: textMuted)),
            ],
          ),
        );
      }).toList(),
      onChanged: (cat) => vm.setCategory(cat),
    );
  }

  Widget _metricColumn(String label, String value, IconData icon, Color textColor, Color textMuted) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
        Text(label, style: TextStyle(fontSize: 9.5, color: textMuted)),
      ],
    );
  }

  Widget _priceRow(String title, String val, Color textColor, Color textMuted, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 12.5, color: isBold ? textColor : textMuted, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(val, style: TextStyle(fontSize: 12.5, color: textColor, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String val, Color textColor, Color textMuted, {bool isItalic = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(title, style: TextStyle(fontSize: 12, color: textMuted))),
          Expanded(
            child: Text(
              val,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
