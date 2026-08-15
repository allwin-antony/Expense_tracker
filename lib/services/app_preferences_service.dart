import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static final AppPreferencesService instance = AppPreferencesService._internal();

  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyObscureAmounts = 'obscure_amounts';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keySilentNotifications = 'silent_notifications';

  SharedPreferences? _prefs;

  final ValueNotifier<bool> obscureNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> biometricNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> notificationsNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> silentNotificationsNotifier = ValueNotifier<bool>(false);

  AppPreferencesService._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    obscureNotifier.value = isObscureAmountsEnabled;
    biometricNotifier.value = isBiometricEnabled;
    notificationsNotifier.value = areNotificationsEnabled;
    silentNotificationsNotifier.value = isSilentNotificationEnabled;
  }

  bool get isBiometricEnabled {
    return _prefs?.getBool(_keyBiometricEnabled) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs?.setBool(_keyBiometricEnabled, enabled);
    biometricNotifier.value = enabled;
  }

  bool get isObscureAmountsEnabled {
    return _prefs?.getBool(_keyObscureAmounts) ?? false;
  }

  Future<void> setObscureAmountsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyObscureAmounts, enabled);
    obscureNotifier.value = enabled;
  }

  Future<void> toggleObscureAmounts() async {
    final next = !isObscureAmountsEnabled;
    await setObscureAmountsEnabled(next);
  }

  bool get areNotificationsEnabled {
    return _prefs?.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyNotificationsEnabled, enabled);
    notificationsNotifier.value = enabled;
  }

  bool get isSilentNotificationEnabled {
    return _prefs?.getBool(_keySilentNotifications) ?? false;
  }

  Future<void> setSilentNotificationEnabled(bool enabled) async {
    await _prefs?.setBool(_keySilentNotifications, enabled);
    silentNotificationsNotifier.value = enabled;
  }
}
