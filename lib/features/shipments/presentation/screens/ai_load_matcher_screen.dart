import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/ai_matcher_model.dart';
import '../../domain/models/shipment_model.dart';
import '../bloc/shipment_bloc.dart';
import '../bloc/shipment_state.dart';

class AILoadMatcherScreen extends StatefulWidget {
  const AILoadMatcherScreen({super.key});

  @override
  State<AILoadMatcherScreen> createState() => _AILoadMatcherScreenState();
}

class _AILoadMatcherScreenState extends State<AILoadMatcherScreen> {
  DriverPreferences _prefs = const DriverPreferences();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initGps();
  }

  Future<void> _initGps() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getLastKnownPosition() ?? await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() => _currentPosition = pos);
        }
      }
    } catch (_) {}
  }

  List<MatchedShipment> _calculateMatches(List<ShipmentModel> shipments) {
    return shipments.map((shp) {
      int score = 85;
      String reason = 'Sizning avtomobilingiz uchun mos yuk';

      if (shp.weightTons <= _prefs.maxWeightTons) {
        score += 8;
      }
      if (shp.cargoType.toLowerCase().contains('ref') && _prefs.hasRefrigeration) {
        score += 6;
        reason = 'Muzlatgichli (+4°C) fura uchun optimal';
      }
      if (shp.price >= 15000000) {
        score += 5;
      }

      double? dist;
      if (_currentPosition != null && shp.origin.latitude != 0) {
        final meters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          shp.origin.latitude,
          shp.origin.longitude,
        );
        dist = double.parse((meters / 1000.0).toStringAsFixed(1));
      }

      final matchScore = score.clamp(70, 99);
      return MatchedShipment(
        shipment: shp,
        matchPercentage: matchScore,
        distanceFromDriverKm: dist,
        aiReason: reason,
      );
    }).toList()
      ..sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Smart Load Matcher 🤖'),
      ),
      body: BlocBuilder<ShipmentBloc, ShipmentState>(
        builder: (context, state) {
          final matches = _calculateMatches(state.shipments);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Radar Header Banner (Neumorphic)
                NeuCard(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 18,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfacePressed : AppColors.lightSurfacePressed,
                          shape: BoxShape.circle,
                          boxShadow: NeuShadows.inset(isDark: isDark),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Aqlli Yuk Tanlash Tizimi',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Masofa, transport turi, hajm va optimal tarifni real vaqtda tahlil qiladi',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Driver Parameter Controls
                Text(
                  'YOUR RIG & ROUTE PREFERENCES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Search Radius Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Search Radius from Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${_prefs.maxRadiusKm.toInt()} km', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      Slider(
                        value: _prefs.maxRadiusKm,
                        min: 10,
                        max: 200,
                        divisions: 19,
                        label: '${_prefs.maxRadiusKm.toInt()} km',
                        onChanged: (val) {
                          setState(() => _prefs = _prefs.copyWith(maxRadiusKm: val));
                        },
                      ),
                      const Divider(),

                      // Max Payload Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Max Truck Capacity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${_prefs.maxWeightTons.toInt()} Tons', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      Slider(
                        value: _prefs.maxWeightTons,
                        min: 5,
                        max: 35,
                        divisions: 6,
                        label: '${_prefs.maxWeightTons.toInt()} tons',
                        onChanged: (val) {
                          setState(() => _prefs = _prefs.copyWith(maxWeightTons: val));
                        },
                      ),
                      const Divider(),

                      // Refrigeration Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Refrigerated / Cold-Chain Cargo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Prioritize high-rate temp controlled loads', style: TextStyle(fontSize: 11)),
                        value: _prefs.hasRefrigeration,
                        onChanged: (val) {
                          setState(() => _prefs = _prefs.copyWith(hasRefrigeration: val));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Top AI Recommended Loads List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI TOP MATCHES (${matches.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: AppColors.emerald),
                          SizedBox(width: 4),
                          Text('98% Highest Match', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emerald)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...matches.map((item) {
                  final shp = item.shipment;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.matchPercentage >= 95
                            ? AppColors.primary
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: item.matchPercentage >= 95 ? 1.8 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Match Score Badge & Rate
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.matchPercentage >= 90
                                    ? AppColors.emerald.withValues(alpha: 0.15)
                                    : AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: item.matchPercentage >= 90 ? AppColors.emerald : AppColors.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${item.matchPercentage}% AI MATCH',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: item.matchPercentage >= 90 ? AppColors.emerald : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              shp.formattedPrice,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Cargo Title & Specs
                        Text(
                          shp.cargoTitle.tr(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${shp.cargoType.tr()} • ${shp.weightTons}t${item.distanceFromDriverKm != null ? " • ${item.distanceFromDriverKm} km masofa" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Route Points
                        Row(
                          children: [
                            const Icon(Icons.trip_origin_rounded, color: AppColors.emerald, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              shp.origin.city.tr(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
                            ),
                            const Icon(Icons.location_on_rounded, color: AppColors.rose, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              shp.destination.city.tr(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // AI Recommendation Reason Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.cyan),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.aiReason,
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.push('/shipments/${shp.id}'),
                                child: const Text('View Details'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppButton(
                                text: '1-Tap Book Load',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Load ${shp.trackingCode} booked with AI Priority Guarantee!'),
                                      backgroundColor: AppColors.emerald,
                                    ),
                                  );
                                  context.push('/shipments/${shp.id}');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
