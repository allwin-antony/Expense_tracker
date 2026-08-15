import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/parser/ml/clause_semantic_scoper.dart';
import 'package:expense_tracker/parser/message_parser_pipeline.dart';
import 'package:expense_tracker/models/payment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClauseSemanticScoper Tests', () {
    final scoper = ClauseSemanticScoper.instance;
    final pipeline = MessageParserPipeline.instance;

    test('Correctly splits multi-sentence SMS into distinct clauses', () {
      const sms =
          'Dear XXXXXXXX7897, your passbook balance against KRTVM**************0630 is Rs. 46,119/-. Contribution of Rs. 2,350/- for due month Jun-26 has been received.';
      final clauses = scoper.splitIntoClauses(sms);

      expect(clauses.length, greaterThanOrEqualTo(2));
      expect(clauses.any((c) => c.contains('Contribution of Rs. 2,350')), isTrue);
    });

    test('Classifies balance statement vs transaction event accurately', () {
      const balanceClause = 'your passbook balance against KRTVM**************0630 is Rs. 46,119/-';
      const txnClause = 'Contribution of Rs. 2,350/- for due month Jun-26 has been received';
      const greetingClause = 'Dear Customer';

      expect(scoper.classifyClause(balanceClause), equals(ClauseType.balanceStatement));
      expect(scoper.classifyClause(txnClause), equals(ClauseType.transactionEvent));
      expect(scoper.classifyClause(greetingClause), equals(ClauseType.greetingOrHeader));
    });

    test('Isolates transaction event clause from complex multi-amount EPFO SMS', () {
      const sms =
          'Dear XXXXXXXX7897, your passbook balance against KRTVM**************0630 is Rs. 46,119/-. Contribution of Rs. 2,350/- for due month Jun-26 has been received.';
      final isolated = scoper.isolateTransactionClause(sms);

      expect(isolated.contains('Contribution of Rs. 2,350'), isTrue);
      expect(isolated.contains('passbook balance'), isFalse);
    });

    test('End-to-End Pipeline parses correct transaction amount from scoped clause', () {
      const sms =
          'Dear XXXXXXXX7897, your passbook balance against KRTVM**************0630 is Rs. 46,119/-. Contribution of Rs. 2,350/- for due month Jun-26 has been received.';
      final result = pipeline.parse(sms);

      expect(result.isSuccess, isTrue);
      expect(result.payment?.amount, equals(2350.0));
      expect(result.payment?.type, equals(TransactionType.credit));
      expect(result.payment?.category, equals('Investments'));
      expect(result.payment?.description, equals('EPFO Contribution'));
    });

    test('Correctly scopes standard HDFC Bank debit SMS with ending balance', () {
      const sms =
          'Dear Customer, Rs. 540.00 debited from A/c XX1234 on 15-Aug-26 at SWIGGY. Avl Bal: Rs. 14,200.00. Ref 92810283.';
      final result = pipeline.parse(sms);

      expect(result.isSuccess, isTrue);
      expect(result.payment?.amount, equals(540.0));
      expect(result.payment?.type, equals(TransactionType.debit));
      expect(result.payment?.category, equals('Food & Dining'));
    });

    test('Correctly scopes SBI ATM Cash withdrawal SMS', () {
      const sms =
          'Your A/c XX9012 is debited by INR 3,000.00 on 12-Aug-26 by ATM WDL. Total Avail Bal INR 25,400.00.';
      final result = pipeline.parse(sms);

      expect(result.isSuccess, isTrue);
      expect(result.payment?.amount, equals(3000.0));
      expect(result.payment?.type, equals(TransactionType.debit));
    });
  });
}
