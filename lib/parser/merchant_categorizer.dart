class CategorizationResult {
  final String cleanMerchant;
  final String category;
  final double confidence;

  CategorizationResult({
    required this.cleanMerchant,
    required this.category,
    required this.confidence,
  });
}

class MerchantCategorizer {
  // Exact merchant mapping
  static final Map<String, String> _merchantCategoryMap = {
    // Food & Dining
    'zomato': 'Food & Dining',
    'swiggy': 'Food & Dining',
    'dominos': 'Food & Dining',
    'mcdonalds': 'Food & Dining',
    'mcdonald': 'Food & Dining',
    'kfc': 'Food & Dining',
    'starbucks': 'Food & Dining',
    'burger king': 'Food & Dining',
    'pizza hut': 'Food & Dining',
    'subway': 'Food & Dining',
    'chai point': 'Food & Dining',
    'chaayos': 'Food & Dining',
    'barbeque nation': 'Food & Dining',
    'haldiram': 'Food & Dining',
    'behrouz': 'Food & Dining',
    'faasos': 'Food & Dining',
    'ovenstory': 'Food & Dining',
    'eatfit': 'Food & Dining',
    'dineout': 'Food & Dining',
    'cafe coffee day': 'Food & Dining',
    'costa coffee': 'Food & Dining',
    'third wave coffee': 'Food & Dining',
    'blue tokai': 'Food & Dining',

    // Groceries
    'blinkit': 'Groceries',
    'zepto': 'Groceries',
    'instamart': 'Groceries',
    'bigbasket': 'Groceries',
    'bbnow': 'Groceries',
    'dmart': 'Groceries',
    'reliance fresh': 'Groceries',
    'reliance smart': 'Groceries',
    'spencers': 'Groceries',
    'nature basket': 'Groceries',
    'country delight': 'Groceries',
    'dunzo': 'Groceries',
    'freshtohome': 'Groceries',
    'licious': 'Groceries',

    // Shopping
    'amazon': 'Shopping',
    'amzn': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Shopping',
    'ajio': 'Shopping',
    'nykaa': 'Shopping',
    'meesho': 'Shopping',
    'tata cliq': 'Shopping',
    'zara': 'Shopping',
    'h&m': 'Shopping',
    'decathlon': 'Shopping',
    'croma': 'Shopping',
    'reliance digital': 'Shopping',
    'vijay sales': 'Shopping',
    'ikea': 'Shopping',
    'uniqlo': 'Shopping',
    'westside': 'Shopping',
    'pantaloons': 'Shopping',
    'shoppers stop': 'Shopping',
    'max fashion': 'Shopping',
    'lenskart': 'Shopping',

    // Transportation
    'uber': 'Transportation',
    'ola': 'Transportation',
    'rapido': 'Transportation',
    'irctc': 'Transportation',
    'indian railways': 'Transportation',
    'redbus': 'Transportation',
    'abhibus': 'Transportation',
    'yulu': 'Transportation',
    'fastag': 'Transportation',
    'iocl': 'Transportation',
    'hpcl': 'Transportation',
    'bpcl': 'Transportation',
    'shell': 'Transportation',
    'petrol': 'Transportation',
    'fuel': 'Transportation',
    'toll': 'Transportation',
    'chalo': 'Transportation',
    'namma metro': 'Transportation',
    'delhi metro': 'Transportation',
    'dmrc': 'Transportation',

    // Bills & Utilities
    'bescom': 'Bills & Utilities',
    'cesc': 'Bills & Utilities',
    'mseb': 'Bills & Utilities',
    'tneb': 'Bills & Utilities',
    'uppcl': 'Bills & Utilities',
    'bses': 'Bills & Utilities',
    'tata power': 'Bills & Utilities',
    'adani electricity': 'Bills & Utilities',
    'airtel': 'Bills & Utilities',
    'jio': 'Bills & Utilities',
    'vodafone': 'Bills & Utilities',
    'bsnl': 'Bills & Utilities',
    'act fibernet': 'Bills & Utilities',
    'hathway': 'Bills & Utilities',
    'tataplay': 'Bills & Utilities',
    'tata play': 'Bills & Utilities',
    'dishtv': 'Bills & Utilities',
    'dish tv': 'Bills & Utilities',
    'igl': 'Bills & Utilities',
    'mahanagar gas': 'Bills & Utilities',
    'indane': 'Bills & Utilities',
    'hp gas': 'Bills & Utilities',
    'bharat gas': 'Bills & Utilities',
    'cred club': 'Bills & Utilities',

    // Entertainment
    'netflix': 'Entertainment',
    'hotstar': 'Entertainment',
    'disney': 'Entertainment',
    'prime video': 'Entertainment',
    'spotify': 'Entertainment',
    'apple music': 'Entertainment',
    'youtube': 'Entertainment',
    'bookmyshow': 'Entertainment',
    'pvr': 'Entertainment',
    'inox': 'Entertainment',
    'cinepolis': 'Entertainment',
    'steam': 'Entertainment',
    'playstation': 'Entertainment',
    'sonyliv': 'Entertainment',
    'zee5': 'Entertainment',

    // Healthcare
    'apollo': 'Healthcare',
    'pharmeasy': 'Healthcare',
    '1mg': 'Healthcare',
    'tata 1mg': 'Healthcare',
    'netmeds': 'Healthcare',
    'medplus': 'Healthcare',
    'practo': 'Healthcare',
    'hospital': 'Healthcare',
    'clinic': 'Healthcare',
    'pharmacy': 'Healthcare',
    'diagnostics': 'Healthcare',
    'dr lal': 'Healthcare',
    'metropolis': 'Healthcare',

    // Education
    'coursera': 'Education',
    'udemy': 'Education',
    'unacademy': 'Education',
    'byjus': 'Education',
    'upgrad': 'Education',
    'simplilearn': 'Education',

    // Travel
    'makemytrip': 'Travel',
    'goibibo': 'Travel',
    'cleartrip': 'Travel',
    'easemytrip': 'Travel',
    'agoda': 'Travel',
    'booking.com': 'Travel',
    'airbnb': 'Travel',
    'indigo': 'Travel',
    'air india': 'Travel',
    'spicejet': 'Travel',
    'vistara': 'Travel',
    'akasa air': 'Travel',
    'oyo': 'Travel',

    // Investment & Wealth
    'zerodha': 'Investment',
    'groww': 'Investment',
    'upstox': 'Investment',
    'angelone': 'Investment',
    'angel one': 'Investment',
    'kuvera': 'Investment',
    'smallcase': 'Investment',
    'indmoney': 'Investment',
    'etmoney': 'Investment',
    'mutual fund': 'Investment',
    'changejar': 'Investment',
    'jar app': 'Investment',
    'multipl': 'Investment',

    // Financial Services & UPI Apps
    'cred': 'Bills & Utilities',
    'cred club': 'Bills & Utilities',
    'bharatpe': 'Financial Services',
    'bajaj finserv': 'Financial Services',
    'mobikwik': 'Financial Services',
    'money view': 'Financial Services',
    'cheq': 'Financial Services',
    'fave': 'Financial Services',
    'slice': 'Financial Services',
    'jupiter': 'Financial Services',
    'fi money': 'Financial Services',
    'navi': 'Financial Services',
    'kreditbee': 'Financial Services',
    'freo': 'Financial Services',
    'novio': 'Financial Services',
    'kotak811': 'Financial Services',
    'lxme': 'Investment',
    'paytm': 'Financial Services',
    'phonepe': 'Financial Services',
    'google pay': 'Financial Services',
    'gpay': 'Financial Services',
    'amazon pay': 'Financial Services',

    // Personal Care
    'urban company': 'Personal Care',
    'cult.fit': 'Personal Care',
    'cultfit': 'Personal Care',
    'salon': 'Personal Care',
    'spa': 'Personal Care',
    'kaya': 'Personal Care',

    // Income
    'salary': 'Salary',
    'payroll': 'Salary',
    'stipend': 'Salary',
    'dividend': 'Investment Return',
    'cashback': 'Cashback / Reward',
    'refund': 'Refund',
  };

  static final Map<String, List<String>> _categoryKeywords = {
    'Food & Dining': ['restaurant', 'cafe', 'bistro', 'dining', 'bakery', 'kitchen', 'pizza', 'burger', 'sweets'],
    'Groceries': ['supermarket', 'mart', 'provision', 'grocery', 'vegetables', 'fruits', 'dairy'],
    'Transportation': ['cab', 'taxi', 'auto', 'metro', 'toll', 'parking', 'fuel', 'petrol', 'diesel', 'cng', 'fastag', 'railway', 'bus'],
    'Bills & Utilities': ['electricity', 'broadband', 'water bill', 'gas bill', 'dth', 'maintenance bill', 'power bill'],
    'Entertainment': ['cinema', 'movie', 'theatre', 'gaming', 'streaming', 'concert'],
    'Healthcare': ['hospital', 'pharmacy', 'chemist', 'clinic', 'medical', 'dental', 'pathology', 'doctor'],
    'Shopping': ['retail', 'apparel', 'electronics', 'footwear', 'mall', 'fashion'],
    'Travel': ['flight', 'airline', 'hotel', 'resort', 'homestay', 'holiday'],
    'Investment': ['equity', 'shares', 'stocks', 'mutual fund', 'deposit', 'securities', 'sip'],
    'Salary': ['salary', 'payroll', 'wages', 'stipend'],
    'Cashback / Reward': ['cashback', 'reward'],
    'Refund': ['refund', 'reversal', 'reversed'],
  };

  static bool _hasWord(String text, String word) {
    final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
    return pattern.hasMatch(text);
  }

  static String cleanMerchantName(String raw) {
    var cleaned = raw.trim();

    // Remove prefixes (UPI, POS, VPA, NEFT, IMPS, RTGS references)
    cleaned = cleaned.replaceAll(
      RegExp(
        r'^(?:UPI\/[\d]+\/|POS\s+[\d]+\s+|VPA\s+|INFO:\s*|TO\s+|AT\s+|FOR\s+|NEFT\s*(?:Cr|Dr)?[\-\s]*[A-Z0-9]+[\-\s]*)',
        caseSensitive: false,
      ),
      '',
    );

    // Remove trailing bank/account transaction identifiers (e.g. -AXISP00821906005)
    cleaned = cleaned.replaceAll(RegExp(r'[\-\s]+[A-Z]{4,5}[\dA-Z]{6,16}$', caseSensitive: false), '');

    // Extract VPA prefix
    if (cleaned.contains('@')) {
      final parts = cleaned.split('@');
      final prefix = parts[0].replaceAll(RegExp(r'[\d\-_]+$'), '');
      if (prefix.isNotEmpty && prefix.length > 2) {
        cleaned = prefix;
      }
    }

    // Remove noise words
    cleaned = cleaned.replaceAll(RegExp(r'\b(?:pvt|ltd|limited|private|india|technologies|services|payments|in)\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9\s&\.]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) return 'Merchant';
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ').trim();
  }

  static CategorizationResult categorize({
    required String rawMerchant,
    required String fullMessage,
    required bool isIncome,
  }) {
    // 1. If it is an Income transaction, prioritize Income categories
    if (isIncome) {
      if (_hasWord(fullMessage, 'refund') || _hasWord(fullMessage, 'reversal') || _hasWord(fullMessage, 'reversed')) {
        final merchant = rawMerchant.isNotEmpty ? cleanMerchantName(rawMerchant) : 'Refund';
        return CategorizationResult(
          cleanMerchant: merchant,
          category: 'Refund',
          confidence: 0.95,
        );
      }
      if (_hasWord(fullMessage, 'salary') ||
          _hasWord(fullMessage, 'payroll') ||
          _hasWord(fullMessage, 'stipend') ||
          fullMessage.toLowerCase().contains('neft cr')) {
        final merchant = rawMerchant.isNotEmpty ? cleanMerchantName(rawMerchant) : 'Salary';
        return CategorizationResult(
          cleanMerchant: merchant,
          category: 'Salary',
          confidence: 0.95,
        );
      }
      if (_hasWord(fullMessage, 'cashback') || _hasWord(fullMessage, 'reward')) {
        final merchant = rawMerchant.isNotEmpty ? cleanMerchantName(rawMerchant) : 'Cashback';
        return CategorizationResult(
          cleanMerchant: merchant,
          category: 'Cashback / Reward',
          confidence: 0.95,
        );
      }
      if (_hasWord(fullMessage, 'dividend') || _hasWord(fullMessage, 'interest')) {
        return CategorizationResult(
          cleanMerchant: rawMerchant.isNotEmpty ? cleanMerchantName(rawMerchant) : 'Investment Return',
          category: 'Investment Return',
          confidence: 0.90,
        );
      }
    }

    // 2. Direct merchant dictionary with word boundary matching
    for (final entry in _merchantCategoryMap.entries) {
      if (_hasWord(rawMerchant, entry.key) || _hasWord(fullMessage, entry.key)) {
        return CategorizationResult(
          cleanMerchant: cleanMerchantName(entry.key.toUpperCase()),
          category: entry.value,
          confidence: 0.95,
        );
      }
    }

    // 3. Keyword matching with word boundary
    for (final entry in _categoryKeywords.entries) {
      for (final kw in entry.value) {
        if (_hasWord(rawMerchant, kw) || _hasWord(fullMessage, kw)) {
          return CategorizationResult(
            cleanMerchant: cleanMerchantName(rawMerchant.isNotEmpty ? rawMerchant : entry.key),
            category: entry.key,
            confidence: 0.85,
          );
        }
      }
    }

    // 4. Default fallback
    if (isIncome) {
      return CategorizationResult(
        cleanMerchant: cleanMerchantName(rawMerchant.isNotEmpty ? rawMerchant : 'Income Source'),
        category: 'Other Income',
        confidence: 0.60,
      );
    }

    return CategorizationResult(
      cleanMerchant: cleanMerchantName(rawMerchant.isNotEmpty ? rawMerchant : 'Expense'),
      category: 'Other Expense',
      confidence: 0.50,
    );
  }
}
