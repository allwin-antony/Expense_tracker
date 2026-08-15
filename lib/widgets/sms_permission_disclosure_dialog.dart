import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/sms_sync_service.dart';

class SmsPermissionDisclosureDialog extends StatelessWidget {
  const SmsPermissionDisclosureDialog({super.key});

  /// Static helper: Displays the Prominent Disclosure before triggering the OS runtime permission prompt.
  /// Fully complies with Google Play SMS & Call Log Permissions Policy.
  static Future<bool> showDisclosureAndRequest(BuildContext context) async {
    final status = await Permission.sms.status;
    if (status.isGranted) return true;

    if (!context.mounted) return false;

    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const SmsPermissionDisclosureDialog(),
    );

    if (agreed == true) {
      final granted = await SmsSyncService.instance.requestPermissions();
      if (granted) {
        // Automatically sync all transactions for the entire current month upon permission grant
        await SmsSyncService.instance.syncThisMonth();
      }
      return granted;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.25 : 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'SMS & Privacy Disclosure',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To automate your expense tracking without manual entry, Expense Tracker requires access to your SMS messages under Google Play\'s financial tracking policy.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 16),

            // Feature 1: What is accessed
            _buildDisclosureItem(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF16A34A),
              title: 'Transactional Alerts Only',
              description: 'We only read automated debit, credit, and UPI alerts from verified bank and merchant sender IDs.',
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // Feature 2: What is filtered
            _buildDisclosureItem(
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFFEAB308),
              title: 'Zero Personal Messages or OTPs',
              description: 'Personal conversations, authentication OTPs, and promotional ads are ignored and never logged.',
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // Feature 3: 100% On-Device Privacy
            _buildDisclosureItem(
              icon: Icons.phonelink_lock_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: '100% Local & Private',
              description: 'All analysis and transactions stay securely on your device. Your data is never sent to any cloud servers or shared.',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can revoke SMS permissions at any time in device settings.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop(false);
          },
          child: Text(
            'Not Now',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(true);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: const Text(
            'Agree & Continue',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildDisclosureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
