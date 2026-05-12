import 'package:intl/intl.dart';

/// Grouped decimal amounts for ledger UI (no currency symbol).
NumberFormat appAmountFormatter() => NumberFormat('#,##0.00', 'en_US');
