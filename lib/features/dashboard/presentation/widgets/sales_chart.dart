import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/providers/merchant_session_provider.dart';
import '../../../transactions/presentation/providers/transactions_providers.dart';

/// Last 7 calendar days (including today), daily sum of [Transaction.amount]
/// from `POST …/merchant-registrations/transactions` — same source as Reports.
class SalesChart extends ConsumerStatefulWidget {
  const SalesChart({super.key});

  @override
  ConsumerState<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends ConsumerState<SalesChart> {
  static final DateFormat _apiDateFmt = DateFormat('yyyy-MM-dd');
  static final DateFormat _weekdayFmt = DateFormat('EEE');

  bool _loading = true;
  List<FlSpot> _spots = const [
    FlSpot(0, 0),
    FlSpot(1, 0),
    FlSpot(2, 0),
    FlSpot(3, 0),
    FlSpot(4, 0),
    FlSpot(5, 0),
    FlSpot(6, 0),
  ];
  List<String> _weekdayLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  double _minY = 0;
  double _maxY = 5000;
  double _gridInterval = 1000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRevenueSeries());
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  double _niceCeil(double v) {
    if (v <= 0) return 0;
    final exp = (math.log(v) / math.ln10).floor();
    final pow10 = math.pow(10.0, exp).toDouble();
    final frac = v / pow10;
    final double niceFrac;
    if (frac <= 1) {
      niceFrac = 1;
    } else if (frac <= 2) {
      niceFrac = 2;
    } else if (frac <= 5) {
      niceFrac = 5;
    } else {
      niceFrac = 10;
    }
    return niceFrac * pow10;
  }

  void _applyScale(List<FlSpot> spots) {
    final ys = spots.map((s) => s.y).toList();
    var minV = ys.reduce(math.min);
    var maxV = ys.reduce(math.max);
    if (minV > 0) minV = 0;

    if (maxV <= 0 && minV >= 0) {
      _minY = 0;
      _maxY = 5000;
      _gridInterval = 1000;
      return;
    }

    final span = maxV - minV;
    if (span.abs() < 1e-6) {
      maxV = minV + 1;
    }

    final padLow = minV < 0 ? (minV * 0.12 - (maxV - minV) * 0.02) : 0.0;
    final padHigh = (maxV - minV) * 0.15 + (minV < 0 ? 0.0 : maxV * 0.05);
    var low = minV + padLow;
    var high = maxV + padHigh;
    if (low > 0) low = 0;

    _minY = low;
    _maxY = _niceCeil(high);
    if (_maxY <= _minY) _maxY = _minY + 500;

    final divisions = 5;
    _gridInterval = (_maxY - _minY) / divisions;
    if (_gridInterval <= 0) _gridInterval = 1000;
  }

  String _leftAxisLabel(double value) {
    final absMax = math.max(_minY.abs(), _maxY.abs());
    if (absMax >= 1000) {
      final k = value / 1000;
      if (k == k.roundToDouble()) {
        return '${k.toInt()}k';
      }
      return '${k.toStringAsFixed(1)}k';
    }
    return value.round().toString();
  }

  Future<void> _loadRevenueSeries() async {
    final session = ref.read(merchantSessionProvider);
    final now = DateTime.now();
    final today = _dayOnly(now);
    final rangeStart = today.subtract(const Duration(days: 6));

    final labels = List.generate(
      7,
      (i) => _weekdayFmt.format(rangeStart.add(Duration(days: i))),
    );

    void finish(List<FlSpot> spots) {
      if (!mounted) return;
      setState(() {
        _spots = spots;
        _weekdayLabels = labels;
        _applyScale(spots);
        _loading = false;
      });
    }

    List<FlSpot> zeros() => List.generate(
          7,
          (i) => FlSpot(i.toDouble(), 0),
        );

    if (session == null) {
      finish(zeros());
      return;
    }

    final fromStr = _apiDateFmt.format(rangeStart);
    final toStr = _apiDateFmt.format(today);

    try {
      final list = await ref.read(transactionsRepositoryProvider).fetchTransactions(
            merchantCode: session.code,
            merchantSecret: session.secret,
            fromDate: fromStr,
            toDate: toStr,
          );

      final buckets = <DateTime, double>{};
      for (var i = 0; i < 7; i++) {
        final d = rangeStart.add(Duration(days: i));
        buckets[_dayOnly(d)] = 0;
      }
      for (final t in list) {
        final day = _dayOnly(t.date);
        if (buckets.containsKey(day)) {
          buckets[day] = buckets[day]! + t.amount;
        }
      }

      final spots = List.generate(7, (i) {
        final d = rangeStart.add(Duration(days: i));
        final v = buckets[_dayOnly(d)] ?? 0;
        return FlSpot(i.toDouble(), v);
      });
      finish(spots);
    } catch (_) {
      finish(zeros());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
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
          Text(
            'Revenue Overview',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _gridInterval,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppPalette.divider,
                            strokeWidth: 1,
                            dashArray: const [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(color: AppPalette.textSecondary, fontSize: 12);
                              final i = value.round().clamp(0, 6);
                              final text = _weekdayLabels[i];
                              return SideTitleWidget(meta: meta, child: Text(text, style: style));
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _gridInterval,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _leftAxisLabel(value),
                                style: const TextStyle(color: AppPalette.textSecondary, fontSize: 12),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: _minY,
                      maxY: _maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
                          color: AppPalette.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppPalette.primary.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
