import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/neu_design_system.dart';
import '../../../../shipments/presentation/bloc/shipment_bloc.dart';
import '../../../../shipments/presentation/bloc/shipment_state.dart';

class AdminFleetSurveillanceView extends StatelessWidget {
  const AdminFleetSurveillanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShipmentBloc, ShipmentState>(
      builder: (context, state) {
        final activeLoads = state.shipments.where((s) {
          final st = s.status.name.toLowerCase();
          return st.contains('transit') || st.contains('loaded') || st.contains('pickup');
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeuCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'REAL-TIME RADAR & TELEMETRIYA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${activeLoads.length} TRANSPORT HARAKATDA',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'O\'zbekiston va Xalqaro Magistrallar Jonli Monitoringi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Avtomobillarning real GPS koordinatalari va reys holati to\'g\'ridan-to\'g\'ri drayver qurilmasidan uzatiladi.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                    if (activeLoads.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      NeuButton(
                        text: 'Xaritada Kuzatish',
                        icon: Icons.map_rounded,
                        onPressed: () => context.push('/tracking/${activeLoads.first.id}'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'MAGISTRALDAGI TRANSPORTLAR RO\'YXATI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              if (activeLoads.isEmpty)
                const NeuCard(
                  padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Column(
                    children: [
                      Icon(Icons.radar_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Ayni vaqtda tranzitda faol transportlar mavjud emas',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Yangi yuk reysga chiqqanda real telemetriya ma\'lumotlari ushbu radarda ko\'rinadi.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...activeLoads.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NeuCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 16,
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
                                      border: Border.all(color: Colors.black26),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      (s.vehiclePlate != null && s.vehiclePlate!.isNotEmpty)
                                          ? s.vehiclePlate!
                                          : 'Davlat raqamisiz',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    s.trackingCode,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Text(
                                  s.status.name,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Haydovchi: ${s.driverName ?? "Biriktirilmagan"} • ${s.origin.city} ➔ ${s.destination.city}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Masofa: ${s.distanceKm > 0 ? "${s.distanceKm} km" : "Hisoblanmoqda"}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              NeuButton(
                                text: 'Kuzatish ➔',
                                variant: NeuButtonVariant.secondary,
                                height: 36,
                                onPressed: () => context.push('/tracking/${s.id}'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
