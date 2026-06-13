import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final CookieJar cookieJar = CookieJar();
  static const String _tokenKey = 'accessToken';

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(_authInterceptor());
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            final refreshDio = Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
            ));
            refreshDio.interceptors.add(CookieManager(cookieJar));
            final refreshResponse = await refreshDio.post(
              ApiConfig.refreshToken,
              options: Options(headers: {'Content-Type': 'application/json'}),
            );

            if (refreshResponse.data['accessToken'] != null) {
              final newToken = refreshResponse.data['accessToken'];
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_tokenKey, newToken);

              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            }
          } catch (_) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_tokenKey);
            await prefs.remove('auth_user');
          }
        }
        handler.next(error);
      },
    );
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('auth_user');
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return dio.patch(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) {
    return dio.delete(path, data: data);
  }

  static String getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối quá thời gian. Vui lòng thử lại.';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến máy chủ.';
      default:
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          return e.response!.data['message'];
        }
        return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
  }
}
