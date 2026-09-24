import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/program.dart';
import '../../../core/services/radio_schedule_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../view_models/radio_station_view_model.dart';
import 'program_card.dart';
import 'program_detail_sheet.dart';

class AllShowsScreen extends StatefulWidget {
  final String radioId;
  final String radioName;

  const AllShowsScreen({
    Key? key,
    required this.radioId,
    required this.radioName,
  }) : super(key: key);

  @override
  State<AllShowsScreen> createState() => _AllShowsScreenState();
}

class _AllShowsScreenState extends State<AllShowsScreen> {
  String _search = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();
    final service = RadioScheduleService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Shows & Programs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.radioName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Program>>(
        stream: service.streamPrograms(widget.radioId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPrograms = snap.data ?? [];
          if (allPrograms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_off_outlined,
                      size: 64, color: AppColors.textMuted.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'No shows available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Gather categories
          final categories = {'All'};
          for (final p in allPrograms) {
            categories.addAll(p.categories);
          }

          // Filter
          final filtered = allPrograms.where((p) {
            final matchesSearch = _search.isEmpty ||
                p.name.toLowerCase().contains(_search.toLowerCase()) ||
                p.description.toLowerCase().contains(_search.toLowerCase());
            final matchesCat = _selectedCategory == 'All' ||
                p.categories.contains(_selectedCategory);
            return matchesSearch && matchesCat;
          }).toList();

          return Column(
            children: [
              // Search & Filter
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search shows, topics, hosts...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.background,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (v) => setState(() => _search = v.trim()),
                    ),
                    if (categories.length > 2) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            final sel = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: sel,
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                                selectedColor: AppColors.primary.withOpacity(0.15),
                                backgroundColor: AppColors.background,
                                side: BorderSide(
                                  color: sel ? AppColors.primary : AppColors.border,
                                ),
                                labelStyle: TextStyle(
                                  color: sel ? AppColors.primary : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Shows Grid
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No shows match "$_search"',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          final isFav = vm.isProgramFavourite(p.id);

                          return ProgramCard(
                            program: p,
                            isFavourite: isFav,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (_) => ChangeNotifierProvider.value(
                                  value: vm,
                                  child: ProgramDetailSheet(program: p),
                                ),
                              );
                            },
                            onToggleFavourite: () =>
                                vm.toggleFavouriteProgram(p.id, p.name),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
