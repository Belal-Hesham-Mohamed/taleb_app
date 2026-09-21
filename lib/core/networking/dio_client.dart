import 'package:dio/dio.dart';

import 'api_config.dart';

class DioConfig {
  static Dio create(ApiConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
      ),
    );

    return dio;
  }
}