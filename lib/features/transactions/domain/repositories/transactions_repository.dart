import 'dart:typed_data';

import '../models/transaction.dart';

abstract class TransactionsRepository {
  Future<List<Transaction>> fetchTransactions({
    required String merchantCode,
    required String merchantSecret,
    required String fromDate,
    required String toDate,
  });

  /// GET `/api/v1/receipt/{reference}` — PDF bytes from server, or generated from JSON response.
  Future<Uint8List> fetchReceiptDocument(
    String receiptReference, {
    String? merchantCode,
    String? merchantSecret,
  });
}
