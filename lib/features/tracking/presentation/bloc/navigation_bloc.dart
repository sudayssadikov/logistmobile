import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  Timer? _routeSimulationTimer;

  NavigationBloc() : super(const NavigationState()) {
    on<StartNavigation>(_onStartNavigation);
    on<ToggleVoiceGuidance>(_onToggleVoiceGuidance);
    on<AdvanceRouteStep>(_onAdvanceRouteStep);
    on<EndNavigation>(_onEndNavigation);
  }

  void _onStartNavigation(StartNavigation event, Emitter<NavigationState> emit) {
    _routeSimulationTimer?.cancel();

    final mockManeuvers = [
      const RouteManeuver(
        instructionUz: '300 metrdan so\'ng o\'ngga buriling: M39 Toshkent - Samarqand trassasi',
        instructionEn: 'In 300 meters, turn right onto M39 Highway towards Samarkand',
        instructionRu: 'Через 300 метров поверните направо на трассу М39 в сторону Самарканда',
        distanceText: '300 m',
        iconType: 'turn_right',
      ),
      const RouteManeuver(
        instructionUz: 'M39 magistral yo\'li bo\'ylab to\'g\'ri 45 km davom eting',
        instructionEn: 'Continue straight along M39 highway for 45 km',
        instructionRu: 'Продолжайте движение прямо по трассе М39 на протяжении 45 км',
        distanceText: '45 km',
        iconType: 'straight',
      ),
      const RouteManeuver(
        instructionUz: 'Jizzax aylanma yo\'li: 2-chi chiqish orqali aylanaga kiring',
        instructionEn: 'Jizzakh bypass: Take the 2nd exit at the roundabout',
        instructionRu: 'Объездная Джизака: съезжайте на 2-й съезд кольцевого движения',
        distanceText: '1.2 km',
        iconType: 'roundabout',
      ),
      const RouteManeuver(
        instructionUz: 'Manzilga 500 metr qoldi: Samarqand Logistika Markazi, 12-Dok',
        instructionEn: 'Destination in 500 meters: Samarkand Logistics Hub, Dock 12',
        instructionRu: 'До пункта назначения 500 метров: Самаркандский логистический центр, Док 12',
        distanceText: '500 m',
        iconType: 'destination',
      ),
    ];

    emit(state.copyWith(
      isNavigating: true,
      shipment: event.shipment,
      currentStepIndex: 0,
      maneuvers: mockManeuvers,
      spokenAlert: mockManeuvers.first.instructionUz,
      remainingDistanceKm: 142.5,
      remainingMinutes: 115,
      currentSpeedKmh: 78.0,
    ));

    // Simulated progress timer
    _routeSimulationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      add(AdvanceRouteStep());
    });
  }

  void _onToggleVoiceGuidance(ToggleVoiceGuidance event, Emitter<NavigationState> emit) {
    emit(state.copyWith(voiceGuidanceEnabled: event.enabled));
  }

  void _onAdvanceRouteStep(AdvanceRouteStep event, Emitter<NavigationState> emit) {
    if (state.currentStepIndex < state.maneuvers.length - 1) {
      final nextIdx = state.currentStepIndex + 1;
      final nextManeuver = state.maneuvers[nextIdx];
      emit(state.copyWith(
        currentStepIndex: nextIdx,
        spokenAlert: state.voiceGuidanceEnabled ? nextManeuver.instructionUz : null,
        remainingDistanceKm: (state.remainingDistanceKm - 35.0).clamp(0.5, 300.0),
        remainingMinutes: (state.remainingMinutes - 25).clamp(5, 300),
      ));
    }
  }

  void _onEndNavigation(EndNavigation event, Emitter<NavigationState> emit) {
    _routeSimulationTimer?.cancel();
    _routeSimulationTimer = null;
    emit(state.copyWith(
      isNavigating: false,
      clearAlert: true,
    ));
  }

  @override
  Future<void> close() {
    _routeSimulationTimer?.cancel();
    return super.close();
  }
}
