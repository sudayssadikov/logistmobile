import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/status_badge.dart';

class AdminFleetSurveillanceView extends StatelessWidget {
  const AdminFleetSurveillanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mockVehicles = [
      {
        'plate': '01 842 TAA',
        'model': 'MAN TGX 18.500',
        'driver': 'Dilshod Raximov',
        'route': 'Toshkent ➔ Samarqand (M39)',
        'speed': '78 km/h',
        'status': 'Tranzitda',
        'statusColor': AppColors.emerald,
        'trackingCode': 'LF-UZ-8921',
      },
      {
        'plate': '01 950 UBA',
        'model': 'Volvo FH16 (Ref)',
        'driver': 'Rustam Karimov',
        'route': 'Toshkent ➔ Buxoro',
        'speed': '65 km/h',
        'status': 'Tranzitda',
        'statusColor': AppColors.emerald,
        'trackingCode': 'LF-UZ-8922',
      },
      {
        'plate': '40 312 FBA',
        'model': 'DAF XF 105',
        'driver': 'Botir Qodirov',
        'route': 'Farg\'ona ➔ Toshkent (Kamchiq)',
        'speed': '0 km/h (To\'xtash)',
        'status': 'Tekshiruvda',
        'statusColor': AppColors.rose,
        'trackingCode': 'LF-UZ-8923',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Surveillance Map Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'REAL-TIME RADAR & TELEMATICS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '142 AVTOMOBIL FAOL',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emerald),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'O\'zbekiston va MDH Magistrallari Jonli Monitoringi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Avtomobillarning tezligi, to\'xtash vaqti va yo\'ldagi hodisalar real vaqtda qayd etiladi.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'To\'liq Xaritani Ochish (OSM 100% Free)',
                  prefixIcon: Icons.map_rounded,
                  onPressed: () => context.push('/tracking/SHP-1001'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active Fleet Units
          Text(
            'MAGISTRALDAGI TRANSPORTLAR RO\'YXATI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: mockVehicles.map((v) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                v['plate'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              v['model'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                        StatusBadge(
                          label: v['status'] as String,
                          color: v['statusColor'] as Color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Haydovchi: ${v['driver']} • ${v['route']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tezlik: ${v['speed']}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: () => context.push('/tracking/${v['trackingCode']}'),
                          child: const Text('Kuzatish ➔', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
