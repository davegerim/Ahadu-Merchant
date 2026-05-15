import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/formatting/app_amount_format.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/models/transaction.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  /// When true, renders only the scrollable body (no [Scaffold]). The parent
  /// screen supplies app bar / navigation so the main shell stays visible.
  final bool embedded;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.embedded = false,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final amountFormatter = appAmountFormatter();
    final dateFormatter = DateFormat('MMM dd, yyyy - hh:mm a');
    final isPositive = transaction.amount > 0;

    final scrollContent = SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppPalette.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isPositive ? AppPalette.successBg : AppPalette.errorBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isPositive ? AppPalette.success : AppPalette.error,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${isPositive ? '+' : ''}${amountFormatter.format(transaction.amount)}',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? AppPalette.success : AppPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppPalette.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          transaction.status.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: AppPalette.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppPalette.surface,
                    borderRadius: BorderRadius.circular(24),
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
                      Text(
                        'Details',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildDetailRow('Transaction ID', transaction.id),
                      const Divider(height: 32, color: AppPalette.divider),
                      _buildDetailRow('Title', transaction.title),
                      const Divider(height: 32, color: AppPalette.divider),
                      _buildDetailRow(
                        transaction.enteredOn != null ? 'Entered on' : 'Date & time',
                        dateFormatter.format(transaction.date),
                      ),
                      const Divider(height: 32, color: AppPalette.divider),
                      _buildDetailRow('Type', _typeDisplayLabel(transaction)),
                      ..._ledgerDetailRows(transaction, amountFormatter, dateFormatter),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

    if (widget.embedded) {
      return scrollContent;
    }

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('Transaction Details'),
      ),
      body: scrollContent,
    );
  }

  String _typeDisplayLabel(Transaction t) {
    final d = t.debitAmount ?? 0;
    final c = t.creditAmount ?? 0;
    if (t.debitAmount != null || t.creditAmount != null) {
      if (d > 0 && c == 0) return 'Debit';
      if (c > 0 && d == 0) return 'Credit';
    }
    return t.type == 'payment' ? 'Incoming Payment' : 'Outgoing Refund';
  }

  List<Widget> _ledgerDetailRows(
    Transaction t,
    NumberFormat amountFormatter,
    DateFormat dateFormatter,
  ) {
    void addOptional(List<Widget> out, String label, String? value) {
      if (value == null || value.trim().isEmpty) return;
      out.add(const Divider(height: 32, color: AppPalette.divider));
      out.add(_buildDetailRow(label, value));
    }

    final out = <Widget>[];

    if (t.transactionValueDate != null) {
      addOptional(
        out,
        'Value date',
        dateFormatter.format(t.transactionValueDate!),
      );
    }

    if (t.debitAmount != null || t.creditAmount != null) {
      if (t.debitAmount != null) {
        addOptional(out, 'Debit amount', amountFormatter.format(t.debitAmount!));
      }
      if (t.creditAmount != null) {
        addOptional(out, 'Credit amount', amountFormatter.format(t.creditAmount!));
      }
    }

    addOptional(out, 'Debit account', t.debitAccount);
    addOptional(out, 'Debit account name', t.debitAccountName);
    addOptional(out, 'Credit account', t.creditAccount);
    addOptional(out, 'Credit account name', t.creditAccountName);

    if (t.branchCode != null) {
      addOptional(out, 'Branch code', t.branchCode.toString());
    }
    if (t.batchNumber != null) {
      addOptional(out, 'Batch number', t.batchNumber.toString());
    }

    final n1 = t.narrativeDetail1;
    if (n1 != null &&
        n1.trim().isNotEmpty &&
        n1.trim() != t.title.trim()) {
      addOptional(out, 'Narrative 1', n1);
    }
    addOptional(out, 'Narrative 2', t.narrativeDetail2);
    addOptional(out, 'Narrative 3', t.narrativeDetail3);

    return out;
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppPalette.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: AppPalette.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
