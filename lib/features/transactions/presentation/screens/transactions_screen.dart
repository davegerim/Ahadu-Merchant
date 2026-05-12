import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/formatting/app_amount_format.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/providers/merchant_session_provider.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../providers/transactions_providers.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _selectedFilter = 'All';
  DateTime? _selectedDate;
  final List<String> _filters = ['All', 'Completed', 'Pending', 'Failed', 'Refunds'];

  static final DateFormat _apiDateFmt = DateFormat('yyyy-MM-dd');

  List<Transaction>? _apiTransactions;
  bool _apiLoading = false;
  String? _apiErrorMessage;

  /// In-tab detail view (keeps main navigation shell visible).
  Transaction? _openedDetail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMerchantTransactions());
  }

  /// Loads transactions. Pass [day] to query that calendar day only (POST
  /// `fromDate` / `toDate` both `yyyy-MM-dd` for that day); omit for last 30 days.
  Future<void> _loadMerchantTransactions([DateTime? day]) async {
    final session = ref.read(merchantSessionProvider);
    if (session == null) return;

    final String fromStr;
    final String toStr;
    if (day != null) {
      final normalized = DateTime(day.year, day.month, day.day);
      fromStr = _apiDateFmt.format(normalized);
      toStr = fromStr;
    } else {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 30));
      fromStr = _apiDateFmt.format(from);
      toStr = _apiDateFmt.format(now);
    }

    setState(() {
      _apiLoading = true;
      _apiErrorMessage = null;
    });

    try {
      final list = await ref.read(transactionsRepositoryProvider).fetchTransactions(
            merchantCode: session.code,
            merchantSecret: session.secret,
            fromDate: fromStr,
            toDate: toStr,
          );
      if (!mounted) return;
      setState(() {
        _apiTransactions = list;
        _apiLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _apiLoading = false;
        _apiErrorMessage = e.response?.data?.toString() ?? e.message ?? 'Request failed';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_apiErrorMessage!)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiLoading = false;
        _apiErrorMessage = e.toString();
      });
    }
  }

  String _transactionListSubtitle(Transaction tx, NumberFormat amountFmt) {
    final parts = <String>[];
    if (tx.debitAccountName != null && tx.debitAccountName!.trim().isNotEmpty) {
      parts.add(tx.debitAccountName!.trim());
    }
    if (tx.debitAccount != null && tx.debitAccount!.trim().isNotEmpty) {
      parts.add(tx.debitAccount!.trim());
    }
    if (tx.debitAmount != null) {
      parts.add('Debit: ${amountFmt.format(tx.debitAmount!)}');
    }
    return parts.join(' · ');
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null || picked == _selectedDate) return;
    setState(() => _selectedDate = picked);
    await _loadMerchantTransactions(picked);
  }

  Future<void> _clearDateFilter() async {
    setState(() => _selectedDate = null);
    await _loadMerchantTransactions();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Transaction?>(pendingTransactionDetailProvider, (previous, next) {
      if (next != null) {
        setState(() => _openedDetail = next);
        ref.read(pendingTransactionDetailProvider.notifier).clear();
      }
    });

    final amountFormatter = appAmountFormatter();
    final dateFormatter = DateFormat('MMM dd, yyyy - hh:mm a');

    final baseTransactions = _apiTransactions ?? mockTransactions;

    // Filter transactions based on selection
    final filteredTransactions = baseTransactions.where((tx) {
      bool passStatus = true;
      if (_selectedFilter != 'All') {
        if (_selectedFilter == 'Refunds') {
          passStatus = tx.type == 'refund';
        } else {
          passStatus = tx.status.toLowerCase() == _selectedFilter.toLowerCase();
        }
      }

      // API list is already scoped by POST fromDate/toDate (single day or 30-day window).
      // Only apply calendar filtering for mock data when no API payload is loaded.
      bool passDate = true;
      if (_selectedDate != null && _apiTransactions == null) {
        bool sameDay(DateTime a, DateTime b) =>
            a.year == b.year && a.month == b.month && a.day == b.day;
        passDate = sameDay(tx.date, _selectedDate!) ||
            (tx.transactionValueDate != null &&
                sameDay(tx.transactionValueDate!, _selectedDate!));
      }

      return passStatus && passDate;
    }).toList();

    final showingDetail = _openedDetail != null;

    return PopScope(
      canPop: !showingDetail,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && showingDetail) {
          setState(() => _openedDetail = null);
        }
      },
      child: Scaffold(
        backgroundColor: AppPalette.background,
        appBar: AppBar(
          leading: showingDetail
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _openedDetail = null),
                )
              : null,
          title: Text(showingDetail ? 'Transaction Details' : 'Transactions'),
          actions: showingDetail
              ? null
              : [
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () => _pickDate(context),
                  ),
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearDateFilter,
                    ),
                ],
        ),
        body: showingDetail
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: TransactionDetailScreen(
                    embedded: true,
                    transaction: _openedDetail!,
                  ),
                ),
              )
            : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              if (_apiLoading)
                const LinearProgressIndicator(minHeight: 2),
              // Filter Chips
          Container(
            color: AppPalette.surface,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      backgroundColor: AppPalette.background,
                      selectedColor: AppPalette.primary.withOpacity(0.1),
                      labelStyle: GoogleFonts.inter(
                        color: isSelected ? AppPalette.primary : AppPalette.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppPalette.primary : AppPalette.divider,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Transaction List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = filteredTransactions[index];
                final isPositive = tx.amount > 0;

                return Container(
                  decoration: BoxDecoration(
                    color: AppPalette.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() => _openedDetail = tx);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
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
                                    fontWeight: FontWeight.bold,
                                    color: AppPalette.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                                if (_transactionListSubtitle(tx, amountFormatter).isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _transactionListSubtitle(tx, amountFormatter),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: AppPalette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: AppPalette.textSecondary),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        dateFormatter.format(tx.date),
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: AppPalette.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppPalette.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  ),
),
);
  }
}
