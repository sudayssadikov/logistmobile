import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow_mobile/features/shipments/domain/models/load_status.dart';
import 'package:logiflow_mobile/features/auth/domain/models/user_model.dart';

void main() {
  group('Shipment State Machine Tests', () {
    test('12-step sequence progression is strictly ordered', () {
      expect(LoadStatus.created.index, 0);
      expect(LoadStatus.pendingBid.index, 1);
      expect(LoadStatus.carrierAssigned.index, 2);
      expect(LoadStatus.escrowFunded.index, 3);
      expect(LoadStatus.goingToPickup.index, 4);
      expect(LoadStatus.arrivedAtPickup.index, 5);
      expect(LoadStatus.loading.index, 6);
      expect(LoadStatus.inTransit.index, 7);
      expect(LoadStatus.arrivedAtDestination.index, 8);
      expect(LoadStatus.unloading.index, 9);
      expect(LoadStatus.delivered.index, 10);
      expect(LoadStatus.completedPayoutReleased.index, 11);
    });

    test('nextStatus transitions sequentially to end of lifecycle', () {
      expect(LoadStatus.created.nextStatus, LoadStatus.pendingBid);
      expect(LoadStatus.pendingBid.nextStatus, LoadStatus.carrierAssigned);
      expect(LoadStatus.carrierAssigned.nextStatus, LoadStatus.escrowFunded);
      expect(LoadStatus.escrowFunded.nextStatus, LoadStatus.goingToPickup);
      expect(LoadStatus.inTransit.nextStatus, LoadStatus.arrivedAtDestination);
      expect(LoadStatus.unloading.nextStatus, LoadStatus.delivered);
      expect(LoadStatus.delivered.nextStatus, LoadStatus.completedPayoutReleased);
      expect(LoadStatus.completedPayoutReleased.nextStatus, isNull);
    });

    test('Role-based permission guards for state progression', () {
      // Driver can advance in-transit states
      expect(LoadStatus.inTransit.canAdvance(UserRole.driver), isTrue);
      // Shipper cannot advance driver in-transit states
      expect(LoadStatus.inTransit.canAdvance(UserRole.shipper), isFalse);
      // Shipper can fund escrow
      expect(LoadStatus.carrierAssigned.canAdvance(UserRole.shipper), isTrue);
    });
  });
}
