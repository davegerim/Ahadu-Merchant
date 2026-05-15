import '../../domain/models/merchant_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<MerchantProfile> validateMerchant({
    required String merchantCode,
    required String merchantSecret,
  }) {
    return _remoteDataSource.validateMerchant(
      merchantCode: merchantCode,
      merchantSecret: merchantSecret,
    );
  }
}
