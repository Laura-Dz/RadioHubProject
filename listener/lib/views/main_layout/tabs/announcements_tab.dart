import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../view_models/announcement_view_model.dart';
import '../../announcements/my_announcements_screen.dart';

class AnnouncementsTab extends StatefulWidget {
  const AnnouncementsTab({Key? key}) : super(key: key);

  @override
  State<AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<AnnouncementsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      context.read<AnnouncementViewModel>().watchMyAnnouncements(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MyAnnouncementsScreen(
      showAppBar: false,
    );
  }
}
