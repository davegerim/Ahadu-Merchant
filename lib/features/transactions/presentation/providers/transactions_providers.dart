import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/datasources/transactions_remote_datasource.dart';
import '../../data/repositories/transactions_repository_impl.dart';
import '../../domain/models/transaction.dart';
import '../../domain/repositories/transactions_repository.dart';

/// When set (e.g. from Dashboard “recent” list), [TransactionsScreen] opens this
/// transaction in-tab instead of pushing a root route.
class PendingTransactionDetail extends Notifier<Transaction?> {
  @override
  Transaction? build() => null;

  void set(Transaction tx) => state = tx;

  void clear() => state = null;
}

final pendingTransactionDetailProvider =
    NotifierProvider<PendingTransactionDetail, Transaction?>(
        PendingTransactionDetail.new);

final transactionsRemoteDataSourceProvider =
    Provider<TransactionsRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return TransactionsRemoteDataSource(dio);
});

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final remote = ref.watch(transactionsRemoteDataSourceProvider);
  return TransactionsRepositoryImpl(remote);
});
