import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/widgets/upi_payment_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => UpiPaymentDialog(
                    onPaymentInitiated: (payment) {},
                  ),
                );
              },
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('UpiPaymentDialog renders 3-mode segmented button', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Open the bottom sheet dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog title is present
    expect(find.text('Initiate UPI Payment'), findsOneWidget);

    // Verify all 3 mode options exist in the SegmentedButton
    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('Direct Pay'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('UpiPaymentDialog Scan QR mode shows scan button by default', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // By default, Scan QR mode should be active
    // Should show the "Open Camera & Scan QR" button
    expect(find.text('Open Camera & Scan QR'), findsOneWidget);

    // Should NOT show direct pay fields
    expect(find.widgetWithText(TextFormField, 'Recipient UPI ID'), findsNothing);
  });

  testWidgets('UpiPaymentDialog Direct Pay mode shows UPI ID fields', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Switch to Direct Pay mode
    await tester.tap(find.text('Direct Pay'));
    await tester.pumpAndSettle();

    // Should show recipient fields
    expect(find.widgetWithText(TextFormField, 'Recipient UPI ID'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Recipient Name (Optional)'), findsOneWidget);

    // Should NOT show scan button
    expect(find.text('Open Camera & Scan QR'), findsNothing);
  });

  testWidgets('UpiPaymentDialog Copy Amount mode hides all recipient fields', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Switch to Copy Amount mode
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    // Should NOT show recipient fields or scan button
    expect(find.widgetWithText(TextFormField, 'Recipient UPI ID'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Recipient Name (Optional)'), findsNothing);
    expect(find.text('Open Camera & Scan QR'), findsNothing);
  });

  testWidgets('UpiPaymentDialog Direct Pay validation rules', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Switch to Direct Pay mode
    await tester.tap(find.text('Direct Pay'));
    await tester.pumpAndSettle();

    // Tap Initiate Payment without filling anything
    await tester.tap(find.text('Initiate Payment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that error messages are shown
    expect(find.text('Please enter an amount'), findsOneWidget);
    expect(find.text('Please enter a UPI ID'), findsOneWidget);

    // Enter invalid UPI ID (without @) and valid amount
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '100');
    await tester.enterText(find.widgetWithText(TextFormField, 'Recipient UPI ID'), 'invalidupi');
    await tester.tap(find.text('Initiate Payment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify invalid UPI ID error message
    expect(find.text('Please enter a valid UPI ID (e.g. user@bank)'), findsOneWidget);

    // Enter valid UPI ID
    await tester.enterText(find.widgetWithText(TextFormField, 'Recipient UPI ID'), 'test@upi');
    await tester.tap(find.text('Initiate Payment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the validation errors are gone
    expect(find.text('Please enter a valid UPI ID (e.g. user@bank)'), findsNothing);
  });
}
