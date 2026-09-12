import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/program_model.dart';
import '../../../core/models/technician/program_category_model.dart';
import '../../../core/models/technician/host_model.dart';
import '../../../core/constants/app_colors.dart';

class ProgramEditModal extends StatefulWidget {
  final Program? program;
  const ProgramEditModal({Key? key, this.program}) : super(key: key);

  @override
  State<ProgramEditModal> createState() => _ProgramEditModalState();
}

class _ProgramEditModalState extends State<ProgramEditModal> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _newCatCtrl = TextEditingController();

  List<String> _categories = [];
  List<String> _hostIds = [];
  int _duration = 60;
  bool _allowsCalls = true;
  bool _allowsComments = true;
  bool _submitting = false;
  bool _showNewCatInput = false;

  @override
  void initState() {
    super.initState();
    if (widget.program != null) {
      _name.text = widget.program!.name;
      _description.text = widget.program!.description;
      _categories = List<String>.from(widget.program!.categories);
      _hostIds = List<String>.from(widget.program!.hostIds);
      _duration = widget.program!.defaultDurationMinutes;
      _allowsCalls = widget.program!.allowsCalls;
      _allowsComments = widget.program!.allowsComments;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
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
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
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
                        _field(_name, 'Program name', required: true),
                        const SizedBox(height: 14),
                        _field(_description, 'Short description', maxLines: 3),
                        const SizedBox(height: 20),

                        // ---------- CATEGORIES ----------
                        _sectionLabel('Categories (tags)'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...vm.categories.map((cat) => _catChip(cat.name)),
                            _addCategoryChip(),
                          ],
                        ),
                        if (_showNewCatInput) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newCatCtrl,
                                  autofocus: true,
                                  decoration: _dec().copyWith(
                                    hintText: 'New category name',
                                    isDense: true,
                                  ),
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
                              const SizedBox(width: 6),
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
                        const SizedBox(height: 20),

                        // ---------- HOSTS ----------
                        _sectionLabel('Hosts for this program'),
                        const SizedBox(height: 4),
                        const Text(
                          'Pick the hosts that can run this show. The daily host is chosen per session.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: vm.hosts.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Text(
                                    'No hosts available. Ask the Radio Admin to create hosts for this radio.',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textMuted),
                                  ),
                                )
                              : Column(
                                  children: vm.hosts.map(_hostRow).toList(),
                                ),
                        ),
                        const SizedBox(height: 20),

                        // ---------- DURATION ----------
                        _sectionLabel('Default duration'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [30, 45, 60, 90, 120].map((m) {
                            final sel = _duration == m;
                            return ChoiceChip(
                              label: Text('$m min'),
                              selected: sel,
                              onSelected: (_) => setState(() => _duration = m),
                              selectedColor: AppColors.primary.withOpacity(0.12),
                              backgroundColor: AppColors.surface,
                              side: BorderSide(
                                  color:
                                      sel ? AppColors.primary : AppColors.border),
                              labelStyle: TextStyle(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                        ),
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

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700));

  Widget _catChip(String name) {
    final sel = _categories.contains(name);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: FilterChip(
        label: Text(name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : ''),
        selected: sel,
        onSelected: (v) => setState(() {
          if (v) {
            _categories.add(name);
          } else {
            _categories.remove(name);
          }
        }),
        selectedColor: AppColors.primary.withOpacity(0.15),
        checkmarkColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(
            color: sel ? AppColors.primary : AppColors.border),
        labelStyle: TextStyle(
          color: sel ? AppColors.primary : AppColors.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _addCategoryChip() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ActionChip(
        avatar: const Icon(Icons.add, size: 16, color: AppColors.primary),
        label: const Text('New category'),
        onPressed: () => setState(() => _showNewCatInput = true),
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _hostRow(Host host) {
    final sel = _hostIds.contains(host.id);
    return InkWell(
      onTap: () => setState(() {
        if (sel) {
          _hostIds.remove(host.id);
        } else {
          _hostIds.add(host.id);
        }
      }),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  host.name.isNotEmpty
                      ? host.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(host.name,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                  Text(host.email,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Checkbox(
              value: sel,
              onChanged: (_) => setState(() {
                if (sel) {
                  _hostIds.remove(host.id);
                } else {
                  _hostIds.add(host.id);
                }
              }),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
            ),
          ],
        ),
      ),
    );
  }

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

  InputDecoration _dec() => InputDecoration(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pick at least one category'),
            backgroundColor: AppColors.error),
      );
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

      if (widget.program == null) {
        await vm.createProgram(Program(
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
          createdAt: DateTime.now(),
        ));
      } else {
        await vm.updateProgram(widget.program!.id, {
          'name': _name.text.trim(),
          'description': _description.text.trim(),
          'categories': _categories,
          'defaultDurationMinutes': _duration,
          'hostIds': _hostIds,
          'hostNames': hostNames,
          'allowsCalls': _allowsCalls,
          'allowsComments': _allowsComments,
        });
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.program == null ? 'Program created' : 'Program updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
