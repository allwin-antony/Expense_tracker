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

  static const Map<String, IconData> categoryMaterialIcons = {
    // Expense categories
    'Food & Dining': Icons.restaurant_rounded,
    'Groceries': Icons.shopping_cart_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Transportation': Icons.directions_car_rounded,
    'Bills & Utilities': Icons.receipt_long_rounded,
    'Entertainment': Icons.movie_filter_rounded,
    'Healthcare': Icons.medical_services_rounded,
    'Education': Icons.school_rounded,
    'Travel': Icons.flight_takeoff_rounded,
    'Investment': Icons.trending_up_rounded,
    'Personal Care': Icons.spa_rounded,
    'Other Expense': Icons.payments_rounded,

    // Income categories
    'Salary': Icons.work_rounded,
    'Freelance / Business': Icons.laptop_mac_rounded,
    'Investment Return': Icons.account_balance_wallet_rounded,
    'Cashback / Reward': Icons.stars_rounded,
    'Refund': Icons.replay_circle_filled_rounded,
    'Gift / Transfer': Icons.volunteer_activism_rounded,
    'Other Income': Icons.savings_rounded,
  };

  static const Map<String, Color> categoryColors = {
    'Food & Dining': Color(0xFFFF7043),
    'Groceries': Color(0xFF10B981),
    'Shopping': Color(0xFF8B5CF6),
    'Transportation': Color(0xFF0EA5E9),
    'Bills & Utilities': Color(0xFFF59E0B),
    'Entertainment': Color(0xFFEC4899),
    'Healthcare': Color(0xFFEF4444),
    'Education': Color(0xFF6366F1),
    'Travel': Color(0xFF06B6D4),
    'Investment': Color(0xFF14B8A6),
    'Personal Care': Color(0xFFD97706),
    'Other Expense': Color(0xFF64748B),

    'Salary': Color(0xFF22C55E),
    'Freelance / Business': Color(0xFF0284C7),
    'Investment Return': Color(0xFF84CC16),
    'Cashback / Reward': Color(0xFFEAB308),
    'Refund': Color(0xFF4F46E5),
    'Gift / Transfer': Color(0xFF9333EA),
    'Other Income': Color(0xFF0D9488),
  };

  static String getIcon(String category) {
    return categoryIcons[category] ?? '💳';
  }

  static IconData getMaterialIcon(String category) {
    return categoryMaterialIcons[category] ?? Icons.category_rounded;
  }

  static Color getColor(String category) {
    return categoryColors[category] ?? const Color(0xFF64748B);
  }

  /// Builds a professional category dropdown item with an icon badge and styled typography
  static DropdownMenuItem<String> buildDropdownItem(
    String category, {
    bool isDark = false,
  }) {
    final color = getColor(category);
    final icon = getMaterialIcon(category);

    return DropdownMenuItem<String>(
      value: category,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.4 : 0.25),
                width: 0.8,
              ),
            ),
            child: Icon(
              icon,
              size: 15,
              color: color,
            ),
          ),
          Flexible(
            child: Text(
              category,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}