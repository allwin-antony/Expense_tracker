import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/widgets/end_of_list_sync_prompt.dart';

void main() {
  group('EndOfListSyncPrompt Widget Tests', () {
    testWidgets('Renders rich prompt card when user history is limited (<= 3 months)', (tester) async {
      bool syncTapped = false;
      final recentDate = DateTime.now().subtract(const Duration(days: 30));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EndOfListSyncPrompt(
              totalCount: 25,
              earliestDate: recentDate,
              onSyncTap: () {
                syncTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Looking for older transactions?'), findsOneWidget);
      expect(find.text('Sync More Time Ranges'), findsOneWidget);

      await tester.tap(find.text('Sync More Time Ranges'));
      await tester.pumpAndSettle();

      expect(syncTapped, isTrue);
    });

    testWidgets('Renders clean footer with action button when history spans over 4 months', (tester) async {
      bool syncTapped = false;
      final oldDate = DateTime.now().subtract(const Duration(days: 180));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EndOfListSyncPrompt(
              totalCount: 150,
              earliestDate: oldDate,
              onSyncTap: () {
                syncTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('All 150 transactions loaded'), findsOneWidget);
      expect(find.text('Sync older time ranges'), findsOneWidget);

      await tester.tap(find.text('Sync older time ranges'));
      await tester.pumpAndSettle();

      expect(syncTapped, isTrue);
    });
  });
}
