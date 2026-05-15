import '../models/merchant_profile.dart';

abstract class AuthRepository {
  Future<MerchantProfile> validateMerchant({
    required String merchantCode,
    required String merchantSecret,
  });
}
