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

    test('#43 Multi-Line Sent UPI transaction with Call/SMS block message', () {
      final sms = '''Sent Rs.10000.00
From HDFC Bank A/C *5095
To ancyantony968@okaxis
On 11/06/26
Ref 616291718743
Not You?
Call 18002586161/SMS BLOCK UPI to 7308080808''';
      final res = pipeline.parse(sms);
      expect(res.isSuccess, isTrue);
      expect(res.payment?.amount, 10000.0);
      expect(res.payment?.type, TransactionType.debit);
      expect(res.payment?.description, 'Ancyantony');
      expect(res.payment?.paymentMode, PaymentMode.upi);
    });

    test('#44 Rejects HDFC Loan on Card Promotional Offer', () {
      final sms = '''Important Update: HDFC Bank Card xx3177:
Higher Rs. 75000 Loan on Card at the lowest interest rates! Check EMIs.
https://1.hdfc.bank.in/HDFCBK/s/7q2JoEdV
T&C''';
      final res = pipeline.parse(sms);
      expect(res.isSuccess, isFalse);
    });

    group('89 Additional Phishing, Scam, and Real Transaction Validation Cases', () {
      final userCases = [
        // --- Unstructured Valid Transactions ---
        _TestCase('Val_1', true, 'Rs.500.00 debited from a/c **1234 on 15-08-26 to VPA merchant@ybl. UPI Ref 123456789012. Not you? Call 1800-111-222.', expectedAmount: 500.0, expectedType: TransactionType.debit),
        _TestCase('Val_2', true, 'Sent Rs. 150.00 from HDFC Bank Acct 9999 to Rahul. UPI Ref 654321. Bal: Rs. 10,500.25.', expectedAmount: 150.0, expectedType: TransactionType.debit),
        _TestCase('Val_3', true, 'Alert: INR 2,050.00 deducted from A/C XXXXXX5555 on 16/08/26 14:20 via UPI. Payee: Swiggy. Bal: INR 12,000.', expectedAmount: 2050.0, expectedType: TransactionType.debit),
        _TestCase('Val_4', true, 'Dear Customer, Acct XX5678 is credited with INR 1,500.00 on 14-Aug-26 from UPI/user@okaxis. Ref 987654321.', expectedAmount: 1500.0, expectedType: TransactionType.credit),
        _TestCase('Val_5', true, 'You have received Rs. 850.00 from Amit Kumar on your ICICI Bank A/c ending 1122 via UPI. Available balance: Rs 4,500.00.', expectedAmount: 850.0, expectedType: TransactionType.credit),
        _TestCase('Val_6', true, "Alert: You've spent INR 2,450.50 on your SBI Credit Card ending 4455 at AMAZON INDIA on 12-08-26. Avail. Lmt: INR 45,000.", expectedAmount: 2450.50, expectedType: TransactionType.debit),
        _TestCase('Val_7', true, 'Transaction of USD 15.99 on your Axis Bank Credit Card xx1122 at NETFLIX COM on 15/08/2026. Available limit: Rs 150000.', expectedAmount: 15.99, expectedType: TransactionType.debit),
        _TestCase('Val_8', true, 'Thank you for using your Citi Card 8899 for Rs. 540 at STARBUCKS on 14AUG26. Limit available Rs. 89,000.', expectedAmount: 540.0, expectedType: TransactionType.debit),
        _TestCase('Val_9', true, 'Chase Bank: \$45.20 was charged to your Visa ending 1234 at TARGET on 08/15. Reply STOP to cancel alerts.', expectedAmount: 45.20, expectedType: TransactionType.debit),
        _TestCase('Val_10', true, '£14.50 has been debited from your Monzo account ending 0987. Retailer: TESCO. Date: 16 Aug.', expectedAmount: 14.50, expectedType: TransactionType.debit),
        _TestCase('Val_11', true, 'Your A/C XXXXXX8888 has been credited with Rs 85,000.00 on 31/07/26 by SALARY CORP. Info: NEFT/ABC12345. Bal: Rs 92,000.00.', expectedAmount: 85000.0, expectedType: TransactionType.credit),
        _TestCase('Val_12', true, 'IMPS P2A fund transfer of Rs 5,000.00 credited to your A/c XX2222 on 15-08-26. Ref no 55556666. Avail Bal Rs 15,200.00.', expectedAmount: 5000.0, expectedType: TransactionType.credit),
        _TestCase('Val_13', true, 'Dear Customer, Rs. 10,000.00 credited to your account **9988 on 15/08/2026 via RTGS from MR SHARMA. Available Balance is INR 50,000.', expectedAmount: 10000.0, expectedType: TransactionType.credit),
        _TestCase('Val_14', true, 'Bank of America alert: A direct deposit of \$3,200.00 was posted to checking account 9876 on Aug 14.', expectedAmount: 3200.0, expectedType: TransactionType.credit),
        _TestCase('Val_15', true, 'Cash withdrawal of Rs. 2,000.00 made from A/c No. XXXX1111 on 15-08-26 at SBI ATM. Available Bal: Rs. 15,340.50.', expectedAmount: 2000.0, expectedType: TransactionType.debit),
        _TestCase('Val_16', true, 'Alert! Rs. 500.00 withdrawn at HDFC ATM from Acct ending 7777 on 16/08/26 10:30AM. Clear Bal: Rs 8,000.00.', expectedAmount: 500.0, expectedType: TransactionType.debit),
        _TestCase('Val_17', true, 'Rs. 1,499.00 has been debited from your A/c XXXXX5555 on 10-08-26 towards JIO FIBER auto-pay. Bal Rs 14,000.', expectedAmount: 1499.0, expectedType: TransactionType.debit),
        _TestCase('Val_18', true, 'Alert: EMI of Rs. 15,500.00 for your Home Loan XX1122 has been debited from Savings A/c XX4455 on 05-Aug-2026.', expectedAmount: 15500.0, expectedType: TransactionType.debit),
        _TestCase('Val_19', true, 'Your SIP of Rs 3,000.00 in MUTUAL FUND is successfully processed from A/c XX7777 on 12-08-26. Bal: Rs 42,100.', expectedAmount: 3000.0, expectedType: TransactionType.debit),
        _TestCase('Val_20', true, 'Refund of Rs. 499.00 processed for your transaction at SWIGGY. Amount credited to A/c XX5566 on 16/08/26. Bal: Rs 3,499.00.', expectedAmount: 499.0, expectedType: TransactionType.credit),
        _TestCase('Val_21', true, 'INR 1,200.00 reversed to your Kotak CC 11**44 on 14-Aug-26 for txn originally billed at ZOMATO.', expectedAmount: 1200.0, expectedType: TransactionType.credit),
        _TestCase('Val_22', true, 'Dear Customer, Annual maintenance charge of Rs 295.00 has been deducted from A/c XX1234 on 15/08/26. Available balance is Rs 9,500.25.', expectedAmount: 295.0, expectedType: TransactionType.debit),

        // --- Unstructured Fake/Scams ---
        _TestCase('Fake_1', false, 'Dear Customer, your HDFC bank account will be blocked today due to pending PAN Card update. Click here to update now: http://bit.ly/fake-update-link'),
        _TestCase('Fake_2', false, 'SBI Alert: Your YONO account is suspended. Please complete your KYC verification immediately to avoid account closure. Link: https://sbi-kyc-verify-fake.com'),
        _TestCase('Fake_3', false, 'Dear User, your Bank A/c has been blocked. Please update your Aadhar and PAN card immediately. Visit: http://tinyurl.com/bank-kyc-alert'),
        _TestCase('Fake_4', false, 'Dear User, Rs. 25,000.00 has been credited to your bank account. Claim your amount here: http://claim-your-reward.com'),
        _TestCase('Fake_5', false, 'Congratulations! You have received a scratch card cashback of Rs 1,999 from Google Pay. Click here to receive the money directly in your UPI a/c: http://gpay-cashback-scam.in'),
        _TestCase('Fake_6', false, 'Your mobile number has won Rs 50,00,000 in the KBC Jio lottery. Please contact the manager on WhatsApp at +919876543210 to claim your prize.'),
        _TestCase('Fake_7', false, 'Dear Taxpayer, your Income Tax refund of Rs 14,500 for the current financial year has been approved. Please verify your bank account details here to process the refund: http://incometax-refund-gov.com'),
        _TestCase('Fake_8', false, 'ITD Alert: A refund of Rs. 8,450 has been generated for PAN ABCDE1234F. Click below to approve the transfer to your account.'),
        _TestCase('Fake_9', false, "Dear customer, your electricity power will be disconnected tonight at 9:30 PM from the electricity office because your previous month's bill was not updated. Please contact our officer at 9876543210."),
        _TestCase('Fake_10', false, 'Jio Alert: Your SIM card will be deactivated in 24 hours. Recharge immediately to keep your number active. Click here: http://jio-recharge-fake.com'),
        _TestCase('Fake_11', false, 'Work from home and earn Rs 3000 to 5000 daily by just liking YouTube videos. Reply via WhatsApp to start: http://wa.me/919876543210'),
        _TestCase('Fake_12', false, 'Amazon is hiring! Work part-time and earn up to Rs 8,000/day. No experience needed. Contact HR: +919000000000.'),

        // --- Structured Valid (1 to 30) ---
        _TestCase('Str_Val_1', true, 'Your TestBank Savings A/c XX1234 is debited with Rs. 1,250.00 on 16-08-2026 at AMAZON PAY. Avl. Bal: Rs. 23,456.78', expectedAmount: 1250.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_2', true, 'Dear Customer, Rs. 2,500.00 credited to A/c 9876****** on 16-08-26 towards salary from Demo Pvt Ltd. Net balance Rs. 45,000.00', expectedAmount: 2500.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_3', true, 'UPI/DR/612345012345: Rs 500/- debited from your DemoPay account on 16/08/2026 to MERCHANT KIRANA. UPI Ref: 612345012345', expectedAmount: 500.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_4', true, 'UPI/CR/612345012346: INR 1,500.00 credited to your account from RAMESH KUMAR. Available balance ₹12,300.50', expectedAmount: 1500.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_5', true, 'TestBank: ATM cash withdrawal of ₹10,000 from A/c ****4321 on 16-08-2026. Available Balance: ₹50,000', expectedAmount: 10000.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_6', true, 'Your credit card ending 5678 was used for INR 3,499.00 at SWIGGY on 16 Aug 2026. This is a debit transaction.', expectedAmount: 3499.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_7', true, 'Refund of Rs. 750.50 credited to your account 1234XXXXXX from FLIPKART on 16-08-2026. Total balance Rs. 10,250.25', expectedAmount: 750.50, expectedType: TransactionType.credit),
        _TestCase('Str_Val_8', true, 'EMI of Rs 4,999.00 debited from A/c 9999 for LOAN ABC on 16-08-2026. Available balance Rs 25,000.00', expectedAmount: 4999.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_9', true, 'Dear User, ₹99.00 was deducted from your wallet for mobile recharge. Transaction ID: TRX123456.', expectedAmount: 99.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_10', true, 'Salary credit: ₹1,00,000.00 to A/c 5555 on 16-08-2026 from SAMPLE TECHNOLOGIES. Balance: ₹2,00,000.00', expectedAmount: 100000.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_11', true, 'Auto debit: Rs. 1,199.00 paid to NETFLIX_SUBSCRIPTION from A/c XX8888 on 16-08-26. Avl bal: Rs. 10,000.00', expectedAmount: 1199.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_12', true, 'Interest credited Rs. 2,345.67 to your Savings A/c 1111 for Q2 FY2026. Balance: Rs. 1,23,456.78', expectedAmount: 2345.67, expectedType: TransactionType.credit),
        _TestCase('Str_Val_13', true, 'POS purchase of ₹780.00 at RELIANCE SMART with A/c ***2222 on 16-08-2026. Available balance ₹4,321.00', expectedAmount: 780.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_14', true, 'Your A/c 7777 received ₹5,000 via IMPS from PRIYA SHARMA. Ref No. 612345678901. Balance ₹15,000', expectedAmount: 5000.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_15', true, 'Insurance premium of Rs. 2,500.00 debited from account 4444 on 16/08/2026. Policy: DEMO123.', expectedAmount: 2500.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_16', true, 'Dividend of INR 1,000.00 credited to A/c 3333 on 16-08-2026 from DEMOSTOCK. Ledger balance INR 20,000.00', expectedAmount: 1000.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_17', true, 'Fuel purchase: Rs. 2,000.00 debited at HP PUMP with A/c XX6666, Date: 16-08-2026. Avl Bal: Rs. 30,000.00', expectedAmount: 2000.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_18', true, 'Cashback of Rs 50 credited to your TestBank account for UPI txn 612345012347. Balance Rs 1,250', expectedAmount: 50.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_19', true, 'Loan disbursed: ₹50,000.00 credited to your Savings A/c 8888 on 16-08-2026 by Demo FinApp.', expectedAmount: 50000.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_20', true, 'Electricity bill payment of ₹1,234.00 made from A/c 2222 to BSES. Txn ID UPI612345012348. Bal ₹9,876', expectedAmount: 1234.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_21', true, 'rs.1000.00 debited from your account 1234 on 16-08-2026 to MERCHANT XYZ. Updated balance Rs.4000.00', expectedAmount: 1000.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_22', true, 'INR 100000 credited to A/c 4321 via NEFT CR from ABC ORG on 16082026. Avail bal INR 500000', expectedAmount: 100000.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_23', true, 'Dear Cust, ₹250.75 has been debited for GST payment. A/c ****9999. Updated balance: ₹7,500.25', expectedAmount: 250.75, expectedType: TransactionType.debit),
        _TestCase('Str_Val_24', true, 'Your Demat account was credited with dividend ₹320.00. Value date 16-08-2026. Ignore if not due.', expectedAmount: 320.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_25', true, 'SIP installment of Rs. 5,000.00 debited from A/c 5555 towards MUTUAL FUND on 16 Aug 2026. Balance Rs. 45,000.00', expectedAmount: 5000.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_26', true, 'Maturity amount ₹1,50,000.00 credited to your fixed deposit linked A/c 1212 on 16-08-2026.', expectedAmount: 150000.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_27', true, 'Rent received: ₹18,000 credited to A/c 3434 on 16-08-2026 from TENANT. Balance ₹88,000', expectedAmount: 18000.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_28', true, 'Your card ending 8765 was charged ₹499.00 for subscription renewal. This will appear as an expense.', expectedAmount: 499.0, expectedType: TransactionType.debit),
        _TestCase('Str_Val_29', true, 'Wallet refund: ₹300 credited to your PayWallet. Transaction reference: REF98765. Balance ₹450.00', expectedAmount: 300.0, expectedType: TransactionType.credit),
        _TestCase('Str_Val_30', true, 'UPI expense: ₹1,00,000.00 paid to MERCHANT LIMITED via UPI. Ref: 612345012349. A/c XX9876. Balance ₹2,00,000.00', expectedAmount: 100000.0, expectedType: TransactionType.debit),

        // --- Structured Scam/Phishing (1 to 25) ---
        _TestCase('Str_Scam_1', false, 'SBI YONO: Your A/c will be blocked today. Update KYC immediately to continue services. Click: http://sbi-kyc-update.in'),
        _TestCase('Str_Scam_2', false, 'Dear Customer, Your Mobile No. has been selected for KBC Lottery 2026 of ₹25,00,000. To claim your prize pay ₹1500 registration fee to UPI: kbc-prime@okaxis'),
        _TestCase('Str_Scam_3', false, 'URGENT: Your Electricity Bill is pending and power will be disconnected tonight. Please pay immediately or update PAN: http://bijli-portal.in'),
        _TestCase('Str_Scam_4', false, "You have received ₹4,999 from 'CASHBACK_WIN'. To accept into your bank account, click this link: http://upi-accept.in or scan QR."),
        _TestCase('Str_Scam_5', false, 'Work from Home! Earn Rs 3000 to Rs 8000 daily just by liking YouTube videos and rating apps. WhatsApp: 70XXXXXX45'),
        _TestCase('Str_Scam_6', false, 'DTDC: Your parcel from the UK is held at Mumbai Customs. Pay ₹1500 clearance fee to avoid police action. Link: http://customs-clearance.co'),
        _TestCase('Str_Scam_7', false, 'TestBank: A/c XX1234 debited for Rs 15,000. If not done by you, your card is blocked. Call Customer Care immediately: +91-98XXXXXX12'),
        _TestCase('Str_Scam_8', false, 'Congrats! Pre-approved personal loan of Rs 5,00,000. 0% Interest. Disburse to your account now: http://instant-loan-approval.app'),
        _TestCase('Str_Scam_9', false, 'RBI ALERT: Your bank account is not linked to Aadhar. It will be frozen in 24 hours. Verify here: http://rbi-gov-in-verify.com'),
        _TestCase('Str_Scam_10', false, 'UPI: ₹10,000 credited to your account. To process withdrawal and accept money, enter your UPI PIN now.'),
        _TestCase('Str_Scam_11', false, 'I have recorded your private videos. Pay Rs 20,000 to UPI ID: blackmailer@oksbi or I will send them to your family contacts.'),
        _TestCase('Str_Scam_12', false, 'HDFC Bank: You are eligible for a Lifetime Free Credit Card upgrade. Pay Rs 999 refundable security deposit: http://hdfc-upgrade.cc'),
        _TestCase('Str_Scam_13', false, 'LIC Policy: Your life insurance policy has matured. Claim Rs 10,00,000. Pay Rs 500 processing fee to UPI ID: lic-claim@okicici'),
        _TestCase('Str_Scam_14', false, 'ALERT: An attempt was made to login to your NetBanking. To block this, click: http://secure-bank-login.net and enter the OTP sent to you.'),
        _TestCase('Str_Scam_15', false, 'Your FD of Rs 50,000 has matured. Renew with 12% interest. Pay Rs 200 registration fee to this UPI ID to get maturity amount.'),
        _TestCase('Str_Scam_16', false, 'Rs 2,000 credited to your account. Download the attached APK (statement.pdf.exe) to view transaction details and statement.'),
        _TestCase('Str_Scam_17', false, 'CIBIL ALERT: You are a willful defaulter. Police complaint filed. Pay Rs 15,000 settlement to UPI ID: legal-cell@okaxis to close case.'),
        _TestCase('Str_Scam_18', false, 'PM Ujjwala Yojana: Gas subsidy of Rs 2400 pending. Provide bank details and Rs 10 activation fee here: http://govt-subsidy.in'),
        _TestCase('Str_Scam_19', false, 'Income Tax Dept: Refund of Rs 14,500 is pending. Update your bank account to receive amount: http://incometax-refund-gov.com'),
        _TestCase('Str_Scam_20', false, 'Urgent: PM Cares Fund / Temple Trust needs donation. Get 100% tax exemption. Donate minimum Rs 500 to UPI: pm-cares-donate@okhdfc'),
        _TestCase('Str_Scam_21', false, 'Urgent requirement for data entry operators. Salary Rs 45,000/month. Registration fee Rs 500 required to start. Pay to UPI: hr-desk@okicici'),
        _TestCase('Str_Scam_22', false, 'Your Paytm Soundbox subscription expires today. Renew for Rs 299 to keep receiving audio alerts: http://paytm-soundbox.in'),
        _TestCase('Str_Scam_23', false, 'Flipkart: Refund of Rs 1,200 initiated to your account. To confirm bank details and receive money, call our WhatsApp Support: 88XXXXXX99'),
        _TestCase('Str_Scam_24', false, 'EPFO: Your PF amount of Rs 2,50,000 is ready for withdrawal. Pay Rs 500 tax fee to UPI ID: epfo-tax-clearance@oksbi to release funds.'),
        _TestCase('Str_Scam_25', false, 'PhonePe Alert: Your wallet has been hacked and Rs 5,000 transferred. Click here to freeze your account and reverse transaction: http://phonepe-secure.com'),
      ];

      for (final tc in userCases) {
        test(tc.label, () {
          final res = pipeline.parse(tc.sms, source: PaymentSource.sms);
          if (tc.shouldPass) {
            expect(res.isSuccess, isTrue, reason: 'Failed to parse: ${res.errorMessage}');
            expect(res.payment?.amount, tc.expectedAmount);
            if (tc.expectedType != null) {
              expect(res.payment?.type, tc.expectedType);
            }
          } else {
            expect(res.isSuccess, isFalse, reason: 'Expected to reject, but it was accepted with amount ${res.payment?.amount}');
          }
        });
      }
    });
  });
}

class _TestCase {
  final String label;
  final bool shouldPass;
  final String sms;
  final double? expectedAmount;
  final TransactionType? expectedType;

  _TestCase(this.label, this.shouldPass, this.sms, {this.expectedAmount, this.expectedType});
}
