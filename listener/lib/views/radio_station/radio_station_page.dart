import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_models/radio_station_view_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/safe_image.dart';
import 'widgets/hero_block.dart';
import 'widgets/player_controls.dart';
import 'widgets/about_section.dart';
import 'widgets/shows_section.dart';
import 'widgets/station_media_section.dart';
import 'widgets/hosts_section.dart';
import 'widgets/request_announcement_card.dart';
import 'widgets/related_radios.dart';

class RadioStationPage extends StatefulWidget {
  final String radioId;
  const RadioStationPage({Key? key, required this.radioId}) : super(key: key);

  @override
  State<RadioStationPage> createState() => _State();
}

class _State extends State<RadioStationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioStationViewModel>().attach(widget.radioId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();
    final r = vm.radio;

    if (vm.loading || r == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SafeImage(
                imageUrl: r.logoUrl,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                fallback: Container(
                  width: 32,
                  height: 32,
                  color: AppColors.primary.withOpacity(0.1),
                  child: Center(
                    child: Text(
                      r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      r.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (r.isVerified)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.verified,
                          size: 14, color: AppColors.primary),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: r.isFollowed ? 'Starred' : 'Star radio',
            icon: Icon(
              r.isFollowed ? Icons.star : Icons.star_border,
              color: r.isFollowed ? AppColors.gold : null,
            ),
            onPressed: vm.toggleStarRadio,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            HeroBlock(),
            PlayerControls(),
            AboutSection(),
            ShowsSection(),               // shows + schedule/timetable buttons
            HostsSection(),               // host carousel
            StationMediaSection(),        // audios & videos / podcasts section
            RequestAnnouncementCard(),     // request announcement card
            RelatedRadios(),              // related radios
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
