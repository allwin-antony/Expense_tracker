import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/app_preferences_service.dart';
import 'package:expense_tracker/models/payment.dart';
import 'package:expense_tracker/widgets/payment_card.dart';
import 'package:intl/intl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('History Top Summary Privacy Mode Tests', () {
    testWidgets('PaymentCard displays individual transaction amounts', (tester) async {
      final payment = Payment(
        id: 1,
        amount: 2540.50,
        type: TransactionType.debit,
        category: 'Food',
        date: DateTime.now(),
        description: 'Swiggy Dinner',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentCard(payment: payment),
          ),
        ),
      );

      expect(find.text('- ₹2,540.50'), findsOneWidget);
    });

    testWidgets('Top summary total values obscure in Privacy Mode', (tester) async {
      final income = 45000.0;
      final expense = 12500.0;

      Widget buildTopSummary() {
        return MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: AppPreferencesService.instance.obscureNotifier,
              builder: (context, isObscured, _) {
                return Row(
                  children: [
                    Text(
                      isObscured
                          ? '+₹ ••••••  '
                          : '+₹${NumberFormat('#,##,###').format(income)}  ',
                      style: const TextStyle(color: Color(0xFF16A34A)),
                    ),
                    Text(
                      isObscured
                          ? '-₹ ••••••'
                          : '-₹${NumberFormat('#,##,###').format(expense)}',
                      style: const TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }

      // Initial state: Not obscured
      AppPreferencesService.instance.obscureNotifier.value = false;
      await tester.pumpWidget(buildTopSummary());

      expect(find.text('+₹45,000  '), findsOneWidget);
      expect(find.text('-₹12,500'), findsOneWidget);

      // Privacy Mode ON
      AppPreferencesService.instance.obscureNotifier.value = true;
      await tester.pumpAndSettle();

      expect(find.text('+₹ ••••••  '), findsOneWidget);
      expect(find.text('-₹ ••••••'), findsOneWidget);
      expect(find.text('+₹45,000  '), findsNothing);
      expect(find.text('-₹12,500'), findsNothing);

      // Privacy Mode OFF
      AppPreferencesService.instance.obscureNotifier.value = false;
      await tester.pumpAndSettle();

      expect(find.text('+₹45,000  '), findsOneWidget);
      expect(find.text('-₹12,500'), findsOneWidget);
    });
  });
}
