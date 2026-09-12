import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../view_models/sysadmin_view_model.dart';
import '../dashboard/widgets/stats_card.dart';
import 'widgets/show_stats_card.dart';
import 'widgets/audimat_chart.dart';

class ShowsStatisticsScreen extends StatefulWidget {
  const ShowsStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<ShowsStatisticsScreen> createState() => _ShowsStatisticsScreenState();
}

class _ShowsStatisticsScreenState extends State<ShowsStatisticsScreen> {
  String _selectedRadio = 'all';
  String _selectedPeriod = 'week';

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SysAdminViewModel>();
    final filteredShows = _getFilteredShows(viewModel);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.tv_rounded, color: AppColors.primaryLight, size: 22),
            SizedBox(width: 10),
            Text(
              'SHOW STATISTICS & AUDIMAT',
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
          // Radio filter
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: AppColors.surface,
                value: _selectedRadio,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All Radios')),
                  ...viewModel.radios.map((radio) => DropdownMenuItem(
                        value: radio.id,
                        child: Text(radio.name),
                      )),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRadio = value);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Period filter
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: AppColors.surface,
                value: _selectedPeriod,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                items: const [
                  DropdownMenuItem(value: 'today', child: Text('Today')),
                  DropdownMenuItem(value: 'week', child: Text('This Week')),
                  DropdownMenuItem(value: 'month', child: Text('This Month')),
                  DropdownMenuItem(value: 'year', child: Text('This Year')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedPeriod = value);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh Shows',
            onPressed: viewModel.refreshData,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Quick Stats Row
                  _buildStatsRow(filteredShows),
                  const SizedBox(height: 24),
                  // Audimat Chart
                  _buildAudimatChart(filteredShows),
                  const SizedBox(height: 24),
                  // Shows List
                  _buildShowsList(filteredShows),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsRow(List<Map<String, dynamic>> filteredShows) {
    final totalShows = filteredShows.length;
    final liveShows = filteredShows.where((s) => s['status'] == 'live').length;
    final totalListeners = filteredShows.fold<int>(0, (sum, s) => sum + ((s['listenerCount'] ?? 0) as int));

    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: 'Total Shows',
            value: totalShows.toString(),
            change: 'In ${_getPeriodLabel(_selectedPeriod).toLowerCase()}',
            color: AppColors.info,
            icon: Icons.tv_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            title: 'Live Now',
            value: liveShows.toString(),
            change: 'Active broadcasts',
            color: AppColors.live,
            icon: Icons.cell_tower_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            title: 'Total Audimat',
            value: totalListeners.toString(),
            change: 'Cumulative listeners',
            color: AppColors.chartMusic,
            icon: Icons.headphones_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatsCard(
            title: 'Avg. Listeners',
            value: totalShows > 0 ? (totalListeners / totalShows).round().toString() : '0',
            change: 'Per show audience',
            color: AppColors.chartSports,
            icon: Icons.trending_up_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildAudimatChart(List<Map<String, dynamic>> filteredShows) {
    return Container(
      padding: const EdgeInsets.all(22),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: AppColors.primaryLight, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AUDIMAT BY SHOW',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Listener count per broadcast (${_getPeriodLabel(_selectedPeriod)})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${filteredShows.length} Shows Tracked',
                  style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: AudimatChart(shows: filteredShows),
          ),
        ],
      ),
    );
  }

  Widget _buildShowsList(List<Map<String, dynamic>> filteredShows) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.list_alt_rounded, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'SHOWS ARCHIVE & SESSIONS',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredShows.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No shows found for this radio or period selection.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredShows.length,
              itemBuilder: (context, index) {
                final show = filteredShows[index];
                return ShowStatsCard(show: show);
              },
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredShows(SysAdminViewModel viewModel) {
    final allShows = viewModel.shows.map((s) => s.toMap()).toList();

    var filtered = _selectedRadio == 'all'
        ? allShows
        : allShows.where((s) => s['radioId'] == _selectedRadio || s['programId'] == _selectedRadio).toList();

    return filtered;
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'today':
        return 'Today';
      case 'week':
        return '7 Days';
      case 'month':
        return '30 Days';
      case 'year':
        return '365 Days';
      default:
        return 'Period';
    }
  }
}

