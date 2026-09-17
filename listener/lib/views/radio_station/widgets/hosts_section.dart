import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../view_models/radio_station_view_model.dart';
import '../../../core/models/host.dart';
import '../../../core/services/radio_schedule_service.dart';
import '../../../core/constants/app_colors.dart';
import 'host_card.dart';
import '../host/host_detail_page.dart';

class HostsSection extends StatelessWidget {
  const HostsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();
    final radio = vm.radio;
    if (radio == null) return const SizedBox.shrink();

    final service = RadioScheduleService();

    return StreamBuilder<List<Host>>(
      stream: service.streamHosts(radio.id),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final hosts = snap.data!;
        if (hosts.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.groups_outlined,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Our hosts',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(
                      '${hosts.length}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'The voices behind the shows',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 14),

              // Hosts carousel
              SizedBox(
                height: 125,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: hosts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => HostCard(
                    host: hosts[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HostDetailPage(
                          host: hosts[i],
                          radioId: radio.id,
                          radioName: radio.name,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
