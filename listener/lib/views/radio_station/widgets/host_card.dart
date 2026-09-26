import 'package:flutter/material.dart';

import '../../../core/models/host.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/safe_image.dart';

class HostCard extends StatefulWidget {
  final Host host;
  final VoidCallback onTap;

  const HostCard({Key? key, required this.host, required this.onTap})
      : super(key: key);

  @override
  State<HostCard> createState() => _State();
}

class _State extends State<HostCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.host;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 95,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover
                  ? AppColors.primary.withOpacity(0.35)
                  : AppColors.border,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SafeImage(
                    imageUrl: h.photoUrl,
                    fit: BoxFit.cover,
                    fallback: _initials(h.name),
                  ),
                ),
                const SizedBox(height: 6),
                // Name
                Text(
                  h.name,
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                // Specialty / role
                Text(
                  h.specialty ??
                      (h.experienceYears != null
                          ? '${h.experienceYears} yrs'
                          : 'Host'),
                  style: const TextStyle(
                      fontSize: 9.5, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _initials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
