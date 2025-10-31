import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class LastRouteService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _lastRouteKey = 'last_route_key';

  static Future<void> save(String route) async {
    if (kIsWeb) {
      html.window.localStorage[_lastRouteKey] = route;
    } else {
      await _storage.write(key: _lastRouteKey, value: route);
    }
  }

  static Future<String?> load() async {
    if (kIsWeb) {
      return html.window.localStorage[_lastRouteKey];
    } else {
      return await _storage.read(key: _lastRouteKey);
    }
  }

  static Future<void> clear() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_lastRouteKey);
    } else {
      await _storage.delete(key: _lastRouteKey);
    }
  }
}


