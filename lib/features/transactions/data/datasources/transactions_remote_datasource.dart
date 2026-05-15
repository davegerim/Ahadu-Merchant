import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/transaction.dart';
import '../../pdf/transaction_receipt_pdf.dart';

class TransactionsRemoteDataSource {
  TransactionsRemoteDataSource(this._dio);

  final Dio _dio;

  static const String _transactionsUrl =
      'http://10.20.0.45:7035/api/v1/merchant-registrations/transactions';

  static const String _receiptHost = '10.20.0.45';
  static const int _receiptPort = 7035;

  /// Receipt GET must not inherit global Dio `Content-Type: application/json` (some servers error on GET).
  static final Dio _receiptDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );

  Future<List<Transaction>> fetchTransactions({
    required String merchantCode,
    required String merchantSecret,
    required String fromDate,
    required String toDate,
  }) async {
    final payload = <String, dynamic>{
      'merchantCode': merchantCode,
      'merchantSecret': merchantSecret,
      'fromDate': fromDate,
      'toDate': toDate,
    };

    debugPrint('[TXNS][REQUEST] POST $_transactionsUrl');
    debugPrint('[TXNS][PAYLOAD] $payload');

    try {
      final response = await _dio.post<dynamic>(
        _transactionsUrl,
        data: payload,
      );

      debugPrint('[TXNS][RESPONSE][STATUS] ${response.statusCode}');
      debugPrint('[TXNS][RESPONSE][BODY] ${response.data}');

      return _parseTransactionsResponse(response.data);
    } on DioException catch (e) {
      debugPrint('[TXNS][ERROR][TYPE] ${e.type}');
      debugPrint('[TXNS][ERROR][MESSAGE] ${e.message}');
      debugPrint('[TXNS][ERROR][STATUS] ${e.response?.statusCode}');
      debugPrint('[TXNS][ERROR][BODY] ${e.response?.data}');
      rethrow;
    }
  }

  /// `GET /api/v1/receipt/{reference}` — returns PDF bytes, or JSON that we map to the receipt layout.
  Future<Uint8List> fetchReceiptDocument(
    String receiptReference, {
    String? merchantCode,
    String? merchantSecret,
  }) async {
    final ref = receiptReference.trim();
    if (ref.isEmpty) {
      throw ArgumentError('Receipt reference is empty');
    }

    final query = <String, String>{};
    final code = merchantCode?.trim();
    final secret = merchantSecret?.trim();
    if (code != null && code.isNotEmpty) {
      query['merchantCode'] = code;
    }
    if (secret != null && secret.isNotEmpty) {
      query['merchantSecret'] = secret;
    }

    final uri = Uri(
      scheme: 'http',
      host: _receiptHost,
      port: _receiptPort,
      pathSegments: ['api', 'v1', 'receipt', ref],
      queryParameters: query.isEmpty ? null : query,
    );

    debugPrint('[RECEIPT][GET] $uri');

    final response = await _receiptDio.get<List<int>>(
      uri.toString(),
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status >= 200 && status < 300,
        headers: <String, String>{
          'Accept': 'application/pdf, application/json, */*',
        },
      ),
    );

    final bytes = Uint8List.fromList(response.data ?? <int>[]);
    final ct = _headerContentType(response);

    if (_isPdfBytes(bytes) ||
        ct.contains('application/pdf') ||
        (ct.contains('application/octet-stream') && _isPdfBytes(bytes))) {
      return bytes;
    }

    Map<String, dynamic>? map;
    try {
      final text = utf8.decode(bytes);
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        map = decoded;
      } else if (decoded is Map) {
        map = Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      debugPrint('[RECEIPT][JSON][PARSE][ERROR] $e');
    }

    if (map != null) {
      var payload = map;
      for (final key in ['data', 'receipt', 'payload', 'result', 'item']) {
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
      final tx = _tryMapToTransaction(payload);
      if (tx != null) {
        return buildTransactionReceiptPdf(tx);
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message:
          'Receipt could not be used: expected PDF or known transaction JSON (content-type: $ct, ${bytes.length} bytes)',
      response: response,
    );
  }

  String _headerContentType(Response<dynamic> response) {
    final raw = response.headers.value('content-type');
    if (raw == null || raw.isEmpty) return '';
    return raw.toLowerCase();
  }

  bool _isPdfBytes(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  List<Transaction> _parseTransactionsResponse(dynamic data) {
    final rawList = _extractTransactionList(data);
    if (rawList == null) return [];

    final out = <Transaction>[];
    for (var i = 0; i < rawList.length; i++) {
      final item = rawList[i];
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final tx = _tryMapToTransaction(m);
      if (tx != null) out.add(tx);
    }
    return out;
  }

  List<dynamic>? _extractTransactionList(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    for (final key in ['data', 'transactions', 'items', 'results', 'content']) {
      final v = map[key];
      if (v is List<dynamic>) return v;
    }
    return null;
  }

  Transaction? _tryMapToTransaction(Map<String, dynamic> m) {
    try {
      final id = _readString(m, const [
        'externalReferenceNo',
        'id',
        'transactionId',
        'reference',
        'trxId',
        'txnId',
      ]);
      if (id == null) return null;

      final title = _readString(m, const [
            'narrativeDetail1',
            'narrativeDetail2',
            'narrativeDetail3',
            'title',
            'description',
            'narration',
            'remark',
            'merchantName',
            'customerName',
          ]) ??
          'Transaction';

      final amount = _readAmount(m);
      final enteredOn = _readDateFromKey(m, 'enteredOn');
      final valueDate = _readDateFromKey(m, 'transactionDate');
      final date = enteredOn ?? valueDate ?? _readDate(m) ?? DateTime.now();
      final status = (_readString(m, const ['status', 'state']) ?? 'completed')
          .toLowerCase();
      final type = _inferType(m);

      final debitAmt = _parseAmountField(m['debitAmount']);
      final creditAmt = _parseAmountField(m['creditAmount']);

      return Transaction(
        id: id,
        title: title,
        amount: amount,
        date: date,
        status: status,
        type: type,
        debitAccountName: _readString(m, const ['debitAccountName']),
        debitAccount: _readString(m, const ['debitAccount']),
        debitAmount: debitAmt,
        creditAccountName: _readString(m, const ['creditAccountName']),
        creditAccount: _readString(m, const ['creditAccount']),
        creditAmount: creditAmt,
        branchCode: _readInt(m['branchCode']),
        batchNumber: _readInt(m['batchNumber']),
        narrativeDetail1: _readString(m, const ['narrativeDetail1']),
        narrativeDetail2: _readString(m, const ['narrativeDetail2']),
        narrativeDetail3: _readString(m, const ['narrativeDetail3']),
        transactionValueDate: valueDate,
        enteredOn: enteredOn,
        receiptReference: _readString(m, const [
          'receiptReference',
          'receiptNo',
          'receiptId',
          'mbReceiptNo',
        ]),
      );
    } catch (_) {
      return null;
    }
  }

  String? _readString(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString();
      }
    }
    return null;
  }

  double _readAmount(Map<String, dynamic> m) {
    final debit = _parseAmountField(m['debitAmount']);
    final credit = _parseAmountField(m['creditAmount']);
    if (debit != null || credit != null) {
      return (credit ?? 0) - (debit ?? 0);
    }
    for (final k in ['amount', 'value', 'total', 'trxAmount']) {
      final v = m[k];
      if (v == null) continue;
      if (v is num) return v.toDouble();
      final parsed = _parseAmountField(v);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  double? _parseAmountField(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    var s = v.toString().trim();
    if (s.isEmpty) return null;
    // Allow "5,011.50" style strings from some serializers.
    s = s.replaceAll(',', '');
    return double.tryParse(s);
  }

  DateTime? _readDateFromKey(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) {
      if (v > 2000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      }
    }
    return DateTime.tryParse(v.toString());
  }

  int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  DateTime? _readDate(Map<String, dynamic> m) {
    for (final k in [
      'enteredOn',
      'date',
      'transactionDate',
      'createdAt',
      'timestamp',
      'txnDate',
    ]) {
      final v = m[k];
      if (v == null) continue;
      if (v is DateTime) return v;
      if (v is int) {
        if (v > 2000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
        if (v > 1000000000) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      }
      final s = v.toString();
      final iso = DateTime.tryParse(s);
      if (iso != null) return iso;
    }
    return null;
  }

  String _inferType(Map<String, dynamic> m) {
    final t = _readString(m, const ['type', 'transactionType', 'txnType']);
    if (t != null) {
      final lower = t.toLowerCase();
      if (lower.contains('refund')) return 'refund';
      if (lower.contains('pay') || lower.contains('credit')) {
        return 'payment';
      }
    }
    final narration = _readString(m, const [
          'narrativeDetail1',
          'narrativeDetail2',
          'title',
        ]) ??
        '';
    if (narration.toLowerCase().contains('refund')) return 'refund';
    // Ledger debits/credits are still "payments" for filter chips; not refunds by sign alone.
    return 'payment';
  }
}
