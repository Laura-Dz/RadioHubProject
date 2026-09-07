import 'package:dio/dio.dart';
import 'package:radiohub_listener/models/listener_models.dart';

class ListenerRepository {
  static const String _baseUrl = 'http://YOUR_API_HOST/api/v1/listener';
  final Dio _dio;

  ListenerRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Accept': 'application/json',
              },
            ));

  Future<LiveStream> getActiveLiveStream() async {
    try {
      final response = await _dio.get('/live-stream/');
      return LiveStream.fromJson(response.data['live_stream'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to load live stream: $e');
    }
  }

  Future<List<Announcement>> getActiveAnnouncements() async {
    try {
      final response = await _dio.get('/announcements/');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((item) => Announcement.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to load announcements: $e');
    }
  }

  Future<List<Show>> getShowSchedule({String? filter}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (filter != null) {
        queryParams['filter'] = filter;
      }

      final response = await _dio.get('/shows/', queryParameters: queryParams);
      final List<dynamic> data = response.data['results'] as List<dynamic>? ?? response.data as List<dynamic>;
      return data.map((item) => Show.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to load show schedule: $e');
    }
  }

  Future<List<Episode>> getEpisodes({int? showId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (showId != null) {
        queryParams['show'] = showId.toString();
      }

      final response = await _dio.get('/episodes/', queryParameters: queryParams);
      final List<dynamic> data = response.data['results'] as List<dynamic>? ?? response.data as List<dynamic>;
      return data.map((item) => Episode.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Failed to load episodes: $e');
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Request failed';
      if (data is Map<String, dynamic>) {
        message = data['detail'] as String? ?? data.toString();
      } else {
        message = data?.toString() ?? 'HTTP $statusCode';
      }
      return Exception('Error $statusCode: $message');
    }
    return Exception('Network error: ${e.message}');
  }
}
