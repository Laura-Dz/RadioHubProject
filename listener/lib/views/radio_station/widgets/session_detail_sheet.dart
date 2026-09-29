import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../view_models/radio_station_view_model.dart';
import '../../../core/models/session_model.dart';
import '../../../core/constants/app_colors.dart';

class SessionDetailSheet extends StatelessWidget {
  final SessionModel session;
  const SessionDetailSheet({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status badge
              _statusBadge(),

              const SizedBox(height: 12),

              // Title
              Text(session.programName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),

              const SizedBox(height: 4),

              // Time
              Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('EEEE d MMMM').format(session.scheduledStart)} · '
                    '${DateFormat('HH:mm').format(session.scheduledStart)}–'
                    '${DateFormat('HH:mm').format(session.scheduledEnd)}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (session.hostName != null && session.hostName!.isNotEmpty)
                _row(Icons.mic_none, 'Main Host', session.hostName!),
              if (session.coHostNames.isNotEmpty)
                _chipsRow(Icons.people_outline, 'Co-Hosts', session.coHostNames),
              if (session.guests.isNotEmpty)
                _guestsRow(session.guests)
              else if (session.guestName != null && session.guestName!.isNotEmpty)
                _row(Icons.person_outline, 'Guest',
                    '${session.guestName}${session.guestRole != null ? " · ${session.guestRole}" : ""}'),
              if (session.thematic != null && session.thematic!.isNotEmpty)
                _row(Icons.label_outline, 'Thematic', session.thematic!),
              if (session.description != null &&
                  session.description!.isNotEmpty)
                _row(Icons.description_outlined, 'About',
                    session.description!),

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: _markButton(
                      context,
                      label: vm.isProgramFavourite(session.programId)
                          ? 'Favourited'
                          : 'Favourite',
                      icon: vm.isProgramFavourite(session.programId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      isActive: vm.isProgramFavourite(session.programId),
                      onTap: () => vm.toggleFavouriteProgram(
                          session.programId, session.programName),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _markButton(
                      context,
                      label: vm.isSessionReminder(session.id)
                          ? 'Reminder set'
                          : 'Remind me',
                      icon: vm.isSessionReminder(session.id)
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      isActive: vm.isSessionReminder(session.id),
                      onTap: () => vm.toggleReminder(session),
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

  Widget _statusBadge() {
    if (session.status == SessionStatus.onAir) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('ON AIR',
            style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6)),
      );
    }
    if (session.isRediffusion) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('REDIFFUSION',
            style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('UPCOMING',
          style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6)),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _chipsRow(IconData icon, String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: items.map((it) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Text(it, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guestsRow(List<Map<String, String>> guests) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 10),
          const SizedBox(
            width: 70,
            child: Text('Guests',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: guests.map((g) {
                final hasRole = (g['role'] ?? '').isNotEmpty;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    hasRole ? '${g['name']} · ${g['role']}' : (g['name'] ?? ''),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _markButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: isActive ? AppColors.primary : AppColors.textSecondary,
        backgroundColor:
            isActive ? AppColors.primary.withOpacity(0.06) : null,
        side: BorderSide(
            color: isActive ? AppColors.primary : AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
