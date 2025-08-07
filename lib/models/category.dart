class Category {
  static const List<String> defaultCategories = [
    'Food & Dining',
    'Transportation',
    'Bills & Utilities',
    'Entertainment',
    'Shopping',
    'Healthcare',
    'Education',
    'Travel',
    'Investment',
    'Other',
  ];

  static const Map<String, String> categoryIcons = {
    'Food & Dining': '🍽️',
    'Transportation': '🚗',
    'Bills & Utilities': '💡',
    'Entertainment': '🎬',
    'Shopping': '🛍️',
    'Healthcare': '⚕️',
    'Education': '📚',
    'Travel': '✈️',
    'Investment': '💰',
    'Other': '📋',
  };

  static String getIcon(String category) {
    return categoryIcons[category] ?? '📋';
  }
}