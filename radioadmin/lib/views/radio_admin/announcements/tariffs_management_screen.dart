import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/announcement_tariff_model.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/tariff_edit_dialog.dart';
import 'widgets/add_category_dialog.dart';

class TariffsManagementScreen extends StatelessWidget {
  const TariffsManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();

    // Standard built-in categories (excluding generic 'other')
    final builtInCategories = AnnouncementCategory.values.where((c) => c != AnnouncementCategory.other).toList();

    // Map each category to an existing tariff or a default unconfigured one
    final List<AnnouncementTariff> displayTariffs = [];

    for (final cat in builtInCategories) {
      final existing = vm.tariffs.firstWhere(
        (t) => !t.isCustom && t.category == cat,
        orElse: () => AnnouncementTariff(
          id: '',
          radioId: vm.radioId,
          category: cat,
          ratePer15SecUnit: 0,
          updatedAt: DateTime.now(),
        ),
      );
      displayTariffs.add(existing);
    }

    // Append custom categories created by the admin
    final customTariffs = vm.tariffs.where((t) => t.isCustom).toList();
    displayTariffs.addAll(customTariffs);

    final configured = displayTariffs.where((t) => t.ratePer15SecUnit > 0).length;
    final total = displayTariffs.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Announcement Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => _showAddCategoryDialog(context),
              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
              label: const Text('Add Category', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      // Wrapped in a scroll page as requested
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formula explanation card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calculate_outlined, color: AppColors.gold, size: 22),
                      SizedBox(width: 10),
                      Text('How Pricing Works',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _formulaStep('1', 'Set a rate per 15-second unit for each category.'),
                  _formulaStep('2', 'The listener chooses how many diffusions per day and for how many days.'),
                  _formulaStep('3', 'The final price is: Rate × Diffusions per day × Days.'),
                  _formulaStep('4', 'On validation you receive the base amount directly in your radio payout.'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.lightbulb_outline, color: AppColors.gold, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Example: Birthday at 200 XAF/unit, 2 diffusions/day for 3 days = 200 × 2 × 3 = 1,200 XAF payout to your radio upon validation.',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Categories Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categories ($configured / $total configured)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Manage per-unit pricing or add custom announcement categories.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Category'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Responsive Categories Grid + Add Card with '+'
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 3;
                if (constraints.maxWidth < 640) {
                  crossAxisCount = 1;
                } else if (constraints.maxWidth < 980) {
                  crossAxisCount = 2;
                } else if (constraints.maxWidth < 1350) {
                  crossAxisCount = 3;
                } else {
                  crossAxisCount = 4;
                }

                // Total items = all display tariffs + 1 (the card with +)
                final totalItems = displayTariffs.length + 1;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: totalItems,
                  itemBuilder: (context, i) {
                    // Last item is always the card with '+' to add a category
                    if (i == displayTariffs.length) {
                      return _AddCategoryCard(
                        onTap: () => _showAddCategoryDialog(context),
                      );
                    }

                    final t = displayTariffs[i];
                    return _TariffTile(
                      tariff: t,
                      isConfigured: t.ratePer15SecUnit > 0,
                      onEdit: () => showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => TariffEditDialog(tariff: t),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AddCategoryDialog(),
    );
  }

  Widget _formulaStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(number,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

/// The Card with '+' allowing the radio admin to add a custom category
class _AddCategoryCard extends StatefulWidget {
  final VoidCallback onTap;

  const _AddCategoryCard({Key? key, required this.onTap}) : super(key: key);

  @override
  State<_AddCategoryCard> createState() => _AddCategoryCardState();
}

class _AddCategoryCardState extends State<_AddCategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.primary.withOpacity(0.04) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? AppColors.primary : AppColors.primary.withOpacity(0.35),
              width: _hovered ? 1.6 : 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(_hovered ? 0.16 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Add Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Create custom pricing',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TariffTile extends StatefulWidget {
  final AnnouncementTariff tariff;
  final bool isConfigured;
  final VoidCallback onEdit;

  const _TariffTile({
    Key? key,
    required this.tariff,
    required this.isConfigured,
    required this.onEdit,
  }) : super(key: key);

  @override
  State<_TariffTile> createState() => _TariffTileState();
}

class _TariffTileState extends State<_TariffTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onEdit,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? AppColors.primary.withOpacity(0.5) : AppColors.border,
              width: _hovered ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconFor(widget.tariff), size: 20, color: AppColors.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.tariff.categoryLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.tariff.isCustom)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Custom',
                          style: TextStyle(fontSize: 9.5, color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  if (!widget.isConfigured)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Not set',
                          style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const Spacer(),
              if (widget.isConfigured) ...[
                Text('${widget.tariff.ratePer15SecUnit.toStringAsFixed(0)} XAF',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 2),
                const Text('per 15-sec unit',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ] else
                const Text('Tap to set rate',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
              const Spacer(),
              Row(
                children: const [
                  Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Edit rate', style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(AnnouncementTariff t) {
    if (t.isCustom) return Icons.new_label_outlined;
    switch (t.category) {
      case AnnouncementCategory.birthday: return Icons.cake_outlined;
      case AnnouncementCategory.anniversary: return Icons.favorite_border;
      case AnnouncementCategory.congratulations: return Icons.celebration_outlined;
      case AnnouncementCategory.condolence: return Icons.sentiment_dissatisfied_outlined;
      case AnnouncementCategory.promotional: return Icons.campaign_outlined;
      case AnnouncementCategory.event: return Icons.event_outlined;
      case AnnouncementCategory.dedication: return Icons.music_note_outlined;
      case AnnouncementCategory.other: return Icons.label_outline;
      case AnnouncementCategory.general: return Icons.announcement_outlined;
    }
  }
}
