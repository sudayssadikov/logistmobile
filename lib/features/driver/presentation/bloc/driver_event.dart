import '../../domain/models/driver_feed_item_model.dart';

abstract class DriverEvent {
  const DriverEvent();
}

class DriverFeedRequested extends DriverEvent {
  final bool refresh;
  const DriverFeedRequested({this.refresh = false});
}

class DriverFilterChanged extends DriverEvent {
  final DriverFeedFilter filter;
  const DriverFilterChanged(this.filter);
}

class DriverSearchChanged extends DriverEvent {
  final String query;
  const DriverSearchChanged(this.query);
}

class DriverSortChanged extends DriverEvent {
  final String sort;
  const DriverSortChanged(this.sort);
}

class DriverVehiclesLoadRequested extends DriverEvent {
  const DriverVehiclesLoadRequested();
}

class DriverVehicleAddRequested extends DriverEvent {
  final String truckType;
  final double capacityTons;
  final String? plateNumber;
  final bool isPrimary;

  const DriverVehicleAddRequested({
    required this.truckType,
    required this.capacityTons,
    this.plateNumber,
    this.isPrimary = true,
  });
}
