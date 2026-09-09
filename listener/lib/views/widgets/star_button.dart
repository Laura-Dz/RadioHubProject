import 'package:flutter/material.dart';

class StarButton extends StatelessWidget {
  final String channelId;
  final bool isStarred;
  final VoidCallback onToggle;

  const StarButton({
    Key? key,
    required this.channelId,
    required this.isStarred,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isStarred ? Icons.star : Icons.star_border,
        color: isStarred ? Colors.amber : Colors.grey,
        size: 22,
      ),
      onPressed: onToggle,
      tooltip: isStarred ? 'Remove from favorites' : 'Add to favorites',
    );
  }
}
