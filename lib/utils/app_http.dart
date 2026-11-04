import 'dart:convert';
import 'package:http/http.dart' as http_pkg;
// Export de tous les objets utiles de la librairie http (MultipartRequest, Response, etc.)
// SAUF les méthodes top-level que nous surchargeons.
export 'package:http/http.dart'
    hide get, post, put, delete, patch, head, read, readBytes;

import '../services/app_log_service.dart';

void _checkConnection() {
  // Optionnellement activable
}

Future<http_pkg.Response> get(Uri url, {Map<String, String>? headers}) async {
  _checkConnection();
  final stopwatch = Stopwatch()..start();
  try {
    final response = await http_pkg.get(url, headers: headers);
    stopwatch.stop();
    AppLogService.logApi(
      method: 'GET',
      url: url.toString(),
      statusCode: response.statusCode,
      durationMs: stopwatch.elapsedMilliseconds,
    );
    return response;
  } catch (e) {
    stopwatch.stop();
    AppLogService.logApi(
      method: 'GET',
      url: url.toString(),
      durationMs: stopwatch.elapsedMilliseconds,
      error: e.toString(),
    );
    rethrow;
  }
}

Future<http_pkg.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  _checkConnection();
  final stopwatch = Stopwatch()..start();
  try {
    final response = await http_pkg.post(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
    stopwatch.stop();
    AppLogService.logApi(
      method: 'POST',
      url: url.toString(),
      statusCode: response.statusCode,
      durationMs: stopwatch.elapsedMilliseconds,
    );
    return response;
  } catch (e) {
    stopwatch.stop();
    AppLogService.logApi(
      method: 'POST',
      url: url.toString(),
      durationMs: stopwatch.elapsedMilliseconds,
      error: e.toString(),
    );
    rethrow;
  }
}

Future<http_pkg.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  _checkConnection();
  final stopwatch = Stopwatch()..start();
  try {
    final response = await http_pkg.put(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
    stopwatch.stop();
    AppLogService.logApi(
      method: 'PUT',
      url: url.toString(),
      statusCode: response.statusCode,
      durationMs: stopwatch.elapsedMilliseconds,
    );
    return response;
  } catch (e) {
    stopwatch.stop();
    AppLogService.logApi(
      method: 'PUT',
      url: url.toString(),
      durationMs: stopwatch.elapsedMilliseconds,
      error: e.toString(),
    );
    rethrow;
  }
}

Future<http_pkg.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  _checkConnection();
  final stopwatch = Stopwatch()..start();
  try {
    final response = await http_pkg.delete(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
    stopwatch.stop();
    AppLogService.logApi(
      method: 'DELETE',
      url: url.toString(),
      statusCode: response.statusCode,
      durationMs: stopwatch.elapsedMilliseconds,
    );
    return response;
  } catch (e) {
    stopwatch.stop();
    AppLogService.logApi(
      method: 'DELETE',
      url: url.toString(),
      durationMs: stopwatch.elapsedMilliseconds,
      error: e.toString(),
    );
    rethrow;
  }
}

Future<http_pkg.Response> patch(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async {
  _checkConnection();
  final stopwatch = Stopwatch()..start();
  try {
    final response = await http_pkg.patch(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
    stopwatch.stop();
    AppLogService.logApi(
      method: 'PATCH',
      url: url.toString(),
      statusCode: response.statusCode,
      durationMs: stopwatch.elapsedMilliseconds,
    );
    return response;
  } catch (e) {
    stopwatch.stop();
    AppLogService.logApi(
      method: 'PATCH',
      url: url.toString(),
      durationMs: stopwatch.elapsedMilliseconds,
      error: e.toString(),
    );
    rethrow;
  }
}

Future<http_pkg.Response> head(Uri url, {Map<String, String>? headers}) async {
  _checkConnection();
  final stopwatch = Stopwatch()..start();
  try {
    final response = await http_pkg.head(url, headers: headers);
    stopwatch.stop();
    AppLogService.logApi(
      method: 'HEAD',
      url: url.toString(),
      statusCode: response.statusCode,
      durationMs: stopwatch.elapsedMilliseconds,
    );
    return response;
  } catch (e) {
    stopwatch.stop();
    AppLogService.logApi(
      method: 'HEAD',
      url: url.toString(),
      durationMs: stopwatch.elapsedMilliseconds,
      error: e.toString(),
    );
    rethrow;
  }
}

Future<String> read(Uri url, {Map<String, String>? headers}) async {
  _checkConnection();
  final stopwatch = Stopwatch()..start();
  try {
    final response = await http_pkg.read(url, headers: headers);
    stopwatch.stop();
    AppLogService.logApi(
      method: 'READ',
      url: url.toString(),
      statusCode: 200,
      durationMs: stopwatch.elapsedMilliseconds,
    );
    return response;
  } catch (e) {
    stopwatch.stop();
    AppLogService.logApi(
      method: 'READ',
      url: url.toString(),
      durationMs: stopwatch.elapsedMilliseconds,
      error: e.toString(),
    );
    rethrow;
  }
}
