import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/announcement_tariff_model.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/tariff_edit_dialog.dart';

class TariffsManagementScreen extends StatelessWidget {
  const TariffsManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final configured = vm.tariffs.where((t) => t.ratePer15SecUnit > 0).length;
    final total = AnnouncementCategory.values.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Announcement Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calculate_outlined, color: AppColors.gold, size: 20),
                      SizedBox(width: 10),
                      Text('How pricing works',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _formulaStep('1', 'Set a rate per 15-second unit for each category.'),
                  _formulaStep('2', 'The listener chooses how many diffusions per day and for how many days.'),
                  _formulaStep('3', 'The final price is: rate × diffusions per day × days.'),
                  _formulaStep('4', 'On validation you receive the base amount for that category.'),
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
                            'Example: Birthday at 200 XAF/unit, 2 diffusions/day for 3 days = 200 × 2 × 3 = 1,200 XAF payout to your radio on validation.',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Text('Categories ($configured / $total configured)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                ),
                itemCount: AnnouncementCategory.values.length,
                itemBuilder: (context, i) {
                  final cat = AnnouncementCategory.values[i];
                  final t = vm.tariffs.firstWhere(
                    (x) => x.category == cat,
                    orElse: () => AnnouncementTariff(
                      id: '',
                      radioId: vm.radioId,
                      category: cat,
                      ratePer15SecUnit: 0,
                      updatedAt: DateTime.now(),
                    ),
                  );
                  return _TariffTile(
                    category: cat,
                    tariff: t,
                    isConfigured: t.ratePer15SecUnit > 0,
                    onEdit: () => showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => TariffEditDialog(tariff: t),
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

class _TariffTile extends StatefulWidget {
  final AnnouncementCategory category;
  final AnnouncementTariff tariff;
  final bool isConfigured;
  final VoidCallback onEdit;

  const _TariffTile({
    Key? key,
    required this.category,
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
                  Icon(_iconFor(widget.category), size: 20, color: AppColors.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.category.name[0].toUpperCase() + widget.category.name.substring(1),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
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

  IconData _iconFor(AnnouncementCategory c) {
    switch (c) {
      case AnnouncementCategory.birthday: return Icons.cake_outlined;
      case AnnouncementCategory.anniversary: return Icons.favorite_border;
      case AnnouncementCategory.congratulations: return Icons.celebration_outlined;
      case AnnouncementCategory.condolence: return Icons.sentiment_dissatisfied_outlined;
      case AnnouncementCategory.promotional: return Icons.campaign_outlined;
      case AnnouncementCategory.event: return Icons.event_outlined;
      case AnnouncementCategory.dedication: return Icons.music_note_outlined;
      case AnnouncementCategory.other: return Icons.more_horiz;
      case AnnouncementCategory.general: return Icons.announcement_outlined;
    }
  }
}
