import 'package:equatable/equatable.dart';
import '../../domain/models/sos_model.dart';

enum SosStatus { initial, loading, success, error, dispatched }

class SosState extends Equatable {
  final SosStatus status;
  final List<NearbySosProvider> providers;
  final SosServiceType? activeFilter;
  final double currentLatitude;
  final double currentLongitude;
  final String? errorMessage;

  const SosState({
    this.status = SosStatus.initial,
    this.providers = const [],
    this.activeFilter,
    this.currentLatitude = 40.1158,
    this.currentLongitude = 67.8422,
    this.errorMessage,
  });

  SosState copyWith({
    SosStatus? status,
    List<NearbySosProvider>? providers,
    SosServiceType? activeFilter,
    bool clearFilter = false,
    double? currentLatitude,
    double? currentLongitude,
    String? errorMessage,
  }) {
    return SosState(
      status: status ?? this.status,
      providers: providers ?? this.providers,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        providers,
        activeFilter,
        currentLatitude,
        currentLongitude,
        errorMessage,
      ];
}
