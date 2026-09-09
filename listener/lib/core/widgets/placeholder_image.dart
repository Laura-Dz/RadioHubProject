import 'package:flutter/material.dart';
import 'package:listener/core/theme/app_colors.dart';

class PlaceholderImage extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData? icon;
  final Color? color;

  const PlaceholderImage({
    Key? key,
    this.width,
    this.height,
    this.icon,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon ?? Icons.radio,
        color: color ?? AppColors.primary,
      ),
    );
  }
}
