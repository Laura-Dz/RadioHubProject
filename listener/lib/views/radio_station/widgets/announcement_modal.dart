import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../view_models/radio_station_view_model.dart';
import '../../announcements/create_announcement_modal.dart';

class AnnouncementModal extends StatelessWidget {
  final RadioStationViewModel viewModel;
  final VoidCallback onRequestSubmitted;

  const AnnouncementModal({
    Key? key,
    required this.viewModel,
    required this.onRequestSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radio = viewModel.radio;
    final radioId = radio?.id ?? 'radio_1';
    final radioName = radio?.name ?? 'Radio Station';
    final user = FirebaseAuth.instance.currentUser;
    final listenerName = user?.displayName ?? user?.email ?? 'Listener';

    return CreateAnnouncementModal(
      radioId: radioId,
      radioName: radioName,
      listenerName: listenerName,
    );
  }
}
