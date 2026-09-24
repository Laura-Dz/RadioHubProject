import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/app_program_image.dart';

import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/program_model.dart';
import '../../../core/models/technician/host_model.dart';
import '../../../core/models/technician/timetable_slot_model.dart';
import '../../../core/utils/app_file_picker.dart';
import '../../../core/constants/app_colors.dart';

class ProgramEditModal extends StatefulWidget {
  final Program? program;
  const ProgramEditModal({Key? key, this.program}) : super(key: key);

  @override
  State<ProgramEditModal> createState() => _State();
}

class _State extends State<ProgramEditModal> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _customDuration = TextEditingController();
  final _newCatCtrl = TextEditingController();

  List<String> _categories = [];
  List<String> _hostIds = [];
  int _duration = 60;
  bool _useCustomDuration = false;
  bool _allowsCalls = true;
  bool _allowsComments = true;

  // Image
  String? _imageUrl;
  Uint8List? _previewBytes;
  bool _uploadingImage = false;
  double _uploadProgress = 0;


  // Recurrence
  RecurrenceType _recurrenceType = RecurrenceType.none;
  List<int> _recurrenceDays = [];
  TimeOfDay? _defaultStartTime;

  bool _submitting = false;
  bool _showNewCatInput = false;

  @override
  void initState() {
    super.initState();
    if (widget.program != null) {
      final p = widget.program!;
      _name.text = p.name;
      _description.text = p.description;
      _categories = List<String>.from(p.categories);
      _hostIds = List<String>.from(p.hostIds);
      _duration = p.defaultDurationMinutes;
      _useCustomDuration = ![30, 45, 60, 90, 120].contains(_duration);
      if (_useCustomDuration) _customDuration.text = _duration.toString();
      _allowsCalls = p.allowsCalls;
      _allowsComments = p.allowsComments;
      _imageUrl = p.imageUrl;
      _recurrenceType = p.recurrenceType;
      _recurrenceDays = List<int>.from(p.recurrenceDays);
      if (p.defaultStartHour != null) {
        _defaultStartTime = TimeOfDay(
          hour: p.defaultStartHour!,
          minute: p.defaultStartMinute ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _customDuration.dispose();
    _newCatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();
    final isEdit = widget.program != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit program' : 'New program',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------- IMAGE ----------
                        _sectionLabel('Cover image'),
                        const SizedBox(height: 8),
                        _imageTile(),
                        const SizedBox(height: 20),

                        // ---------- NAME / DESCRIPTION ----------
                        _field(_name, 'Program name', required: true),
                        const SizedBox(height: 14),
                        _field(_description, 'Short description', maxLines: 3),
                        const SizedBox(height: 20),

                        // ---------- CATEGORIES ----------
                        _sectionLabel('Categories (tags) *'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Dropdown of available categories not yet selected
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: null,
                                isExpanded: true,
                                decoration: _dec('Pick a category to add'),
                                items: vm.categories
                                    .where((c) => !_categories.contains(c.name))
                                    .map((c) => DropdownMenuItem(
                                          value: c.name,
                                          child: Text(c.name.isNotEmpty
                                              ? (c.name[0].toUpperCase() + c.name.substring(1))
                                              : ''),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null || _categories.contains(v)) return;
                                  setState(() => _categories.add(v));
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // "+" — add new category
                            Tooltip(
                              message: 'Create a new category',
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => setState(() => _showNewCatInput = true),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                    ),
                                    child: const Icon(Icons.add, color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // New category inline input
                        if (_showNewCatInput) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newCatCtrl,
                                  autofocus: true,
                                  decoration: _dec('New category name').copyWith(isDense: true),
                                  onSubmitted: (_) => _submitNewCategory(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _submitNewCategory,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Add'),
                              ),
                              TextButton(
                                onPressed: () => setState(() {
                                  _showNewCatInput = false;
                                  _newCatCtrl.clear();
                                }),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],

                        // Selected categories shown under
                        if (_categories.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _categories
                                .map((name) => Chip(
                                      label: Text(name.isNotEmpty
                                          ? (name[0].toUpperCase() + name.substring(1))
                                          : ''),
                                      deleteIcon: const Icon(Icons.close, size: 14),
                                      onDeleted: () => setState(() => _categories.remove(name)),
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                                      labelStyle: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Text(
                            'No categories selected yet. Pick from the list or add a new one.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // ---------- HOSTS ----------
                        _sectionLabel('Hosts for this program'),
                        const SizedBox(height: 6),
                        if (vm.hosts.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              'No hosts available. Ask the Radio Admin to create hosts for this radio.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: null,
                                  isExpanded: true,
                                  decoration: _dec('Pick a host to add'),
                                  items: vm.hosts
                                      .where((h) => !_hostIds.contains(h.id))
                                      .map((h) => DropdownMenuItem(
                                            value: h.id,
                                            child: Text('${h.name}  ·  ${h.email}'),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null || _hostIds.contains(v)) return;
                                    setState(() => _hostIds.add(v));
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Refresh marker — the dropdown clears after each pick automatically
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Tooltip(
                                  message: 'Pick from the list to add another host',
                                  child: Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),

                        // Selected hosts shown under
                        if (_hostIds.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Column(
                            children: _hostIds.map((id) {
                              final h = vm.hosts.where((x) => x.id == id).toList();
                              if (h.isEmpty) return const SizedBox.shrink();
                              final host = h.first;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          host.name.isNotEmpty ? host.name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(host.name,
                                              style: const TextStyle(
                                                  fontSize: 13, fontWeight: FontWeight.w600)),
                                          Text(host.email,
                                              style: const TextStyle(
                                                  fontSize: 11.5, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      tooltip: 'Remove host',
                                      onPressed: () => setState(() => _hostIds.remove(id)),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Text(
                            'No hosts assigned yet. Pick from the list above.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                        const SizedBox(height: 20),


                        // ---------- DURATION ----------
                        _sectionLabel('Default duration'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            ...[30, 45, 60, 90, 120].map((m) => _durChip(m)),
                            _customDurChip(),
                          ],
                        ),
                        if (_useCustomDuration) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _customDuration,
                              keyboardType: TextInputType.number,
                              decoration: _dec().copyWith(
                                labelText: 'Custom minutes',
                                isDense: true,
                              ),
                              onChanged: (v) {
                                final n = int.tryParse(v);
                                if (n != null && n > 0) {
                                  setState(() => _duration = n);
                                }
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // ---------- RECURRENCE ----------
                        _sectionLabel('Recurrence (auto-fill timetable)'),
                        const SizedBox(height: 4),
                        const Text(
                          'Optionally generate timetable slots automatically when you save.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        _recurrenceRow(),
                        if (_recurrenceType == RecurrenceType.weekly) ...[
                          const SizedBox(height: 10),
                          _weekdaysPicker(),
                        ],
                        if (_recurrenceType != RecurrenceType.none) ...[
                          const SizedBox(height: 12),
                          _startTimeRow(),
                        ],
                        if (_recurrenceType != RecurrenceType.none && _defaultStartTime != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Will generate ${_previewSlotCount(vm)} timetable slot(s) for "${_name.text.isEmpty ? "this program" : _name.text}". Existing overlaps will be skipped.',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ---------- PERMISSIONS ----------
                        _sectionLabel('Session permissions'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _allowsCalls,
                                onChanged: (v) => setState(() => _allowsCalls = v),
                                title: const Text('Allow listener calls',
                                    style: TextStyle(fontSize: 13.5)),
                                activeColor: AppColors.primary,
                                dense: true,
                              ),
                              const Divider(height: 1, color: AppColors.divider),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _allowsComments,
                                onChanged: (v) =>
                                    setState(() => _allowsComments = v),
                                title: const Text('Allow live comments',
                                    style: TextStyle(fontSize: 13.5)),
                                activeColor: AppColors.primary,
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _submitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 16),
                      label: Text(isEdit ? 'Save changes' : 'Create program'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== WIDGETS ==========

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700));

  Widget _imageTile() {
    return Row(
      children: [
        MouseRegion(
          cursor: _uploadingImage ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _uploadingImage ? null : _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _imageUrl != null
                          ? AppColors.border
                          : AppColors.primary.withOpacity(0.3),
                      width: _imageUrl != null ? 1 : 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _previewBytes != null
                      ? Image.memory(
                          _previewBytes!,
                          fit: BoxFit.cover,
                        )
                      : (_imageUrl != null && _imageUrl!.isNotEmpty
                          ? AppProgramImage(
                              imageUrl: _imageUrl,
                              name: _name.text,
                              width: 140,
                              height: 140,
                              borderRadius: 14,
                              fit: BoxFit.cover,
                            )
                          : _emptyImageTile()),
                ),
                if (_uploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 30, height: 30,
                              child: CircularProgressIndicator(
                                value: _uploadProgress > 0 ? _uploadProgress : null,
                                strokeWidth: 3, color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _imageUrl == null ? 'No image yet' : 'Cover image',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('Shown on program cards and listener app. 512×512 PNG or JPG, max 5 MB.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _uploadingImage ? null : _pickImage,
                icon: Icon(_imageUrl == null
                    ? Icons.upload_outlined
                    : Icons.swap_horiz, size: 16),
                label: Text(_imageUrl == null ? 'Upload image' : 'Change image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (_imageUrl != null) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _uploadingImage
                      ? null
                      : () => setState(() {
                            _imageUrl = null;
                            _previewBytes = null;
                          }),
                  icon: const Icon(Icons.delete_outline,
                      size: 14, color: AppColors.error),
                  label: const Text('Remove',
                      style: TextStyle(color: AppColors.error, fontSize: 12.5)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyImageTile() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined,
                size: 32, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(height: 6),
            Text('No image',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary.withOpacity(0.6),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  int _previewSlotCount(TechnicianViewModel vm) {
    final days = _recurrenceType.resolveDays(_recurrenceDays);
    if (days.isEmpty || _defaultStartTime == null) return 0;
    final endMin = _defaultStartTime!.hour * 60 + _defaultStartTime!.minute + _duration;
    int count = 0;
    for (final wd in days) {
      final candidate = TimetableSlot(
        id: '',
        radioId: vm.radioId,
        programId: 'preview',
        programName: '',
        weekday: wd,
        startHour: _defaultStartTime!.hour,
        startMinute: _defaultStartTime!.minute,
        endHour: (endMin ~/ 60) % 24,
        endMinute: endMin % 60,
        createdAt: DateTime.now(),
      );
      if (!vm.timetableOverlaps(candidate)) count++;
    }
    return count;
  }


  Widget _durChip(int m) {
    final sel = !_useCustomDuration && _duration == m;
    return ChoiceChip(
      label: Text('$m min'),
      selected: sel,
      onSelected: (_) => setState(() {
        _duration = m;
        _useCustomDuration = false;
      }),
      selectedColor: AppColors.primary.withOpacity(0.12),
      backgroundColor: AppColors.surface,
      side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
      labelStyle: TextStyle(
        color: sel ? AppColors.primary : AppColors.textSecondary,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _customDurChip() => ChoiceChip(
        label: const Text('Custom'),
        selected: _useCustomDuration,
        onSelected: (_) => setState(() => _useCustomDuration = true),
        selectedColor: AppColors.primary.withOpacity(0.12),
        backgroundColor: AppColors.surface,
        side: BorderSide(
            color: _useCustomDuration ? AppColors.primary : AppColors.border),
        labelStyle: TextStyle(
          color: _useCustomDuration ? AppColors.primary : AppColors.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _recurrenceRow() {
    return Wrap(
      spacing: 8,
      children: RecurrenceType.values.map((t) {
        final sel = _recurrenceType == t;
        return ChoiceChip(
          label: Text(t.label),
          selected: sel,
          onSelected: (_) => setState(() => _recurrenceType = t),
          selectedColor: AppColors.primary.withOpacity(0.12),
          backgroundColor: AppColors.surface,
          side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
          labelStyle: TextStyle(
            color: sel ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Widget _weekdaysPicker() {
    const short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Wrap(
      spacing: 6,
      children: List.generate(7, (i) {
        final d = i + 1;
        final sel = _recurrenceDays.contains(d);
        return FilterChip(
          label: Text(short[i]),
          selected: sel,
          onSelected: (v) => setState(() {
            if (v) {
              _recurrenceDays.add(d);
            } else {
              _recurrenceDays.remove(d);
            }
          }),
          selectedColor: AppColors.primary.withOpacity(0.15),
          checkmarkColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
          labelStyle: TextStyle(
            color: sel ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      }),
    );
  }

  Widget _startTimeRow() => InkWell(
        onTap: () async {
          final t = await showTimePicker(
            context: context,
            initialTime: _defaultStartTime ?? const TimeOfDay(hour: 8, minute: 0),
          );
          if (t != null) setState(() => _defaultStartTime = t);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Start time',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(
                      _defaultStartTime != null
                          ? '${_defaultStartTime!.hour.toString().padLeft(2, '0')}:${_defaultStartTime!.minute.toString().padLeft(2, '0')}'
                          : 'Pick a time',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      );

  Widget _field(TextEditingController c, String label,
          {int maxLines = 1, bool required = false}) =>
      TextFormField(
        controller: c,
        maxLines: maxLines,
        decoration: _dec().copyWith(labelText: label),
        validator: required
            ? (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null
            : null,
      );

  InputDecoration _dec([String? hint]) => InputDecoration(
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
      );


  // ========== ACTIONS ==========

  Future<void> _pickImage() async {
    try {
      final file = await AppFilePicker.pickImage();
      if (file == null) return;
      if (file.size > 5 * 1024 * 1024) {
        _snack('Image is too large (max 5 MB).', error: true);
        return;
      }
      setState(() {
        _uploadingImage = true;
        _uploadProgress = 0;
        _previewBytes = file.bytes;
      });

      // For new programs we don't have a real id yet — use a temp key.
      final vm = context.read<TechnicianViewModel>();
      final programKey = widget.program?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final ext = file.name.split('.').last.toLowerCase();

      final url = await vm.uploadProgramImage(
        programId: programKey,
        bytes: file.bytes,
        extension: ext,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );
      if (!mounted) return;
      setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }


  Future<void> _submitNewCategory() async {
    final name = _newCatCtrl.text.trim();
    if (name.isEmpty) return;
    final vm = context.read<TechnicianViewModel>();
    try {
      await vm.createCategory(name);
      if (!mounted) return;
      setState(() {
        _categories.add(name.toLowerCase());
        _newCatCtrl.clear();
        _showNewCatInput = false;
      });
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_categories.isEmpty) {
      _snack('Pick at least one category', error: true);
      return;
    }
    if (_useCustomDuration) {
      final n = int.tryParse(_customDuration.text);
      if (n == null || n <= 0) {
        _snack('Enter a valid custom duration', error: true);
        return;
      }
      _duration = n;
    }
    if (_recurrenceType != RecurrenceType.none && _defaultStartTime == null) {
      _snack('Pick a start time for the recurrence', error: true);
      return;
    }
    if (_recurrenceType == RecurrenceType.weekly && _recurrenceDays.isEmpty) {
      _snack('Pick at least one day for the weekly pattern', error: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final vm = context.read<TechnicianViewModel>();
      final hostNames = <String>[];
      for (final id in _hostIds) {
        final h = vm.hosts.where((x) => x.id == id);
        if (h.isNotEmpty) hostNames.add(h.first.name);
      }

      Program program;
      if (widget.program == null) {
        program = Program(
          id: '',
          radioId: vm.radioId,
          name: _name.text.trim(),
          description: _description.text.trim(),
          categories: _categories,
          defaultDurationMinutes: _duration,
          hostIds: _hostIds,
          hostNames: hostNames,
          allowsCalls: _allowsCalls,
          allowsComments: _allowsComments,
          imageUrl: _imageUrl,
          recurrenceType: _recurrenceType,
          recurrenceDays: _recurrenceDays,
          defaultStartHour: _defaultStartTime?.hour,
          defaultStartMinute: _defaultStartTime?.minute,
          createdAt: DateTime.now(),
        );
        final id = await vm.createProgram(program);
        program = Program(
          id: id,
          radioId: program.radioId,
          name: program.name,
          description: program.description,
          categories: program.categories,
          defaultDurationMinutes: program.defaultDurationMinutes,
          hostIds: program.hostIds,
          hostNames: program.hostNames,
          allowsCalls: program.allowsCalls,
          allowsComments: program.allowsComments,
          imageUrl: program.imageUrl,
          recurrenceType: program.recurrenceType,
          recurrenceDays: program.recurrenceDays,
          defaultStartHour: program.defaultStartHour,
          defaultStartMinute: program.defaultStartMinute,
          createdAt: program.createdAt,
        );
      } else {
        program = Program(
          id: widget.program!.id,
          radioId: widget.program!.radioId,
          name: _name.text.trim(),
          description: _description.text.trim(),
          categories: _categories,
          defaultDurationMinutes: _duration,
          hostIds: _hostIds,
          hostNames: hostNames,
          allowsCalls: _allowsCalls,
          allowsComments: _allowsComments,
          imageUrl: _imageUrl,
          recurrenceType: _recurrenceType,
          recurrenceDays: _recurrenceDays,
          defaultStartHour: _defaultStartTime?.hour,
          defaultStartMinute: _defaultStartTime?.minute,
          createdAt: widget.program!.createdAt,
        );
        await vm.updateProgram(widget.program!.id, {
          'name': program.name,
          'description': program.description,
          'categories': program.categories,
          'defaultDurationMinutes': program.defaultDurationMinutes,
          'hostIds': program.hostIds,
          'hostNames': program.hostNames,
          'allowsCalls': program.allowsCalls,
          'allowsComments': program.allowsComments,
          'imageUrl': program.imageUrl,
          'recurrenceType': program.recurrenceType.toString().split('.').last,
          'recurrenceDays': program.recurrenceDays,
          'defaultStartHour': program.defaultStartHour,
          'defaultStartMinute': program.defaultStartMinute,
        });
      }

      // Auto-generate timetable slots if recurrence is set
      int generated = 0;
      if (_recurrenceType != RecurrenceType.none) {
        generated = await vm.generateTimetableFromProgram(program);
      }

      if (!mounted) return;
      Navigator.pop(context);
      if (generated > 0) {
        _snack('Program saved · $generated slot${generated == 1 ? '' : 's'} added to timetable');
      } else if (_recurrenceType != RecurrenceType.none) {
        _snack('Program saved · no slots generated (all overlap with existing)',
            error: false);
      } else {
        _snack(widget.program == null ? 'Program created' : 'Program updated');
      }

    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
        duration: Duration(seconds: error ? 6 : 3),
      ),
    );
  }
}
