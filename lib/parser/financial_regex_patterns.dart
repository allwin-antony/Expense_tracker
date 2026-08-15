class FinancialRegexPatterns {
  // Regex to reject OTPs, verification codes, and security messages
  static final RegExp otpFilterRegex = RegExp(
    r'\b(?:otp|one\s*time\s*password|verification\s*code|secret\s*code|do\s*not\s*share|security\s*code|login\s*code|auth\s*code)\b',
    caseSensitive: false,
  );

  // Regex to reject promotional, loan offers, credit line ads, cashback offers, and marketing spam
  static final RegExp promotionalFilterRegex = RegExp(
    r'\b(?:'
    r'pre[\s\-]?approved|pre[\s\-]?qualified|instant\s*loan|personal\s*loan|home\s*loan|business\s*loan|gold\s*loan|'
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

  // Rejects messages that are ONLY checking balance without any transaction keywords
  static final RegExp balanceOnlyQueryRegex = RegExp(
    r'\b(?:available\s*balance|avl\s*bal|account\s*balance)\b',
    caseSensitive: false,
  );

  // Currency & Amount extraction
  // Handles: ₹450, Rs. 1,450.50, INR 2500, Rs 500.00, Rs.450.00, etc.
  static final RegExp amountRegex = RegExp(
    r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  // Alternate Amount suffix: 450.00 INR, 500 Rs
  static final RegExp amountSuffixRegex = RegExp(
    r'([\d,]+(?:\.\d{1,2})?)\s*(?:INR|Rs\.?|₹)',
    caseSensitive: false,
  );

  // Explicit Debit keywords (past completed transaction)
  static final RegExp debitKeywordsRegex = RegExp(
    r'\b(?:debited|debit|spent|paid|withdrawn|transferred|sent|purchase|charged|deducted)\b',
    caseSensitive: false,
  );

  // Explicit Credit keywords (past completed transaction)
  static final RegExp creditKeywordsRegex = RegExp(
    r'\b(?:credited|deposited|received|refunded|refund|reversed|salary)\b',
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
    RegExp(r'(?:to|at|towards)\s+([A-Za-z0-9\s._\-&]+?)(?:\s+(?:on|ref|via|using|avl|bal|upi|from|a/c|thru|dated|worth)|[\.\,\;]|$)', caseSensitive: false),
    RegExp(r'(?:info\s*[:\-])\s*([A-Za-z0-9\s._\-&]+?)(?:\s+(?:on|ref|via|using|avl|bal)|[\.\,\;]|$)', caseSensitive: false),
    RegExp(r'(?:VPA\s+)([a-zA-Z0-9.\-_]+@[a-zA-Z]+)', caseSensitive: false),
    RegExp(r'(?:for\s+)([A-Za-z0-9\s._\-&]+?)(?:\s+(?:on|ref|via|using|avl|bal)|[\.\,\;]|$)', caseSensitive: false),
    RegExp(r'(?:paid\s+to\s+)([A-Za-z0-9\s._\-&]+?)(?:\s+(?:on|ref|via|using|avl|bal)|[\.\,\;]|$)', caseSensitive: false),
  ];
}
