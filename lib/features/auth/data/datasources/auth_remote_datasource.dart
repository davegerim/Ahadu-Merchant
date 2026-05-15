import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/merchant_profile.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  static const String _validateUrl =
      'http://10.20.0.45:7035/api/v1/merchant-registrations/validate';

  Future<MerchantProfile> validateMerchant({
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
      return _parseMerchantProfile(response.data);
    } on DioException catch (e) {
      debugPrint('[AUTH][ERROR][TYPE] ${e.type}');
      debugPrint('[AUTH][ERROR][MESSAGE] ${e.message}');
      debugPrint('[AUTH][ERROR][STATUS] ${e.response?.statusCode}');
      debugPrint('[AUTH][ERROR][BODY] ${e.response?.data}');
      rethrow;
    }
  }

  MerchantProfile _parseMerchantProfile(dynamic data) {
    Map<String, dynamic>? map;
    if (data is Map<String, dynamic>) {
      map = data;
    } else if (data is Map) {
      map = Map<String, dynamic>.from(data);
    }
    if (map == null) return MerchantProfile.empty;

    var payload = map;
    for (final key in ['data', 'result', 'merchant', 'payload', 'item']) {
      final inner = payload[key];
      if (inner is Map<String, dynamic>) {
        payload = inner;
        break;
      }
      if (inner is Map) {
        payload = Map<String, dynamic>.from(inner);
        break;
      }
    }

    final fullName = _readString(payload, const [
          'fullName',
          'name',
          'merchantName',
          'businessName',
        ]) ??
        '';
    final accountNumber = _readString(payload, const [
          'accountNumber',
          'accountNo',
          'account',
        ]) ??
        '';
    final alertPhones = _readStringList(
      payload['alertPhones'] ??
          payload['alertPhoneNumbers'] ??
          payload['alertPhone'],
    );

    return MerchantProfile(
      fullName: fullName,
      accountNumber: accountNumber,
      alertPhones: alertPhones,
    );
  }

  String? _readString(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return null;
  }

  List<String> _readStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (v is String) {
      return v
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }
}
