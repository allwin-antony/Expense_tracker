import 'dart:convert';
import 'dart:io' as io;
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:sqflite/sqflite.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/upi_app.dart';
import '../types/upi_applications.dart';
import 'database_service.dart';
import 'config_fetch_service.dart';

class UPIAppsService {
  static final UPIAppsService instance = UPIAppsService._constructor();
  UPIAppsService._constructor();

  // Table name for UPI apps
  static const String _tableName = 'upi_apps';

  // Initialize UPI apps table
  Future<void> _initUPITable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        androidPackageName TEXT NOT NULL UNIQUE,
        appName TEXT NOT NULL
      )
    ''');
  }

  // Fetch and save UPI apps on startup
  Future<void> fetchAndSaveUPIApps() async {
    try {
      final db = await DatabaseService.instance.database;
      await _initUPITable(db);

      final upiApps = await ConfigFetchService.fetchUPIApps();

      if (upiApps.isNotEmpty) {
        await _saveUPIAppsToDatabase(upiApps);
        print('Successfully saved ${upiApps.length} UPI apps to database');
      }
    } catch (e) {
      print('Error fetching/saving UPI apps: $e');
      // Ignore error as per requirement
    }
  }

  // Save UPI apps to database
  Future<void> _saveUPIAppsToDatabase(List<dynamic> upiApps) async {
    final db = await DatabaseService.instance.database;

    // Clear existing data
    await db.delete(_tableName);
    // Insert new data
    for (final app in upiApps) {
      final upiApp = UPIApp.fromJson(app);
      await db.insert(
        _tableName,
        upiApp.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Get all UPI apps from database
  Future<List<UPIApp>> getAllUPIApps() async {
    try {
      final db = await DatabaseService.instance.database;
      final data = await db.query(_tableName);
      return data.map((e) => UPIApp.fromMap(e)).toList();
    } catch (e) {
      print('Error getting UPI apps from database: $e');
      return [];
    }
  }

  // Clear UPI apps table
  Future<void> clearUPIApps() async {
    try {
      final db = await DatabaseService.instance.database;
      await db.delete(_tableName);
    } catch (e) {
      print('Error clearing UPI apps: $e');
    }
  }

  // Get installed UPI apps using installed_apps package
  static Future<List<UpiApplication>> getInstalledUpiApps() async {
    try {
      // Get all installed apps
      final installedApps = await InstalledApps.getInstalledApps(true, true);

      // Get all UPI apps from our database
      var allUpiApps = await UPIAppsService.instance.getAllUPIApps();

      // Fallback if local database is empty due to config URL issues
      if (allUpiApps.isEmpty) {
        allUpiApps = UpiApplications.all
            .map((app) => UPIApp(
                  androidPackageName: app.androidPackageName,
                  appName: app.appName,
                ))
            .toList();
      }

      final installedUpiApps = installedApps
          .where((allApp) {
            print("${allApp.name} ${allApp.packageName}");
            return allUpiApps.any((upiApp) {
              return upiApp.androidPackageName == allApp.packageName;
            });
          })
          .map((allApp) {
            // Convert icon (Uint8List?) to base64 String
            String? iconBase64;
            if (allApp.icon != null) {
              iconBase64 = base64Encode(allApp.icon!);
            }
            return UpiApplication(
              androidPackageName: allApp.packageName,
              appName: allApp.name,
              iconBase64: iconBase64,
            );
          })
          .toList();
      return installedUpiApps;
    } catch (e) {
      print('Error getting installed UPI apps: $e');
      return [];
    }
  }

  /// Launch a UPI application
  static Future<bool> launchUpiApp(UpiApplication app) async {
    try {
      final result = await LaunchApp.openApp(
        androidPackageName: app.androidPackageName,
        iosUrlScheme: app.iosBundleId,
      );
      return result == 1;
    } catch (e) {
      // print('Error launching UPI app: $e');
      return false;
    }
  }

  /// Launch a custom UPI deep link using android_intent_plus for Android
  /// or fallback to url_launcher / package launcher if that fails.
  static Future<bool> launchUpiUrl(UpiApplication app, String upiUrl) async {
    try {
      if (io.Platform.isAndroid) {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: upiUrl,
          package: app.androidPackageName,
        );
        await intent.launch();
        return true;
      } else {
        final uri = Uri.parse(upiUrl);
        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      return false;
    } catch (e) {
      print('Error launching package-specific intent: $e. Falling back...');
      // Fallback: Copy clipboard + launch basic app package
      return await launchUpiApp(app);
    }
  }
}
