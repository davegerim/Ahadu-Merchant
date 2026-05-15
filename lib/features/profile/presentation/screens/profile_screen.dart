import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/colors.dart';
import '../../../auth/domain/models/merchant_profile.dart';
import '../../../auth/presentation/providers/merchant_session_provider.dart';
import '../providers/profile_subview_provider.dart';
import 'help_support_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'AM';
    if (parts.length == 1) {
      final s = parts[0];
      if (s.length >= 2) return s.substring(0, 2).toUpperCase();
      return s.toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static String _displayName(MerchantProfile profile) {
    final n = profile.fullName.trim();
    if (n.isNotEmpty) return n;
    return 'Ahadu Merchant';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(merchantSessionProvider);
    final profile = session?.profile ?? MerchantProfile.empty;
    final displayName = _displayName(profile);
    final merchantId = session?.code.trim();
    final subtitle = merchantId != null && merchantId.isNotEmpty
        ? 'Merchant ID: $merchantId'
        : 'Merchant ID: —';
    final subview = ref.watch(profileSubviewProvider);

    if (subview == ProfileSubview.helpSupport) {
      return Scaffold(
        backgroundColor: AppPalette.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                ref.read(profileSubviewProvider.notifier).showMain(),
          ),
          title: const Text('Help & Support'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: const HelpSupportScreen(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppPalette.primary,
                  child: Text(
                    _initials(profile.fullName),
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                _buildProfileMenu(
                  icon: Icons.storefront,
                  title: 'Business Details',
                  subtitle: profile.accountNumber.trim().isNotEmpty
                      ? 'Account · ${_maskAccountTail(profile.accountNumber)}'
                      : 'Account & alert contacts',
                  onTap: () => _openBusinessDetailsSheet(context, profile),
                ),
                _buildProfileMenu(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'FAQs, hours & contact',
                  onTap: () =>
                      ref.read(profileSubviewProvider.notifier).showHelp(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: AppPalette.error),
                    label: Text(
                      'Log Out',
                      style: GoogleFonts.inter(
                        color: AppPalette.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppPalette.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows last digits only on the menu hint — full number appears in the sheet.
  static String _maskAccountTail(String accountNumber) {
    final digits = accountNumber.replaceAll(RegExp(r'\s'), '');
    if (digits.length <= 4) return digits;
    return '··· ${digits.substring(digits.length - 4)}';
  }

  static void _openBusinessDetailsSheet(
    BuildContext context,
    MerchantProfile profile,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + bottomInset,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppPalette.divider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppPalette.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: AppPalette.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business details',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppPalette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Information from your merchant registration',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.35,
                                color: AppPalette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _BusinessDetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetSectionLabel('Registered name'),
                        const SizedBox(height: 8),
                        Text(
                          profile.fullName.trim().isNotEmpty
                              ? profile.fullName.trim()
                              : '—',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BusinessDetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _sheetSectionLabel('Settlement account'),
                            ),
                            if (profile.accountNumber.trim().isNotEmpty)
                              IconButton(
                                tooltip: 'Copy account number',
                                icon: Icon(
                                  Icons.copy_rounded,
                                  size: 22,
                                  color: AppPalette.primary.withOpacity(0.85),
                                ),
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: profile.accountNumber.trim(),
                                    ),
                                  );
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      content: Text(
                                        'Account number copied',
                                        style: GoogleFonts.inter(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          profile.accountNumber.trim().isNotEmpty
                              ? _formatAccountDisplay(profile.accountNumber)
                              : '—',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppPalette.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BusinessDetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetSectionLabel('Alert phone numbers'),
                        const SizedBox(height: 12),
                        if (profile.alertPhones.isEmpty)
                          Text(
                            'No alert numbers on file.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppPalette.textSecondary,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final phone in profile.alertPhones)
                                _AlertPhoneChip(phone: phone),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatAccountDisplay(String raw) {
    final digits = raw.replaceAll(RegExp(r'\s'), '');
    if (digits.length <= 4) return raw.trim();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  static Widget _sheetSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppPalette.textSecondary,
      ),
    );
  }

  Widget _buildProfileMenu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppPalette.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppPalette.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppPalette.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppPalette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessDetailCard extends StatelessWidget {
  const _BusinessDetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.divider),
      ),
      child: child,
    );
  }
}

class _AlertPhoneChip extends StatelessWidget {
  const _AlertPhoneChip({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final cleaned = phone.trim();
    return Material(
      color: AppPalette.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: cleaned.isEmpty
            ? null
            : () async {
                await Clipboard.setData(ClipboardData(text: cleaned));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: Text('Phone copied', style: GoogleFonts.inter()),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 18,
                color: AppPalette.primary.withOpacity(0.9),
              ),
              const SizedBox(width: 8),
              Text(
                cleaned.isEmpty ? '—' : cleaned,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
