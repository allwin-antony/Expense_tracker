import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/biometric_auth_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _triggerBiometricAuth();
  }

  Future<void> _triggerBiometricAuth() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final success = await BiometricAuthService.instance.authenticate(
      reason: 'Authenticate to access Expense Tracker',
    );

    if (mounted) {
      setState(() => _isAuthenticating = false);
      if (success) {
        HapticFeedback.mediumImpact();
        widget.onUnlocked();
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _errorMessage = 'Authentication failed. Please tap to try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Security Shield Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.22 : 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 52,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App Title
                Text(
                  'Expense Tracker Locked',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Your financial data is protected by biometric security.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 36),

                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Unlock Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _isAuthenticating ? null : _triggerBiometricAuth,
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_open_rounded, size: 20),
                    label: Text(
                      _isAuthenticating ? 'Authenticating...' : 'Unlock Dashboard',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
}
