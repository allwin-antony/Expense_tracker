import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/services/app_preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPreferencesService & Privacy Notifier Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'biometric_enabled': false,
        'obscure_amounts': false,
      });
      await AppPreferencesService.instance.init();
    });

    test('Initializes preferences with default values accurately', () {
      expect(AppPreferencesService.instance.isBiometricEnabled, isFalse);
      expect(AppPreferencesService.instance.isObscureAmountsEnabled, isFalse);
      expect(AppPreferencesService.instance.obscureNotifier.value, isFalse);
    });

    test('Toggles obscure amounts and updates ValueNotifier reactively', () async {
      int notifyCount = 0;
      AppPreferencesService.instance.obscureNotifier.addListener(() {
        notifyCount++;
      });

      await AppPreferencesService.instance.toggleObscureAmounts();

      expect(AppPreferencesService.instance.isObscureAmountsEnabled, isTrue);
      expect(AppPreferencesService.instance.obscureNotifier.value, isTrue);
      expect(notifyCount, equals(1));

      await AppPreferencesService.instance.toggleObscureAmounts();

      expect(AppPreferencesService.instance.isObscureAmountsEnabled, isFalse);
      expect(AppPreferencesService.instance.obscureNotifier.value, isFalse);
      expect(notifyCount, equals(2));
    });

    test('Toggles notification preference setting correctly', () async {
      expect(AppPreferencesService.instance.areNotificationsEnabled, isTrue);

      await AppPreferencesService.instance.setNotificationsEnabled(false);
      expect(AppPreferencesService.instance.areNotificationsEnabled, isFalse);
      expect(AppPreferencesService.instance.notificationsNotifier.value, isFalse);

      await AppPreferencesService.instance.setNotificationsEnabled(true);
      expect(AppPreferencesService.instance.areNotificationsEnabled, isTrue);
      expect(AppPreferencesService.instance.notificationsNotifier.value, isTrue);
    });

    test('Toggles silent notification preference setting correctly', () async {
      expect(AppPreferencesService.instance.isSilentNotificationEnabled, isFalse);

      await AppPreferencesService.instance.setSilentNotificationEnabled(true);
      expect(AppPreferencesService.instance.isSilentNotificationEnabled, isTrue);
      expect(AppPreferencesService.instance.silentNotificationsNotifier.value, isTrue);

      await AppPreferencesService.instance.setSilentNotificationEnabled(false);
      expect(AppPreferencesService.instance.isSilentNotificationEnabled, isFalse);
      expect(AppPreferencesService.instance.silentNotificationsNotifier.value, isFalse);
    });

    test('Tracks onboarding completed status accurately', () async {
      expect(AppPreferencesService.instance.hasCompletedOnboarding, isFalse);

      await AppPreferencesService.instance.setHasCompletedOnboarding(true);
      expect(AppPreferencesService.instance.hasCompletedOnboarding, isTrue);

      await AppPreferencesService.instance.setHasCompletedOnboarding(false);
      expect(AppPreferencesService.instance.hasCompletedOnboarding, isFalse);
    });
  });
}
