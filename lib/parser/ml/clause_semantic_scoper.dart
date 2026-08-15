import '../financial_regex_patterns.dart';

enum ClauseType {
  transactionEvent,
  balanceStatement,
  greetingOrHeader,
  other,
}

class ScopedClause {
  final String text;
  final ClauseType type;

  const ScopedClause({
    required this.text,
    required this.type,
  });
}

class ClauseSemanticScoper {
  static final ClauseSemanticScoper instance = ClauseSemanticScoper._();
  ClauseSemanticScoper._();

  // Keywords that identify static balance or limit statements
  static final RegExp _balanceKeywordsRegex = RegExp(
    r'\b(?:passbook\s*balance|available\s*balance|avl\s*bal|account\s*balance|total\s*balance|remaining\s*balance|ledger\s*balance|updated\s*balance|net\s*balance|clear\s*bal|available\s*limit|avail\s*limit|avail\s*lmt|limit\s*available|avail\.\s*lmt)\b',
    caseSensitive: false,
  );

  // Keywords that identify active transaction events (debit, credit, contribution, spent, paid, received)
  static final RegExp _transactionKeywordsRegex = RegExp(
    r'\b(?:debited|debit|spent|paid|withdrawn|transferred|sent|charged|deducted|credited|deposited|received|refunded|refund|reversed|salary|contribution|dividend|disbursed|posted|using|used|processed|sip|installment|made\s*from|payment\s*of|transaction\s*of)\b',
    caseSensitive: false,
  );

  // Greeting or header patterns
  static final RegExp _greetingRegex = RegExp(
    r'^(?:dear|hi|hello|alert|notification|info|notice|update)\b',
    caseSensitive: false,
  );

  /// Splits raw SMS into distinct clauses while preserving currency decimals (e.g. "Rs. 46,119/-")
  List<String> splitIntoClauses(String rawSms) {
    final clean = rawSms.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (clean.isEmpty) return [];

    // Split on newlines or sentence-ending periods (avoiding splitting "Rs. 100" or "45.50")
    final List<String> rawClauses = [];
    final lines = clean.split('\n');

    final sentenceSplitter = RegExp(r'(?<!\bRs|\bINR|\bRe|\bdr|\bmr|\bms|\bA\/c|\bNo)(?:\/|\-|\w{2,})\.\s+(?=[A-Z])|;\s*');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      final subClauses = trimmedLine.split(sentenceSplitter);
      for (final sub in subClauses) {
        final t = sub.trim();
        if (t.isNotEmpty) {
          rawClauses.add(t);
        }
      }
    }

    return rawClauses;
  }

  /// Classifies a single clause into its semantic type
  ClauseType classifyClause(String clause) {
    final lower = clause.toLowerCase().trim();

    // Check if it's a greeting/header
    if (_greetingRegex.hasMatch(lower) && !FinancialRegexPatterns.amountRegex.hasMatch(clause)) {
      return ClauseType.greetingOrHeader;
    }

    // Check if it's an active transaction event clause
    final hasTxnKeyword = _transactionKeywordsRegex.hasMatch(lower);
    final hasAmount = FinancialRegexPatterns.amountRegex.hasMatch(clause) ||
        FinancialRegexPatterns.amountSuffixRegex.hasMatch(clause);

    final isBalanceStatement = _balanceKeywordsRegex.hasMatch(lower);

    if (isBalanceStatement) {
      // If clause contains balance keywords, check if it ALSO contains a distinct transaction verb
      if (hasTxnKeyword && (lower.contains('debited') || lower.contains('credited') || lower.contains('spent') || lower.contains('contribution'))) {
        return ClauseType.transactionEvent;
      }
      return ClauseType.balanceStatement;
    }

    if (hasTxnKeyword || (hasAmount && (lower.contains('rs') || lower.contains('inr') || lower.contains('₹')))) {
      return ClauseType.transactionEvent;
    }

    return ClauseType.other;
  }

  /// Evaluates an SMS, segregates clauses, and isolates the primary Transaction Event clause.
  /// Falls back to full raw SMS if no single transaction clause is segregated.
  String isolateTransactionClause(String rawSms) {
    final clauses = splitIntoClauses(rawSms);
    if (clauses.length <= 1) return rawSms;

    final List<ScopedClause> scopedClauses = [];
    final List<String> txnEventClauses = [];

    for (final c in clauses) {
      final type = classifyClause(c);
      scopedClauses.add(ScopedClause(text: c, type: type));
      if (type == ClauseType.transactionEvent) {
        txnEventClauses.add(c);
      }
    }

    // If exactly one clause is a Transaction Event, return that isolated clause!
    if (txnEventClauses.length == 1) {
      return txnEventClauses.first;
    }

    // If multiple transaction clauses exist, join them excluding pure balance clauses
    final nonBalanceClauses = scopedClauses
        .where((sc) => sc.type != ClauseType.balanceStatement && sc.type != ClauseType.greetingOrHeader)
        .map((sc) => sc.text)
        .toList();

    if (nonBalanceClauses.isNotEmpty) {
      return nonBalanceClauses.join('. ');
    }

    return rawSms;
  }
}
