import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';

class AppProgramImage extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const AppProgramImage({
    Key? key,
    required this.imageUrl,
    this.name,
    this.width = 52,
    this.height = 52,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  Widget _buildFallback() {
    final initial = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()[0].toUpperCase()
        : null;

    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withOpacity(0.12),
      child: Center(
        child: initial != null
            ? Text(
                initial,
                style: TextStyle(
                  fontSize: width * 0.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                Icons.tv_rounded,
                color: AppColors.primary,
                size: width * 0.48,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildFallback(),
      );
    }

    final trimmed = imageUrl!.trim();

    // 1. Base64 Data URI
    if (trimmed.startsWith('data:image') || trimmed.contains(';base64,')) {
      try {
        final commaIdx = trimmed.indexOf(',');
        final rawBase64 = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
        final cleanBase64 = rawBase64.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildFallback(),
          ),
        );
      } catch (_) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: _buildFallback(),
        );
      }
    }

    // 2. Ensure S3 URL signature is fresh (or path is converted to signed URL)
    final validUrl = StorageService.ensureValidUrl(trimmed);

    // 3. Render using Image.network (Native browser <img> tag on Flutter Web avoids CORS blocks)
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        validUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.primary.withOpacity(0.08),
            child: Center(
              child: SizedBox(
                width: width * 0.35,
                height: width * 0.35,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('AppProgramImage error loading [$validUrl]: $error');
          return _buildFallback();
        },
      ),
    );
  }
}
