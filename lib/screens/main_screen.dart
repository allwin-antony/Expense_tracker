import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';
import '../widgets/add_payment_dialog.dart';
import '../services/database_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  String? _historyCategory;
  String? _historyType;
  DateTime? _historyMonth;

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _navigateToHistoryWithFilters(String category, TransactionType type, DateTime month) {
    HapticFeedback.mediumImpact();
    setState(() {
      _historyCategory = category;
      _historyType = type == TransactionType.debit ? 'Expense' : 'Income';
      _historyMonth = month;
      _selectedIndex = 1; // Switch to History tab
    });
  }

  void _openQuickAdd() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPaymentDialog(
        onPaymentAdded: (payment) async {
          await DatabaseService.instance.addPayment(payment);
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            onNavigateToHistory: () => _onItemTapped(1),
          ),
          HistoryScreen(
            initialCategory: _historyCategory,
            initialFilterType: _historyType,
            initialMonth: _historyMonth,
          ),
          StatisticsScreen(
            onCategorySelected: _navigateToHistoryWithFilters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQuickAdd,
        elevation: 4,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.transparent,
          indicatorColor: theme.colorScheme.primaryContainer.withValues(alpha: isDark ? 0.4 : 0.6),
          elevation: 0,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 22),
              selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF2563EB), size: 22),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_rounded, size: 22),
              selectedIcon: Icon(Icons.history_toggle_off_rounded, color: Color(0xFF2563EB), size: 22),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined, size: 22),
              selectedIcon: Icon(Icons.insights_rounded, color: Color(0xFF2563EB), size: 22),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }
}