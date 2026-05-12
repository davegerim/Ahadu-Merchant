import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/formatting/app_amount_format.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/providers/merchant_session_provider.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_providers.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_index_provider.dart';

class RecentTransactionsList extends ConsumerStatefulWidget {
  const RecentTransactionsList({super.key});

  @override
  ConsumerState<RecentTransactionsList> createState() =>
      _RecentTransactionsListState();
}

class _RecentTransactionsListState extends ConsumerState<RecentTransactionsList> {
  static final DateFormat _apiDateFmt = DateFormat('yyyy-MM-dd');

  List<Transaction> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecentTransactions());
  }

  /// Same POST …/merchant-registrations/transactions as the Transactions tab,
  /// with `fromDate` and `toDate` both set to **today** (local calendar day),
  /// matching the single-day payload shape from the API contract.
  Future<void> _loadRecentTransactions() async {
    final session = ref.read(merchantSessionProvider);
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _items = mockTransactions.take(3).toList();
        _loading = false;
      });
      return;
    }

    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final dayStr = _apiDateFmt.format(day);

    try {
      final list = await ref.read(transactionsRepositoryProvider).fetchTransactions(
            merchantCode: session.code,
            merchantSecret: session.secret,
            fromDate: dayStr,
            toDate: dayStr,
          );
      list.sort((a, b) => b.date.compareTo(a.date));
      if (!mounted) return;
      setState(() {
        _items = list.take(3).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountFormatter = appAmountFormatter();
    final dateFormatter = DateFormat('MMM dd, yyyy - hh:mm a');

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full transactions list
                    ref.read(dashboardIndexProvider.notifier).setIndex(1);
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppPalette.divider),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppPalette.divider, indent: 20, endIndent: 20),
            itemBuilder: (context, index) {
              final tx = _items[index];
              final isPositive = tx.amount > 0;
              
              return InkWell(
                onTap: () {
                  ref.read(dashboardIndexProvider.notifier).setIndex(1);
                  ref.read(pendingTransactionDetailProvider.notifier).set(tx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isPositive ? AppPalette.successBg : AppPalette.errorBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isPositive ? AppPalette.success : AppPalette.error,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormatter.format(tx.date),
                              style: GoogleFonts.inter(
                                color: AppPalette.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isPositive ? '+' : ''}${amountFormatter.format(tx.amount)}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: isPositive ? AppPalette.success : AppPalette.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppPalette.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tx.status.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: AppPalette.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
