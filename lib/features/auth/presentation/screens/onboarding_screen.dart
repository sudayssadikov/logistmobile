import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLang = context.read<LocalizationBloc>().state.language;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile.language'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            final isSelected = lang == currentLang;
            return ListTile(
              leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
              title: Text(lang.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                Navigator.of(ctx).pop();
                context.read<LocalizationBloc>().add(ChangeLanguageEvent(lang));
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locState = context.watch<LocalizationBloc>().state;

    final slides = [
      _OnboardingItem(
        title: 'onboarding.slide1Title'.tr(),
        subtitle: 'onboarding.slide1Subtitle'.tr(),
        icon: Icons.hub_rounded,
        accentColor: AppColors.primary,
      ),
      _OnboardingItem(
        title: 'onboarding.slide2Title'.tr(),
        subtitle: 'onboarding.slide2Subtitle'.tr(),
        icon: Icons.security_rounded,
        accentColor: AppColors.emerald,
      ),
      _OnboardingItem(
        title: 'onboarding.slide3Title'.tr(),
        subtitle: 'onboarding.slide3Subtitle'.tr(),
        icon: Icons.navigation_rounded,
        accentColor: AppColors.cyan,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip & Language
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'common.appName'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _showLanguageDialog(context),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              Text(locState.language.flag, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Text(locState.language.code.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'auth.skip'.tr(),
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.accentColor.withValues(alpha: 0.12),
                            border: Border.all(color: item.accentColor.withValues(alpha: 0.3), width: 2),
                          ),
                          child: Center(
                            child: Icon(item.icon, size: 64, color: item.accentColor),
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Pagination Dots & Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: _currentPage == slides.length - 1 ? 'auth.getStarted'.tr() : 'common.next'.tr(),
                    suffixIcon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      if (_currentPage < slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go('/login');
                      }
                    },
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

class _OnboardingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });
}
