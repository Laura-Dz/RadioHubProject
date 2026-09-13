import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final BoxBorder? border;

  const AppAvatar({
    Key? key,
    this.photoUrl,
    required this.name,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final fallbackBg = backgroundColor ?? AppColors.primary.withOpacity(0.12);
    final fallbackColor = textColor ?? AppColors.primary;

    final fallback = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: fallbackBg,
        shape: BoxShape.circle,
        border: border,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.85,
          color: fallbackColor,
        ),
      ),
    );

    if (photoUrl == null || photoUrl!.trim().isEmpty) {
      return fallback;
    }

    final trimmed = photoUrl!.trim();

    Widget imageWidget;
    if (trimmed.startsWith('data:')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final rawBase64 = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final bytes = base64Decode(rawBase64);
        imageWidget = Image.memory(
          bytes,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    } else {
      imageWidget = Image.network(
        trimmed,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    final circular = ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: imageWidget,
      ),
    );

    if (border != null) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border,
        ),
        child: circular,
      );
    }

    return circular;
  }
}
