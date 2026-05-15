import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which surface is shown inside the Profile tab (no route push — same as tab switching).
enum ProfileSubview { main, helpSupport }

class ProfileSubviewNotifier extends Notifier<ProfileSubview> {
  @override
  ProfileSubview build() => ProfileSubview.main;

  void showHelp() => state = ProfileSubview.helpSupport;

  void showMain() => state = ProfileSubview.main;
}

final profileSubviewProvider =
    NotifierProvider<ProfileSubviewNotifier, ProfileSubview>(
  ProfileSubviewNotifier.new,
);
