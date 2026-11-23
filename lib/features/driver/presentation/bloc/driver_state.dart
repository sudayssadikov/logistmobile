import '../../domain/models/driver_feed_item_model.dart';
import '../../domain/models/driver_vehicle_model.dart';

enum DriverStatus { initial, loading, success, failure }

class DriverState {
  final DriverStatus status;
  final List<DriverFeedItemModel> feedItems;
  final bool hasVehicle;
  final List<DriverVehicleModel> vehicles;
  final DriverFeedFilter filter;
  final String? searchQuery;
  final String? errorMessage;

  const DriverState({
    this.status = DriverStatus.initial,
    this.feedItems = const [],
    this.hasVehicle = true,
    this.vehicles = const [],
    this.filter = const DriverFeedFilter(),
    this.searchQuery,
    this.errorMessage,
  });

  DriverState copyWith({
    DriverStatus? status,
    List<DriverFeedItemModel>? feedItems,
    bool? hasVehicle,
    List<DriverVehicleModel>? vehicles,
    DriverFeedFilter? filter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return DriverState(
      status: status ?? this.status,
      feedItems: feedItems ?? this.feedItems,
      hasVehicle: hasVehicle ?? this.hasVehicle,
      vehicles: vehicles ?? this.vehicles,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

