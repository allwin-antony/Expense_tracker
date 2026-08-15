import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static final BiometricAuthService instance = BiometricAuthService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;

  bool get isAuthenticating => _isAuthenticating;

  BiometricAuthService._internal();

  /// Check if hardware supports biometrics and is configured
  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  /// Request fingerprint / face / PIN authentication
  Future<bool> authenticate({String reason = 'Please authenticate to unlock Expense Tracker'}) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      _isAuthenticating = true;
      try {
        final result = await _auth.authenticate(
          localizedReason: reason,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false, // Allows device PIN fallback if biometric fails
            useErrorDialogs: true,
          ),
        );
        return result;
      } finally {
        // Small delay to allow OS lifecycle transitions (paused -> resumed) to settle
        await Future.delayed(const Duration(milliseconds: 600));
        _isAuthenticating = false;
      }
    } on PlatformException catch (_) {
      _isAuthenticating = false;
      return false;
    } catch (_) {
      _isAuthenticating = false;
      return false;
    }
  }
}
