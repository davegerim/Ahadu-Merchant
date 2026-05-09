abstract class AuthRepository {
  Future<void> validateMerchant({
    required String merchantCode,
    required String merchantSecret,
  });
}
