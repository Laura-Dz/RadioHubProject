import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/sysadmin/subscription_plan_model.dart';
import '../../../../view_models/sysadmin_view_model.dart';

class PlanEditModal extends StatefulWidget {
  final SubscriptionPlan? plan;

  const PlanEditModal({
    Key? key,
    this.plan,
  }) : super(key: key);

  @override
  State<PlanEditModal> createState() => _PlanEditModalState();
}

class _PlanEditModalState extends State<PlanEditModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _daysController;
  late final TextEditingController _amountController;
  late final TextEditingController _descController;
  final TextEditingController _customFeatureController = TextEditingController();

  late bool _isActive;
  late bool _isPopular;
  late List<String> _features;
  bool _isLoading = false;
  String? _errorMessage;

  static const List<String> _suggestedFeatures = [
    'Unlimited Announcements',
    'HD Audio Streaming (320kbps)',
    'Audimat Basic Analytics',
    'AI Insights',
    'Escrow Tariffs & Financial Clearing',
    'Custom Show Scheduling & Playlists',
    'Priority 24/7 Dedicated Support',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _labelController = TextEditingController(text: p?.label ?? '');
    _daysController = TextEditingController(text: p != null ? p.days.toString() : '30');
    _amountController = TextEditingController(text: p != null ? p.amount.toInt().toString() : '15000');
    _descController = TextEditingController(text: p?.description ?? '');
    _isActive = p?.isActive ?? true;
    _isPopular = p?.isPopular ?? false;
    _features = p != null
        ? List<String>.from(p.features)
        : [
            'Unlimited Announcements',
            'HD Audio Streaming (320kbps)',
            'Audimat Basic Analytics',
          ];
  }

  @override
  void dispose() {
    _labelController.dispose();
    _daysController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _customFeatureController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.plan != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 620,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.loyalty_rounded, color: AppColors.primaryLight, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isEditing ? 'Edit Subscription Plan' : 'Create Subscription Plan',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Configure pricing, duration, and feature tier entitlements for radio stations.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Section 1: Basic Plan Info
                const Text(
                  '1. Plan Identification & Duration',
                  style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _labelController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration('Plan Name / Label', 'e.g. Quarterly Pro, Monthly Starter'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Plan name is required' : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration('Duration in Days', 'e.g. 30, 90, 365'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Days required';
                          final n = int.tryParse(v.trim());
                          if (n == null || n <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration('Price (XAF)', 'e.g. 15000, 40000'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Price required';
                          final n = double.tryParse(v.trim());
                          if (n == null || n < 0) return 'Must be >= 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Quick duration chip selectors
                Row(
                  children: [
                    const Text('Quick Select Duration: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(width: 8),
                    _buildDurationChip('30d (1 mo)', 30),
                    const SizedBox(width: 6),
                    _buildDurationChip('90d (3 mo)', 90),
                    const SizedBox(width: 6),
                    _buildDurationChip('180d (6 mo)', 180),
                    const SizedBox(width: 6),
                    _buildDurationChip('365d (1 yr)', 365),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration('Description (Optional)', 'Brief summary of who this plan is for...'),
                ),
                const SizedBox(height: 20),

                // Section 2: Plan Settings / Toggles
                const Text(
                  '2. Plan Visibility & Promotion',
                  style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active for New Subscriptions', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Radio stations can view and purchase this tier', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        value: _isActive,
                        activeColor: AppColors.success,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                      const Divider(color: AppColors.divider, height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Highlight as "Most Popular"', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Adds a glowing badge on the RadioAdmin subscription store', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        value: _isPopular,
                        activeColor: AppColors.primaryLight,
                        onChanged: (val) => setState(() => _isPopular = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section 3: Feature Entitlements
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '3. Included Features & Entitlements',
                      style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      '${_features.length} selected',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ensure "AI Insights" is included if this plan should unlock Gemini analytics reports in RadioAdmin.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),

                // Checkbox list of suggested features
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: _suggestedFeatures.map((feat) {
                      final isSelected = _features.contains(feat);
                      final isAi = feat.contains('AI');
                      return CheckboxListTile(
                        dense: true,
                        activeColor: isAi ? AppColors.accent : AppColors.primaryLight,
                        title: Row(
                          children: [
                            if (isAi) ...[
                              const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.accent),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                feat,
                                style: TextStyle(
                                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: isAi ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              if (!_features.contains(feat)) _features.add(feat);
                            } else {
                              _features.remove(feat);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Custom feature add row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customFeatureController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration('Add Custom Feature', 'Type feature and press +'),
                        onFieldSubmitted: (_) => _addCustomFeature(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                        foregroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _addCustomFeature,
                      child: const Icon(Icons.add_rounded, size: 20),
                    ),
                  ],
                ),

                if (_features.any((f) => !_suggestedFeatures.contains(f))) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _features.where((f) => !_suggestedFeatures.contains(f)).map((f) {
                      return Chip(
                        backgroundColor: AppColors.surfaceLight,
                        label: Text(f, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.error),
                        onDeleted: () {
                          setState(() {
                            _features.remove(f);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_isEditing ? 'Save Changes' : 'Create Plan'),
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

  Widget _buildDurationChip(String label, int days) {
    final isSelected = int.tryParse(_daysController.text) == days;
    return InkWell(
      onTap: () {
        setState(() {
          _daysController.text = days.toString();
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceLight,
          border: Border.all(color: isSelected ? AppColors.primaryLight : AppColors.cardBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _addCustomFeature() {
    final text = _customFeatureController.text.trim();
    if (text.isNotEmpty && !_features.contains(text)) {
      setState(() {
        _features.add(text);
        _customFeatureController.clear();
      });
    }
  }

  InputDecoration _buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryLight),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_features.isEmpty) {
      setState(() {
        _errorMessage = 'Please select or add at least one feature.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final viewModel = context.read<SysAdminViewModel>();
      final days = int.parse(_daysController.text.trim());
      final amount = double.parse(_amountController.text.trim());
      final label = _labelController.text.trim();
      final desc = _descController.text.trim();

      if (_isEditing) {
        final updatedPlan = widget.plan!.copyWith(
          label: label,
          days: days,
          amount: amount,
          isActive: _isActive,
          isPopular: _isPopular,
          features: _features,
          description: desc.isNotEmpty ? desc : null,
        );
        await viewModel.updatePlan(updatedPlan);
      } else {
        final newPlan = SubscriptionPlan(
          id: '',
          label: label,
          days: days,
          amount: amount,
          currency: 'XAF',
          isActive: _isActive,
          isPopular: _isPopular,
          features: _features,
          description: desc.isNotEmpty ? desc : null,
          createdAt: DateTime.now(),
        );
        await viewModel.createPlan(newPlan);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              _isEditing
                  ? 'Subscription plan "$label" updated successfully!'
                  : 'Subscription plan "$label" created successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }
}
