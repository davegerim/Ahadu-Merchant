import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models/transaction.dart';

class TransactionsRemoteDataSource {
  TransactionsRemoteDataSource(this._dio);

  final Dio _dio;

  static const String _transactionsUrl =
      'http://10.20.0.45:7035/api/v1/merchant-registrations/transactions';

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
