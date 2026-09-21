import 'package:dio/dio.dart';

import 'api_config.dart';
import 'interceptors/auth_interceptor.dart';
import '../storage/secure_storage/secure_storage.dart';

class DioConfig {
  static Dio create({
    required ApiConfig config,
    required SecureStorage secureStorage,
  }) {
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
      ),
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
      ),
    );

    dio.interceptors.add(
      AuthInterceptor(
        secureStorage: secureStorage,
        dio: dio,
        refreshDio: refreshDio,
      ),
    );

    return dio;
  }
}