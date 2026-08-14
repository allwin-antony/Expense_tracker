import '../models/payment.dart';
import 'financial_regex_patterns.dart';
import 'merchant_categorizer.dart';

class ParsedTransactionResult {
  final bool isSuccess;
  final String? errorMessage;
  final Payment? payment;
  final double confidence;
  final String? rawMerchant;
  final String? refId;

  ParsedTransactionResult({
    required this.isSuccess,
    this.errorMessage,
    this.payment,
    this.confidence = 0.0,
    this.rawMerchant,
    this.refId,
  });

  factory ParsedTransactionResult.failure(String message) {
    return ParsedTransactionResult(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class MessageParserPipeline {
  static final MessageParserPipeline instance = MessageParserPipeline._();
  MessageParserPipeline._();

  /// Validates whether the given message is a legitimate financial transaction alert
  bool isFinancialMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length < 10) return false;

    // Filter out OTPs and non-transaction security messages
    if (FinancialRegexPatterns.otpFilterRegex.hasMatch(trimmed)) {
      return false;
    }

    // Filter out promotional, loan marketing, and spam ads
    if (FinancialRegexPatterns.promotionalFilterRegex.hasMatch(trimmed)) {
      return false;
    }

    // Must contain a debit or credit intent indicator
    final hasDebit = FinancialRegexPatterns.debitKeywordsRegex.hasMatch(trimmed);
    final hasCredit = FinancialRegexPatterns.creditKeywordsRegex.hasMatch(trimmed);

    if (!hasDebit && !hasCredit) {
      return false;
    }

    // Must contain an amount pattern
    final hasAmount = FinancialRegexPatterns.amountRegex.hasMatch(trimmed) ||
        FinancialRegexPatterns.amountSuffixRegex.hasMatch(trimmed);

    if (!hasAmount) return false;

    // Additional check: If message contains promotional URLs and lacks any bank or account/card reference, reject
    final hasUrl = trimmed.toLowerCase().contains('http://') || trimmed.toLowerCase().contains('https://');
    final hasAcc = FinancialRegexPatterns.accountRegex.hasMatch(trimmed);
    final hasBank = FinancialRegexPatterns.bankNameRegex.hasMatch(trimmed);
    final hasRef = FinancialRegexPatterns.refIdRegex.hasMatch(trimmed);

    if (hasUrl && !hasAcc && !hasBank && !hasRef) {
      return false;
    }

    return true;
  }

  /// Parses a bank SMS, transaction notification, or clipboard text
  ParsedTransactionResult parse(
    String text, {
    PaymentSource source = PaymentSource.sms,
  }) {
    final cleanText = text.replaceAll('\n', ' ').trim();

    if (!isFinancialMessage(cleanText)) {
      return ParsedTransactionResult.failure(
        'No valid financial transaction (amount & debit/credit keyword) detected in this text.',
      );
    }

    // 1. Extract Amount
    double? extractedAmount;
    final prefixMatch = FinancialRegexPatterns.amountRegex.firstMatch(cleanText);
    if (prefixMatch != null && prefixMatch.group(1) != null) {
      final amountStr = prefixMatch.group(1)!.replaceAll(',', '').trim();
      extractedAmount = double.tryParse(amountStr);
    }

    if (extractedAmount == null) {
      final suffixMatch = FinancialRegexPatterns.amountSuffixRegex.firstMatch(cleanText);
      if (suffixMatch != null && suffixMatch.group(1) != null) {
        final amountStr = suffixMatch.group(1)!.replaceAll(',', '').trim();
        extractedAmount = double.tryParse(amountStr);
      }
    }

    if (extractedAmount == null || extractedAmount <= 0) {
      return ParsedTransactionResult.failure('Could not extract a valid transaction amount.');
    }

    // 2. Extract Transaction Type (Debit vs Credit)
    final hasDebit = FinancialRegexPatterns.debitKeywordsRegex.hasMatch(cleanText);
    final hasCredit = FinancialRegexPatterns.creditKeywordsRegex.hasMatch(cleanText);

    TransactionType type = TransactionType.debit;
    final lower = cleanText.toLowerCase();
    if (hasCredit && (!hasDebit || lower.contains('refund') || lower.contains('salary') || lower.contains('received') || lower.contains('credited'))) {
      type = TransactionType.credit;
    }

    // 3. Extract Account / Card / Bank reference
    String? accountRef;
    final bankMatch = FinancialRegexPatterns.bankNameRegex.firstMatch(cleanText);
    final accMatch = FinancialRegexPatterns.accountRegex.firstMatch(cleanText);

    final bankName = bankMatch?.group(1)?.toUpperCase();
    final accNumber = accMatch?.group(1);

    if (bankName != null && accNumber != null) {
      accountRef = '$bankName A/c $accNumber';
    } else if (accNumber != null) {
      accountRef = 'A/c $accNumber';
    } else if (bankName != null) {
      accountRef = '$bankName Bank';
    }

    // 4. Extract Payment Mode
    PaymentMode paymentMode = PaymentMode.upi;
    if (lower.contains('card') || lower.contains('pos') || lower.contains('credit card') || lower.contains('debit card')) {
      paymentMode = PaymentMode.card;
    } else if (lower.contains('neft') || lower.contains('imps') || lower.contains('rtgs') || lower.contains('netbanking') || lower.contains('net banking')) {
      paymentMode = PaymentMode.netBanking;
    } else if (lower.contains('atm') || lower.contains('cash')) {
      paymentMode = PaymentMode.cash;
    } else if (lower.contains('upi') || lower.contains('vpa')) {
      paymentMode = PaymentMode.upi;
    }

    // 5. Extract Reference / UTR
    final refMatch = FinancialRegexPatterns.refIdRegex.firstMatch(cleanText);
    final refId = refMatch?.group(1);

    // 6. Extract Merchant / Payee
    String rawMerchant = '';
    for (final pattern in FinancialRegexPatterns.merchantPatterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null && match.group(1) != null) {
        final candidate = match.group(1)!.trim();
        if (candidate.isNotEmpty && candidate.length > 2 && candidate.length < 50) {
          rawMerchant = candidate;
          break;
        }
      }
    }

    // 7. Semantic categorization & normalization
    final catResult = MerchantCategorizer.categorize(
      rawMerchant: rawMerchant,
      fullMessage: cleanText,
      isIncome: type == TransactionType.credit,
    );

    final payment = Payment(
      description: catResult.cleanMerchant,
      amount: extractedAmount,
      type: type,
      category: catResult.category,
      paymentMode: paymentMode,
      source: source,
      accountReference: accountRef,
      rawMessage: cleanText,
      confidence: catResult.confidence,
      date: DateTime.now(),
      notes: refId != null ? 'Ref: $refId' : null,
    );

    return ParsedTransactionResult(
      isSuccess: true,
      payment: payment,
      confidence: catResult.confidence,
      rawMerchant: rawMerchant,
      refId: refId,
    );
  }
}
