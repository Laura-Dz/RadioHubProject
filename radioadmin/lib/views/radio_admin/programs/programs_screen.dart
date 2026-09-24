import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/program_model.dart';
import '../../../core/models/radio_admin/staff_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../tabs/widgets/program_form_dialog.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({Key? key}) : super(key: key);

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _categoryFilter;

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();

    final filtered = vm.programs.where((p) {
      final query = _search.text.trim().toLowerCase();
      final matchSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);

      final matchCat = _categoryFilter == null ||
          p.categories.any((c) => c.toLowerCase() == _categoryFilter!.toLowerCase()) ||
          p.category.name.toLowerCase() == _categoryFilter!.toLowerCase() ||
          (p.categories.isEmpty && _categoryFilter!.toLowerCase() == 'general');

      return matchSearch && matchCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Programs',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ProgramFormDialog(viewModel: vm),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Program'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Search & Category Filters Toolbar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search programs...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _search.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            )
                          : null,
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
                          color: AppColors.primary,
                          width: 1.4,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _catChip(null, 'All'),
                const SizedBox(width: 8),
                ...vm.categories.take(6).map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _catChip(
                        c,
                        c.isNotEmpty ? c[0].toUpperCase() + c.substring(1) : '',
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 16),

            // Programs List / Grid
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(vm)
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: ListView.separated(
                        controller: _scrollController,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ProgramCard(
                          program: filtered[i],
                          viewModel: vm,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catChip(String? value, String label) {
    final sel = _categoryFilter == value;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(() => _categoryFilter = value),
        selectedColor: AppColors.primary.withOpacity(0.12),
        backgroundColor: AppColors.surface,
        side: BorderSide(color: sel ? AppColors.primary : AppColors.border),
        labelStyle: TextStyle(
          color: sel ? AppColors.primary : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState(RadioAdminViewModel vm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tv_outlined,
            size: 64,
            color: AppColors.textMuted.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'No programs found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create your first program or adjust the search filter.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => ProgramFormDialog(viewModel: vm),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Program'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatefulWidget {
  final Program program;
  final RadioAdminViewModel viewModel;

  const _ProgramCard({
    required this.program,
    required this.viewModel,
  });

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.program;
    final staffList = widget.viewModel.staff;

    // Resolve assigned hosts
    final matchedHosts = p.hostIds
        .map((id) => staffList.where((s) => s.id == id).firstOrNull)
        .whereType<StaffMember>()
        .toList();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hover ? AppColors.surface.withOpacity(0.9) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hover
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.border,
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program Image or Fallback Box
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                    ? Image.network(
                        p.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.radio,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      )
                    : const Icon(
                        Icons.radio,
                        color: AppColors.primary,
                        size: 26,
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!p.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ARCHIVED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      p.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...p.categories.map((c) => _tag(
                            c.isNotEmpty ? c[0].toUpperCase() + c.substring(1) : '',
                            AppColors.primary,
                          )),
                      _tag(
                        '${p.defaultDurationMinutes} min',
                        AppColors.textSecondary,
                      ),
                      if (p.allowsCalls) _tag('Calls', AppColors.success),
                      if (p.allowsComments) _tag('Comments', AppColors.info),
                    ],
                  ),
                  if (matchedHosts.isNotEmpty || p.hostNames.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Hosts: ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (matchedHosts.isNotEmpty)
                          ...matchedHosts.map((h) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppAvatar(
                                      imageUrl: h.photoUrl,
                                      name: h.name,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      h.name,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                        else
                          ...p.hostNames.map((name) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              )),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit program',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => ProgramFormDialog(
                      viewModel: widget.viewModel,
                      program: p,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Archive program',
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: () => _confirmArchive(context, p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmArchive(BuildContext context, Program p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Archive ${p.name}?'),
        content: const Text(
          'This program will be deactivated and hidden from active scheduling.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              widget.viewModel.archiveProgram(p.id);
              Navigator.pop(ctx);
            },
            child: const Text('Archive', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
