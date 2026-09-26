import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final bool isFollowed;
  final VoidCallback onToggle;
  final int followerCount;
  final bool compact;

  const FollowButton({
    Key? key,
    required this.isFollowed,
    required this.onToggle,
    this.followerCount = 0,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: isFollowed ? Colors.grey.shade200 : Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFollowed ? Icons.check : Icons.add,
                  size: compact ? 13 : 16,
                  color: isFollowed ? Colors.black87 : Colors.white,
                ),
                const SizedBox(width: 3),
                Text(
                  isFollowed ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: isFollowed ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 10.5 : 12,
                  ),
                ),
              ],
            ),
          ),
          if (!compact && followerCount > 0) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _formatCount(followerCount),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

