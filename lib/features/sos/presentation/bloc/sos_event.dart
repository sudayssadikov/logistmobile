import 'package:equatable/equatable.dart';
import '../../domain/models/sos_model.dart';

abstract class SosEvent extends Equatable {
  const SosEvent();
  @override
  List<Object?> get props => [];
}

class FetchNearbySosProvidersRequested extends SosEvent {
  final double latitude;
  final double longitude;
  final SosServiceType? filterType;

  const FetchNearbySosProvidersRequested({
    this.latitude = 40.1158,
    this.longitude = 67.8422,
    this.filterType,
  });

  @override
  List<Object?> get props => [latitude, longitude, filterType];
}

class ChangeSosFilterType extends SosEvent {
  final SosServiceType? filterType;

  const ChangeSosFilterType(this.filterType);

  @override
  List<Object?> get props => [filterType];
}

class DispatchEmergencyAlertRequested extends SosEvent {
  final double latitude;
  final double longitude;
  final SosServiceType type;
  final String driverPhone;
  final String notes;

  const DispatchEmergencyAlertRequested({
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.driverPhone,
    required this.notes,
  });

  @override
  List<Object?> get props => [latitude, longitude, type, driverPhone, notes];
}
