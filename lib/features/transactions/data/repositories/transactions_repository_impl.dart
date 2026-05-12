import '../../domain/models/transaction.dart';
import '../../domain/repositories/transactions_repository.dart';
import '../datasources/transactions_remote_datasource.dart';

class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl(this._remoteDataSource);

  final TransactionsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Transaction>> fetchTransactions({
    required String merchantCode,
    required String merchantSecret,
    required String fromDate,
    required String toDate,
  }) {
    return _remoteDataSource.fetchTransactions(
      merchantCode: merchantCode,
      merchantSecret: merchantSecret,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
