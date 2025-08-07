import 'dart:io' as io;

/// Represents a UPI payment application.
///
/// Stores unique identifiers for a UPI payment application across Android and
/// iOS. On iOS, the information required to discover the app is also stored.
class UpiApplication {
  /// Value of `package` attribute in `manifest` tag in `AndroidManifest.xml`
  /// of Android version of a UPI app. Serves as the identifier on Android.
  final String androidPackageName;

  /// Value of `CFBundleIdentifier` property in `Info.plist` of the iOS version
  /// of a UPI app. Serves as the identifier on iOS.
  final String? iosBundleId;

  /// Friendly and typically a shorter version of a UPI app's name.
  final String appName;


  /// The Application Icon
  final String? iconBase64;
  /// As per the [UPI Linking Specification](https://www.npci.org.in/sites/default/files/UPI%20Linking%20Specs_ver%201.6.pdf),
  /// each iOS UPI app that can be invoked directly for UPI payment must
  /// implement the custom scheme `upi`. For the purpose of discovering an iOS
  /// UPI app without ambiguity, we need any other unique custom scheme that the
  /// app implements. Any such unique custom scheme, if available, is stored in
  /// this attribute to be used for discovering this app.
  final String? discoveryCustomScheme;

  const UpiApplication({
    required this.androidPackageName,
    this.iosBundleId,
    required this.appName,
    this.discoveryCustomScheme,
    this.iconBase64, 
  });

  /// Google Pay
  static const googlePay = UpiApplication(
    androidPackageName: 'com.google.android.apps.nbu.paisa.user',
    iosBundleId: 'com.google.paisa',
    appName: 'Google Pay',
    discoveryCustomScheme: 'gpay',
  );

  /// PhonePe
  static const phonePe = UpiApplication(
    androidPackageName: 'com.phonepe.app',
    iosBundleId: 'com.phonepe.PhonePeApp',
    appName: 'PhonePe',
    discoveryCustomScheme: 'phonepe',
  );

  /// Paytm
  static const paytm = UpiApplication(
    androidPackageName: 'net.one97.paytm',
    iosBundleId: 'com.one97.paytm',
    appName: 'Paytm',
    discoveryCustomScheme: 'paytm',
  );

  /// BHIM SBI Pay (State Bank of India's BHIM UPI app)
  static const sbiPay = UpiApplication(
    androidPackageName: 'com.sbi.upi',
    iosBundleId: 'com.sbi.upi',
    appName: 'SBI Pay',
  );

  /// iMobile by ICICI
  static const iMobile = UpiApplication(
    androidPackageName: 'com.csam.icici.bank.imobile',
    iosBundleId: 'com.icicibank.imobile',
    appName: 'iMobile',
    discoveryCustomScheme: 'imobileapp',
  );

  /// BHIM from NPCI
  static const bhim = UpiApplication(
    androidPackageName: 'in.org.npci.upiapp',
    iosBundleId: 'in.org.npci.ios.upiapp',
    appName: 'BHIM',
    discoveryCustomScheme: 'BHIM',
  );

  /// MiPay from Xiomi
  static const miPay = UpiApplication(
    androidPackageName: 'com.mipay.in.wallet',
    appName: 'Mi Pay',
  );

  /// Amazon (amazonPay signifies that the package uses the payment module)
  static const amazonPay = UpiApplication(
    androidPackageName: 'in.amazon.mShop.android.shopping',
    iosBundleId: 'com.amazon.AmazonIN',
    appName: 'Amazon Pay',
    discoveryCustomScheme: 'com.amazon.mobile.shopping',
  );

  /// Truecaller
  static const trueCaller = UpiApplication(
    androidPackageName: 'com.truecaller',
    iosBundleId: 'com.truesoftware.TrueCallerOther',
    appName: 'Truecaller',
    discoveryCustomScheme: 'truecaller',
  );

  /// Airtel Thanks
  static const airtel = UpiApplication(
    androidPackageName: 'com.myairtelapp',
    iosBundleId: 'com.BhartiMobile.myairtel',
    appName: 'Airtel',
    discoveryCustomScheme: 'myairtel',
  );

  /// BHIM Axis Pay
  static const axisPay = UpiApplication(
    androidPackageName: 'com.upi.axispay',
    iosBundleId: 'comaxisbank.axispay',
    appName: 'Axis Pay',
  );

  /// Returns the platform-specific package name.
  @override
  String toString() {
    return io.Platform.isAndroid ? androidPackageName : iosBundleId!;
  }

  /// Returns app's name.
  String getAppName() {
    return appName;
  }
}

/// List of all UPI applications
class UpiApplications {
  static const List<UpiApplication> all = [
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
  ];
}
