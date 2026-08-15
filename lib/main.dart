import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/app_preferences_service.dart';
import 'parser/ml/fasttext_engine.dart';
import 'parser/merchant_categorizer.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences
  await AppPreferencesService.instance.init();

  // Initialize database
  await DatabaseService.instance.database;

  // Load custom user merchant categorization rules
  final customRules = await DatabaseService.instance.getAllCustomMerchantRules();
  MerchantCategorizer.loadUserRules(customRules);

  // Initialize interactive notification service
  await NotificationService.instance.initialize();

  // Initialize on-device FastText AI classifier
  await FastTextEngine.instance.initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const BudgetTrackerApp());
}

class BudgetTrackerApp extends StatelessWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Custom base text theme using GoogleFonts Inter
    final lightTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    final darkTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Tracker',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Vibrant indigo blue
          brightness: Brightness.light,
          primary: const Color(0xFF2563EB),
          surface: Colors.white,
          surfaceContainerHighest: const Color(0xFFF1F5F9),
        ),
        textTheme: lightTextTheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFFF8FAFC),
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: GoogleFonts.inter(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F172A),
          contentTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          actionTextColor: const Color(0xFF60A5FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF334155), width: 0.5),
          ),
          elevation: 6,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F17),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
          primary: const Color(0xFF3B82F6),
          surface: const Color(0xFF131B2A),
          surfaceContainerHighest: const Color(0xFF1E293B),
        ),
        textTheme: darkTextTheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFF0B0F17),
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF131B2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          contentTextStyle: GoogleFonts.inter(
            color: const Color(0xFFF8FAFC),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          actionTextColor: const Color(0xFF93C5FD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}
