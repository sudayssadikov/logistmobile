import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class ReturnTripDialog extends StatelessWidget {
  final String destinationCity;
  final String originCity;

  const ReturnTripDialog({
    super.key,
    required this.destinationCity,
    required this.originCity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Success Badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 36),
            ),
            const SizedBox(height: 14),

            const Text(
              'Yuk Muvaffaqiyatli Topshirildi! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Eskrou to\'lovi hamyoningizga chiqarildi. $destinationCity shahrida turibsiz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 18),

            // AI Return Trip Recommendation Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.autorenew_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'BO\'SH QAYTMANG! (AI Return Match)',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Qurilish materiallari & Keramik plitalar',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$destinationCity ➔ $originCity (20t)',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const Text(
                        '12,800,000 UZS',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            AppButton(
              text: 'Qaytish Yukini Olish (1-Tap)',
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Qaytish reysi muvaffaqiyatli band qilindi! 🚛'),
                    backgroundColor: AppColors.emerald,
                  ),
                );
                context.push('/shipments');
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
              child: const Text('Bosh sahifaga qaytish'),
            ),
          ],
        ),
      ),
    );
  }
}
