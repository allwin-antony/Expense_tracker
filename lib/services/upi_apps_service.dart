import 'dart:convert';

import 'package:installed_apps/installed_apps.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import '../types/upi_applications.dart';

class UpiAppsService {
  /// Get all UPI applications as a formatted list
  static List<UpiApplication> getAllUpiApplications() {
    return [
      UpiApplication.googlePay,
      UpiApplication.phonePe,
      UpiApplication.paytm,
      UpiApplication.sbiPay,
      UpiApplication.iMobile,
      UpiApplication.bhim,
      UpiApplication.miPay,
      UpiApplication.amazonPay,
      UpiApplication.trueCaller,
      UpiApplication.airtel,
      UpiApplication.axisPay,
      // Additional common UPI apps
      const UpiApplication(
        androidPackageName: 'com.lcode.allahabadupi',
        appName: 'ALLBANK',
      ),
      const UpiApplication(
        androidPackageName: 'com.olive.andhra.upi',
        appName: 'Andhra UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.aubank.aupay.bhimupi',
        appName: 'AUPay',
      ),
      const UpiApplication(
        androidPackageName: 'com.fisglobal.bandhanupi.app',
        appName: 'Bandhan UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.bankofbaroda.upi',
        appName: 'BOB Pay',
      ),
      const UpiApplication(
        androidPackageName: 'com.infra.boiupi',
        appName: 'BOI UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.infrasofttech.centralbankupi',
        appName: 'Cent UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.lcode.corpupi',
        appName: 'CORP UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.lcode.csbupi',
        appName: 'CSB UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.cub.wallet.gui',
        appName: 'CUB UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.olive.dcb.upi',
        appName: 'DCB UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.lcode.dlbupi',
        appName: 'DLB UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.equitasbank.upi',
        appName: 'Equitas UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.fss.idfcpsp',
        appName: 'IDFC First Bank UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.infrasofttech.indianbankupi',
        appName: 'Indian Bank UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.mgs.induspsp',
        appName: 'IndusPay UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.euronet.iobupi',
        appName: 'IOB UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.finacus.jetpay',
        appName: 'JetPay',
      ),
      const UpiApplication(
        androidPackageName: 'com.fss.jnkpsp',
        appName: 'JK Bank UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.lcode.smartz',
        appName: 'KBL UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.mycompany.kvb',
        appName: 'KVB Upay',
      ),
      const UpiApplication(
        androidPackageName: 'com.upi.federalbank.org.lotza',
        appName: 'LOTZA UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.lvbank.upaay',
        appName: 'LVB Upaay',
      ),
      const UpiApplication(
        androidPackageName: 'com.mgs.obcbank',
        appName: 'Oriental Pay',
      ),
      const UpiApplication(
        androidPackageName: 'com.idbibank.paywiz',
        appName: 'Paywiz V2',
      ),
      const UpiApplication(
        androidPackageName: 'com.fss.pnbpsp',
        appName: 'PNB',
      ),
      const UpiApplication(
        androidPackageName: 'com.mobileware.upipsb',
        appName: 'PSB',
      ),
      const UpiApplication(
        androidPackageName: 'com.rblbank.upi',
        appName: 'RBL Pay',
      ),
      const UpiApplication(
        androidPackageName: 'com.fisglobal.syndicateupi.app',
        appName: 'SyndUPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.lcode.ucoupi',
        appName: 'UCO UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.fss.unbipsp',
        appName: 'United UPI Pay',
      ),
      const UpiApplication(
        androidPackageName: 'com.fss.vijayapsp',
        appName: 'Vijaya UPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.YesBank',
        appName: 'Yes Pay',
      ),
      const UpiApplication(
        androidPackageName: 'com.finopaytech.bpayfino',
        appName: 'BPay',
      ),
      const UpiApplication(
        androidPackageName: 'money.bullet',
        appName: 'Bullet',
      ),
      const UpiApplication(
        androidPackageName: 'com.canarabank.mobility',
        appName: 'Canara Bank App',
      ),
      const UpiApplication(
        androidPackageName: 'in.cointab.app',
        appName: 'Cointab',
      ),
      const UpiApplication(
        androidPackageName: 'com.dreamplug.androidapp',
        appName: 'CRED',
      ),
      const UpiApplication(
        androidPackageName: 'com.cub.plus.gui',
        appName: 'CUB mBank Plus',
      ),
      const UpiApplication(
        androidPackageName: 'com.fss.ippbpsp',
        appName: 'DakPay',
      ),
      const UpiApplication(
        androidPackageName: 'com.dbs.in.digitalbank',
        appName: 'Digibank',
      ),
      const UpiApplication(
        androidPackageName: 'com.fampay.in',
        appName: 'FamPay',
      ),
      const UpiApplication(
        androidPackageName: 'com.freecharge.android',
        appName: 'Freecharge',
      ),
      const UpiApplication(
        androidPackageName: 'com.snapwork.hdfc',
        appName: 'HDFC',
      ),
      const UpiApplication(
        androidPackageName: 'com.mgs.hsbcupi',
        appName: 'HSBC Simply Pay',
      ),
      const UpiApplication(
        androidPackageName: 'com.khaalijeb.inkdrops',
        appName: 'KhaaliJeb',
      ),
      const UpiApplication(
        androidPackageName: 'com.citrus.citruspay',
        appName: 'LazyPay',
      ),
      const UpiApplication(
        androidPackageName: 'com.infrasofttech.mahaupi',
        appName: 'MahaUPI',
      ),
      const UpiApplication(
        androidPackageName: 'com.mobikwik_new',
        appName: 'Mobikwik',
      ),
      const UpiApplication(
        androidPackageName: 'com.microlucid.mudrapay.android',
        appName: 'MudraPay',
      ),
      const UpiApplication(
        androidPackageName: 'com.jio.myjio',
        appName: 'MyJio',
      ),
      const UpiApplication(
        androidPackageName: 'com.omegaon_internet_pvt_ltd',
        appName: 'Omega Pay',
      ),
      const UpiApplication(
        androidPackageName: 'com.enstage.wibmo.hdfc',
        appName: 'PayZapp',
      ),
      const UpiApplication(
        androidPackageName: 'com.rblbank.mobank',
        appName: 'RBL MoBank',
      ),
      const UpiApplication(
        androidPackageName: 'com.realmepay.payments',
        appName: 'Realme PaySa',
      ),
      const UpiApplication(
        androidPackageName: 'com.SIBMobile',
        appName: 'SIB Mirror+',
      ),
      const UpiApplication(
        androidPackageName: 'com.finacus.tranzapp',
        appName: 'Tranzapp',
      ),
      const UpiApplication(
        androidPackageName: 'com.ultracash.payment.customer',
        appName: 'UltraCash',
      ),
      const UpiApplication(
        androidPackageName: 'com.infrasoft.uboi',
        appName: 'U-Mobile',
      ),
      const UpiApplication(
        androidPackageName: 'com.whatsapp',
        appName: 'WhatsApp',
      ),
      const UpiApplication(
        androidPackageName: 'com.atomyes',
        appName: 'Yes Mobile',
      ),
      const UpiApplication(
        androidPackageName: 'com.udma.yuvapay.app',
        appName: 'Yuva Pay',
      ),
      const UpiApplication(androidPackageName: 'money.super.payments', appName: 'super.money')
    ];
  }

  /// Check which UPI apps are installed on the device
  static Future<List<UpiApplication>> getInstalledUpiApps() async {
    try {
      final installedApps = await InstalledApps.getInstalledApps(true);
      final upiApps = getAllUpiApplications();

      final installedUpiApps = <UpiApplication>[];

      for (final app in installedApps) {
        final packageName = app.packageName;
        final matchingApp = upiApps.firstWhere(
          (upiApp) => upiApp.androidPackageName == packageName,
          orElse: () =>
              const UpiApplication(androidPackageName: '', appName: ''),
        );

        if (matchingApp.androidPackageName.isNotEmpty) {
          installedUpiApps.add(
            UpiApplication(
              androidPackageName: matchingApp.androidPackageName,
              iosBundleId: matchingApp.iosBundleId,
              appName: matchingApp.appName,
              discoveryCustomScheme: matchingApp.discoveryCustomScheme,
              iconBase64: app.icon != null ? base64Encode(app.icon!) : null,
            ),
          );
        }
            }

      return installedUpiApps;
    } catch (e) {
      // print('Error getting installed UPI apps: $e');
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
}
