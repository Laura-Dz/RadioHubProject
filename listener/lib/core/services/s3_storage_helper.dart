import 'dart:convert';
import 'package:crypto/crypto.dart';

class S3StorageHelper {
  static const String endpoint = 'https://radiohub.s3.eu-central-1.idrivee2.com';
  static const String host = 'radiohub.s3.eu-central-1.idrivee2.com';
  static const String region = 'eu-central-1';
  static const String bucket = 'radiohub';
  static const String accessKey = '4UOvofQuvZpXifvKCqDb';
  static const String secretKey = 'dTObjCGXfPg8ku0eL8zQYewi7z8QBfGWKv5gdFFK';

  /// Ensures that any S3/iDrive URL (or relative key) is signed with a fresh valid SigV4 signature.
  static String ensureValidUrl(String? rawUrl) {
    if (rawUrl == null) return '';
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    // If it's a relative path in our bucket
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      if (trimmed.startsWith('radios/') ||
          trimmed.startsWith('/radios/') ||
          trimmed.contains('/programs/') ||
          trimmed.contains('/hosts/') ||
          trimmed.contains('/media/') ||
          trimmed.contains('/podcasts/') ||
          trimmed.contains('/videos/') ||
          trimmed.contains('/audios/')) {
        return generatePresignedGetUrl(
          path: trimmed.startsWith('/') ? trimmed.substring(1) : trimmed,
          expiresInSeconds: 604800,
        );
      }
      return trimmed;
    }

    if (!trimmed.contains(host) && !trimmed.contains('s3.eu-central-1.idrivee2.com')) {
      return trimmed;
    }

    try {
      String path = trimmed;
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
      return trimmed;
    }
  }

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
        .map((k) => '${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(qs[k]!)}')
        .join('&');

    final canonicalRequest = 'GET\n/$normalizedPath\n$sortedQs\nhost:$host\n\nhost\nUNSIGNED-PAYLOAD';
    final canonicalHash = sha256.convert(utf8.encode(canonicalRequest)).toString();
    final stringToSign = 'AWS4-HMAC-SHA256\n$amzDate\n$scope\n$canonicalHash';

    final signingKey = _getSignatureKey(secretKey, dateStamp, region, 's3');
    final signature = Hmac(sha256, signingKey).convert(utf8.encode(stringToSign)).toString();

    return '$endpoint/$normalizedPath?$sortedQs&X-Amz-Signature=$signature';
  }

  static List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  static List<int> _getSignatureKey(String key, String dateStamp, String regionName, String serviceName) {
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
}
