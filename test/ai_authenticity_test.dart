import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/payment.dart';
import 'package:expense_tracker/parser/ml/bert_tokenizer.dart';
import 'package:expense_tracker/parser/ml/authenticity_validator.dart';
import 'package:expense_tracker/parser/message_parser_pipeline.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BertTokenizer Tests', () {
    final tokenizer = BertTokenizer.instance;

    setUpAll(() async {
      await tokenizer.initialize();
    });

    test('Encodes financial text into token IDs and attention mask', () {
      const text = 'Rs. 450 debited from HDFC Bank to Swiggy';
      final encoded = tokenizer.encode(text, maxSeqLength: 32);

      expect(encoded.inputIds.length, 32);
      expect(encoded.attentionMask.length, 32);
      expect(encoded.tokens.first, '[CLS]');
      expect(encoded.tokens.contains('[SEP]'), true);
      expect(encoded.tokens.contains('debited'), true);
      expect(encoded.tokens.contains('hdfc'), true);
      expect(encoded.tokens.contains('swiggy'), true);
    });

    test('Handles subwords with ## prefixes correctly', () {
      const text = 'transferring refunding';
      final encoded = tokenizer.encode(text, maxSeqLength: 16);

      expect(encoded.inputIds.length, 16);
      expect(encoded.attentionMask.first, 1);
    });
  });

  group('AI Authenticity & Semantic Validator Tests', () {
    final validator = AuthenticityValidator.instance;
    final pipeline = MessageParserPipeline.instance;

    test('Confirms Authentic HDFC Bank UPI Debit', () {
      const sms = 'Dear Customer, Rs.450.00 has been debited from your HDFC Bank A/c XX4021 to SWIGGY on 14-Aug-2026 via UPI Ref 422891829102. Avl Bal: Rs 25,400.00';
      final eval = validator.evaluate(
        rawText: sms,
        rawMerchant: 'SWIGGY',
        amount: 450.0,
        isCredit: false,
      );

      expect(eval.isAuthentic, true);
      expect(eval.authenticityScore, greaterThanOrEqualTo(0.85));
      expect(eval.intent, MessageIntent.authenticTransaction);
      expect(eval.category, 'Food & Dining');
      expect(eval.cleanMerchant, 'Swiggy');
    });

    test('Confirms Authentic ICICI Credit Card swipe at Amazon', () {
      const sms = 'Your ICICI Bank Credit Card ending 8091 was spent for INR 2,499.00 at AMAZON RETAIL on 14-Aug-2026. Avl Limit: INR 85,000.00';
      final eval = validator.evaluate(
        rawText: sms,
        rawMerchant: 'AMAZON RETAIL',
        amount: 2499.0,
        isCredit: false,
      );

      expect(eval.isAuthentic, true);
      expect(eval.authenticityScore, greaterThanOrEqualTo(0.85));
      expect(eval.intent, MessageIntent.authenticTransaction);
      expect(eval.category, 'Shopping');
      expect(eval.cleanMerchant, 'Amazon');
    });

    test('Confirms Authentic Salary Credit', () {
      const sms = 'Salary of INR 85,000.00 has been credited to your Axis Bank A/c XX9920 on 01-Aug-2026 by ACME CORP. Avl Bal: INR 1,12,000.00';
      final eval = validator.evaluate(
        rawText: sms,
        rawMerchant: 'ACME CORP',
        amount: 85000.0,
        isCredit: true,
      );

      expect(eval.isAuthentic, true);
      expect(eval.authenticityScore, greaterThanOrEqualTo(0.85));
      expect(eval.intent, MessageIntent.authenticTransaction);
      expect(eval.category, 'Salary');
    });

    test('Rejects Disguised Flipkart Pre-Approved Loan Offer (Fake Credit)', () {
      const sms = 'Good news ALLWIN S, Pre-approved loan of upto Rs.10,00,000 is credited instantly when you avail on Flipkart. Avail now! http://u3.mnge.co/FLPKRT/oDREx0';
      
      final eval = validator.evaluate(
        rawText: sms,
        rawMerchant: 'Flipkart',
        amount: 1000000.0,
        isCredit: true,
      );

      expect(eval.isAuthentic, false);
      expect(eval.authenticityScore, lessThan(0.50));
      expect(eval.intent, MessageIntent.promotionalOrLoanOffer);
      expect(eval.rejectionReason, contains('loan offer'));

      // Pipeline test
      final pipeResult = pipeline.parse(sms);
      expect(pipeResult.isSuccess, false);
    });

    test('Rejects Credit Card Limit Increase & Personal Loan Marketing', () {
      const sms = 'Congratulations! You are eligible for an instant personal loan of up to Rs. 5,00,000 with zero documentation. Apply now: https://bit.ly/loan';
      
      final eval = validator.evaluate(
        rawText: sms,
        rawMerchant: '',
        amount: 500000.0,
        isCredit: true,
      );

      expect(eval.isAuthentic, false);
      expect(eval.intent, MessageIntent.promotionalOrLoanOffer);

      final pipeResult = pipeline.parse(sms);
      expect(pipeResult.isSuccess, false);
    });

    test('Rejects OTP verification alert', () {
      const sms = 'Your OTP for transaction of Rs. 1,200.00 at Zomato is 918230. Do not share this OTP with anyone.';
      final eval = validator.evaluate(
        rawText: sms,
        rawMerchant: 'Zomato',
        amount: 1200.0,
        isCredit: false,
      );

      expect(eval.isAuthentic, false);
      expect(eval.intent, MessageIntent.otpOrSecurity);

      final pipeResult = pipeline.parse(sms);
      expect(pipeResult.isSuccess, false);
    });

    test('Rejects Balance Query without transaction', () {
      const sms = 'Dear Customer, your available balance in A/C XX4920 is INR 45,230.50 as on 14-Aug-2026.';
      final eval = validator.evaluate(
        rawText: sms,
        rawMerchant: '',
        amount: 45230.50,
        isCredit: false,
      );

      expect(eval.isAuthentic, false);
      expect(eval.intent, MessageIntent.balanceQuery);

      final pipeResult = pipeline.parse(sms);
      expect(pipeResult.isSuccess, false);
    });

    test('Confirms Authentic NEFT Salary / Company Deposit SMS', () {
      const sms = 'Update! INR 29,424.00 deposited in HDFC Bank A/c XX5095 on 31-JUL-26 for NEFT Cr-UTIB0000802-ACSIA TECHNOLOGIES PRIVATE LIMITED-Allwin S Antony-AXISP00821906005.Avl bal INR 1,32,566.60. Cheque deposits in A/C are subject to clearing';
      
      final pipeResult = pipeline.parse(sms);
      expect(pipeResult.isSuccess, isTrue);
      expect(pipeResult.payment, isNotNull);
      expect(pipeResult.payment!.amount, 29424.00);
      expect(pipeResult.payment!.type, TransactionType.credit);
      expect(pipeResult.payment!.paymentMode, PaymentMode.netBanking);
      expect(pipeResult.payment!.accountReference, 'HDFC A/c XX5095');
    });
  });
}
