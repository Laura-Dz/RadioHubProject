import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Synchronizes with Cameroon (WAT, UTC+1) time so that session scheduling,
/// live countdowns, and extra-time calculations are exact regardless of device clock settings.
class NetworkTimeService {
  static final NetworkTimeService _i = NetworkTimeService._();
  factory NetworkTimeService() => _i;
  NetworkTimeService._();

  Duration _drift = Duration.zero;
  bool _synced = false;
  DateTime _lastSync = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isSynced => _synced;
  Duration get drift => _drift;

  /// Server-synced time in Cameroon (WAT, UTC+1).
  DateTime now() => DateTime.now().add(_drift);

  Future<void> sync() async {
    if (_synced &&
        DateTime.now().difference(_lastSync) < const Duration(minutes: 15)) {
      return;
    }

    // Try 1: timeapi.io (Africa/Douala, CORS: *)
    try {
      final r = await http
          .get(Uri.parse('https://timeapi.io/api/time/current/zone?timeZone=Africa/Douala'))
          .timeout(const Duration(milliseconds: 2500));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final dtStr = data['dateTime'] as String?;
        if (dtStr != null) {
          final parsed = DateTime.parse(dtStr);
          final cameroonLocal = DateTime(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
          );
          _drift = cameroonLocal.difference(DateTime.now());
          _synced = true;
          _lastSync = DateTime.now();
          debugPrint(
              'Host NetworkTimeService: Synced via timeapi.io! Cameroon time is ${now()} (drift: ${_drift.inMinutes}m)');
          return;
        }
      }
    } catch (_) {}

    // Try 2: Cloudflare trace (CORS: *, ts=UTC epoch)
    try {
      final r = await http
          .get(Uri.parse('https://cloudflare.com/cdn-cgi/trace'))
          .timeout(const Duration(milliseconds: 2500));
      if (r.statusCode == 200) {
        for (final line in r.body.split('\n')) {
          if (line.startsWith('ts=')) {
            final tsSec = double.tryParse(line.substring(3).trim());
            if (tsSec != null) {
              final utcServer = DateTime.fromMillisecondsSinceEpoch(
                (tsSec * 1000).round(),
                isUtc: true,
              );
              // Cameroon is WAT (UTC+1) year-round
              final cameroonUtc1 = utcServer.add(const Duration(hours: 1));
              final cameroonLocal = DateTime(
                cameroonUtc1.year,
                cameroonUtc1.month,
                cameroonUtc1.day,
                cameroonUtc1.hour,
                cameroonUtc1.minute,
                cameroonUtc1.second,
              );
              _drift = cameroonLocal.difference(DateTime.now());
              _synced = true;
              _lastSync = DateTime.now();
              debugPrint(
                  'Host NetworkTimeService: Synced via cloudflare! Cameroon time is ${now()} (drift: ${_drift.inMinutes}m)');
              return;
            }
          }
        }
      }
    } catch (_) {}

    // Try 3: worldtimeapi.org (fallback)
    try {
      final r = await http
          .get(Uri.parse('https://worldtimeapi.org/api/timezone/Africa/Douala'))
          .timeout(const Duration(milliseconds: 2500));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final unixSeconds = data['unixtime'] as int?;
        if (unixSeconds != null) {
          final utcServer = DateTime.fromMillisecondsSinceEpoch(
            unixSeconds * 1000,
            isUtc: true,
          );
          final cameroonUtc1 = utcServer.add(const Duration(hours: 1));
          final cameroonLocal = DateTime(
            cameroonUtc1.year,
            cameroonUtc1.month,
            cameroonUtc1.day,
            cameroonUtc1.hour,
            cameroonUtc1.minute,
            cameroonUtc1.second,
          );
          _drift = cameroonLocal.difference(DateTime.now());
          _synced = true;
          _lastSync = DateTime.now();
          debugPrint(
              'Host NetworkTimeService: Synced via worldtimeapi! Cameroon time is ${now()} (drift: ${_drift.inMinutes}m)');
          return;
        }
      }
    } catch (_) {}
  }
}
