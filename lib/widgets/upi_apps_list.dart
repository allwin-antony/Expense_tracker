import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/upi_apps_service.dart';
import '../types/upi_applications.dart';

class UpiAppsList extends StatefulWidget {
  const UpiAppsList({Key? key}) : super(key: key);

  @override
  State<UpiAppsList> createState() => _UpiAppsListState();
}

class _UpiAppsListState extends State<UpiAppsList> {
  late Future<List<UpiApplication>> _installedAppsFuture;

  @override
  void initState() {
    super.initState();
    _installedAppsFuture = UpiAppsService.getInstalledUpiApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Available UPI Payment Apps',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          FutureBuilder<List<UpiApplication>>(
            future: _installedAppsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading UPI apps'));
              }

              final apps = snapshot.data ?? [];

              if (apps.isEmpty) {
                return const Center(
                  child: Text('No UPI apps found on this device'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  final app = apps[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading:
                          (app.iconBase64 != null && app.iconBase64!.isNotEmpty)
                          ? Image.memory(
                              base64Decode(app.iconBase64!),
                              width: 40,
                              height: 40,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.payment),
                            )
                          : const Icon(Icons.payment),
                      title: Text(app.getAppName()),
                      subtitle: Text(app.androidPackageName),
                      trailing: const Icon(Icons.launch),
                      onTap: () async {
                        final success = await UpiAppsService.launchUpiApp(app);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not launch ${app.getAppName()}',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
