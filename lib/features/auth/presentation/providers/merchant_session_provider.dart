import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds merchant credentials after a successful validate call so other
/// features (e.g. transactions API) can reuse them in-session.
class MerchantSession extends Notifier<({String code, String secret})?> {
  @override
  ({String code, String secret})? build() => null;

  void setCredentials({
    required String merchantCode,
    required String merchantSecret,
  }) {
    state = (code: merchantCode, secret: merchantSecret);
  }

  void clear() => state = null;
}

final merchantSessionProvider =
    NotifierProvider<MerchantSession, ({String code, String secret})?>(
  MerchantSession.new,
);
