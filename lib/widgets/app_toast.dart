import 'dart:async';
import 'package:flutter/material.dart';

class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Shows a floating, animated toast banner that automatically fades away.
  static void show(
    BuildContext context, {
    required String message,
    Widget? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    // 1. Immediately dismiss any existing toast
    dismiss();

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _ToastWidget(
          message: message,
          icon: icon,
          actionLabel: actionLabel,
          onAction: () {
            dismiss();
            onAction?.call();
          },
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    // 2. Set strict auto-dismiss timer
    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  /// Immediately dismisses the current active toast
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (_currentEntry != null) {
      final entryToDismiss = _currentEntry;
      _currentEntry = null;
      try {
        entryToDismiss?.remove();
      } catch (_) {}
    }
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Widget? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ToastWidget({
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Positioned(
      bottom: mediaQuery.padding.bottom + 80, // Positioned safely above bottom navigation bar
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.actionLabel != null) ...[
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: widget.onAction,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          widget.actionLabel!,
                          style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
