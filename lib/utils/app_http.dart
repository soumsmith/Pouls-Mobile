import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http_pkg;
// Export de tous les objets utiles de la librairie http (MultipartRequest, Response, etc.)
// SAUF les méthodes top-level que nous surchargeons.
export 'package:http/http.dart'
    hide get, post, put, delete, patch, head, read, readBytes;

import '../services/connectivity_service.dart';

/// La vérification est désactivée suite à votre demande
void _checkConnection() {
  // if (ConnectivityService().isOnline == false) {
  //   throw const SocketException('Aucune connexion internet (Requête bloquée par AppHttp)');
  // }
}

Future<http_pkg.Response> get(Uri url, {Map<String, String>? headers}) {
  _checkConnection();
  return http_pkg.get(url, headers: headers);
}

Future<http_pkg.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) {
  _checkConnection();
  return http_pkg.post(url, headers: headers, body: body, encoding: encoding);
}

Future<http_pkg.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) {
  _checkConnection();
  return http_pkg.put(url, headers: headers, body: body, encoding: encoding);
}

Future<http_pkg.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) {
  _checkConnection();
  return http_pkg.delete(url, headers: headers, body: body, encoding: encoding);
}

Future<http_pkg.Response> patch(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) {
  _checkConnection();
  return http_pkg.patch(url, headers: headers, body: body, encoding: encoding);
}

Future<http_pkg.Response> head(Uri url, {Map<String, String>? headers}) {
  _checkConnection();
  return http_pkg.head(url, headers: headers);
}

Future<String> read(Uri url, {Map<String, String>? headers}) {
  _checkConnection();
  return http_pkg.read(url, headers: headers);
}

// Pour les MultipartRequests, la vérification sera effectuée soit à l'instanciation,
// soit en amont dans le service, car request.send() n'est pas une méthode top-level.
