/// Snapshot of merchant identity returned by the validate endpoint.
class MerchantProfile {
  const MerchantProfile({
    required this.fullName,
    required this.accountNumber,
    required this.alertPhones,
  });

  final String fullName;
  final String accountNumber;
  final List<String> alertPhones;

  static const MerchantProfile empty = MerchantProfile(
    fullName: '',
    accountNumber: '',
    alertPhones: [],
  );
}
