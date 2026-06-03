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

  testWidgets('UpiPaymentDialog UI and toggle behavior', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Open the bottom sheet dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog title is present
    expect(find.text('Initiate UPI Payment'), findsOneWidget);

    // Verify Direct Pay and Copy Amount options exist in the SegmentedButton
    expect(find.text('Direct Pay'), findsOneWidget);
    expect(find.text('Copy Amount'), findsOneWidget);

    // By default, Direct Pay should be active, showing the Recipient UPI ID and Recipient Name fields
    expect(find.widgetWithText(TextFormField, 'Recipient UPI ID'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Recipient Name (Optional)'), findsOneWidget);

    // Switch to Copy Amount mode
    await tester.tap(find.text('Copy Amount'));
    await tester.pumpAndSettle();

    // The recipient fields should not be visible anymore
    expect(find.widgetWithText(TextFormField, 'Recipient UPI ID'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Recipient Name (Optional)'), findsNothing);

    // Switch back to Direct Pay mode
    await tester.tap(find.text('Direct Pay'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Recipient UPI ID'), findsOneWidget);
  });

  testWidgets('UpiPaymentDialog validation rules', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Open the bottom sheet dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Tap Initiate Payment without filling anything
    await tester.tap(find.text('Initiate Payment'));
    await tester.pumpAndSettle();

    // Verify that error messages are shown
    expect(find.text('Please enter an amount'), findsOneWidget);
    expect(find.text('Please enter a UPI ID'), findsOneWidget);

    // Enter invalid UPI ID (without @) and valid amount
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '100');
    await tester.enterText(find.widgetWithText(TextFormField, 'Recipient UPI ID'), 'invalidupi');
    await tester.tap(find.text('Initiate Payment'));
    await tester.pumpAndSettle();

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
