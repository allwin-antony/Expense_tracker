import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/category.dart';

class PaymentCard extends StatefulWidget {
  final Payment payment;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleExcluded;
  final ValueChanged<DateTime?>? onAssignBudgetMonth;

  const PaymentCard({
    super.key,
    required this.payment,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.onToggleExcluded,
    this.onAssignBudgetMonth,
  });

  @override
  State<PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<PaymentCard> {
  bool _isPressed = false;

  void _showBudgetMonthPicker(BuildContext context) {
    HapticFeedback.selectionClick();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final payment = widget.payment;
    final originalMonth = DateTime(payment.date.year, payment.date.month, 1);
    final nextMonth = DateTime(payment.date.year, payment.date.month + 1, 1);
    final prevMonth = DateTime(payment.date.year, payment.date.month - 1, 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Assign Budget Month',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose which month this transaction counts towards in budget & analytics totals.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                // Option 1: Original Transaction Month
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF2563EB)),
                  title: Text(
                    'Actual Month (${DateFormat('MMMM yyyy').format(originalMonth)})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Count in the month the payment actually occurred', style: TextStyle(fontSize: 11.5)),
                  trailing: (payment.budgetMonth == null ||
                          (payment.budgetMonth!.year == originalMonth.year &&
                              payment.budgetMonth!.month == originalMonth.month))
                      ? const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onAssignBudgetMonth?.call(null);
                  },
                ),

                // Option 2: Next Month (+1)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF7C3AED)),
                  title: Text(
                    'Next Month (${DateFormat('MMMM yyyy').format(nextMonth)})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('e.g. Month-end early salary budgeted for next month', style: TextStyle(fontSize: 11.5)),
                  trailing: (payment.budgetMonth != null &&
                          payment.budgetMonth!.year == nextMonth.year &&
                          payment.budgetMonth!.month == nextMonth.month)
                      ? const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onAssignBudgetMonth?.call(nextMonth);
                  },
                ),

                // Option 3: Previous Month (-1)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0284C7)),
                  title: Text(
                    'Previous Month (${DateFormat('MMMM yyyy').format(prevMonth)})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('e.g. Late reimbursement or delayed expense', style: TextStyle(fontSize: 11.5)),
                  trailing: (payment.budgetMonth != null &&
                          payment.budgetMonth!.year == prevMonth.year &&
                          payment.budgetMonth!.month == prevMonth.month)
                      ? const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onAssignBudgetMonth?.call(prevMonth);
                  },
                ),

                // Option 4: Pick Custom Month
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month_outlined, color: Color(0xFFEA580C)),
                  title: const Text(
                    'Custom Month...',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Pick any specific year and month', style: TextStyle(fontSize: 11.5)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: payment.effectiveMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      helpText: 'SELECT BUDGET MONTH',
                    );
                    if (picked != null) {
                      widget.onAssignBudgetMonth?.call(DateTime(picked.year, picked.month, 1));
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExcluded = widget.payment.isExcludedFromBudget;
    final isIncome = widget.payment.type == TransactionType.credit;
    final isCurrentYear = widget.payment.date.year == DateTime.now().year;
    final dateTimeFormatter = isCurrentYear
        ? DateFormat('d MMM, h:mm a')
        : DateFormat('d MMM yy, h:mm a');

    final amountColor = isExcluded
        ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
        : (isIncome
            ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
            : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)));

    final categoryColor = Category.getColor(widget.payment.category);

    final cardContent = AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isExcluded
                ? (isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFCBD5E1))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            style: isExcluded ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        color: isExcluded
            ? (isDark ? const Color(0xFF151C28) : const Color(0xFFF8FAFC))
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap?.call();
          },
          onHighlightChanged: (pressed) {
            setState(() => _isPressed = pressed);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            widget.onLongPress?.call();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Category Icon Container with subtle gradient & shadow
                Opacity(
                  opacity: isExcluded ? 0.6 : 1.0,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Category.getMaterialIcon(widget.payment.category),
                        size: 21,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title, Badges & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.payment.description,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                letterSpacing: -0.2,
                                color: isExcluded
                                    ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isExcluded)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155).withValues(alpha: 0.6)
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.do_not_disturb_on_outlined,
                                    size: 10,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Excluded',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Badges row: Category, Mode, Account, Budget Month Shift Badge
                      Wrap(
                        spacing: 5,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            widget.payment.category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isExcluded
                                  ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: 11.5,
                            ),
                          ),
                          Text('•', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.payment.paymentMode.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isExcluded
                                    ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (widget.payment.accountReference != null &&
                              widget.payment.accountReference!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: isExcluded ? 0.2 : 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.payment.accountReference!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isExcluded
                                      ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          if (widget.payment.hasShiftedBudgetMonth)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF4C1D95).withValues(alpha: 0.6)
                                    : const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF8B5CF6) : const Color(0xFFC4B5FD),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swap_horiz_rounded,
                                    size: 11,
                                    color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Budget: ${DateFormat('MMM yyyy').format(widget.payment.budgetMonth!)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF6D28D9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text('•', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                          Text(
                            dateTimeFormatter.format(widget.payment.date),
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Amount & Auto-sync badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'} ₹${NumberFormat('#,##,###.00').format(widget.payment.amount)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: -0.3,
                        color: amountColor,
                        decoration: isExcluded ? TextDecoration.lineThrough : null,
                        decorationColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                    if (widget.payment.source == PaymentSource.sms ||
                        widget.payment.source == PaymentSource.clipboard)
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 9, color: Colors.blue.shade600),
                            const SizedBox(width: 3),
                            Text(
                              widget.payment.source.displayName,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Popup Menu
                if (widget.onEdit != null ||
                    widget.onDelete != null ||
                    widget.onToggleExcluded != null ||
                    widget.onAssignBudgetMonth != null)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      if (widget.onAssignBudgetMonth != null)
                        const PopupMenuItem(
                          value: 'budget_month',
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF7C3AED)),
                              SizedBox(width: 10),
                              Text('Assign Budget Month...', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      if (widget.onToggleExcluded != null)
                        PopupMenuItem(
                          value: isExcluded ? 'include' : 'exclude',
                          child: Row(
                            children: [
                              Icon(
                                isExcluded
                                    ? Icons.notifications_active_outlined
                                    : Icons.do_not_disturb_on_outlined,
                                size: 18,
                                color: isExcluded ? const Color(0xFF2563EB) : const Color(0xFFEAB308),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isExcluded ? 'Include in Budget' : 'Exclude from Budget',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      if (widget.onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Edit', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      if (widget.onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13)),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) {
                      if (value == 'budget_month') _showBudgetMonthPicker(context);
                      if (value == 'edit') widget.onEdit?.call();
                      if (value == 'delete') widget.onDelete?.call();
                      if (value == 'exclude') widget.onToggleExcluded?.call(true);
                      if (value == 'include') widget.onToggleExcluded?.call(false);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // If neither edit nor delete is enabled, return raw card
    if (widget.onDelete == null && widget.onEdit == null) {
      return cardContent;
    }

    // Dismissible with swipe actions (75% drag threshold prevents accidental swipes while scrolling)
    return Dismissible(
      key: ValueKey('payment_${widget.payment.id ?? widget.payment.date.microsecondsSinceEpoch}'),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.75,
        DismissDirection.endToStart: 0.75,
      },
      direction: widget.onDelete != null
          ? (widget.onEdit != null
              ? DismissDirection.horizontal
              : DismissDirection.endToStart)
          : DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Swipe left -> Delete
          HapticFeedback.heavyImpact();
          widget.onDelete?.call();
          return false;
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe right -> Edit
          HapticFeedback.lightImpact();
          widget.onEdit?.call();
          return false;
        }
        return false;
      },
      // Background for swipe right (Edit)
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.edit, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      // Secondary background for swipe left (Delete)
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white, size: 20),
          ],
        ),
      ),
      child: cardContent,
    );
  }
}
