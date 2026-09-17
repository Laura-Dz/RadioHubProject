import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/channels_service.dart';

class SearchHistoryDropdown extends StatelessWidget {
  final List<SearchEntry> entries;
  final void Function(String query) onSelect;
  final void Function(String id) onRemove;
  final VoidCallback onClearAll;

  const SearchHistoryDropdown({
    Key? key,
    required this.entries,
    required this.onSelect,
    required this.onRemove,
    required this.onClearAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.surface,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
              child: Row(
                children: [
                  const Text('Recent searches',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                  const Spacer(),
                  TextButton(
                    onPressed: onClearAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear all',
                        style: TextStyle(
                            fontSize: 11.5, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            // Entries
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final e = entries[i];
                  return InkWell(
                    onTap: () => onSelect(e.query),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.history,
                              size: 15, color: AppColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(e.query,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(
                            DateFormat('d MMM').format(e.searchedAt),
                            style: const TextStyle(
                                fontSize: 10.5, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 14, color: AppColors.textMuted),
                            onPressed: () => onRemove(e.id),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 24, minHeight: 24),
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
