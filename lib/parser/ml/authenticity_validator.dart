import '../financial_regex_patterns.dart';
import '../merchant_categorizer.dart';
import 'bert_tokenizer.dart';
import 'fasttext_engine.dart';

enum MessageIntent {
  authenticTransaction,
  promotionalOrLoanOffer,
  balanceQuery,
  otpOrSecurity,
  unknown;
}

class AuthenticityEvaluation {
  final bool isAuthentic;
  final double authenticityScore;
  final MessageIntent intent;
  final String? rejectionReason;
  final String category;
  final String cleanMerchant;
  final double confidence;

  AuthenticityEvaluation({
    required this.isAuthentic,
    required this.authenticityScore,
    required this.intent,
    this.rejectionReason,
    required this.category,
    required this.cleanMerchant,
    required this.confidence,
  });
}

class AuthenticityValidator {
  static final AuthenticityValidator instance = AuthenticityValidator._();
  AuthenticityValidator._();

  /// Validates authenticity and extracts semantic information with AI heuristics
  AuthenticityEvaluation evaluate({
    required String rawText,
    required String rawMerchant,
    required double? amount,
    required bool isCredit,
  }) {
    final clean = rawText.replaceAll('\n', ' ').trim();

    // 1. Tokenize message using BERT WordPiece tokenizer
    final tokens = BertTokenizer.instance.encode(clean, maxSeqLength: 64);
    final validTokenCount = tokens.attentionMask.where((mask) => mask == 1).length;

    // 2. Multi-Signal Scoring System
    double score = validTokenCount > 5 ? 0.50 : 0.40; // Prior conditioned on token richness
    String? rejectionReason;
    MessageIntent intent = MessageIntent.unknown;

    // Check OTP
    if (FinancialRegexPatterns.otpFilterRegex.hasMatch(clean)) {
      return AuthenticityEvaluation(
        isAuthentic: false,
        authenticityScore: 0.05,
        intent: MessageIntent.otpOrSecurity,
        rejectionReason: 'OTP verification code detected (non-transactional)',
        category: 'Other Expense',
        cleanMerchant: 'Security Alert',
        confidence: 0.99,
      );
    }

    // Check Promotional / Pre-approved loan traps
    if (FinancialRegexPatterns.promotionalFilterRegex.hasMatch(clean)) {
      return AuthenticityEvaluation(
        isAuthentic: false,
        authenticityScore: 0.10,
        intent: MessageIntent.promotionalOrLoanOffer,
        rejectionReason: 'Promotional marketing / Pre-approved loan offer detected',
        category: 'Other Expense',
        cleanMerchant: 'Promotional Offer',
        confidence: 0.95,
      );
    }

    // Check Balance-only queries (reject only if neither debit nor credit keywords exist)
    if (FinancialRegexPatterns.balanceOnlyQueryRegex.hasMatch(clean) &&
        !FinancialRegexPatterns.debitKeywordsRegex.hasMatch(clean) &&
        !FinancialRegexPatterns.creditKeywordsRegex.hasMatch(clean)) {
      return AuthenticityEvaluation(
        isAuthentic: false,
        authenticityScore: 0.20,
        intent: MessageIntent.balanceQuery,
        rejectionReason: 'Account balance query without transaction',
        category: 'Other Expense',
        cleanMerchant: 'Balance Alert',
        confidence: 0.90,
      );
    }

    // FastText Neural Semantic Evaluation (if model is initialized)
    final mlResult = FastTextEngine.instance.classify(clean);
    if (mlResult != null) {
      if (mlResult.isSpam && mlResult.confidence >= 0.70) {
        return AuthenticityEvaluation(
          isAuthentic: false,
          authenticityScore: 0.05,
          intent: MessageIntent.promotionalOrLoanOffer,
          rejectionReason: 'AI Classifier flagged promotional spam (${(mlResult.confidence * 100).toInt()}% confidence)',
          category: 'Other Expense',
          cleanMerchant: 'Promotional Offer',
          confidence: mlResult.confidence,
        );
      }
      if (mlResult.isOtp && mlResult.confidence >= 0.75) {
        return AuthenticityEvaluation(
          isAuthentic: false,
          authenticityScore: 0.05,
          intent: MessageIntent.otpOrSecurity,
          rejectionReason: 'AI Classifier flagged OTP verification (${(mlResult.confidence * 100).toInt()}% confidence)',
          category: 'Other Expense',
          cleanMerchant: 'Security Alert',
          confidence: mlResult.confidence,
        );
      }
      if (mlResult.isInfo &&
          mlResult.confidence >= 0.75 &&
          !FinancialRegexPatterns.debitKeywordsRegex.hasMatch(clean) &&
          !FinancialRegexPatterns.creditKeywordsRegex.hasMatch(clean)) {
        return AuthenticityEvaluation(
          isAuthentic: false,
          authenticityScore: 0.15,
          intent: MessageIntent.balanceQuery,
          rejectionReason: 'AI Classifier flagged balance / info message (${(mlResult.confidence * 100).toInt()}% confidence)',
          category: 'Other Expense',
          cleanMerchant: 'Balance Alert',
          confidence: mlResult.confidence,
        );
      }
    }

    // Authenticity Positive Signals
    final hasAmount = amount != null && amount > 0;
    final hasDebit = FinancialRegexPatterns.debitKeywordsRegex.hasMatch(clean);
    final hasCredit = FinancialRegexPatterns.creditKeywordsRegex.hasMatch(clean);
    final hasAcc = FinancialRegexPatterns.accountRegex.hasMatch(clean);
    final hasBank = FinancialRegexPatterns.bankNameRegex.hasMatch(clean);
    final hasRef = FinancialRegexPatterns.refIdRegex.hasMatch(clean);

    if (hasAmount) score += 0.25;
    if (hasDebit || hasCredit) score += 0.20;
    if (hasAcc) score += 0.20;
    if (hasBank) score += 0.15;
    if (hasRef) score += 0.10;

    // Blend with FastText genuine confidence if available
    if (mlResult != null && mlResult.isGenuine) {
      score = (score * 0.4) + (mlResult.confidence * 0.6);
    }

    // Phishing / Fake alert penalty (contains suspicious shortlinks without verified account)
    final hasSuspiciousUrl = (clean.contains('http://') || clean.contains('https://')) && !hasAcc && !hasRef;
    if (hasSuspiciousUrl) {
      score -= 0.40;
    }

    // Clamp score
    score = score.clamp(0.0, 1.0);

    final bool isAuthentic = score >= 0.70 && hasAmount && (hasDebit || hasCredit);

    if (isAuthentic) {
      intent = MessageIntent.authenticTransaction;
    } else {
      rejectionReason ??= 'Insufficient transactional indicators to confirm authenticity';
    }

    // Semantic categorization
    final catResult = MerchantCategorizer.categorize(
      rawMerchant: rawMerchant,
      fullMessage: clean,
      isIncome: isCredit,
    );

    return AuthenticityEvaluation(
      isAuthentic: isAuthentic,
      authenticityScore: score,
      intent: intent,
      rejectionReason: rejectionReason,
      category: catResult.category,
      cleanMerchant: catResult.cleanMerchant,
      confidence: (catResult.confidence * 0.5) + (score * 0.5),
    );
  }
}
