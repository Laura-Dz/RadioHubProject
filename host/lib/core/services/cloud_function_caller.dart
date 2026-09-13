import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class CloudFunctionCaller {
  static const String projectId = "radiohub12";
  static const String region = "europe-west1";
  static const String baseUrl = "https://$region-$projectId.cloudfunctions.net";

  /// Calls a Firebase HTTPS Callable Cloud Function directly over HTTP.
  /// This avoids dart2js Int64 serialization issues on Flutter Web.
  static Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;

    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    final uri = Uri.parse("$baseUrl/$functionName");
    http.Response response;
    try {
      response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({"data": data}),
      );
    } catch (e) {
      debugPrint("CloudFunctionCaller network error: $e");
      throw Exception("Network error connecting to $functionName: $e");
    }

    if (response.statusCode == 404) {
      throw Exception(
        "Cloud Function \"$functionName\" not found (404). "
        "Please deploy functions with \"firebase deploy --only functions\".",
      );
    }

    if (response.statusCode >= 400) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey("error")) {
          final error = body["error"];
          final message = error is Map
              ? (error["message"] ?? error["status"])
              : error.toString();
          throw Exception(message);
        }
      } catch (_) {}
      throw Exception("Server error (${response.statusCode}): ${response.body}");
    }

    final body = jsonDecode(response.body);
    if (body is Map && body.containsKey("result")) {
      final res = body["result"];
      if (res is Map<String, dynamic>) return res;
      if (res is Map) return Map<String, dynamic>.from(res);
      return {"result": res};
    }
    return body is Map ? Map<String, dynamic>.from(body) : {};
  }
}
