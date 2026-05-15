import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/colors.dart';

/// Merchant help center: contact channels, hours, and FAQs.
/// Shown inside the Profile tab when help mode is active (same IndexedStack-style swap as other tabs).
/// Contact rows use copy-to-clipboard (same pattern as Business details).
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _hotlineDisplay = '+251 900 123 456';
  static const String _hotlineRaw = '+251900123456';
  static const String _supportEmail = 'merchant.support@ahadu.et';

  static Future<void> _copy(
    BuildContext context,
    String confirmation,
    String value,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(confirmation, style: GoogleFonts.inter()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeroHeader(),
            const SizedBox(height: 20),
            _HoursCard(),
            const SizedBox(height: 24),
            Text(
              'Contact us',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _ContactTile(
              icon: Icons.phone_in_talk_rounded,
              title: 'Merchant hotline',
              subtitle: _hotlineDisplay,
              detail: 'Tap to copy — paste in your Phone app to call',
              onTap: () => _copy(
                context,
                'Phone number copied',
                _hotlineRaw,
              ),
            ),
            _ContactTile(
              icon: Icons.mail_outline_rounded,
              title: 'Email support',
              subtitle: _supportEmail,
              detail: 'Tap to copy — paste into your mail app',
              onTap: () => _copy(
                context,
                'Email copied',
                _supportEmail,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Common questions',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _FaqPanel(),
            const SizedBox(height: 28),
            Text(
              'Ahadu Merchant · secure merchant tools',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.45,
                color: AppPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppPalette.primary,
            AppPalette.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppPalette.primary.withOpacity(0.38),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'re here to help',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find answers below or reach our merchant team. Copy phone or email and use your preferred app to connect.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: AppPalette.primary.withOpacity(0.95),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support hours',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Monday – Friday · 8:00 – 20:00 EAT\nSaturday · 9:00 – 14:00 EAT\nEmergency hotline available 24/7',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: AppPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppPalette.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppPalette.primary, size: 22),
                ),
                const SizedBox(width: 14),
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: AppPalette.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        detail,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.35,
                          color: AppPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 20,
                    color: AppPalette.textSecondary.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: AppPalette.divider.withOpacity(0.85),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppPalette.primary.withOpacity(0.08),
          highlightColor: AppPalette.primary.withOpacity(0.05),
        ),
        child: Column(
          children: [
            _FaqTile(
              question: 'How quickly are settlements credited?',
              answer:
                  'Settlement timing follows your merchant agreement and bank processing windows. Completed transactions appear in your overview once the acquiring network confirms them — typically within the next business window for card batches.',
            ),
            divider,
            _FaqTile(
              question: 'A transaction shows failed — what should I check?',
              answer:
                  'Confirm the customer had sufficient funds and network coverage. Retry once; if it persists, note the transaction reference from the receipt and contact merchant support with your Merchant ID so we can trace the authorization.',
            ),
            divider,
            _FaqTile(
              question: 'How do I export reports?',
              answer:
                  'Open the Reports tab, choose your date range and format (PDF or spreadsheet), then share or save using your device\'s export options. Large ranges may take a few moments to prepare.',
            ),
            divider,
            _FaqTile(
              question: 'Who can see my settlement account?',
              answer:
                  'Your registered settlement account is tied to your merchant profile for payouts. Only display masked digits in shared screenshots; never share OTPs or banking passwords with anyone claiming to be support.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.fromLTRB(18, 4, 12, 4),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      iconColor: AppPalette.primary,
      collapsedIconColor: AppPalette.textSecondary,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        question,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: AppPalette.textPrimary,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: AppPalette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
