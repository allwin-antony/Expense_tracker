import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_preferences_service.dart';
import '../widgets/sms_permission_disclosure_dialog.dart';

class OnboardingTourSheet extends StatefulWidget {
  const OnboardingTourSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OnboardingTourSheet(),
    );
  }

  @override
  State<OnboardingTourSheet> createState() => _OnboardingTourSheetState();
}

class _OnboardingTourSheetState extends State<OnboardingTourSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TourSlide> _slides = const [
    _TourSlide(
      icon: Icons.mark_email_read_rounded,
      gradientColors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
      title: 'Automatic Banking SMS Sync',
      subtitle:
          'Effortlessly captures debit & credit transactions from Indian Bank & UPI SMS messages (HDFC, SBI, ICICI, Swiggy, Paytm & more) 100% offline.',
      badgeText: '100% Offline AI',
    ),
    _TourSlide(
      icon: Icons.security_rounded,
      gradientColors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
      title: 'Biometric Lock & Privacy Mode',
      subtitle:
          'Secure your financial records behind Fingerprint or Face Unlock. Use Public Privacy Mode to obscure balance totals (₹ ••••••) in public places.',
      badgeText: 'Complete Security',
    ),
    _TourSlide(
      icon: Icons.insights_rounded,
      gradientColors: [Color(0xFF059669), Color(0xFF10B981)],
      title: 'Category & Merchant Analytics',
      subtitle:
          'Gain crystal-clear clarity on where your money goes. Analyze spending by Category or top Merchants, track daily averages, and set custom rules.',
      badgeText: 'Smart Insights',
    ),
    _TourSlide(
      icon: Icons.notifications_active_rounded,
      gradientColors: [Color(0xFFD97706), Color(0xFFF59E0B)],
      title: 'Instant Action Notifications',
      subtitle:
          'Get heads-up notifications with interactive action buttons to Exclude or Delete transactions directly from your phone’s notification bar.',
      badgeText: 'One-Tap Actions',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishTour() async {
    HapticFeedback.mediumImpact();
    await AppPreferencesService.instance.setHasCompletedOnboarding(true);
    if (mounted) {
      Navigator.of(context).pop();
      // Prompt for SMS disclosure & permission upon finishing tour
      await SmsPermissionDisclosureDialog.showDisclosureAndRequest(context);
    }
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishTour();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Top Handle Bar & Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Spacer
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  TextButton(
                    onPressed: _finishTour,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Container
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: slide.gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: slide.gradientColors.first.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(slide.icon, size: 44, color: Colors.white),
                        ),
                        const SizedBox(height: 24),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: slide.gradientColors.first.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            slide.badgeText,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: slide.gradientColors.first,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Row (Dots & Next Button)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots Indicator
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF2563EB)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Get Started Button
                  FilledButton.icon(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      _currentPage == _slides.length - 1
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourSlide {
  final IconData icon;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final String badgeText;

  const _TourSlide({
    required this.icon,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.badgeText,
  });
}
