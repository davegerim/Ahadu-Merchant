import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  static const String _validateUrl =
      'http://10.20.0.45:7035/api/v1/merchant-registrations/validate';

  Future<void> validateMerchant({
    required String merchantCode,
    required String merchantSecret,
  }) async {
    final payload = <String, dynamic>{
      'merchantCode': merchantCode,
      // API contract provided by backend uses this exact key spelling.
      'merchantSecerete': merchantSecret,
    };

    debugPrint('[AUTH][REQUEST] POST $_validateUrl');
    debugPrint('[AUTH][PAYLOAD] $payload');

    try {
      final response = await _dio.post<dynamic>(
        _validateUrl,
        data: payload,
      );

      debugPrint('[AUTH][RESPONSE][STATUS] ${response.statusCode}');
      debugPrint('[AUTH][RESPONSE][BODY] ${response.data}');
    } on DioException catch (e) {
      debugPrint('[AUTH][ERROR][TYPE] ${e.type}');
      debugPrint('[AUTH][ERROR][MESSAGE] ${e.message}');
      debugPrint('[AUTH][ERROR][STATUS] ${e.response?.statusCode}');
      debugPrint('[AUTH][ERROR][BODY] ${e.response?.data}');
      rethrow;
    }
  }
}
