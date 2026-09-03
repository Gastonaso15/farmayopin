import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // En Android emulator: 'http://10.0.2.2:8080'
  // En Web / Linux / macOS / iOS Simulator: 'http://localhost:8080'
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String logoutEndpoint = '/api/auth/logout';
}
