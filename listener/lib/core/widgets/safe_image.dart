import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

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
    final clean = widget.imageUrl?.trim() ?? '';
    if (clean.isEmpty) {
      _loadedBytes = null;
      _isLoading = false;
      _hasFailed = false;
      return;
    }

    // Base64 Data URI
    if (clean.startsWith('data:image')) {
      try {
        final comma = clean.indexOf(',');
        final base64Data = comma != -1 ? clean.substring(comma + 1) : clean;
        _loadedBytes = base64Decode(
          base64Data.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', ''),
        );
        _hasFailed = false;
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
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
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

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final clean = widget.imageUrl?.trim() ?? '';

    if (clean.isEmpty || _hasFailed) {
      imageWidget = widget.fallback ?? widget.placeholder ?? const SizedBox.shrink();
    } else if (_loadedBytes != null) {
      imageWidget = Image.memory(
        _loadedBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => widget.fallback ?? widget.placeholder ?? const SizedBox.shrink(),
      );
    } else if (_isLoading) {
      imageWidget = widget.placeholder ?? widget.fallback ?? const SizedBox.shrink();
    } else if (!kIsWeb && (clean.startsWith('http://') || clean.startsWith('https://'))) {
      imageWidget = CachedNetworkImage(
        imageUrl: clean,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (_, __) => widget.placeholder ?? widget.fallback ?? const SizedBox.shrink(),
        errorWidget: (_, __, ___) => widget.fallback ?? widget.placeholder ?? const SizedBox.shrink(),
      );
    } else {
      imageWidget = widget.fallback ?? widget.placeholder ?? const SizedBox.shrink();
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
