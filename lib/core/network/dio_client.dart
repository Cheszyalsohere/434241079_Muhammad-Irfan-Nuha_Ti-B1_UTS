/// Configured `Dio` instance for HTTP calls outside the Supabase SDK
/// (rarely needed — most data goes through the Supabase client). Kept
/// here for future integrations (e.g. third-party image enrichment).
library;

import 'package:dio/dio.dart';

abstract final class DioClient {
  static Dio create() {
    final Dio dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        headers: <String, String>{'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (Object msg) {
          // Intentionally routed through debugPrint at call site.
        },
      ),
    );

    return dio;
  }
}
