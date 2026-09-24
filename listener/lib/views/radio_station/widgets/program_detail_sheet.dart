import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/program.dart';
import '../../../core/constants/app_colors.dart';
import '../../../view_models/radio_station_view_model.dart';

class ProgramDetailSheet extends StatelessWidget {
  final Program program;

  const ProgramDetailSheet({Key? key, required this.program})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();
    final isFav = vm.isProgramFavourite(program.id);
    final isListenLater = vm.isProgramListenLater(program.id);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Category
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (program.categories.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: program.categories
                                .map((c) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (program.imageUrl != null && program.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        program.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              if (program.description.isNotEmpty) ...[
                Text(
                  program.description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Hosts
              if (program.hostNames.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      'Presented by: ${program.hostNames.join(", ")}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Follow Show button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => vm.toggleFavouriteProgram(
                      program.id, program.name),
                  icon: Icon(
                    isFav ? Icons.check_circle_rounded : Icons.add_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    isFav ? 'Following' : 'Follow Show',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFav ? AppColors.surface : AppColors.primary,
                    foregroundColor: isFav ? AppColors.primary : Colors.white,
                    side: isFav
                        ? const BorderSide(color: AppColors.primary, width: 1.5)
                        : BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => vm.toggleListenLater(
                          program.id, program.name),
                      icon: Icon(
                        isListenLater
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      label: Text(
                          isListenLater ? 'Saved for later' : 'Listen later'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
