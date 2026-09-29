import 'package:equatable/equatable.dart';
import '../../../shipments/domain/models/shipment_model.dart';

class RouteManeuver extends Equatable {
  final String instructionUz;
  final String instructionEn;
  final String instructionRu;
  final String distanceText;
  final String iconType; // 'turn_right', 'straight', 'roundabout', 'destination'

  const RouteManeuver({
    required this.instructionUz,
    required this.instructionEn,
    required this.instructionRu,
    required this.distanceText,
    required this.iconType,
  });

  @override
  List<Object?> get props => [instructionUz, instructionEn, instructionRu, distanceText, iconType];
}

class NavigationState extends Equatable {
  final bool isNavigating;
  final ShipmentModel? shipment;
  final int currentStepIndex;
  final List<RouteManeuver> maneuvers;
  final bool voiceGuidanceEnabled;
  final double currentSpeedKmh;
  final double remainingDistanceKm;
  final int remainingMinutes;
  final String? spokenAlert;

  const NavigationState({
    this.isNavigating = false,
    this.shipment,
    this.currentStepIndex = 0,
    this.maneuvers = const [],
    this.voiceGuidanceEnabled = true,
    this.currentSpeedKmh = 76.0,
    this.remainingDistanceKm = 142.5,
    this.remainingMinutes = 115,
    this.spokenAlert,
  });

  RouteManeuver? get currentManeuver =>
      maneuvers.isNotEmpty && currentStepIndex < maneuvers.length ? maneuvers[currentStepIndex] : null;

  NavigationState copyWith({
    bool? isNavigating,
    ShipmentModel? shipment,
    int? currentStepIndex,
    List<RouteManeuver>? maneuvers,
    bool? voiceGuidanceEnabled,
    double? currentSpeedKmh,
    double? remainingDistanceKm,
    int? remainingMinutes,
    String? spokenAlert,
    bool clearAlert = false,
  }) {
    return NavigationState(
      isNavigating: isNavigating ?? this.isNavigating,
      shipment: shipment ?? this.shipment,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      maneuvers: maneuvers ?? this.maneuvers,
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      remainingDistanceKm: remainingDistanceKm ?? this.remainingDistanceKm,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      spokenAlert: clearAlert ? null : (spokenAlert ?? this.spokenAlert),
    );
  }

  @override
  List<Object?> get props => [
        isNavigating,
        shipment,
        currentStepIndex,
        maneuvers,
        voiceGuidanceEnabled,
        currentSpeedKmh,
        remainingDistanceKm,
        remainingMinutes,
        spokenAlert,
      ];
}
