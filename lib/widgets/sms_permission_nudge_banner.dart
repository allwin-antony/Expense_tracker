import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'sms_permission_disclosure_dialog.dart';

class SmsPermissionNudgeBanner extends StatefulWidget {
  final VoidCallback? onPermissionGranted;

  const SmsPermissionNudgeBanner({
    super.key,
    this.onPermissionGranted,
  });

  @override
  State<SmsPermissionNudgeBanner> createState() => _SmsPermissionNudgeBannerState();
}

class _SmsPermissionNudgeBannerState extends State<SmsPermissionNudgeBanner> {
  bool _isGranted = true;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.sms.status;
    if (mounted) {
      setState(() {
        _isGranted = status.isGranted;
      });
    }
  }

  Future<void> _handleEnablePermission() async {
    HapticFeedback.mediumImpact();
    final status = await Permission.sms.status;

    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      _showSettingsRedirectDialog();
    } else {
      final granted = await SmsPermissionDisclosureDialog.showDisclosureAndRequest(context);
      if (granted) {
        setState(() => _isGranted = true);
        widget.onPermissionGranted?.call();
      } else {
        final recheckStatus = await Permission.sms.status;
        if (recheckStatus.isPermanentlyDenied && mounted) {
          _showSettingsRedirectDialog();
        }
      }
    }
  }

  void _showSettingsRedirectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.settings_suggest_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Text('SMS Permission Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'SMS auto-sync is the core feature of Expense Tracker. SMS permission has been disabled in system settings.\n\nWould you like to open Settings to enable it now?',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Now'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open Settings'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isGranted || _isDismissed) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.3 : 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                color: Color(0xFF2563EB),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SMS Auto-Sync Disabled',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Grant SMS access to automatically track bank & UPI transactions.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _handleEnablePermission,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Enable Auto-Sync',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              onPressed: () {
                setState(() => _isDismissed = true);
              },
            ),
          ],
        ),
      ),
    );
  }
}
