import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  StreamSubscription<Position>? _positionSubscription;

  NavigationBloc() : super(const NavigationState()) {
    on<StartNavigation>(_onStartNavigation);
    on<ToggleVoiceGuidance>(_onToggleVoiceGuidance);
    on<AdvanceRouteStep>(_onAdvanceRouteStep);
    on<EndNavigation>(_onEndNavigation);
  }

  Future<void> _onStartNavigation(StartNavigation event, Emitter<NavigationState> emit) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final origin = event.shipment.origin.address;
    final destination = event.shipment.destination.address;

    final maneuvers = [
      RouteManeuver(
        instructionUz: '$origin dan harakatni boshlang',
        instructionEn: 'Start navigation from $origin',
        instructionRu: 'Начните движение от $origin',
        distanceText: '0 m',
        iconType: 'straight',
      ),
      const RouteManeuver(
        instructionUz: 'Belgilangan marshrut bo\'yicha davom eting',
        instructionEn: 'Proceed along the designated route',
        instructionRu: 'Следуйте по заданному маршруту',
        distanceText: '1 km',
        iconType: 'straight',
      ),
      RouteManeuver(
        instructionUz: 'Yetkazish manzili: $destination',
        instructionEn: 'Destination: $destination',
        instructionRu: 'Пункт назначения: $destination',
        distanceText: '100 m',
        iconType: 'destination',
      ),
    ];

    final meters = Geolocator.distanceBetween(
      event.shipment.origin.latitude,
      event.shipment.origin.longitude,
      event.shipment.destination.latitude,
      event.shipment.destination.longitude,
    );
    final initialDistKm = meters / 1000.0;

    emit(state.copyWith(
      isNavigating: true,
      shipment: event.shipment,
      currentStepIndex: 0,
      maneuvers: maneuvers,
      spokenAlert: maneuvers.first.instructionUz,
      remainingDistanceKm: initialDistKm,
      remainingMinutes: initialDistKm > 0 ? (initialDistKm / 60.0 * 60).round() : 0,
      currentSpeedKmh: 0.0,
    ));

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          double speedKmh = position.speed > 0 ? (position.speed * 3.6) : 0.0;
          double remainingKm = state.remainingDistanceKm;

          final distMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            event.shipment.destination.latitude,
            event.shipment.destination.longitude,
          );
          remainingKm = (distMeters / 1000.0);

          int minutes = speedKmh > 5 ? ((remainingKm / speedKmh) * 60).round() : 0;

          add(AdvanceRouteStep(
            speedKmh: speedKmh,
            remainingKm: remainingKm,
            remainingMinutes: minutes,
          ));
        });
      }
    } catch (_) {
      // GPS not available
    }
  }

  void _onToggleVoiceGuidance(ToggleVoiceGuidance event, Emitter<NavigationState> emit) {
    emit(state.copyWith(voiceGuidanceEnabled: event.enabled));
  }

  void _onAdvanceRouteStep(AdvanceRouteStep event, Emitter<NavigationState> emit) {
    emit(state.copyWith(
      currentSpeedKmh: event.speedKmh ?? state.currentSpeedKmh,
      remainingDistanceKm: event.remainingKm ?? state.remainingDistanceKm,
      remainingMinutes: event.remainingMinutes ?? state.remainingMinutes,
    ));
  }

  void _onEndNavigation(EndNavigation event, Emitter<NavigationState> emit) {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    emit(state.copyWith(
      isNavigating: false,
      clearAlert: true,
      currentSpeedKmh: 0.0,
    ));
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
