class UPIApp {
  final String androidPackageName;
  final String appName;

  UPIApp({
    required this.androidPackageName,
    required this.appName,
  });

  factory UPIApp.fromJson(Map<String, dynamic> json) {
    return UPIApp(
      androidPackageName: json['androidPackageName'],
      appName: json['appName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'androidPackageName': androidPackageName,
      'appName': appName,
    };
  }

  factory UPIApp.fromMap(Map<String, dynamic> map) {
    return UPIApp(
      androidPackageName: map['androidPackageName'],
      appName: map['appName'],
    );
  }
}
