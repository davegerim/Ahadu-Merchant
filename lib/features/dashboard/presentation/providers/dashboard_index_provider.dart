import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardIndex extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final dashboardIndexProvider = NotifierProvider<DashboardIndex, int>(DashboardIndex.new);
