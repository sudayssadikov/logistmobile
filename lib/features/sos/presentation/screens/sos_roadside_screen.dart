import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../domain/models/sos_model.dart';
import '../bloc/sos_bloc.dart';
import '../bloc/sos_event.dart';
import '../bloc/sos_state.dart';

class SosRoadsideScreen extends StatefulWidget {
  const SosRoadsideScreen({super.key});

  @override
  State<SosRoadsideScreen> createState() => _SosRoadsideScreenState();
}

class _SosRoadsideScreenState extends State<SosRoadsideScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SosBloc>().add(const FetchNearbySosProvidersRequested());
  }

  void _triggerEmergencyBroadcast(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.rose, size: 28),
            SizedBox(width: 8),
            Text('SOS Favqulodda Yordam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Siz turgan joy koordinatalari (M39 trassasi, 210-km) eng yaqin TIR-evakuator va servis guruhlariga avtomatik yuboriladi. Dispetcherlik 60 soniya ichida siz bilan bog\'lanadi.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SosBloc>().add(
                    const DispatchEmergencyAlertRequested(
                      latitude: 40.1158,
                      longitude: 67.8422,
                      type: SosServiceType.heavyTowTruck,
                      driverPhone: '+998 90 123 45 67',
                      notes: 'TIR breakdown on highway',
                    ),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚨 SOS signal yuborildi! Eng yaqin evakuator yo\'lga chiqdi.'),
                  backgroundColor: AppColors.rose,
                  duration: Duration(seconds: 4),
                ),
              );
            },
            child: const Text('Ha, Yordam Chaqirish (SOS)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filterOptions = [
      {'title': 'Barchasi', 'type': null},
      {'title': '🚜 TIR Evakuator', 'type': SosServiceType.heavyTowTruck},
      {'title': '🛞 Vulkanizatsiya', 'type': SosServiceType.tyreRepair},
      {'title': '🔧 Dizel Servis', 'type': SosServiceType.dieselRepair},
      {'title': '⛽ Yoqilg\'i yetkazish', 'type': SosServiceType.fuelDelivery},
      {'title': '⚡ Avtoelektrik', 'type': SosServiceType.autoElectric},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Yo\'lda Yordam & TIR Radar 🆘'),
      ),
      body: BlocBuilder<SosBloc, SosState>(
        builder: (context, state) {
          return Column(
            children: [
              // Top GPS Highway Radar Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rose.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sizning GPS nuqtangiz:',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const Text(
                            'M39 trassasi, 210-km (Jizzax yaqinida)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lat: ${state.currentLatitude.toStringAsFixed(4)} • Lng: ${state.currentLongitude.toStringAsFixed(4)}',
                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: filterOptions.map((opt) {
                    final isSelected = state.activeFilter == opt['type'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(opt['title'] as String),
                        selected: isSelected,
                        onSelected: (_) {
                          context.read<SosBloc>().add(
                                ChangeSosFilterType(opt['type'] as SosServiceType?),
                              );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Nearby Providers List
              Expanded(
                child: state.status == SosStatus.loading && state.providers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.providers.isEmpty
                        ? const EmptyStateView(
                            icon: Icons.car_repair_rounded,
                            title: 'No nearby services found',
                            description: 'Try changing the category filter or refreshing your GPS coordinates.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: state.providers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final p = state.providers[index];

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.rose.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.build_circle_outlined, color: AppColors.rose, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            p.address,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.emerald.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '📍 ${p.distanceKm} km yaqinlikda (${p.estimatedArrivalMinutes})',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.emerald,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '⭐ ${p.rating}',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Direct Phone Call Button
                                    IconButton.filled(
                                      icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                                      style: IconButton.styleFrom(backgroundColor: AppColors.emerald),
                                      tooltip: 'Qo\'ng\'iroq qilish: ${p.phone}',
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Qo\'ng\'iroq qilinmoqda: ${p.phone} (${p.name})'),
                                            backgroundColor: AppColors.emerald,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Bottom Red SOS Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
                    label: const Text(
                      'Barcha Yaqin Xizmatlarga SOS Yuborish',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rose,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: () => _triggerEmergencyBroadcast(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
