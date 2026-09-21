import 'package:dio/dio.dart';
import 'package:taleb/core/networking/interceptors/auth_interceptor.dart';
import 'package:taleb/core/storage/secure_storage.dart';

import 'api_config.dart';

class DioConfig {
  static Dio create({required ApiConfig config
  ,    required SecureStorage secureStorage,
}) {
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
      ),
    );
    

    return dio;
  }
}