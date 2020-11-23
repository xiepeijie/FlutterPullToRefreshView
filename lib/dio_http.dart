import 'package:dio/dio.dart';

class DioHttp {
  static Dio _dio;

  /// http request methods
  static const String GET = 'get';
  static const String POST = 'post';

  static const String _baseUrl = 'https://www.wanandroid.com';

  static Future<Dio> _getDio() async {
    if (_dio == null) {
      var options = BaseOptions(
          method: POST,
          connectTimeout: 20000,
          receiveTimeout: 20000,
          sendTimeout: 30000,
          baseUrl: _baseUrl,
          responseType: ResponseType.json,
          validateStatus: (status) {
            return true;
          },
          headers: {
            'Accept': 'application/json,*/*',
            'Content-Type': 'application/json'
          });
      _dio = Dio(options);
      _dio.interceptors.add(InterceptorsWrapper(
          onRequest: (RequestOptions options) {},
          onResponse: (data) {},
          onError: (error) {}));
    }
    return _dio;
  }

  static void request<T>(String apiPath,
      { String method = POST,
        parameters,
        Function(T) onSuccess,
        Function(int error, String errorMsg) onError,
        CancelToken cancelToken }) async {
    try {
      Dio dio = await _getDio();
      Response response;
      if (method == GET) {
        response = await dio.get(apiPath, queryParameters: parameters, cancelToken: cancelToken);
      } else {
        response = await dio.post(apiPath, cancelToken: cancelToken);
      }
      var resData = response.data;
      var code = resData['errorCode'];
      var msg = resData['errorMsg'];
      print('response code <- $code');
      if (code == 0 || code == 200) {
        var data = resData['data'];
        onSuccess(data);
      } else {
        onError(code, msg);
      }
    } catch (e) {
      print('http error \n$e');
      onError(-100, e.toString());
    }
  }

}
