import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/merchant_profile.dart';

/// Holds merchant credentials and profile fields from validate so other
/// features (e.g. transactions API, profile) can reuse them in-session.
class MerchantSession
    extends Notifier<({String code, String secret, MerchantProfile profile})?> {
  @override
  ({String code, String secret, MerchantProfile profile})? build() => null;

  void setCredentials({
    required String merchantCode,
    required String merchantSecret,
    required MerchantProfile profile,
  }) {
    state = (
      code: merchantCode,
      secret: merchantSecret,
      profile: profile,
    );
  }

  void clear() => state = null;
}

final merchantSessionProvider = NotifierProvider<MerchantSession,
    ({String code, String secret, MerchantProfile profile})?>(
  MerchantSession.new,
);
