import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/payment.dart';
import '../services/database_service.dart';

class AddCategoryDialog extends StatefulWidget {
  final TransactionType initialType;
  final bool lockType;

  const AddCategoryDialog({
    super.key,
    this.initialType = TransactionType.debit,
    this.lockType = false,
  });

  static Future<String?> show(
    BuildContext context, {
    TransactionType initialType = TransactionType.debit,
    bool lockType = false,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AddCategoryDialog(
        initialType: initialType,
        lockType: lockType,
      ),
    );
  }

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late TransactionType _selectedType;
  String? _selectedIconKey;
  Color? _selectedColor;



  final List<Color> _availableColors = [
    const Color(0xFFFF7043), const Color(0xFF10B981), const Color(0xFF8B5CF6),
    const Color(0xFF0EA5E9), const Color(0xFFF59E0B), const Color(0xFFEC4899),
    const Color(0xFFEF4444), const Color(0xFF6366F1), const Color(0xFF06B6D4),
    const Color(0xFF14B8A6), const Color(0xFFD97706), const Color(0xFF64748B),
    const Color(0xFF22C55E), const Color(0xFF0284C7), const Color(0xFF84CC16),
    const Color(0xFFEAB308), const Color(0xFF4F46E5), const Color(0xFF9333EA),
    const Color(0xFF0D9488), const Color(0xFFF43F5E), const Color(0xFF8B5CF6),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIconKey == null || _selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an icon and a color.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (Category.allCategories.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category already exists.')),
      );
      return;
    }

    final typeStr = _selectedType == TransactionType.debit ? 'expense' : 'income';

    await DatabaseService.instance.addCustomCategory(
      name: name,
      type: typeStr,
      iconCode: _selectedIconKey!,
      colorValue: _selectedColor!.toARGB32(),
    );

    Category.addCustomCategory(
      name: name,
      type: typeStr,
      icon: Category.iconRegistry[_selectedIconKey!]!,
      color: _selectedColor!,
    );

    if (mounted) {
      Navigator.pop(context, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
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
                const SizedBox(height: 16),
                if (!widget.lockType)
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.debit,
                        label: Text('Expense', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: TransactionType.credit,
                        label: Text('Income', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (set) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedType = set.first);
                    },
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter a name';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text('Select Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: Category.iconRegistry.length,
                    itemBuilder: (context, index) {
                      final iconKey = Category.iconRegistry.keys.elementAt(index);
                      final icon = Category.iconRegistry[iconKey]!;
                      final isSelected = _selectedIconKey == iconKey;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedIconKey = iconKey);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: isSelected ? theme.colorScheme.primary : null),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Select Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _availableColors.length,
                    itemBuilder: (context, index) {
                      final color = _availableColors[index];
                      final isSelected = _selectedColor == color;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedColor = color);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
