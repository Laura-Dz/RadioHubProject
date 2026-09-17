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
  late final TextEditingController _nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rate = TextEditingController(
      text: widget.tariff.ratePer15SecUnit > 0 ? widget.tariff.ratePer15SecUnit.toStringAsFixed(0) : '',
    );
    _nameController = TextEditingController(
      text: widget.tariff.categoryLabel,
    );
  }

  @override
  void dispose() {
    _rate.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.tariff.categoryLabel;
    final isCustom = widget.tariff.isCustom;

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
                      child: Text(
                        isCustom ? 'Edit $label Category' : '$label Rate',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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
                if (isCustom) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                ],
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
                  children: [
                    if (isCustom && widget.tariff.id.isNotEmpty) ...[
                      TextButton.icon(
                        onPressed: _saving ? null : _delete,
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check, size: 16),
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
    setState(() => _saving = true);
    final isCustom = widget.tariff.isCustom;
    final updated = AnnouncementTariff(
      id: widget.tariff.id,
      radioId: widget.tariff.radioId,
      category: widget.tariff.category,
      customCategoryName: isCustom ? _nameController.text.trim() : widget.tariff.customCategoryName,
      ratePer15SecUnit: double.parse(_rate.text.trim()),
      isActive: true,
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete the "${widget.tariff.categoryLabel}" category?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _saving = true);
    await context.read<RadioAdminViewModel>().deleteTariff(widget.tariff.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted'), backgroundColor: AppColors.info),
      );
    }
  }
}
