import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/recommendation_model.dart';
import '../../../core/constants/app_colors.dart';
import '../subscription/subscription_screen.dart';
import 'comparison_view.dart';

class InsightsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSubscription;

  const InsightsScreen({Key? key, this.onNavigateToSubscription}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _range = 'last_30_days';

  @override
  void initState() {
    super.initState();
    // Do NOT auto-fetch insights. User must explicitly request it per requirements.
  }

  void _requestReport(RadioAdminViewModel vm) {
    if (_range == 'custom' && vm.customStartDate != null && vm.customEndDate != null) {
      vm.requestAiReport(startDate: vm.customStartDate, endDate: vm.customEndDate);
    } else {
      vm.requestAiReport(timeRange: _range);
    }
  }

  Future<void> _pickCustomDateRange(BuildContext context, RadioAdminViewModel vm) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 10)),
      lastDate: now,
      initialDateRange: (vm.customStartDate != null && vm.customEndDate != null)
          ? DateTimeRange(start: vm.customStartDate!, end: vm.customEndDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      helpText: 'SELECT PERIOD (MAX 5 YEARS)',
      confirmText: 'APPLY',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final days = picked.end.difference(picked.start).inDays;
      if (days > 1826) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('The selected interval ($days days) exceeds the 5-year maximum limit (1,826 days).'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      vm.setCustomDateRange(picked.start, picked.end);
      setState(() => _range = 'custom');
      if (vm.aiReportRequested && vm.isAiEligible) {
        vm.requestAiReport(startDate: picked.start, endDate: picked.end);
      }
    }
  }

  void _openSubscription(BuildContext context) {
    if (widget.onNavigateToSubscription != null) {
      widget.onNavigateToSubscription!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final insights = vm.insights;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'AI Strategic Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 12, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Gemini 3.6 Flash',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'last_7_days', label: Text('7d')),
                ButtonSegment(value: 'last_30_days', label: Text('30d')),
                ButtonSegment(value: 'last_90_days', label: Text('90d')),
              ],
              selected: {_range == 'custom' ? '' : _range},
              emptySelectionAllowed: true,
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                vm.clearCustomDateRange();
                setState(() => _range = s.first);
                if (vm.aiReportRequested && vm.isAiEligible) {
                  _requestReport(vm);
                }
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.resolveWith((states) =>
                    states.contains(MaterialState.selected) ? Colors.white : AppColors.textSecondary),
                backgroundColor: MaterialStateProperty.resolveWith((states) =>
                    states.contains(MaterialState.selected) ? AppColors.primary : AppColors.surface),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(
                Icons.date_range,
                size: 16,
                color: _range == 'custom' ? Colors.white : AppColors.primary,
              ),
              label: Text(
                _range == 'custom' && vm.customStartDate != null && vm.customEndDate != null
                    ? '${vm.customStartDate!.day}/${vm.customStartDate!.month}/${vm.customStartDate!.year} - ${vm.customEndDate!.day}/${vm.customEndDate!.month}/${vm.customEndDate!.year}'
                    : 'Custom (≤5 yrs)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _range == 'custom' ? Colors.white : AppColors.primary,
                ),
              ),
              backgroundColor: _range == 'custom' ? AppColors.primary : AppColors.primary.withOpacity(0.08),
              side: BorderSide(
                color: _range == 'custom' ? AppColors.primary : AppColors.primary.withOpacity(0.2),
              ),
              onPressed: () => _pickCustomDateRange(context, vm),
            ),
          ),
          if (vm.aiReportRequested && vm.isAiEligible)
            IconButton(
              tooltip: 'Regenerate report',
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: vm.loadingInsights ? null : () => _requestReport(vm),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, vm, insights),
    );
  }

  Widget _buildBody(BuildContext context, RadioAdminViewModel vm, RadioInsights? insights) {
    if (vm.loadingInsights) {
      return _buildLoadingView();
    }

    // Ineligible plan check
    if (!vm.isAiEligible || (insights != null && !insights.isEligible)) {
      return _buildIneligibleView(context, vm, insights);
    }

    // Unrequested state
    if (!vm.aiReportRequested && insights == null) {
      return _buildUnrequestedView(vm);
    }

    // Report is ready
    if (insights != null) {
      return _buildReportView(vm, insights);
    }

    return _buildUnrequestedView(vm);
  }

  Widget _buildLoadingView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Synthesizing Station Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            Text(
              'Collecting and segmenting your station\'s real audimat curves, show metrics, announcement volume, and revenue...\nGemini 2.0 Flash is structuring actionable recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIneligibleView(BuildContext context, RadioAdminViewModel vm, RadioInsights? insights) {
    final reason = vm.aiIneligibleReason ??
        insights?.ineligibleReason ??
        'Your current subscription plan is not eligible for AI Strategic Insights. AI Insights require an active Quarterly, Yearly, or Enterprise subscription.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.warning.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, size: 40, color: AppColors.warning),
              ),
              const SizedBox(height: 20),
              const Text(
                'AI Insights Plan Not Eligible',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.border),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What you unlock with an eligible plan:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              _featureRow(Icons.auto_awesome, 'Direct Gemini 2.0 Flash Station Analysis', 'Full strategic audit segmented by audimat, shows, and revenue.'),
              _featureRow(Icons.show_chart, 'Audimat Dynamics & Listener Drop-Offs', 'Identifies exact peak listening hours and declining time slots.'),
              _featureRow(Icons.monetization_on_outlined, 'Monetization & Ad Tariffs Strategy', 'Optimizes announcement pricing and ad escrow slots.'),
              _featureRow(Icons.playlist_add_check, 'Prioritized Strategic Action Plan', 'Actionable steps to grow audience and maximize broadcast revenue.'),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => _requestReport(vm),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    child: const Text('Check Again'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openSubscription(context),
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    label: const Text('Upgrade Subscription Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      elevation: 2,
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

  Widget _featureRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: desc, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnrequestedView(RadioAdminViewModel vm) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Generate Strategic Station Report',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Request an on-demand AI strategic audit tailored strictly to your radio station. Powered directly by Google Gemini 2.0 Flash.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _featureRow(Icons.analytics_outlined, 'Segmented Audimat Analysis', 'Audience retention, live peaks, and decline patterns.'),
                    _featureRow(Icons.tv_outlined, 'Show Performance & Schedule', 'Diagnostics of top-performing and struggling programs.'),
                    _featureRow(Icons.monetization_on_outlined, 'Revenue & Escrow Opportunities', 'Announcement tariffs and commercial broadcast recommendations.'),
                    _featureRow(Icons.fact_check_outlined, 'Strategic Action Plan', 'Step-by-step executive roadmap for station management.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Audit Period: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _range,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'last_7_days', child: Text('Last 7 Days')),
                      DropdownMenuItem(value: 'last_30_days', child: Text('Last 30 Days')),
                      DropdownMenuItem(value: 'last_90_days', child: Text('Last 90 Days')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _range = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _requestReport(vm),
                  icon: const Icon(Icons.bolt, size: 20),
                  label: const Text(
                    'Request Gemini Strategic Report',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Available on eligible plans (Quarterly, Yearly). Requires active subscription.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportView(RadioAdminViewModel vm, RadioInsights insights) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive AI Summary
          if (insights.aiSummary != null && insights.aiSummary!.isNotEmpty) ...[
            _aiSummarySection(insights.aiSummary!),
            const SizedBox(height: 16),
          ],

          // Strategic Action Plan
          if (insights.strategicActionPlan.isNotEmpty) ...[
            _strategicActionPlanSection(insights.strategicActionPlan),
            const SizedBox(height: 16),
          ],

          // Audimat Section
          if (insights.audimat != null || (insights.audimatAnalysis?.isNotEmpty ?? false)) ...[
            _audimatSection(insights.audimat, insights.audimatAnalysis ?? ''),
            const SizedBox(height: 16),
          ],

          // Shows Section
          if (insights.shows != null || (insights.showsAnalysis?.isNotEmpty ?? false)) ...[
            _showsSection(insights.shows, insights.showsAnalysis ?? ''),
            const SizedBox(height: 16),
          ],

          // Revenue Section
          if (insights.revenue != null || (insights.revenueStrategy?.isNotEmpty ?? false)) ...[
            _revenueSection(insights.revenue, insights.revenueStrategy ?? ''),
            const SizedBox(height: 16),
          ],

          // Scheduling Section
          if (insights.scheduling != null || (insights.schedulingRecommendations?.isNotEmpty ?? false)) ...[
            _schedulingSection(insights.scheduling, insights.schedulingRecommendations ?? ''),
            const SizedBox(height: 16),
          ],

          // Comparisons
          if (insights.comparisons.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.compare_arrows, color: AppColors.gold, size: 20),
                SizedBox(width: 8),
                Text('Why some shows outperform others',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ...insights.comparisons.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ComparisonCard(comparison: c),
                )),
          ],

          // Diagnostics
          if (insights.diagnostics.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.insights, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Show diagnostics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ...insights.diagnostics.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DiagnosticCard(diagnostic: d),
                )),
          ],

          // Full Report Markdown (if present)
          if (insights.fullReportMarkdown != null && insights.fullReportMarkdown!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _fullReportSection(insights.fullReportMarkdown!),
            const SizedBox(height: 24),
          ],

          // Bottom Action
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _requestReport(vm),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Re-run Strategic Report'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _aiSummarySection(String summary) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Executive AI Strategic Briefing',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 13, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Gemini 2.0 Flash',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              summary,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );

  Widget _strategicActionPlanSection(List<String> actions) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.playlist_add_check, size: 18, color: AppColors.gold),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recommended Action Plan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...actions.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final action = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$idx',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action,
                        style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );

  Widget _audimatSection(AudimatInsights? a, String audimatAnalysis) => _card(
        'Audimat Dynamics & Traffic',
        Icons.analytics_outlined,
        [
          if (audimatAnalysis.isNotEmpty) ...[
            Text(audimatAnalysis, style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
          ],
          if (a != null) ...[
            _subsection(
              'Peak hours',
              a.peakHours.map((h) => _insightRow(h.hour, '${h.avgListeners} avg', h.recommendation)).toList(),
            ),
            _subsection(
              'Declining slots',
              a.decliningSlots.map((h) => _insightRow(h.hour, '${h.avgListeners} avg', h.recommendation)).toList(),
            ),
          ],
        ],
      );

  Widget _showsSection(ShowInsights? s, String showsAnalysis) => _card(
        'Show Performance & Content',
        Icons.tv_outlined,
        [
          if (showsAnalysis.isNotEmpty) ...[
            Text(showsAnalysis, style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
          ],
          if (s != null) ...[
            _subsection(
              'Top performers',
              s.topPerformers
                  .map((p) => _insightRow(
                      p.show, '${p.listeners} · ${(p.retention * 100).toInt()}% ret', p.recommendation))
                  .toList(),
            ),
            _subsection(
              'Underperformers',
              s.underperformers
                  .map((p) => _insightRow(
                      p.show, '${p.listeners} · ${(p.retention * 100).toInt()}% ret', p.recommendation))
                  .toList(),
            ),
            _subsection(
              'Suggested changes',
              s.suggestedScheduleChanges
                  .map((c) => _insightRow(c.current, '→ ${c.suggested}', c.reason))
                  .toList(),
            ),
          ],
        ],
      );

  Widget _revenueSection(RevenueInsights? r, String revenueStrategy) => _card(
        'Revenue & Monetization Strategy',
        Icons.attach_money,
        [
          if (revenueStrategy.isNotEmpty) ...[
            Text(revenueStrategy, style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
          ],
          if (r != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Text('Projected monthly: ',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text('${r.projectedMonthly.toStringAsFixed(0)} XAF',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),
            _subsection(
              'Recommended categories',
              r.categoriesRecommended.map((c) => _insightRow(c.category, '', c.reason)).toList(),
            ),
          ],
        ],
      );

  Widget _schedulingSection(SchedulingInsights? s, String schedulingRecommendations) => _card(
        'Scheduling & Grid Optimization',
        Icons.calendar_today_outlined,
        [
          if (schedulingRecommendations.isNotEmpty) ...[
            Text(schedulingRecommendations,
                style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
          ],
          if (s != null) ...[
            _subsection(
              'Recommended slots',
              s.recommendedSlots.map((sl) => _insightRow('${sl.day} · ${sl.hour}', '', sl.reason)).toList(),
            ),
            _subsection(
              'Avoid slots',
              s.avoidSlots.map((sl) => _insightRow('${sl.day} · ${sl.hour}', '', sl.reason)).toList(),
            ),
          ],
        ],
      );

  Widget _fullReportSection(String markdown) => Container(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.article_outlined, size: 18, color: AppColors.info),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Full Strategic Report',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                markdown,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _card(String title, IconData icon, List<Widget> children) => Container(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _subsection(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w700),
          ),
        ),
        ...rows,
      ],
    );
  }

  Widget _insightRow(String label, String value, String recommendation) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                if (value.isNotEmpty)
                  Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            if (recommendation.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                recommendation,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      );
}

class _DiagnosticCard extends StatelessWidget {
  final ShowDiagnostic diagnostic;
  const _DiagnosticCard({required this.diagnostic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(diagnostic.show,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${diagnostic.listeners} avg',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(diagnostic.verdict, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: diagnostic.distribution.map((d) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 40 * d.pct / 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(d.ageGroup, style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
