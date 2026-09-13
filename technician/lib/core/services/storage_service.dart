import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StorageService {
  // iDrive e2 S3 Configuration
  static const String endpoint = 'https://radiohub.s3.eu-central-1.idrivee2.com';
  static const String host = 'radiohub.s3.eu-central-1.idrivee2.com';
  static const String region = 'eu-central-1';
  static const String bucket = 'radiohub';
  static const String accessKey = '4UOvofQuvZpXifvKCqDb';
  static const String secretKey = 'dTObjCGXfPg8ku0eL8zQYewi7z8QBfGWKv5gdFFK';

  static const int maxImageBytes = 5 * 1024 * 1024; // 5 MB

  StorageService();

  /// Uploads program cover image to radios/{radioId}/programs/{programId}/{timestamp}.{ext}
  Future<String> uploadProgramImage({
    required String radioId,
    required String programId,
    required Uint8List bytes,
    required String extension,
    void Function(double)? onProgress,
  }) async {
    if (bytes.length > maxImageBytes) {
      throw Exception('Image is too large (max 5 MB).');
    }
    final ext = extension.toLowerCase().replaceAll('.', '');
    final path =
        'radios/$radioId/programs/$programId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final mimeType = _getMimeType(ext);

    return uploadBytes(
      bytes: bytes,
      path: path,
      contentType: mimeType,
      onProgress: onProgress,
    );
  }

  /// Uploads raw bytes to the iDrive e2 S3 bucket using AWS SigV4 authorization.
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String path,
    required String contentType,
    Function(double progress)? onProgress,
  }) async {
    try {
      final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
      final now = DateTime.now().toUtc();
      final amzDate = _formatAmzDate(now);
      final dateStamp = _formatDateStamp(now);

      final payloadHash = sha256.convert(bytes).toString();
      final canonicalUri = '/$normalizedPath';
      const canonicalQuerystring = '';
      final canonicalHeaders =
          'content-type:$contentType\nhost:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$amzDate\n';
      const signedHeaders = 'content-type;host;x-amz-content-sha256;x-amz-date';

      final canonicalRequest =
          'PUT\n$canonicalUri\n$canonicalQuerystring\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

      const algorithm = 'AWS4-HMAC-SHA256';
      final credentialScope = '$dateStamp/$region/s3/aws4_request';
      final canonicalRequestHash =
          sha256.convert(utf8.encode(canonicalRequest)).toString();
      final stringToSign =
          '$algorithm\n$amzDate\n$credentialScope\n$canonicalRequestHash';

      final signingKey = _getSignatureKey(secretKey, dateStamp, region, 's3');
      final signature =
          Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();
      final authorization =
          '$algorithm Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

      final url = Uri.parse('$endpoint/$normalizedPath');
      final headers = {
        'Host': host,
        'Content-Type': contentType,
        'x-amz-date': amzDate,
        'x-amz-content-sha256': payloadHash,
        'Authorization': authorization,
      };

      onProgress?.call(0.3);

      final response = await http
          .put(
            url,
            headers: headers,
            body: bytes,
          )
          .timeout(const Duration(seconds: 45));

      onProgress?.call(1.0);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('iDrive e2 S3 upload successful: $normalizedPath');
        // Return 7-day presigned URL so it is guaranteed accessible immediately
        return generatePresignedGetUrl(
            path: normalizedPath, expiresInSeconds: 604800);
      } else {
        debugPrint(
            'iDrive e2 S3 upload failed [${response.statusCode}]: ${response.body}');
        throw Exception(
            'S3 upload error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('S3 upload general error: $e');
      rethrow;
    }
  }

  /// Generates a signed GET URL with SigV4 query parameters.
  static String generatePresignedGetUrl({
    required String path,
    int expiresInSeconds = 604800, // 7 days (max allowed by AWS S3 SigV4)
  }) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = _formatDateStamp(now);
    final scope = '$dateStamp/$region/s3/aws4_request';

    final qs = <String, String>{
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': '$accessKey/$scope',
      'X-Amz-Date': amzDate,
      'X-Amz-Expires': expiresInSeconds.toString(),
      'X-Amz-SignedHeaders': 'host',
    };

    final sortedKeys = qs.keys.toList()..sort();
    final sortedQs = sortedKeys
        .map((k) =>
            '${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(qs[k]!)}')
        .join('&');

    final canonicalRequest =
        'GET\n/$normalizedPath\n$sortedQs\nhost:$host\n\nhost\nUNSIGNED-PAYLOAD';
    final canonicalHash =
        sha256.convert(utf8.encode(canonicalRequest)).toString();
    final stringToSign = 'AWS4-HMAC-SHA256\n$amzDate\n$scope\n$canonicalHash';

    final signingKey = _getSignatureKey(secretKey, dateStamp, region, 's3');
    final signature =
        Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

    return '$endpoint/$normalizedPath?$sortedQs&X-Amz-Signature=$signature';
  }

  /// Returns clean direct URL (works when bucket public access is enabled)
  static String getDirectPublicUrl(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return '$endpoint/$normalizedPath';
  }

  /// Ensures a given S3 URL is valid and signed.
  /// If the URL is from our iDrive e2 bucket, it extracts the object key
  /// and generates a fresh 7-day pre-signed GET URL so images and audio never expire.
  static String ensureValidUrl(String url) {
    if (url.isEmpty ||
        (!url.contains(host) && !url.contains('s3.eu-central-1.idrivee2.com'))) {
      return url;
    }
    try {
      String path = url;
      if (path.contains('?')) {
        path = path.split('?').first;
      }
      final uri = Uri.parse(path);
      var key = uri.path;
      if (key.startsWith('/$bucket/')) {
        key = key.substring(bucket.length + 2);
      } else if (key.startsWith('/')) {
        key = key.substring(1);
      }
      return generatePresignedGetUrl(path: key, expiresInSeconds: 604800);
    } catch (_) {
      return url;
    }
  }

  /// Deletes an asset from S3 given its path or URL
  Future<void> deleteOldFile(String urlOrPath) async {
    try {
      if (urlOrPath.isEmpty) return;

      String key = urlOrPath;
      if (key.startsWith('http://') || key.startsWith('https://')) {
        if (!key.contains(host) &&
            !key.contains('s3.eu-central-1.idrivee2.com')) {
          return;
        }
        if (key.contains('?')) {
          key = key.split('?').first;
        }
        final uri = Uri.parse(key);
        key = uri.path;
        if (key.startsWith('/$bucket/')) {
          key = key.substring(bucket.length + 2);
        } else if (key.startsWith('/')) {
          key = key.substring(1);
        }
      }

      final normalizedKey = key.startsWith('/') ? key.substring(1) : key;
      final now = DateTime.now().toUtc();
      final amzDate = _formatAmzDate(now);
      final dateStamp = _formatDateStamp(now);
      final payloadHash = sha256.convert([]).toString();

      final canonicalUri = '/$normalizedKey';
      final canonicalHeaders =
          'host:$host\nx-amz-content-sha256:$payloadHash\nx-amz-date:$amzDate\n';
      const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

      final canonicalRequest =
          'DELETE\n$canonicalUri\n\n$canonicalHeaders\n$signedHeaders\n$payloadHash';
      const algorithm = 'AWS4-HMAC-SHA256';
      final credentialScope = '$dateStamp/$region/s3/aws4_request';
      final stringToSign =
          '$algorithm\n$amzDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

      final signingKey = _getSignatureKey(secretKey, dateStamp, region, 's3');
      final signature =
          Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();
      final authorization =
          '$algorithm Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

      final deleteUrl = Uri.parse('$endpoint/$normalizedKey');
      await http.delete(
        deleteUrl,
        headers: {
          'Host': host,
          'x-amz-date': amzDate,
          'x-amz-content-sha256': payloadHash,
          'Authorization': authorization,
        },
      );
      debugPrint('Deleted old file from S3: $normalizedKey');
    } catch (e) {
      debugPrint('Failed to delete old file from S3: $e');
    }
  }

  static List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  static List<int> _getSignatureKey(
      String key, String dateStamp, String regionName, String serviceName) {
    final kDate = _hmacSha256(utf8.encode('AWS4$key'), dateStamp);
    final kRegion = _hmacSha256(kDate, regionName);
    final kService = _hmacSha256(kRegion, serviceName);
    return _hmacSha256(kService, 'aws4_request');
  }

  static String _formatAmzDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}T'
        '${dt.hour.toString().padLeft(2, '0')}'
        '${dt.minute.toString().padLeft(2, '0')}'
        '${dt.second.toString().padLeft(2, '0')}Z';
  }

  static String _formatDateStamp(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}'
        '${dt.month.toString().padLeft(2, '0')}'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  static String _getMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'png':
        return 'image/png';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}
