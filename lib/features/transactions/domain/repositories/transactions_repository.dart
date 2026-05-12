import '../models/transaction.dart';

abstract class TransactionsRepository {
  Future<List<Transaction>> fetchTransactions({
    required String merchantCode,
    required String merchantSecret,
    required String fromDate,
    required String toDate,
  });
}
