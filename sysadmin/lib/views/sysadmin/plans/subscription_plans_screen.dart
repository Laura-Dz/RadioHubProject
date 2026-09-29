import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/sysadmin/subscription_plan_model.dart';
import '../../../view_models/sysadmin_view_model.dart';
import 'widgets/plan_edit_modal.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, inactive

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SysAdminViewModel>();
    var plans = viewModel.plans;

    if (_statusFilter == 'active') {
      plans = plans.where((p) => p.isActive).toList();
    } else if (_statusFilter == 'inactive') {
      plans = plans.where((p) => !p.isActive).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      plans = plans.where((p) =>
        p.label.toLowerCase().contains(q) ||
        (p.description != null && p.description!.toLowerCase().contains(q)) ||
        p.features.any((f) => f.toLowerCase().contains(q))
      ).toList();
    }

    final totalPlans = viewModel.plans.length;
    final activePlans = viewModel.plans.where((p) => p.isActive).length;
    final aiPlans = viewModel.plans.where((p) => p.hasAiInsights).length;
    final lowestPrice = viewModel.plans.isNotEmpty
        ? viewModel.plans.map((p) => p.amount).reduce((a, b) => a < b ? a : b)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            floating: true,
            title: const Row(
              children: [
                Icon(Icons.loyalty_rounded, color: AppColors.primaryLight, size: 22),
                SizedBox(width: 10),
                Text(
                  'SUBSCRIPTION PLANS & PRICING',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                tooltip: 'Refresh Plans',
                onPressed: viewModel.refreshData,
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Stats Row
                Row(
                  children: [
                    _buildStatCard(
                      'TOTAL PLANS',
                      '$totalPlans',
                      Icons.layers_rounded,
                      AppColors.primaryLight,
                      'Available in system',
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'ACTIVE TIERS',
                      '$activePlans',
                      Icons.check_circle_rounded,
                      AppColors.success,
                      'Visible to radio admins',
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'AI-POWERED TIERS',
                      '$aiPlans',
                      Icons.auto_awesome_rounded,
                      AppColors.accent,
                      'Gemini analytics enabled',
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'ENTRY PRICE',
                      '${lowestPrice.toInt()} XAF',
                      Icons.price_check_rounded,
                      AppColors.secondary,
                      'Lowest tier pricing',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Search & Filter Toolbar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search plan by name, feature, or description...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Status filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: AppColors.surface,
                            value: _statusFilter,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Plans')),
                              DropdownMenuItem(value: 'active', child: Text('Active Only')),
                              DropdownMenuItem(value: 'inactive', child: Text('Inactive Only')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _statusFilter = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Create Plan Action Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Create Plan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const PlanEditModal(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Plans Grid or Empty State
                if (plans.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.loyalty_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 14),
                          const Text(
                            'No subscription plans found',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Click "Create Plan" above to create your first station subscription tier.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      mainAxisExtent: 470,
                    ),
                    itemCount: plans.length,
                    itemBuilder: (context, index) {
                      return _buildPlanCard(context, plans[index], viewModel);
                    },
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan, SysAdminViewModel viewModel) {
    final isPopular = plan.isPopular;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? AppColors.primaryLight : AppColors.cardBorder,
          width: isPopular ? 1.5 : 1.0,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: AppColors.primaryLight.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Badges Row
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            decoration: BoxDecoration(
              color: isPopular ? AppColors.primaryLight.withOpacity(0.06) : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          plan.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'POPULAR',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Toggle Active Switch
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plan.isActive ? 'Active' : 'Disabled',
                      style: TextStyle(
                        color: plan.isActive ? AppColors.success : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: plan.isActive,
                        activeColor: AppColors.success,
                        onChanged: (val) {
                          viewModel.togglePlanStatus(plan.id, val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // Price & Duration Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      plan.formattedPrice,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        plan.durationFormatted,
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (plan.description != null && plan.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    plan.description!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // Features List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: plan.features.map((feat) {
                  final isAi = feat.toLowerCase().contains('ai');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isAi ? Icons.auto_awesome_rounded : Icons.check_circle_rounded,
                          size: 16,
                          color: isAi ? AppColors.accent : AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feat,
                            style: TextStyle(
                              color: isAi ? AppColors.accent : AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: isAi ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // Action Buttons Footer
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Plan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                      side: const BorderSide(color: AppColors.primaryLight),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => PlanEditModal(plan: plan),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Delete Plan',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: () => _confirmDeletePlan(context, plan, viewModel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlan(BuildContext context, SubscriptionPlan plan, SysAdminViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text('Delete Subscription Plan?', style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${plan.label}" (${plan.formattedPrice})?\n\nExisting stations currently subscribed to this tier will keep their active duration, but new stations will no longer see it.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogCtx);
              await viewModel.deletePlan(plan.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.error,
                    content: Text('Plan "${plan.label}" deleted.'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
