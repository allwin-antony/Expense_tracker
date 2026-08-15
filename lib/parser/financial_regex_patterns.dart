class FinancialRegexPatterns {
  // Regex to reject OTPs, verification codes, and security messages
  static final RegExp otpFilterRegex = RegExp(
    r'\b(?:otp|one\s*time\s*password|verification\s*code|secret\s*code|do\s*not\s*share|security\s*code|login\s*code|auth\s*code)\b',
    caseSensitive: false,
  );

  // Regex to reject promotional, loan offers, credit line ads, cashback offers, and marketing spam
  static final RegExp promotionalFilterRegex = RegExp(
    r'\b(?:'
    r'pre[\s\-]?approved|pre[\s\-]?qualified|instant\s*loan|(?:apply|avail|get|instant|eligible\s*for)\s*(?:a\s*)?(?:personal|home|business|gold)\s*loan|'
    r'loan\s*(?:of|upto|up\s*to)|apply\s*(?:now|for)|avail\s*now|claim\s*now|click\s*(?:here|link|to\s*avail)|'
    r'congratulations|good\s*news|hurry|limited\s*(?:period\s*)?offer|offer\s*valid|'
    r'win\s*(?:upto|up\s*to)|chance\s*to\s*win|lucky\s*draw|coupon\s*code|voucher|'
    r'flat\s*(?:off|discount|rs)|upto\s*(?:rs\.?|inr|₹)|\bup\s*to\s*(?:rs\.?|inr|₹)|'
    r'credit\s*card\s*offer|limit\s*increase|enhanced\s*limit|approved\s*limit|eligible\s*for|'
    r'when\s*you\s*avail|when\s*you\s*apply|when\s*you\s*order|on\s*your\s*next\s*order|'
    r'cashback\s*(?:upto|up\s*to|of\s*up\s*to|worth)|reward\s*points\s*worth|'
    r'is\s*due\s*on|due\s*date\s*is|payment\s*is\s*due|minimum\s*(?:amount\s*)?due|pay\s*before|'
    r'get\s*(?:rs\.?|inr|₹)\s*[\d,]+\s*off|save\s*(?:rs\.?|inr|₹)'
    r')\b',
    caseSensitive: false,
  );

  // Regex to reject failed or pending transactions (incomplete state)
  static final RegExp failedOrPendingFilterRegex = RegExp(
    r'\b(?:failed|declined|unsuccessful|transaction\s*failed|payment\s*failed|is\s*pending|payment\s*is\s*pending|payment\s*pending|txn\s*failed)\b',
    caseSensitive: false,
  );

  // Regex to reject spam scams, phishing baiting, and security threats (KYC, fake refunds, lottery, job scams)
  static final RegExp scamFilterRegex = RegExp(
    r'\b(?:'
    r'kyc\s*verification|update\s*kyc|yono\s*(?:account)?|account\s*(?:will\s*be\s*)?blocked|account\s*(?:will\s*be\s*)?suspended|'
    r'confirm\s*bank\s*details|verify\s*your\s*bank\s*account|card\s*is\s*blocked\b.*\bcall|call\s*customer\s*care|'
    r'lottery\b|scratch\s*card\s*cashback|won\s*(?:rs|₹|\$|£|€)|claim\s*your\s*(?:prize|reward|amount)|'
    r'registration\s*fee|processing\s*fee|tax\s*fee|activation\s*fee|clearance\s*fee|'
    r'to\s*release\s*funds|to\s*receive\s*money|approve\s*the\s*transfer|'
    r'enter\s*(?:your\s*)?upi\s*pin|upi\s*pin\s*to|'
    r'work\s*from\s*home|work\s*part[- ]time|earn\s*(?:rs|₹|\$|£|€)\s*\d+.*\b(?:daily|day|month)|'
    r'download\s*(?:the\s*)?attached\s*apk|statement\.pdf\.exe|statement\.apk|'
    r'whatsapp\s*support\b|whatsapp\s*to\s*start'
    r')\b',
    caseSensitive: false,
  );

  // Rejects messages that are ONLY checking balance without any transaction keywords
  static final RegExp balanceOnlyQueryRegex = RegExp(
    r'\b(?:available\s*balance|avl\s*bal|account\s*balance)\b',
    caseSensitive: false,
  );

  // Currency & Amount extraction
  // Handles: ₹450, Rs. 1,450.50, INR 2500, USD 15.99, $45.20, £14.50, etc.
  static final RegExp amountRegex = RegExp(
    r'(?:INR|Rs\.?|₹|USD|GBP|EUR|\$|£|€)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Alternate Amount suffix: 450.00 INR, 500 Rs, 15 USD
  static final RegExp amountSuffixRegex = RegExp(
    r'([\d,]+(?:\.\d{1,2})?)\s*(?:INR|Rs\.?|₹|USD|GBP|EUR|\$|£|€)',
    caseSensitive: false,
  );

  // Explicit Debit keywords (past completed transaction)
  static final RegExp debitKeywordsRegex = RegExp(
    r'\b(?:debited|debit|spent|paid|withdrawn|withdrawal|transferred|sent|purchase|charged|deducted|emi|was\s*used\s*for|using\s*your|used\s*at|processed\s*from|sip|installment|made\s*from|payment\s*of|transaction\s*of)\b',
    caseSensitive: false,
  );

  // Explicit Credit keywords (past completed transaction)
  static final RegExp creditKeywordsRegex = RegExp(
    r'\b(?:credited|deposited|deposit|received|refunded|refund|reversed|salary|contribution|interest|dividend|disbursed|posted)\b',
    caseSensitive: false,
  );

  // Account / Card / VPA references
  static final RegExp accountRegex = RegExp(
    r'(?:(?:a/c|acct|account|card|vpa)\s*(?:no\.?|ending(?:\s*with)?)?\s*[:\-]?\s*([xX*]+[\d]{3,4}|[a-zA-Z0-9.\-_]+@(?:upi|[a-zA-Z0-9]+)|[\d]{4}))',
    caseSensitive: false,
  );

  // Bank name extraction (Covering RBI Public, Private, Small Finance, Payments Banks & Cards)
  static final RegExp bankNameRegex = RegExp(
    r'\b(HDFC|SBI|STATE\s*BANK\s*OF\s*INDIA|ICICI|AXIS|KOTAK|PNB|BOB|BANK\s*OF\s*BARODA|CANARA|UNION\s*BANK|BANK\s*OF\s*INDIA|INDIAN\s*BANK|CENTRAL\s*BANK|IOB|UCO\s*BANK|BANK\s*OF\s*MAHARASHTRA|PUNJAB\s*&\s*SIND|INDUSIND|YES\s*BANK|IDFC\s*FIRST|FEDERAL\s*BANK|RBL|BANDHAN|KARUR\s*VYSYA|CITY\s*UNION|SOUTH\s*INDIAN|J&K\s*BANK|JAMMU\s*&\s*KASHMIR|TAMILNAD\s*MERCANTILE|KARNATAKA\s*BANK|CSB\s*BANK|DCB\s*BANK|AU\s*SMALL\s*FINANCE|EQUITAS|UJJIVAN|JANA|CAPITAL|UTKARSH|SURYODAY|ESAF|PAYTM\s*BANK|AIRTEL\s*BANK|IPPB|INDIA\s*POST|NSDL\s*BANK|FINO|CRED|ONECARD|AMEX|CITI|HSBC|STANDARD\s*CHARTERED)\b',
    caseSensitive: false,
  );

  // UPI Reference / UTR / Txn ID
  static final RegExp refIdRegex = RegExp(
    r'(?:(?:UPI\s*Ref(?:\s*no)?|UTR|Txn\s*ID|Ref\s*no|Reference\s*No)\s*[:\-]?\s*([0-9a-zA-Z]{6,16}))',
    caseSensitive: false,
  );

  // Merchant extraction patterns
  static final List<RegExp> merchantPatterns = [
    RegExp(r'(?:to|at|towards)\s+([A-Za-z0-9\s._\-&@]+?)(?:\s+(?:on|ref|via|using|avl|bal|upi|from|a/c|thru|dated|worth)|[\.\,\;]|$)', caseSensitive: false),
    RegExp(r'(?:info\s*[:\-])\s*([A-Za-z0-9\s._\-&@]+?)(?:\s+(?:on|ref|via|using|avl|bal)|[\.\,\;]|$)', caseSensitive: false),
    RegExp(r'(?:VPA\s+)([a-zA-Z0-9.\-_]+@[a-zA-Z]+)', caseSensitive: false),
    RegExp(r'(?:for\s+)([A-Za-z0-9\s._\-&@]+?)(?:\s+(?:on|ref|via|using|avl|bal)|[\.\,\;]|$)', caseSensitive: false),
    RegExp(r'(?:paid\s+to\s+)([A-Za-z0-9\s._\-&@]+?)(?:\s+(?:on|ref|via|using|avl|bal)|[\.\,\;]|$)', caseSensitive: false),
  ];

  /// Validates whether the sender is an official TRAI alphanumeric header and not a personal phone number
  static bool isLegitimateTraiHeader(String? sender) {
    if (sender == null || sender.trim().isEmpty) {
      // Allow manual clipboard paste or text parsing when sender is not provided
      return true;
    }
    final clean = sender.trim().replaceAll(RegExp(r'[\s\-]'), '');

    // If sender consists only of digits and optional '+' (e.g. +919876543210, 9876543210, +14155552671)
    // and is 7 or more digits, it is a personal phone number and must be rejected!
    final isPurePhoneNumber = RegExp(r'^\+?\d{7,15}$').hasMatch(clean);
    if (isPurePhoneNumber) {
      return false;
    }

    // A legitimate TRAI header must contain alphabetic characters (e.g. "VK-SBIINB", "VM-HDFCBK", "PAYTM", "HDFCBK")
    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(clean);
    return hasLetters;
  }
}
