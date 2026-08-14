import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/payment.dart';

class CategoryPickerSheet extends StatefulWidget {
  final String selectedCategory;
  final TransactionType initialType;
  final ValueChanged<String> onCategorySelected;
  final bool includeAllOption;
  final bool lockType;

  const CategoryPickerSheet({
    super.key,
    required this.selectedCategory,
    this.initialType = TransactionType.debit,
    required this.onCategorySelected,
    this.includeAllOption = false,
    this.lockType = false,
  });

  static Future<String?> show(
    BuildContext context, {
    required String selectedCategory,
    TransactionType type = TransactionType.debit,
    required ValueChanged<String> onSelected,
    bool includeAllOption = false,
    bool lockType = false,
  }) async {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryPickerSheet(
        selectedCategory: selectedCategory,
        initialType: type,
        onCategorySelected: onSelected,
        includeAllOption: includeAllOption,
        lockType: lockType,
      ),
    );
  }

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  late TransactionType _selectedType;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _currentCategories {
    final list = _selectedType == TransactionType.debit
        ? Category.expenseCategories
        : Category.incomeCategories;

    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((c) => c.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = _currentCategories;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Category',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a category for this transaction',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search categories...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 13.5),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Type Switcher: Expenses vs Income (Only shown when category type is not locked)
            if (!widget.lockType)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.debit,
                        label: Text('Expense Categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        icon: Icon(Icons.arrow_downward_rounded, size: 14),
                      ),
                      ButtonSegment(
                        value: TransactionType.credit,
                        label: Text('Income Categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        icon: Icon(Icons.arrow_upward_rounded, size: 14),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (set) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedType = set.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: WidgetStatePropertyAll(
                        BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 6),

            // "All Categories" Quick Selector Card (for History Filter)
            if (widget.includeAllOption && _searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onCategorySelected('All');
                      Navigator.pop(context, 'All');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.selectedCategory == 'All'
                            ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.selectedCategory == 'All'
                              ? theme.colorScheme.primary
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: widget.selectedCategory == 'All' ? 1.8 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.grid_view_rounded,
                              size: 18,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All Categories',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Show transactions across all categories',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          if (widget.selectedCategory == 'All')
                            Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Category Grid
            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 36,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No matching category',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = cat == widget.selectedCategory;
                        final color = Category.getColor(cat);
                        final icon = Category.getMaterialIcon(cat);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              widget.onCategorySelected(cat);
                              Navigator.pop(context, cat);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: isDark ? 0.25 : 0.15)
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : (isDark
                                          ? const Color(0xFF334155).withValues(alpha: 0.6)
                                          : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.8 : 0.8,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon Badge
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: isDark ? 0.22 : 0.14),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: color.withValues(alpha: isDark ? 0.45 : 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        icon,
                                        size: 20,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Category Label
                                  Text(
                                    cat,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected
                                          ? (isDark ? Colors.white : color)
                                          : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B)),
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sleek form input tile that displays the active category and opens the CategoryPickerSheet
class CategorySelectorTile extends StatelessWidget {
  final String selectedCategory;
  final TransactionType type;
  final ValueChanged<String> onCategorySelected;
  final String label;

  const CategorySelectorTile({
    super.key,
    required this.selectedCategory,
    this.type = TransactionType.debit,
    required this.onCategorySelected,
    this.label = 'Category',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = Category.getColor(selectedCategory);
    final icon = Category.getMaterialIcon(selectedCategory);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => CategoryPickerSheet.show(
          context,
          selectedCategory: selectedCategory,
          type: type,
          onSelected: onCategorySelected,
          lockType: true,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Colored Icon Squircle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.25 : 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.45 : 0.3),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),

              // Title & Category Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      selectedCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron / Change Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
