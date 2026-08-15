import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/parser/ml/fasttext_engine.dart';
import 'package:expense_tracker/parser/message_parser_pipeline.dart';
import 'package:expense_tracker/models/payment.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await FastTextEngine.instance.initialize(assetPath: 'assets/models/financial_fasttext.json');
  });

  group('FastText On-Device Classifier Tests', () {
    test('Model initializes successfully and is ready', () {
      expect(FastTextEngine.instance.isReady, isTrue);
    });

    test('Classifies genuine HDFC Bank UPI debit correctly', () {
      const sms = 'Dear Customer, Rs.450.00 has been debited from your HDFC Bank A/c XX4021 to Swiggy on 14-Aug-2026 via UPI Ref 421890123456. Avl Bal: Rs 15,240.00';
      final result = FastTextEngine.instance.classify(sms);

      expect(result, isNotNull);
      expect(result!.classification, equals(SmsClassification.genuineTransaction));
      expect(result.confidence, greaterThan(0.85));
      expect(result.inferenceTimeUs, lessThan(15000)); // Under 15ms in test environment
    });

    test('Classifies genuine ICICI Bank Credit Card swipe correctly', () {
      const sms = 'Your ICICI Bank Credit Card ending XX8091 was spent for INR 1450.00 at Amazon on 12-Aug-2026. Avl Limit: INR 85,000.00';
      final result = FastTextEngine.instance.classify(sms);

      expect(result, isNotNull);
      expect(result!.classification, equals(SmsClassification.genuineTransaction));
      expect(result.confidence, greaterThan(0.85));
    });

    test('Classifies genuine Salary credit correctly', () {
      const sms = 'Salary of INR 75000.00 has been credited to your SBI A/c XX3029 on 01-Aug-2026 by ACME CORP. Avl Bal: INR 95,000.00';
      final result = FastTextEngine.instance.classify(sms);

      expect(result, isNotNull);
      expect(result!.classification, equals(SmsClassification.genuineTransaction));
      expect(result.confidence, greaterThan(0.85));
    });

    test('Detects and flags disguised pre-approved loan spam', () {
      const sms = 'Good news! Pre-approved personal loan of upto Rs.500000 is credited instantly when you apply on HDFC Bank. Click to avail: https://bit.ly/loan';
      final result = FastTextEngine.instance.classify(sms);

      expect(result, isNotNull);
      expect(result!.classification, equals(SmsClassification.promotionalSpam));
      expect(result.confidence, greaterThan(0.80));
    });

    test('Detects and flags credit card limit marketing', () {
      const sms = 'Dear Customer, your Axis Bank credit card limit has been enhanced to Rs.200000. Avail this exclusive offer now: http://offers.bank.com';
      final result = FastTextEngine.instance.classify(sms);

      expect(result, isNotNull);
      expect(result!.classification, equals(SmsClassification.promotionalSpam));
      expect(result.confidence, greaterThan(0.80));
    });

    test('Classifies OTP security code alert accurately', () {
      const sms = 'Your OTP for transaction of INR 450.50 at Zomato is 849201. Do not share this OTP with anyone, including bank staff.';
      final result = FastTextEngine.instance.classify(sms);

      expect(result, isNotNull);
      expect(result!.classification, equals(SmsClassification.otpSecurity));
      expect(result.confidence, greaterThan(0.80));
    });

    test('Classifies available balance inquiry message as Informational', () {
      const sms = 'Dear Customer, your available balance in A/C XX4021 is INR 35000.00 as on 15-Aug-2026.';
      final result = FastTextEngine.instance.classify(sms);

      expect(result, isNotNull);
      expect(result!.classification, equals(SmsClassification.informational));
      expect(result.confidence, greaterThan(0.80));
    });
  });

  group('End-to-End Pipeline with FastText Integration Tests', () {
    test('Parses genuine Swiggy UPI debit with high AI confidence', () {
      const sms = 'Dear Customer, Rs.450.00 has been debited from your HDFC Bank A/c XX4021 to Swiggy on 14-Aug-2026 via UPI Ref 421890123456. Avl Bal: Rs 15,240.00';
      final result = MessageParserPipeline.instance.parse(sms);

      expect(result.isSuccess, isTrue);
      expect(result.payment, isNotNull);
      expect(result.payment!.amount, equals(450.00));
      expect(result.payment!.type, equals(TransactionType.debit));
      expect(result.payment!.category, equals('Food & Dining'));
      expect(result.payment!.paymentMode, equals(PaymentMode.upi));
      expect(result.confidence, greaterThan(0.80));
    });

    test('Rejects fake loan marketing with AI rejection reason', () {
      const sms = 'Congratulations! You are eligible for an instant personal loan of up to Rs. 250000 with zero documentation. Apply now: http://u3.mnge.co/x';
      final result = MessageParserPipeline.instance.parse(sms);

      expect(result.isSuccess, isFalse);
    });

    test('Rejects OTP verification message', () {
      const sms = '672391 is your one time password for SBI Bank NetBanking login. Valid for 5 mins. Do not share.';
      final result = MessageParserPipeline.instance.parse(sms);

      expect(result.isSuccess, isFalse);
    });
  });
}
