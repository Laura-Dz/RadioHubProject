import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../view_models/announcement_view_model.dart';
import '../../core/models/announcement_request.dart';
import '../../core/constants/app_colors.dart';
import 'enhance_preview_dialog.dart';

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
  State<CreateAnnouncementModal> createState() => _State();
}

class _State extends State<CreateAnnouncementModal> {
  final _messageCtrl = TextEditingController();
  final _customCatCtrl = TextEditingController();
  final _diffusionsCtrl = TextEditingController(text: '1');
  final _daysCtrl = TextEditingController(text: '1');

  bool _showCustomCatInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementViewModel>()
        ..reset()
        ..loadTariffs(widget.radioId);
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _customCatCtrl.dispose();
    _diffusionsCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnnouncementViewModel>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.campaign_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Request an announcement',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        Text(widget.radioName,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: vm.submitting
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Body
              Expanded(
                child: vm.loadingTariffs
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ============ CATEGORY ============
                            _label('Category'),
                            const SizedBox(height: 6),
                            if (_showCustomCatInput)
                              _customCategoryField(vm)
                            else
                              _categoryDropdown(vm),
                            const SizedBox(height: 18),

                            // ============ MESSAGE ============
                            _label('Your message'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _messageCtrl,
                              maxLines: 5,
                              maxLength: 500,
                              onChanged: vm.setMessage,
                              decoration: _dec('Write your announcement here…'),
                            ),
                            const SizedBox(height: 8),

                            // ============ AI ENHANCE BUTTON ============
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: vm.enhancing
                                    ? null
                                    : () => _enhance(vm),
                                icon: vm.enhancing
                                    ? const SizedBox(
                                        width: 14, height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary))
                                    : const Icon(Icons.auto_awesome, size: 15),
                                label: Text(vm.enhancing
                                    ? 'Enhancing…'
                                    : 'Enhance with AI'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                      color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // ============ PRIORITY ============
                            _label('Priority'),
                            const SizedBox(height: 6),
                            _priorityRow(vm),
                            const SizedBox(height: 22),

                            // ============ SCHEDULE ============
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Diffusions per day'),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _diffusionsCtrl,
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          final n = int.tryParse(v);
                                          if (n != null) {
                                            vm.setDiffusionsPerDay(n);
                                          }
                                        },
                                        decoration: _dec(''),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('For how many days'),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _daysCtrl,
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          final n = int.tryParse(v);
                                          if (n != null) vm.setDays(n);
                                        },
                                        decoration: _dec(''),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),

              // Error
              if (vm.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(vm.error!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ============ SUBMIT + PRICE ============
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: vm.canSubmit ? () => _submit(vm) : null,
                      icon: vm.submitting
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.arrow_forward, size: 16),
                      label: Text(vm.submitting
                          ? 'Submitting…'
                          : 'Continue to payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.border,
                        disabledForegroundColor: AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted)),
                      Text(
                        '${vm.finalPrice.toStringAsFixed(0)} XAF',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ WIDGETS ============

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700));

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  // ---------- Category dropdown with + add new ----------

  Widget _categoryDropdown(AnnouncementViewModel vm) {
    return DropdownButtonFormField<String>(
      value: vm.selectedCategory,
      isExpanded: true,
      decoration: _dec('Select a category'),
      items: [
        ...vm.tariffs.map((t) => DropdownMenuItem(
              value: t.category,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.category.isEmpty
                          ? ''
                          : t.category[0].toUpperCase() + t.category.substring(1),
                    ),
                  ),
                  Text(
                    '${t.ratePerUnit.toStringAsFixed(0)} XAF',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            )),
        const DropdownMenuItem(
          value: '__custom__',
          child: Row(
            children: [
              Icon(Icons.add, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Add a new category',
                  style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
      ],
      onChanged: (v) {
        if (v == '__custom__') {
          setState(() => _showCustomCatInput = true);
        } else {
          vm.setCategory(v);
        }
      },
    );
  }

  Widget _customCategoryField(AnnouncementViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _customCatCtrl,
            autofocus: true,
            decoration: _dec('Enter a category name'),
            onChanged: (v) {
              if (v.trim().isNotEmpty) {
                vm.setCategory(v.trim().toLowerCase(), custom: true);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          tooltip: 'Back to list',
          onPressed: () {
            setState(() {
              _showCustomCatInput = false;
              _customCatCtrl.clear();
            });
            vm.setCategory(null);
          },
        ),
      ],
    );
  }

  // ---------- Priority row ----------

  Widget _priorityRow(AnnouncementViewModel vm) {
    return Row(
      children: AnnouncementPriority.values.map((p) {
        final selected = vm.priority == p;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: p == AnnouncementPriority.priority ? 0 : 8,
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => vm.setPriority(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.08)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            p == AnnouncementPriority.standard
                                ? Icons.circle_outlined
                                : p == AnnouncementPriority.high
                                    ? Icons.trending_up
                                    : Icons.priority_high,
                            size: 14,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p.description,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ============ ACTIONS ============

  Future<void> _enhance(AnnouncementViewModel vm) async {
    final enhanced = await vm.enhance();
    if (enhanced == null || !mounted) return;

    final original = _messageCtrl.text;
    if (enhanced == original) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already looks great'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    final accepted = await showDialog<String>(
      context: context,
      builder: (_) => EnhancePreviewDialog(
        original: original,
        enhanced: enhanced,
      ),
    );

    if (accepted == 'enhanced') {
      _messageCtrl.text = enhanced;
      vm.acceptEnhanced(enhanced);
    }
  }

  Future<void> _submit(AnnouncementViewModel vm) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final result = await vm.submit(
      radioId: widget.radioId,
      radioName: widget.radioName,
      listenerId: uid,
      listenerName: widget.listenerName,
    );

    if (result == null || !mounted) return;

    // Store result for payment screen
    Navigator.pop(context, result);
  }
}
