import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../view_models/radio_admin_view_model.dart';
import '../../../../core/models/radio_admin/announcement_tariff_model.dart';
import '../../../../core/constants/app_colors.dart';

class TariffEditDialog extends StatefulWidget {
  final AnnouncementTariff tariff;
  const TariffEditDialog({Key? key, required this.tariff}) : super(key: key);

  @override
  State<TariffEditDialog> createState() => _State();
}

class _State extends State<TariffEditDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _rate;

  @override
  void initState() {
    super.initState();
    _rate = TextEditingController(
      text: widget.tariff.ratePer15SecUnit > 0 ? widget.tariff.ratePer15SecUnit.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.tariff.category.name[0].toUpperCase() +
        widget.tariff.category.name.substring(1);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
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
                    const Icon(Icons.price_change_outlined, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('$label rate',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set the price per 15-second unit. Total = rate × diffusions/day × days.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Rate per 15-sec unit (XAF)',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final p = double.tryParse(v);
                    if (p == null || p <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Save rate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final updated = AnnouncementTariff(
      id: widget.tariff.id,
      radioId: widget.tariff.radioId,
      category: widget.tariff.category,
      ratePer15SecUnit: double.parse(_rate.text),
      updatedAt: DateTime.now(),
    );
    await context.read<RadioAdminViewModel>().updateTariff(updated);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rate updated'), backgroundColor: AppColors.success),
      );
    }
  }
}
