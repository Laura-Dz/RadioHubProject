import 'package:flutter/material.dart';

import '../../../core/models/host.dart';
import '../../../core/models/program.dart';
import '../../../core/services/radio_schedule_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/safe_image.dart';
import '../widgets/program_card.dart';
import '../widgets/program_detail_sheet.dart';

class HostDetailPage extends StatelessWidget {
  final Host host;
  final String radioId;
  final String radioName;

  const HostDetailPage({
    Key? key,
    required this.host,
    required this.radioId,
    required this.radioName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = RadioScheduleService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SafeImage(
                        imageUrl: host.photoUrl,
                        fit: BoxFit.cover,
                        fallback: _initials(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      host.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      radioName,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      if (host.experienceYears != null)
                        Expanded(
                          child: _stat(
                            icon: Icons.timeline,
                            value: '${host.experienceYears}',
                            label: 'Years',
                          ),
                        ),
                      if (host.specialty != null)
                        Expanded(
                          child: _stat(
                            icon: Icons.star_border,
                            value: host.specialty!,
                            label: 'Specialty',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bio
                  if (host.bio != null && host.bio!.isNotEmpty) ...[
                    _sectionTitle('About'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        host.bio!,
                        style: const TextStyle(
                            fontSize: 13.5, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Programs
                  _sectionTitle('Shows presented'),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Programs carousel
          SliverToBoxAdapter(
            child: StreamBuilder<List<Program>>(
              stream: service.streamProgramsByHost(
                radioId: radioId,
                hostId: host.id,
              ),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 260,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }
                final programs = snap.data!;
                if (programs.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline,
                            size: 16, color: AppColors.textMuted),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No programs currently linked to this host.',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox(
                  height: 260,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: programs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => ProgramCard(
                      program: programs[i],
                      isFavourite: false,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            ProgramDetailSheet(program: programs[i]),
                      ),
                      onToggleFavourite: () {},
                    ),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _initials() => Center(
        child: Text(
          host.name.isNotEmpty ? host.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      );

  Widget _stat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
