import 'package:flutter/material.dart';

class Category {
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Shopping',
    'Transportation',
    'Bills & Utilities',
    'Entertainment',
    'Healthcare',
    'Education',
    'Travel',
    'Investment',
    'Personal Care',
    'Groceries',
    'Other Expense',
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Freelance / Business',
    'Investment Return',
    'Cashback / Reward',
    'Refund',
    'Gift / Transfer',
    'Other Income',
  ];

  static List<String> get allCategories => [
        ...expenseCategories,
        ...incomeCategories,
      ];

  static const Map<String, String> categoryIcons = {
    // Expense categories
    'Food & Dining': '🍽️',
    'Groceries': '🛒',
    'Shopping': '🛍️',
    'Transportation': '🚗',
    'Bills & Utilities': '💡',
    'Entertainment': '🎬',
    'Healthcare': '⚕️',
    'Education': '📚',
    'Travel': '✈️',
    'Investment': '📈',
    'Personal Care': '💅',
    'Other Expense': '💸',

    // Income categories
    'Salary': '💼',
    'Freelance / Business': '💻',
    'Investment Return': '💰',
    'Cashback / Reward': '🎁',
    'Refund': '🔄',
    'Gift / Transfer': '🤝',
    'Other Income': '💵',
  };

  static const Map<String, Color> categoryColors = {
    'Food & Dining': Color(0xFFFF7043),
    'Groceries': Color(0xFF26A69A),
    'Shopping': Color(0xFFAB47BC),
    'Transportation': Color(0xFF42A5F5),
    'Bills & Utilities': Color(0xFFFFA726),
    'Entertainment': Color(0xFFEC407A),
    'Healthcare': Color(0xFFEF5350),
    'Education': Color(0xFF5C6BC0),
    'Travel': Color(0xFF29B6F6),
    'Investment': Color(0xFF66BB6A),
    'Personal Care': Color(0xFF8D6E63),
    'Other Expense': Color(0xFF78909C),

    'Salary': Color(0xFF43A047),
    'Freelance / Business': Color(0xFF00ACC1),
    'Investment Return': Color(0xFF7CB342),
    'Cashback / Reward': Color(0xFFFFB300),
    'Refund': Color(0xFF3949AB),
    'Gift / Transfer': Color(0xFF8E24AA),
    'Other Income': Color(0xFF00897B),
  };

  static String getIcon(String category) {
    return categoryIcons[category] ?? '💳';
  }

  static Color getColor(String category) {
    return categoryColors[category] ?? const Color(0xFF78909C);
  }
}