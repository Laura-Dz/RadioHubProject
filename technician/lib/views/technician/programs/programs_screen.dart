import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/program_model.dart';
import '../../../core/constants/app_colors.dart';
import 'program_edit_modal.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({Key? key}) : super(key: key);
  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final _search = TextEditingController();
  String? _categoryFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();

    final filtered = vm.programs.where((p) {
      final s = _search.text.toLowerCase();
      final matchSearch = s.isEmpty || p.name.toLowerCase().contains(s);
      final matchCat = _categoryFilter == null ||
          p.categories.contains(_categoryFilter) ||
          (p.categories.isEmpty && _categoryFilter == 'general');
      return matchSearch && matchCat;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Programs'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => const ProgramEditModal(),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New program'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Toolbar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search programs...',
                      prefixIcon: const Icon(Icons.search, size: 18),
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
                            color: AppColors.primary, width: 1.4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _catChip(null, 'All'),
                const SizedBox(width: 8),
                ...vm.categories.take(6).map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _catChip(c.name,
                          c.name[0].toUpperCase() + c.name.substring(1)),
                    )),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? _empty()
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ProgramCard(program: filtered[i]),
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

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_outlined,
                size: 72, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No programs yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Create your first program to start scheduling.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => const ProgramEditModal(),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New program'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
}

class _ProgramCard extends StatefulWidget {
  final Program program;
  const _ProgramCard({required this.program});
  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.program;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hover ? AppColors.hover : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hover
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tv, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(p.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...p.categories.map((c) => _tag(
                          c.isNotEmpty ? c[0].toUpperCase() + c.substring(1) : '',
                          AppColors.primary)),
                      _tag('${p.defaultDurationMinutes} min',
                          AppColors.textSecondary),
                      if (p.allowsCalls)
                        _tag('Calls', AppColors.success),
                      if (p.allowsComments)
                        _tag('Comments', AppColors.info),
                    ],
                  ),
                  if (p.hostNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Hosts: ${p.hostsLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              tooltip: 'Edit program',
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.primary),
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => ProgramEditModal(program: p),
              ),
            ),
            IconButton(
              tooltip: 'Archive program',
              icon: const Icon(Icons.archive_outlined,
                  size: 18, color: AppColors.error),
              onPressed: () => _confirmArchive(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
      );

  Future<void> _confirmArchive(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Archive "${widget.program.name}"?'),
        content: const Text(
          'The program will be hidden from future sessions. Existing sessions are unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<TechnicianViewModel>().archiveProgram(widget.program.id);
    }
  }
}