import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/formatting/app_amount_format.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/file_saver.dart';
import '../../../auth/presentation/providers/merchant_session_provider.dart';
import '../../../transactions/domain/models/transaction.dart';
import '../../../transactions/pdf/transactions_report_pdf.dart';
import '../../../transactions/presentation/providers/transactions_providers.dart';

enum _ExportFormat { csv, excel, pdf }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  List<Transaction>? _transactions;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;

  /// Horizontal scroll for the wide report [DataTable]; paired with [Scrollbar].
  final ScrollController _tableHorizontalScrollController = ScrollController();

  static const List<int> _pageSizeOptions = [10, 25, 50];
  int _rowsPerPage = 10;
  int _currentPage = 0;

  static final DateFormat _apiDateFmt = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDateFmt = DateFormat('MMM dd, yyyy');
  static final DateFormat _detailDateFmt = DateFormat('MMM dd, yyyy – hh:mm a');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    _rangeEnd = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransactions());
  }

  @override
  void dispose() {
    _tableHorizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final session = ref.read(merchantSessionProvider);
    if (session == null) return;

    final fromStr = _apiDateFmt.format(_normalizeDay(_rangeStart));
    final toStr = _apiDateFmt.format(_normalizeDay(_rangeEnd));

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
        _transactions = list;
        _isLoading = false;
        _currentPage = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load report data')),
      );
    }
  }

  DateTime _normalizeDay(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppPalette.primary,
          onPrimary: Colors.white,
          onSurface: AppPalette.textPrimary,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: _pickerTheme,
    );
    if (picked == null) return;
    setState(() {
      final p = _normalizeDay(picked);
      final end = _normalizeDay(_rangeEnd);
      _rangeStart = p;
      if (p.isAfter(end)) _rangeEnd = p;
    });
    await _loadTransactions();
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _rangeEnd,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: _pickerTheme,
    );
    if (picked == null) return;
    setState(() {
      final p = _normalizeDay(picked);
      final start = _normalizeDay(_rangeStart);
      _rangeEnd = p;
      if (p.isBefore(start)) _rangeStart = p;
    });
    await _loadTransactions();
  }

  void _showExportSheet(BuildContext context) {
    if (_transactions == null || _transactions!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export for this range.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExportBottomSheet(
        onSelected: (format) {
          Navigator.pop(ctx);
          _exportAs(format);
        },
      ),
    );
  }

  Future<void> _exportAs(_ExportFormat format) async {
    if (_transactions == null || _transactions!.isEmpty) return;

    setState(() => _isExporting = true);

    try {
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());

      switch (format) {
        case _ExportFormat.csv:
          final bytes = _buildCsvBytes();
          await saveAndShareFile(
            fileName: 'transactions_report_$dateStr.csv',
            bytes: bytes,
            mimeType: 'text/csv',
          );
          break;

        case _ExportFormat.excel:
          final bytes = _buildExcelXlsxBytes();
          await saveAndShareFile(
            fileName: 'transactions_report_$dateStr.xlsx',
            bytes: bytes,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
          break;

        case _ExportFormat.pdf:
          final pdfBytes = await _buildPdfBytes();
          await Printing.sharePdf(
            bytes: pdfBytes,
            filename: 'transactions_report_$dateStr.pdf',
          );
          break;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${format.name.toUpperCase()} report exported successfully'),
          backgroundColor: AppPalette.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  static final List<String> _reportColumnHeaders = [
    'ID',
    'Title',
    'Amount',
    'Date',
    'Status',
    'Type',
    'Debit account name',
    'Debit account',
    'Debit amount',
    'Credit account name',
    'Credit account',
    'Credit amount',
    'Narrative 1',
    'Value date',
    'Entered on',
  ];

  List<dynamic> _transactionToRowValues(Transaction tx) {
    final exportDateFmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    String fo(DateTime? d) => d == null ? '' : exportDateFmt.format(d);
    return [
      tx.id,
      tx.title,
      tx.amount,
      exportDateFmt.format(tx.date),
      tx.status,
      tx.type,
      tx.debitAccountName ?? '',
      tx.debitAccount ?? '',
      tx.debitAmount,
      tx.creditAccountName ?? '',
      tx.creditAccount ?? '',
      tx.creditAmount,
      tx.narrativeDetail1 ?? '',
      fo(tx.transactionValueDate),
      fo(tx.enteredOn),
    ];
  }

  List<List<dynamic>> _buildRows() {
    return [
      [..._reportColumnHeaders],
      ..._transactions!.map(_transactionToRowValues),
    ];
  }

  List<String> _transactionToPdfRow(Transaction tx) {
    return _transactionToRowValues(tx)
        .map((e) => e?.toString() ?? '')
        .toList();
  }

  Uint8List _buildCsvBytes() {
    final csvString = Csv().encode(_buildRows());
    return Uint8List.fromList(utf8.encode(csvString));
  }

  /// Real `.xlsx` (Office Open XML), not plain text with a wrong extension.
  Uint8List _buildExcelXlsxBytes() {
    final excel = Excel.createExcel();
    final defaultSheetName = excel.tables.keys.first;
    excel.rename(defaultSheetName, 'Transactions');
    final sheet = excel['Transactions'];

    final rows = _buildRows();
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final raw = row[c];
        final CellValue cellVal = switch (raw) {
          final int i => IntCellValue(i),
          final double d => DoubleCellValue(d),
          _ => TextCellValue(raw.toString()),
        };
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
          cellVal,
        );
      }
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Excel encoding produced no data');
    }
    return Uint8List.fromList(encoded);
  }

  Future<Uint8List> _buildPdfBytes() {
    double totalRevenue = 0;
    for (var t in _transactions!) {
      if (t.amount > 0 && t.status.toLowerCase() == 'completed') {
        totalRevenue += t.amount;
      }
    }
    final dateRangeLabel =
        '${_displayDateFmt.format(_rangeStart)} – ${_displayDateFmt.format(_rangeEnd)}';

    return buildTransactionsReportPdf(
      headers: _reportColumnHeaders,
      dataRows: _transactions!.map(_transactionToPdfRow).toList(),
      dateRangeLabel: dateRangeLabel,
      totalRevenue: totalRevenue,
      totalOrders: _transactions!.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountFormatter = appAmountFormatter();

    double totalRevenue = 0;
    int totalOrders = 0;
    if (_transactions != null) {
      for (var t in _transactions!) {
        if (t.amount > 0 && t.status.toLowerCase() == 'completed') {
          totalRevenue += t.amount;
        }
        totalOrders++;
      }
    }

    final dateRangeDisplay =
        '${_displayDateFmt.format(_rangeStart)} – ${_displayDateFmt.format(_rangeEnd)}';

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            tooltip: 'Export Report',
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.file_download_outlined),
            onPressed: _isExporting ? null : () => _showExportSheet(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InkWell(
                            onTap: () => _pickStartDate(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppPalette.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppPalette.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_outlined, size: 18, color: AppPalette.primary),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From',
                                        style: GoogleFonts.inter(
                                          color: AppPalette.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _displayDateFmt.format(_rangeStart),
                                        style: GoogleFonts.inter(
                                          color: AppPalette.primary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, color: AppPalette.primary),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _pickEndDate(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppPalette.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppPalette.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_outlined, size: 18, color: AppPalette.primary),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'To',
                                        style: GoogleFonts.inter(
                                          color: AppPalette.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _displayDateFmt.format(_rangeEnd),
                                        style: GoogleFonts.inter(
                                          color: AppPalette.primary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, color: AppPalette.primary),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              dateRangeDisplay,
                              style: GoogleFonts.inter(
                                color: AppPalette.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Summary Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppPalette.primary, AppPalette.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Revenue',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              amountFormatter.format(totalRevenue),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Text(
                                  'Total Orders: $totalOrders',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_transactions == null || _transactions!.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                const Icon(Icons.receipt_long, size: 64, color: AppPalette.divider),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage ?? 'No transactions found for this period.',
                                  style: GoogleFonts.inter(
                                    color: AppPalette.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        // Section header with export button
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Transactions Detail',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.textPrimary,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _isExporting ? null : () => _showExportSheet(context),
                              icon: const Icon(Icons.download, size: 18),
                              label: Text(
                                'Export',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                              ),
                              style: TextButton.styleFrom(foregroundColor: AppPalette.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Data Table (+ pagination)
                        Builder(
                          builder: (context) {
                            final txs = _transactions!;
                            final totalCount = txs.length;
                            final totalPages = totalCount == 0
                                ? 1
                                : math.max(
                                    1,
                                    (totalCount + _rowsPerPage - 1) ~/ _rowsPerPage,
                                  );
                            final pageIdx = totalCount == 0
                                ? 0
                                : _currentPage.clamp(0, totalPages - 1);
                            final startIdx = pageIdx * _rowsPerPage;
                            final pageSlice = totalCount == 0
                                ? <Transaction>[]
                                : txs.sublist(
                                    startIdx,
                                    math.min(startIdx + _rowsPerPage, totalCount),
                                  );
                            final displayStart =
                                totalCount == 0 ? 0 : startIdx + 1;
                            final displayEnd =
                                totalCount == 0 ? 0 : startIdx + pageSlice.length;

                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppPalette.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        10,
                                        12,
                                        4,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.swap_horiz,
                                            size: 16,
                                            color: AppPalette.textSecondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Scroll sideways to see all columns',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color:
                                                    AppPalette.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Scrollbar(
                                      controller:
                                          _tableHorizontalScrollController,
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      interactive: true,
                                      thickness: 6,
                                      radius: const Radius.circular(3),
                                      child: SingleChildScrollView(
                                        controller:
                                            _tableHorizontalScrollController,
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          headingRowColor:
                                              WidgetStateProperty.all(
                                            AppPalette.primary
                                                .withValues(alpha: 0.05),
                                          ),
                                          headingTextStyle: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            color: AppPalette.textSecondary,
                                            fontSize: 12,
                                          ),
                                          dataTextStyle: GoogleFonts.inter(
                                            color: AppPalette.textPrimary,
                                            fontSize: 12,
                                          ),
                                          columns: [
                                            for (final h
                                                in _reportColumnHeaders)
                                              DataColumn(label: Text(h)),
                                          ],
                                          rows: [
                                            for (final tx in pageSlice)
                                              _buildTransactionDataRow(
                                                  tx, amountFormatter),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: AppPalette.divider,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 12,
                                        runSpacing: 10,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Rows per page',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color:
                                                      AppPalette.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              DropdownButton<int>(
                                                value: _rowsPerPage,
                                                underline: const SizedBox(),
                                                items: [
                                                  for (final n
                                                      in _pageSizeOptions)
                                                    DropdownMenuItem(
                                                      value: n,
                                                      child: Text(
                                                        '$n',
                                                        style:
                                                            GoogleFonts.inter(),
                                                      ),
                                                    ),
                                                ],
                                                onChanged: (v) {
                                                  if (v == null) return;
                                                  setState(() {
                                                    _rowsPerPage = v;
                                                    _currentPage = 0;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                totalCount == 0
                                                    ? '0 of 0'
                                                    : '$displayStart–$displayEnd of $totalCount',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: AppPalette
                                                      .textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: 'Previous page',
                                                onPressed: pageIdx > 0
                                                    ? () => setState(
                                                        () => _currentPage--,
                                                      )
                                                    : null,
                                                icon: const Icon(
                                                  Icons.chevron_left,
                                                  color: AppPalette.primary,
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                ),
                                                child: Text(
                                                  'Page ${pageIdx + 1} of $totalPages',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppPalette
                                                        .textPrimary,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Next page',
                                                onPressed: pageIdx <
                                                        totalPages - 1
                                                    ? () => setState(
                                                        () => _currentPage++,
                                                      )
                                                    : null,
                                                icon: const Icon(
                                                  Icons.chevron_right,
                                                  color: AppPalette.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  DataRow _buildTransactionDataRow(Transaction tx, NumberFormat amountFormatter) {
    String dash(String? s) =>
        (s != null && s.trim().isNotEmpty) ? s : '—';
    String dashOptDt(DateTime? d) => d == null ? '—' : _detailDateFmt.format(d);
    String dashOptNum(double? n) => n == null ? '—' : amountFormatter.format(n);
    final isPositive = tx.amount > 0;

    return DataRow(
      cells: [
        DataCell(Text(tx.id)),
        DataCell(_ellipsisCell(tx.title, maxWidth: 160)),
        DataCell(Text(
          '${isPositive ? '+' : ''}${amountFormatter.format(tx.amount)}',
          style: TextStyle(
            color: isPositive ? AppPalette.success : AppPalette.error,
            fontWeight: FontWeight.bold,
          ),
        )),
        DataCell(Text(_detailDateFmt.format(tx.date))),
        DataCell(_statusBadge(tx.status)),
        DataCell(Text(tx.type.toUpperCase())),
        DataCell(Text(dash(tx.debitAccountName))),
        DataCell(Text(dash(tx.debitAccount))),
        DataCell(Text(dashOptNum(tx.debitAmount))),
        DataCell(Text(dash(tx.creditAccountName))),
        DataCell(Text(dash(tx.creditAccount))),
        DataCell(Text(dashOptNum(tx.creditAmount))),
        DataCell(_ellipsisCell(dash(tx.narrativeDetail1), maxWidth: 140)),
        DataCell(Text(dashOptDt(tx.transactionValueDate))),
        DataCell(Text(dashOptDt(tx.enteredOn))),
      ],
    );
  }

  Widget _ellipsisCell(String text, {double maxWidth = 120}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  Widget _statusBadge(String status) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: c,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppPalette.success;
      case 'pending':
        return AppPalette.warning;
      case 'failed':
        return AppPalette.error;
      default:
        return AppPalette.primary;
    }
  }
}

class _ExportBottomSheet extends StatelessWidget {
  final ValueChanged<_ExportFormat> onSelected;

  const _ExportBottomSheet({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppPalette.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Export Report As',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose your preferred file format',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ExportOption(
                  icon: Icons.description_outlined,
                  label: 'CSV',
                  subtitle: 'Comma separated',
                  color: AppPalette.success,
                  onTap: () => onSelected(_ExportFormat.csv),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ExportOption(
                  icon: Icons.table_chart_outlined,
                  label: 'Excel',
                  subtitle: 'Spreadsheet',
                  color: const Color(0xFF217346),
                  onTap: () => onSelected(_ExportFormat.excel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ExportOption(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  subtitle: 'Print ready',
                  color: AppPalette.error,
                  onTap: () => onSelected(_ExportFormat.pdf),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
