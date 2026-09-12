import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryBreakdownChart extends StatelessWidget {
  final Map<String, double> categories;

  const CategoryBreakdownChart({Key? key, required this.categories}) : super(key: key);

  static const Map<String, Color> categoryColors = {
    'Music': AppColors.chartMusic,
    'Talk': AppColors.chartTalk,
    'News': AppColors.chartNews,
    'Sports': AppColors.chartSports,
    'Other': AppColors.chartOther,
    'General': AppColors.primaryLight,
  };

  @override
  Widget build(BuildContext context) {
    final effectiveCategories = categories.isNotEmpty
        ? categories
        : {'Music': 34.0, 'Talk': 28.0, 'News': 20.0, 'Sports': 10.0, 'Other': 8.0};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'CATEGORY BREAKDOWN',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Custom-painted Donut Chart
              SizedBox(
                width: 150,
                height: 150,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    data: effectiveCategories,
                    colors: categoryColors,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${effectiveCategories.length}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Genres',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              // Legend
              Expanded(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: effectiveCategories.entries.map((entry) {
                    final color = categoryColors[entry.key] ?? AppColors.primary;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.key} (${entry.value.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Map<String, Color> colors;

  _DonutChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 24.0;

    final total = data.values.fold<double>(0.0, (sum, val) => sum + val);
    if (total == 0) return;

    var startAngle = -pi / 2;

    for (final entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * pi;
      final paint = Paint()
        ..color = colors[entry.key] ?? AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

