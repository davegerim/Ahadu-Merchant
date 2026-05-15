import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_screen.dart';
import '../providers/dashboard_index_provider.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../profile/presentation/providers/profile_subview_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainLayoutScreen extends ConsumerWidget {
  const MainLayoutScreen({super.key});

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(dashboardIndexProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    ref.listen<int>(dashboardIndexProvider, (previous, next) {
      if (next != 3) {
        ref.read(profileSubviewProvider.notifier).showMain();
      }
    });

    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) => ref.read(dashboardIndexProvider.notifier).setIndex(index),
                  extended: MediaQuery.of(context).size.width >= 1000,
                  minExtendedWidth: 200,
                  backgroundColor: Colors.white,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long),
                      label: Text('Transactions'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart),
                      label: Text('Reports'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            )
          : IndexedStack(
              index: currentIndex,
              children: _screens,
            ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => ref.read(dashboardIndexProvider.notifier).setIndex(index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Transactions',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }
}
