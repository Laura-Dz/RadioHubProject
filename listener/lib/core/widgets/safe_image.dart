import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../services/s3_storage_helper.dart';

/// A robust, web-safe image widget that prevents CanvasKit/WebGL texture crashes.
///
/// On Web:
/// - Base64 Data URIs: decodes in-memory.
/// - HTTP/HTTPS URLs: fetches bytes via HTTP. On success, renders [Image.memory].
///   On CORS failure or error, catches it safely in Dart and renders [fallback]
///   without ever touching WebGL's [makeTexture], preventing browser crashes.
///
/// On Mobile / Desktop:
/// - Uses [CachedNetworkImage] for full disk and memory caching.
class SafeImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? fallback;
  final BorderRadius? borderRadius;

  const SafeImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.fallback,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<SafeImage> createState() => _SafeImageState();
}

class _SafeImageState extends State<SafeImage> {
  static final Map<String, Uint8List> _webByteCache = {};
  static final Set<String> _webFailedUrls = {};

  Uint8List? _loadedBytes;
  bool _isLoading = false;
  bool _hasFailed = false;

  static bool _isValidRasterBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // GIF: 47 49 46
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;
    // WebP: RIFF (52 49 46 46) ... WEBP (57 45 42 50)
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return true;
    }
    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  @override
  void didUpdateWidget(covariant SafeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _checkAndLoad();
    }
  }

  void _checkAndLoad() {
    final rawUrl = widget.imageUrl?.trim() ?? '';
    if (rawUrl.isEmpty) {
      _loadedBytes = null;
      _isLoading = false;
      _hasFailed = false;
      return;
    }

    final clean = S3StorageHelper.ensureValidUrl(rawUrl);

    if (clean.toLowerCase().contains('.svg') || clean.toLowerCase().contains('image/svg')) {
      _loadedBytes = null;
      _isLoading = false;
      _hasFailed = true;
      return;
    }

    // Base64 Data URI
    if (clean.startsWith('data:image')) {
      try {
        final comma = clean.indexOf(',');
        final base64Data = comma != -1 ? clean.substring(comma + 1) : clean;
        final decoded = base64Decode(
          base64Data.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', ''),
        );
        if (_isValidRasterBytes(decoded)) {
          _loadedBytes = decoded;
          _hasFailed = false;
        } else {
          _loadedBytes = null;
          _hasFailed = true;
        }
        _isLoading = false;
      } catch (_) {
        _loadedBytes = null;
        _hasFailed = true;
        _isLoading = false;
      }
      return;
    }

    // Web HTTP/HTTPS fetch
    if (kIsWeb && (clean.startsWith('http://') || clean.startsWith('https://'))) {
      if (_webByteCache.containsKey(clean)) {
        _loadedBytes = _webByteCache[clean];
        _isLoading = false;
        _hasFailed = false;
      } else if (_webFailedUrls.contains(clean)) {
        _loadedBytes = null;
        _isLoading = false;
        _hasFailed = true;
      } else {
        _loadedBytes = null;
        _isLoading = true;
        _hasFailed = false;
        _fetchWebBytes(clean);
      }
    }
  }

  Future<void> _fetchWebBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty && _isValidRasterBytes(response.bodyBytes)) {
        _webByteCache[url] = response.bodyBytes;
        setState(() {
          _loadedBytes = response.bodyBytes;
          _isLoading = false;
          _hasFailed = false;
        });
        return;
      }
    } catch (_) {
      // CORS or network error caught safely in Dart
    }
    _webFailedUrls.add(url);
    if (mounted) {
      setState(() {
        _loadedBytes = null;
        _isLoading = false;
        _hasFailed = true;
      });
    }
  }

  Widget _buildDefaultFallback({bool isLoading = false}) {
    final w = widget.width;
    final h = widget.height;
    final iconSize = (w != null && h != null)
        ? (w < h ? w : h) * 0.38
        : 24.0;

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(isLoading ? 0.08 : 0.14),
            const Color(0xFF00D4AA).withOpacity(isLoading ? 0.04 : 0.08),
          ],
        ),
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: iconSize.clamp(14.0, 24.0),
                height: iconSize.clamp(14.0, 24.0),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6C63FF),
                ),
              )
            : Icon(
                Icons.radio,
                size: iconSize.clamp(16.0, 44.0),
                color: const Color(0xFF6C63FF).withOpacity(0.45),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final rawClean = widget.imageUrl?.trim() ?? '';
    final clean = S3StorageHelper.ensureValidUrl(rawClean);
    final defaultFallback = _buildDefaultFallback(isLoading: false);
    final defaultLoading = _buildDefaultFallback(isLoading: true);

    if (clean.isEmpty || _hasFailed) {
      imageWidget = widget.fallback ?? widget.placeholder ?? defaultFallback;
    } else if (_loadedBytes != null) {
      imageWidget = Image.memory(
        _loadedBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => widget.fallback ?? widget.placeholder ?? defaultFallback,
      );
    } else if (_isLoading) {
      imageWidget = widget.placeholder ?? widget.fallback ?? defaultLoading;
    } else if (!kIsWeb && (clean.startsWith('http://') || clean.startsWith('https://'))) {
      imageWidget = CachedNetworkImage(
        imageUrl: clean,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (_, __) => widget.placeholder ?? widget.fallback ?? defaultLoading,
        errorWidget: (_, __, ___) => widget.fallback ?? widget.placeholder ?? defaultFallback,
      );
    } else {
      imageWidget = widget.fallback ?? widget.placeholder ?? defaultFallback;
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: imageWidget,
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: imageWidget,
    );
  }
}
