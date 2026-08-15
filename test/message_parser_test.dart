import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/parser/message_parser_pipeline.dart';
import 'package:expense_tracker/models/payment.dart';

void main() {
  group('MessageParserPipeline Tests', () {
    final parser = MessageParserPipeline.instance;

    test('Parses HDFC Bank UPI Debit SMS (Swiggy)', () {
      const sms = 'Dear Customer, Rs.450.00 has been debited from your HDFC Bank A/c XX4021 to SWIGGY on 14-Aug-2026 via UPI Ref 422891829102. Avl Bal: Rs 25,400.00';
      final result = parser.parse(sms);

      expect(result.isSuccess, true);
      expect(result.payment?.amount, 450.0);
      expect(result.payment?.type, TransactionType.debit);
      expect(result.payment?.category, 'Food & Dining');
      expect(result.payment?.accountReference, 'HDFC A/c XX4021');
      expect(result.payment?.paymentMode, PaymentMode.upi);
      expect(result.payment?.description, contains('Swiggy'));
    });

    test('Parses SBI Bank ATM Cash Withdrawal SMS', () {
      const sms = 'Your A/C 9876 is debited with INR 2,000.00 on 12-08-2026 by ATM cash withdrawal at MG ROAD BR. Avl Bal: INR 12,500.00 - SBI';
      final result = parser.parse(sms);

      expect(result.isSuccess, true);
      expect(result.payment?.amount, 2000.0);
      expect(result.payment?.type, TransactionType.debit);
      expect(result.payment?.paymentMode, PaymentMode.cash);
      expect(result.payment?.accountReference, 'SBI A/c 9876');
    });

    test('Parses ICICI Credit Card Swipe (Amazon)', () {
      const sms = 'INR 1,899.00 spent on ICICI Bank Card ending 4402 on 10-Aug-2026 at AMAZON INDIA. Avl Limit: INR 85,000.00';
      final result = parser.parse(sms);

      expect(result.isSuccess, true);
      expect(result.payment?.amount, 1899.0);
      expect(result.payment?.type, TransactionType.debit);
      expect(result.payment?.category, 'Shopping');
      expect(result.payment?.paymentMode, PaymentMode.card);
      expect(result.payment?.description, contains('Amazon'));
    });

    test('Parses Salary Credit SMS', () {
      const sms = 'Your HDFC Bank A/c XX1234 is credited with Rs 75,000.00 on 01-Aug-2026 by Salary Payroll. Total Avl Bal Rs 82,450.00';
      final result = parser.parse(sms);

      expect(result.isSuccess, true);
      expect(result.payment?.amount, 75000.0);
      expect(result.payment?.type, TransactionType.credit);
      expect(result.payment?.category, 'Salary');
    });

    test('Parses Uber Ride Transport Debit', () {
      const sms = 'Paid Rs. 249.00 towards Uber ride using Paytm Bank A/c XX9921 on 14-Aug-2026. Txn ID: 8492049182.';
      final result = parser.parse(sms);

      expect(result.isSuccess, true);
      expect(result.payment?.amount, 249.0);
      expect(result.payment?.type, TransactionType.debit);
      expect(result.payment?.category, 'Transportation');
      expect(result.payment?.description, contains('Uber'));
    });

    test('Parses Electricity Bill payment', () {
      const sms = 'Rs 1,450.00 debited from A/c XX5678 for BESCOM electricity bill on 05-Aug-2026 via UPI.';
      final result = parser.parse(sms);

      expect(result.isSuccess, true);
      expect(result.payment?.amount, 1450.0);
      expect(result.payment?.category, 'Bills & Utilities');
    });

    test('Parses Refund Credit SMS', () {
      const sms = 'Refund of INR 350.00 has been credited to your ICICI Bank A/c XX3029 from ZOMATO.';
      final result = parser.parse(sms);

      expect(result.isSuccess, true);
      expect(result.payment?.amount, 350.0);
      expect(result.payment?.type, TransactionType.credit);
      expect(result.payment?.category, 'Refund');
    });

    test('Parses EPFO Passbook Contribution SMS accurately', () {
      const sms = 'Dear XXXXXXXX7897, your passbook balance against KRTVM**************0630 is Rs. 46,119/-. Contribution of Rs. 2,350/- for due month Jun-26 has been received.';
      final result = parser.parse(sms);

      expect(result.isSuccess, true);
      expect(result.payment?.amount, 2350.0);
      expect(result.payment?.type, TransactionType.credit);
      expect(result.payment?.category, 'Investments');
      expect(result.payment?.description, 'EPFO Contribution');
    });

    test('Rejects OTP security message', () {
      const sms = 'Your OTP for transaction of INR 500.00 at Swiggy is 482910. Do not share this OTP with anyone.';
      final result = parser.parse(sms);

      expect(result.isSuccess, false);
    });

    test('Rejects balance-only check', () {
      const sms = 'Dear Customer, your available balance in A/C XX4920 is INR 45,230.50 as on 14-Aug-2026.';
      final result = parser.parse(sms);

      expect(result.isSuccess, false);
    });

    test('Rejects Pre-approved loan offer spam', () {
      const sms = 'Good news ALLWIN S, Pre-approved loan of upto Rs.10,00,000 is credited instantly when you avail on Flipkart. Avail now! http://u3.mnge.co/FLPKRT/oDREx0';
      final result = parser.parse(sms);

      expect(result.isSuccess, false);
    });

    test('Rejects Credit Card marketing limit offer', () {
      const sms = 'Congratulations! You are eligible for an instant personal loan of up to Rs. 5,00,000 with zero documentation. Apply now: https://bit.ly/loan';
      final result = parser.parse(sms);

      expect(result.isSuccess, false);
    });
  });
}
