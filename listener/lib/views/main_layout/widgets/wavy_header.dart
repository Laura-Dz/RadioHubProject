import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WavyHeader extends StatelessWidget {
  final String welcomeMessage;
  final String? userImage;

  const WavyHeader({Key? key, required this.welcomeMessage, this.userImage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)]
              : [const Color(0xFF4A90D9), const Color(0xFF6C63FF), const Color(0xFF7B68EE)],
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.1)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: userImage != null
                          ? ClipOval(
                              child: Image.network(userImage!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 24)),
                            )
                          : const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(welcomeMessage, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black26)])),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  const Text('Live', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                ]),
                              ),
                              const SizedBox(width: 8),
                              Text('${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                            child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    final width = size.width;
    final height = size.height;

    path.moveTo(0, height * 0.6);
    for (double x = 0; x <= width; x += 1) {
      final y = height * 0.6 + sin(x * 0.02 + 1) * 30 + sin(x * 0.03 + 2) * 15;
      path.lineTo(x, y);
    }
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();
    canvas.drawPath(path, paint);

    final path2 = Path();
    path2.moveTo(0, height * 0.8);
    for (double x = 0; x <= width; x += 1) {
      final y = height * 0.8 + sin(x * 0.025 + 3) * 20 + sin(x * 0.035 + 4) * 10;
      path2.lineTo(x, y);
    }
    path2.lineTo(width, height);
    path2.lineTo(0, height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
