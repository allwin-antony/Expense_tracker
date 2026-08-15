import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_preferences_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/database_service.dart';
import '../widgets/onboarding_tour_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBiometricSupported = false;
  int _customRulesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    final isAvailable = await BiometricAuthService.instance.isBiometricAvailable();
    final rules = await DatabaseService.instance.getAllCustomMerchantRules();

    if (mounted) {
      setState(() {
        _isBiometricSupported = isAvailable;
        _customRulesCount = rules.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _onToggleBiometric(bool value) async {
    HapticFeedback.selectionClick();
    final reason = value
        ? 'Authenticate to enable biometric app lock'
        : 'Authenticate to disable biometric app lock';

    final success = await BiometricAuthService.instance.authenticate(
      reason: reason,
    );

    if (success) {
      await AppPreferencesService.instance.setBiometricEnabled(value);
      if (mounted) setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Biometric verification failed. Lock not enabled.'
                  : 'Biometric verification failed. Lock remains active.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _onToggleObscure(bool value) async {
    HapticFeedback.selectionClick();
    await AppPreferencesService.instance.setObscureAmountsEnabled(value);
    if (mounted) setState(() {});
  }

  Future<void> _onToggleNotifications(bool value) async {
    HapticFeedback.selectionClick();
    await AppPreferencesService.instance.setNotificationsEnabled(value);
    if (mounted) setState(() {});
  }

  Future<void> _onToggleSilentNotifications(bool value) async {
    HapticFeedback.selectionClick();
    await AppPreferencesService.instance.setSilentNotificationEnabled(value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // SECTION: Security & Privacy
                _buildSectionHeader(context, 'SECURITY & PRIVACY'),
                const SizedBox(height: 8),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Column(
                    children: [
                      // Biometric Lock
                      SwitchListTile(
                        value: AppPreferencesService.instance.isBiometricEnabled,
                        onChanged: _isBiometricSupported ? _onToggleBiometric : null,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF2563EB), size: 22),
                        ),
                        title: const Text(
                          'Biometric App Lock',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                        ),
                        subtitle: Text(
                          _isBiometricSupported
                              ? 'Require fingerprint or face unlock when opening app'
                              : 'Biometric unlock not available on this device',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

                      // Hide Amounts (Public Mode)
                      SwitchListTile(
                        value: AppPreferencesService.instance.isObscureAmountsEnabled,
                        onChanged: _onToggleObscure,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.visibility_off_rounded, color: Color(0xFF8B5CF6), size: 22),
                        ),
                        title: const Text(
                          'Public Privacy Mode',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                        ),
                        subtitle: Text(
                          'Hide balance totals & amounts (₹ ••••••) in public',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

                      // Transaction Notifications
                      SwitchListTile(
                        value: AppPreferencesService.instance.areNotificationsEnabled,
                        onChanged: _onToggleNotifications,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF06B6D4), size: 22),
                        ),
                        title: const Text(
                          'Transaction Alerts',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                        ),
                        subtitle: Text(
                          'Show alerts when SMS transactions are captured',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),

                      if (AppPreferencesService.instance.areNotificationsEnabled) ...[
                        Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        SwitchListTile(
                          value: AppPreferencesService.instance.isSilentNotificationEnabled,
                          onChanged: _onToggleSilentNotifications,
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64748B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notifications_paused_rounded, color: Color(0xFF64748B), size: 22),
                          ),
                          title: const Text(
                            'Silent Notifications',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                          ),
                          subtitle: Text(
                            'Deliver quietly to notification tray without sound or pop-up',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION: Smart Categorization & Rules
                _buildSectionHeader(context, 'SMART CATEGORIZATION'),
                const SizedBox(height: 8),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 22),
                        ),
                        title: const Text('Smart SMS Categorizer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                        subtitle: const Text('Automatically parses Indian bank & UPI SMS', style: TextStyle(fontSize: 11.5)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Color(0xFFF59E0B), size: 22),
                        ),
                        title: const Text('Learned Merchant Rules', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                        subtitle: Text('$_customRulesCount custom rules saved for auto-categorization', style: const TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SECTION: About & App Info
                _buildSectionHeader(context, 'ABOUT APP'),
                const SizedBox(height: 8),

                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.explore_outlined, size: 20, color: Color(0xFF2563EB)),
                        title: const Text('Replay App Tour', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                        subtitle: const Text('Interactive walkthrough of features', style: TextStyle(fontSize: 11.5)),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          OnboardingTourSheet.show(context);
                        },
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      const ListTile(
                        leading: Icon(Icons.shield_outlined, size: 20, color: Color(0xFF10B981)),
                        title: Text('Privacy Guarantee', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                        subtitle: Text('100% Offline & Private • Zero Cloud Servers', style: TextStyle(fontSize: 11.5)),
                      ),
                      Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      const ListTile(
                        leading: Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF64748B)),
                        title: Text('Version', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                        trailing: Text('1.1.0+2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
