import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';

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
        final cleanBase64 = rawBase64.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);
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
      final validUrl = StorageService.ensureValidUrl(trimmed);
      imageWidget = Image.network(
        validUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return fallback;
        },
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
