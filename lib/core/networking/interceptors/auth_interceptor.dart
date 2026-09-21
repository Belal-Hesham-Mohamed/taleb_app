import 'package:dio/dio.dart';
import 'package:taleb/core/storage/secure_storage.dart';


class AuthInterceptor extends Interceptor {
  final SecureStorage secureStorage;

  AuthInterceptor({
    required this.secureStorage,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await secureStorage.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }
}