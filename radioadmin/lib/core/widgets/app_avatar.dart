import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? imageUrl;
  final String name;
  final double? radius;
  final double? size;
  final Color? backgroundColor;
  final Color? textColor;
  final BoxBorder? border;

  const AppAvatar({
    Key? key,
    this.photoUrl,
    this.imageUrl,
    required this.name,
    this.radius,
    this.size,
    this.backgroundColor,
    this.textColor,
    this.border,
  }) : super(key: key);

  double get _effectiveRadius {
    if (radius != null) return radius!;
    if (size != null) return size! / 2;
    return 20.0;
  }

  String? get _effectiveUrl {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) return imageUrl!.trim();
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) return photoUrl!.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = _effectiveRadius;
    final effectiveUrl = _effectiveUrl;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final fallbackBg = backgroundColor ?? AppColors.primary.withOpacity(0.12);
    final fallbackColor = textColor ?? AppColors.primary;

    final fallback = Container(
      width: effectiveRadius * 2,
      height: effectiveRadius * 2,
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
          fontSize: effectiveRadius * 0.85,
          color: fallbackColor,
        ),
      ),
    );

    if (effectiveUrl == null || effectiveUrl.isEmpty) {
      return fallback;
    }

    Widget imageWidget;
    if (effectiveUrl.startsWith('data:')) {
      try {
        final commaIdx = effectiveUrl.indexOf(',');
        final rawBase64 = commaIdx != -1 ? effectiveUrl.substring(commaIdx + 1) : effectiveUrl;
        final bytes = base64Decode(rawBase64);
        imageWidget = Image.memory(
          bytes,
          width: effectiveRadius * 2,
          height: effectiveRadius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    } else {
      imageWidget = Image.network(
        effectiveUrl,
        width: effectiveRadius * 2,
        height: effectiveRadius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    final circular = ClipOval(
      child: SizedBox(
        width: effectiveRadius * 2,
        height: effectiveRadius * 2,
        child: imageWidget,
      ),
    );

    if (border != null) {
      return Container(
        width: effectiveRadius * 2,
        height: effectiveRadius * 2,
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
