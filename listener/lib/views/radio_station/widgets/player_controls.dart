import 'package:flutter/material.dart';

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayToggle;
  final VoidCallback onQueueTap;
  final VoidCallback onCommentsTap;
  final bool hasComments;

  const PlayerControls({
    Key? key,
    required this.isPlaying,
    required this.onPlayToggle,
    required this.onQueueTap,
    required this.onCommentsTap,
    this.hasComments = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButton(Icons.list_alt, 'Queue', onQueueTap),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF4A90D9)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 40),
              onPressed: onPlayToggle,
              padding: EdgeInsets.zero,
            ),
          ),
          _buildButton(Icons.comment, 'Comments', onCommentsTap, hasBadge: hasComments),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, VoidCallback onTap, {bool hasBadge = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Stack(
              children: [
                Icon(icon, size: 28, color: Colors.grey[600]),
                if (hasBadge)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
