import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/parser/message_parser_pipeline.dart';
import 'package:expense_tracker/models/payment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pipeline = MessageParserPipeline.instance;

  group('40 Synthetic Banking SMS Test Suite', () {
    test('#01 Expense – UPI (Swiggy)', () {
      final res = pipeline.parse('SBI: Rs.450.00 debited from A/c XX1234 on 16-08-26 for UPI txn to SWIGGY. Ref 612345678901.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 450.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.category, 'Food & Dining');
      expect(res.payment?.paymentMode, PaymentMode.upi);
    });

    test('#02 Expense – UPI (Amazon)', () {
      final res = pipeline.parse('HDFC Bank: Rs 1,250.00 spent via UPI from A/c XX5678 to AMAZON. UPI Ref No 623456789012.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 1250.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.paymentMode, PaymentMode.upi);
    });

    test('#03 Expense – Debit Card with Avl Bal (Flipkart)', () {
      final res = pipeline.parse('ICICI Bank: Your Debit Card XX4321 was used for Rs.799.00 at FLIPKART on 16-Aug-26. Avl Bal Rs.24,560.50.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 799.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.paymentMode, PaymentMode.card);
    });

    test('#04 Expense – Debit Card (Myntra)', () {
      final res = pipeline.parse('Axis Bank: INR 2,499.00 debited on Debit Card XX7788 at MYNTRA on 16-Aug-26.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 2499.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.paymentMode, PaymentMode.card);
    });

    test('#05 Expense – Credit Card (Croma)', () {
      final res = pipeline.parse('HDFC Bank Credit Card XX1122: Rs.3,450.00 spent at CROMA on 16-Aug-26.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 3450.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.paymentMode, PaymentMode.card);
    });

    test('#06 Expense – ATM Cash Withdrawal with Avl Bal', () {
      final res = pipeline.parse('SBI: Rs.5,000.00 withdrawn from ATM using Debit Card XX8899 on 16-08-26. Avl Bal Rs.18,420.00.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 5000.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.paymentMode, PaymentMode.cash);
    });

    test('#07 Expense – ATM Cash Withdrawal (ICICI)', () {
      final res = pipeline.parse('ICICI Bank: Cash withdrawal of INR 10,000 from ATM Card XX2211. Transaction date 16-Aug-26.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 10000.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.paymentMode, PaymentMode.cash);
    });

    test('#08 Expense – Bank Transfer NEFT', () {
      final res = pipeline.parse('Kotak Mahindra Bank: Rs 7,500.00 debited from A/c XX3456 through NEFT. Beneficiary: JOHN.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 7500.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.paymentMode, PaymentMode.netBanking);
    });

    test('#09 Expense – IMPS Transfer', () {
      final res = pipeline.parse('Axis Bank: IMPS transaction of Rs.2,000.00 debited from A/c XX9087. Ref ID 987654321.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 2000.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.paymentMode, PaymentMode.netBanking);
    });

    test('#10 Expense – Broadband Bill via Debit Card', () {
      final res = pipeline.parse('Airtel: Payment of Rs.699 received from SBI Debit Card XX1234 for your broadband bill. Txn ID AT123456.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 699.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.category, 'Bills & Utilities');
    });

    test('#11 Expense – Electricity Utility Bill (KSEB)', () {
      final res = pipeline.parse('SBI: Rs.1,850.00 debited from A/c XX4567 towards electricity bill payment. Biller: KSEB.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 1850.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.category, 'Bills & Utilities');
    });

    test('#12 Expense – Subscription (Netflix)', () {
      final res = pipeline.parse('Your HDFC Bank Card XX3322 has been charged Rs.299.00 by NETFLIX.COM.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 299.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.category, 'Entertainment');
      expect(res.payment?.paymentMode, PaymentMode.card);
    });

    test('#13 Income – Salary Credit (ABC Tech)', () {
      final res = pipeline.parse('HDFC Bank: Rs.75,000.00 credited to A/c XX1234. Salary credit from ABC TECHNOLOGIES LTD.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 75000.0);
      expect(res.payment?.type, TransactionType.credit);
      expect(res.payment?.category, 'Salary');
    });

    test('#14 Income – Salary Credit via NEFT Remitter', () {
      final res = pipeline.parse('SBI: Your A/c XX7788 is credited with INR 52,500.00 by NEFT. Remitter: XYZ SOLUTIONS PVT LTD.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 52500.0);
      expect(res.payment?.type, TransactionType.credit);
      expect(res.payment?.category, 'Salary');
    });

    test('#15 Income – UPI Credit from Rahul', () {
      final res = pipeline.parse('ICICI Bank: Rs.2,500.00 credited to A/c XX9012 via UPI from Rahul. UPI Ref 634567890123.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 2500.0);
      expect(res.payment?.type, TransactionType.credit);
    });

    test('#16 Income – Bank Transfer via IMPS', () {
      final res = pipeline.parse('Axis Bank: INR 15,000.00 credited to A/c XX5678 via IMPS. Sender: ANIL KUMAR. Ref 765432198.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 15000.0);
      expect(res.payment?.type, TransactionType.credit);
    });

    test('#17 Income – Cash Deposit with Avl Bal', () {
      final res = pipeline.parse('SBI: Cash deposit of Rs.20,000.00 made to A/c XX3456 on 16-08-26. Avl Bal Rs.85,420.00.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 20000.0);
      expect(res.payment?.type, TransactionType.credit);
      expect(res.payment?.paymentMode, PaymentMode.cash);
    });

    test('#18 Income – Refund (Amazon)', () {
      final res = pipeline.parse('HDFC Bank: Rs.1,299.00 credited to your A/c XX1234. Refund received from AMAZON.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 1299.0);
      expect(res.payment?.type, TransactionType.credit);
      expect(res.payment?.category, 'Refund');
    });

    test('#19 Income – Card Refund (Flipkart)', () {
      final res = pipeline.parse('ICICI Bank: Refund of INR 899.00 credited to Credit Card XX7788 by FLIPKART.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 899.0);
      expect(res.payment?.type, TransactionType.credit);
      expect(res.payment?.category, 'Refund');
    });

    test('#20 Expense – UPI Tea Shop', () {
      final res = pipeline.parse('UPI Alert: Your A/c XX1234 has been debited by Rs 180 for payment to TEA SHOP. Ref 845612349876.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 180.0);
      expect(res.payment?.type, TransactionType.debit);
    });

    test('#21 Expense – Card at Reliance Digital', () {
      final res = pipeline.parse('Dear Customer, Rs.12,750 spent on Axis Bank Credit Card XX5566 at RELIANCE DIGITAL on 16-Aug-26.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 12750.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.category, 'Shopping');
    });

    test('#22 Income – Bank Interest', () {
      final res = pipeline.parse('SBI: Interest of Rs.1,245.60 credited to Savings A/c XX9876.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 1245.60);
      expect(res.payment?.type, TransactionType.credit);
      expect(res.payment?.category, 'Investment Return');
    });

    test('#23 Expense – Personal Loan EMI', () {
      final res = pipeline.parse('ICICI Bank: EMI of Rs.8,450.00 debited from A/c XX1234 for Personal Loan. Loan A/c XX5566.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 8450.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.category, 'Financial Services');
    });

    test('#24 Expense – Wallet Recharge (Paytm)', () {
      final res = pipeline.parse('Kotak Bank: Rs.500.00 debited from A/c XX6789 towards PAYTM wallet recharge.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 500.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.category, 'Financial Services');
    });

    test('#25 Income – Reversal (UPI)', () {
      final res = pipeline.parse('SBI: Rs.450.00 credited to A/c XX1234 as UPI transaction reversal. Ref 612345678901.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 450.0);
      expect(res.payment?.type, TransactionType.credit);
      expect(res.payment?.category, 'Refund');
    });

    test('#26 No Decimals (Zomato)', () {
      final res = pipeline.parse('SBI: Rs 500 debited from A/c XX1234 via UPI to ZOMATO.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 500.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.category, 'Food & Dining');
    });

    test('#27 Indian comma format (1,25,000.00)', () {
      final res = pipeline.parse('HDFC: Rs.1,25,000.00 credited to A/c XX1234 via NEFT.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 125000.0);
      expect(res.payment?.type, TransactionType.credit);
    });

    test('#28 INR instead of Rs (INR 349.50)', () {
      final res = pipeline.parse('Axis Bank: INR 349.50 debited from A/c XX9876 for UPI payment.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 349.50);
      expect(res.payment?.type, TransactionType.debit);
    });

    test('#29 Lowercase SMS', () {
      final res = pipeline.parse('your a/c xx1234 is debited with rs 799 for upi txn to amazon.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 799.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.category, 'Shopping');
    });

    test('#30 Slash date format (16/08/2026)', () {
      final res = pipeline.parse('ICICI: Rs 2,300 debited on 16/08/2026 from A/c XX1234.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 2300.0);
      expect(res.payment?.type, TransactionType.debit);
    });

    test('#31 Embedded amount (Paid Rs.650.00 to Swiggy)', () {
      final res = pipeline.parse('Transaction successful. Paid Rs.650.00 to SWIGGY using UPI from HDFC A/c XX1234.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 650.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.category, 'Food & Dining');
    });

    test('#32 Balance after transaction (750 debited, 14,350.25 bal)', () {
      final res = pipeline.parse('SBI A/c XX1234 debited Rs.750.00. Available balance: Rs.14,350.25.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 750.0);
      expect(res.payment?.type, TransactionType.debit);
    });

    test('#33 Available balance before transaction (Avl Bal 25,000, Debit 1,250)', () {
      final res = pipeline.parse('Available balance Rs 25,000. Debit of Rs 1,250 towards UPI transaction.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 1250.0);
      expect(res.payment?.type, TransactionType.debit);
    });

    test('#34 Reversal (1,500 debited earlier has been reversed)', () {
      final res = pipeline.parse('Rs.1,500 debited earlier has been reversed and credited back to your A/c XX1234.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 1500.0);
      expect(res.payment?.type, TransactionType.credit);
      expect(res.payment?.category, 'Refund');
    });

    test('#35 Rejects Failed Transaction', () {
      final res = pipeline.parse('UPI transaction of Rs.999 to AMAZON failed. Amount will be reversed if debited.');
      expect(res.isSuccess, isFalse);
    });

    test('#36 Rejects Pending Transaction', () {
      final res = pipeline.parse('UPI payment of Rs.2,000 to XYZ is pending. Do not retry until status is confirmed.');
      expect(res.isSuccess, isFalse);
    });

    test('#37 Multiple amounts (Rs.500 debited, Bal 10,500.00)', () {
      final res = pipeline.parse('Rs.500 debited. Your available balance is Rs.10,500.00.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 500.0);
      expect(res.payment?.type, TransactionType.debit);
    });

    test('#38 Credit Card Payment Received', () {
      final res = pipeline.parse('HDFC Bank: Payment of Rs.8,000 received towards Credit Card XX1234.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 8000.0);
    });

    test('#39 Credit Card Bill Payment Outstanding', () {
      final res = pipeline.parse('SBI: Rs 15,000 credited to your Credit Card XX4455 towards outstanding payment.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 15000.0);
    });

    test('#40 Merchant + Reference ID (Dominos)', () {
      final res = pipeline.parse('UPI: Rs 325 paid to DOMINOS. Ref No 823456789012. A/c XX1234 debited.');
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 325.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.category, 'Food & Dining');
    });

    test('#41 TRAI Sender Header Acceptance', () {
      // Legitimate TRAI alphanumeric headers
      const traiSenders = ['VK-SBIINB', 'VM-HDFCBK', 'AD-ICICIB', 'AX-AXISBK', 'JM-KOTAKB', 'BP-EPFOHO', 'JD-PAYTM', 'HDFCBK'];
      for (final sender in traiSenders) {
        final res = pipeline.parse(
          'SBI: Rs.450.00 debited from A/c XX1234 on 16-08-26 for UPI txn to SWIGGY. Ref 612345678901.',
          sender: sender,
        );
        expect(res.isSuccess, isTrue, reason: 'Sender $sender should be accepted as TRAI header');
        expect(res.payment?.amount, 450.0);
      }
    });

    test('#42 Personal Phone Number Rejection (Spoof / Prank Prevention)', () {
      // Personal 10-digit / international phone numbers
      const personalNumbers = ['+919876543210', '9876543210', '+91-98765-43210', '+14155552671', '09876543210', '919876543210'];
      for (final number in personalNumbers) {
        final res = pipeline.parse(
          'SBI: Rs.450.00 debited from A/c XX1234 on 16-08-26 for UPI txn to SWIGGY. Ref 612345678901.',
          sender: number,
        );
        expect(res.isSuccess, isFalse, reason: 'Personal number $number must be rejected');
        expect(res.errorMessage, contains('personal phone number'));
      }
    });
  });
}
