import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/subscription_plan_service.dart';
import 'widgets/subscription_payment_dialog.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final sub = vm.subscription;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription & Billing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active subscription status card
            if (sub != null && !sub.isExpired)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
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
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.verified, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sub.planName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              Text('Active until ${sub.endDate.day}/${sub.endDate.month}/${sub.endDate.year}',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Active',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: sub.daysRemaining > 0 ? (sub.daysRemaining / 30).clamp(0.0, 1.0) : 0,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text('${sub.daysRemaining} days remaining',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 32, color: AppColors.error),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('No Active Subscription',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.error)),
                          SizedBox(height: 2),
                          Text('Choose a plan below to activate or renew your station broadcasting license.',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),

            // Available plans (from SysAdmin subscription_plans collection)
            const Text('Available Plans (SysAdmin Managed)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Select a plan to subscribe or renew.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 16),

            // Responsive Plans Cards
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: vm.plans.map((plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PlanCard(plan: plan),
                    )).toList(),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: vm.plans.map((plan) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: _PlanCard(plan: plan),
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  const _PlanCard({Key? key, required this.plan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          Text(plan.label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('${plan.days} Days', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.amount.toStringAsFixed(0),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              Text(plan.currency, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          ...plan.features.map((f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.check, size: 14, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: const TextStyle(fontSize: 12.5))),
              ],
            ),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPaymentDialog(context, plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Choose Plan'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, SubscriptionPlan plan) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => SubscriptionPaymentDialog(plan: plan),
    );
  }
}
