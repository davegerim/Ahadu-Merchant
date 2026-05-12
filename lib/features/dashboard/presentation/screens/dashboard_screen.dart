import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/sales_chart.dart';
import '../widgets/recent_transactions_list.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('Overview'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white24,
            child: Text('AM', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Ahadu Merchant',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppPalette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here is what\'s happening with your business today.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Stats Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width > 800 ? 4 : 2;
                final spacing = 16.0;
                final totalSpacing = spacing * (crossAxisCount - 1);
                final cardWidth = (width - totalSpacing) / crossAxisCount;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: const [
                    StatCard(
                      title: 'Today\'s Sales',
                      amount: '4,200',
                      change: '12%',
                      isPositive: true,
                      icon: Icons.point_of_sale,
                    ),
                    StatCard(
                      title: 'Total Transactions',
                      amount: '124',
                      change: '4%',
                      isPositive: true,
                      icon: Icons.receipt_long,
                    ),
                    StatCard(
                      title: 'Refunds',
                      amount: '150',
                      change: '1%',
                      isPositive: false,
                      icon: Icons.assignment_return,
                    ),
                    StatCard(
                      title: 'Active Customers',
                      amount: '89',
                      change: '22%',
                      isPositive: true,
                      icon: Icons.people,
                    ),
                  ].map((card) => SizedBox(width: cardWidth, child: card)).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const SalesChart(),
            const SizedBox(height: 24),
            const RecentTransactionsList(),
            const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
