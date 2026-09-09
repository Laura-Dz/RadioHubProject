import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final bool isFollowed;
  final VoidCallback onToggle;
  final int followerCount;

  const FollowButton({
    Key? key,
    required this.isFollowed,
    required this.onToggle,
    this.followerCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isFollowed ? Colors.grey.shade200 : Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                isFollowed ? Icons.check : Icons.add,
                size: 16,
                color: isFollowed ? Colors.black87 : Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                isFollowed ? 'Following' : 'Follow',
                style: TextStyle(
                  color: isFollowed ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (followerCount > 0) ...[
          const SizedBox(width: 8),
          Text(
            '$_formatCount(followerCount)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
