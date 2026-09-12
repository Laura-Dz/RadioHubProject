import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../view_models/sysadmin_view_model.dart';
import 'widgets/stats_card.dart';
import 'widgets/activity_feed.dart';
import 'widgets/category_breakdown_chart.dart';
import '../radios/widgets/radio_card.dart';
import '../radios/widgets/create_radio_modal.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SysAdminViewModel>();
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

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
                Icon(Icons.dashboard_rounded, color: AppColors.primaryLight, size: 22),
                SizedBox(width: 10),
                Text(
                  'SYSADMIN DASHBOARD',
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
                tooltip: 'Refresh Data',
                onPressed: viewModel.refreshData,
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                tooltip: 'Alerts',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No unread system alerts')),
                  );
                },
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Admin Active',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Main Dashboard Content
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. OVERVIEW STATS ROW
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Users',
                        value: NumberFormat('#,###').format(viewModel.totalUsersCount),
                        icon: Icons.people_alt_rounded,
                        change: '+12% this month',
                        isPositive: true,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'Radios',
                        value: '${viewModel.radios.length}',
                        icon: Icons.radio_rounded,
                        change: '${viewModel.radios.where((r) => r.isLive).length} streaming live',
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'Revenue',
                        value: currencyFormatter.format(viewModel.totalRevenue),
                        icon: Icons.payments_rounded,
                        change: '+18.4% growth',
                        isPositive: true,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                     Expanded(
                       child: StatsCard(
                         title: 'Transactions',
                         value: '${viewModel.transactions.length}',
                         icon: Icons.receipt_long_rounded,
                         change: '${viewModel.transactions.where((t) => !t.isAnnouncement).length} subscriptions',
                         color: AppColors.warning,
                       ),
                     ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'Active',
                        value: '${viewModel.activeRadioPercentage}%',
                        icon: Icons.sync_rounded,
                        change: 'Optimal uptime',
                        isPositive: true,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. RECENT ACTIVITY FEED
                ActivityFeed(activities: viewModel.activities),

                const SizedBox(height: 24),

                // 3. RADIOS SECTION
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.radio_rounded, color: AppColors.primaryLight, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'RADIOS (${viewModel.radios.length})',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Create Radio'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const CreateRadioModal(),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (viewModel.radios.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No radios currently registered.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 170,
                          ),
                          itemCount: viewModel.radios.length,
                          itemBuilder: (context, index) {
                            final radio = viewModel.radios[index];
                            return RadioCard(
                              radio: radio,
                              onTap: () {
                                viewModel.selectRadioForDetail(radio);
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. CATEGORY BREAKDOWN DONUT CHART
                CategoryBreakdownChart(categories: viewModel.categoryBreakdown),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

