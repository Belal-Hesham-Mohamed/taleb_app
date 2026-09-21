import 'package:dio/dio.dart';
import 'package:taleb/core/storage/secure_storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage secureStorage;
  final Dio dio;
  final Dio refreshDio;

  AuthInterceptor({
    required this.secureStorage,
    required this.dio,
    required this.refreshDio,
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

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Prevent the same request from entering the refresh flow more than once.
    if (err.requestOptions.extra['authRetry'] == true) {
      return handler.next(err);
    }

    // Only handle 401.
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await secureStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      await secureStorage.clearTokens();
      return handler.next(err);
    }

    try {
      // Use a separate Dio instance for refresh.
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );

      final newAccessToken =
          response.data['accessToken'] as String;

      final newRefreshToken =
          response.data['refreshToken'] as String;

      await secureStorage.saveAccessToken(newAccessToken);
      await secureStorage.saveRefreshToken(newRefreshToken);

      // Original failed request.
      final requestOptions = err.requestOptions;

      // Prevent infinite refresh loop.
      requestOptions.extra['authRetry'] = true;

      // Use new access token.
      requestOptions.headers['Authorization'] =
          'Bearer $newAccessToken';

      // Retry original request.
      final retryResponse = await dio.fetch(requestOptions);

      return handler.resolve(retryResponse);
    } on DioException {
      await secureStorage.clearTokens();

      return handler.next(err);
    }
  }
}