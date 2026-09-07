import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  const SectionHeader({Key? key, required this.title, this.subtitle, this.onSeeAll}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Row(
                children: [
                  const Text('See all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
