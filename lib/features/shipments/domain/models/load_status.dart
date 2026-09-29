import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/domain/models/user_model.dart';

enum LoadStatus {
  created(
    defaultLabel: 'Created',
    defaultDesc: 'Load posted by Shipper, pending carrier bidding.',
    color: AppColors.primary,
  ),
  pendingBid(
    defaultLabel: 'Pending Bids',
    defaultDesc: 'Carriers are submitting bids for this route.',
    color: AppColors.indigo,
  ),
  carrierAssigned(
    defaultLabel: 'Carrier Assigned',
    defaultDesc: 'Carrier bid accepted. Awaiting escrow funding.',
    color: AppColors.amber,
  ),
  escrowFunded(
    defaultLabel: 'Escrow Funded',
    defaultDesc: 'Payment locked in secure escrow. Driver dispatched.',
    color: AppColors.emerald,
  ),
  goingToPickup(
    defaultLabel: 'Going to Pickup',
    defaultDesc: 'Driver is en-route to the pickup facility.',
    color: AppColors.cyan,
  ),
  arrivedAtPickup(
    defaultLabel: 'Arrived at Pickup',
    defaultDesc: 'Truck positioned at loading bay.',
    color: AppColors.cyan,
  ),
  loading(
    defaultLabel: 'Loading Cargo',
    defaultDesc: 'Freight is being verified and loaded onto trailer.',
    color: AppColors.amber,
  ),
  inTransit(
    defaultLabel: 'In Transit',
    defaultDesc: 'Freight en-route on highway with active GPS telemetry.',
    color: AppColors.primary,
  ),
  arrivedAtDestination(
    defaultLabel: 'Arrived at Destination',
    defaultDesc: 'Truck arrived at consignee warehouse/dock.',
    color: AppColors.cyan,
  ),
  unloading(
    defaultLabel: 'Unloading',
    defaultDesc: 'Cargo being inspected and unloaded.',
    color: AppColors.amber,
  ),
  delivered(
    defaultLabel: 'Delivered (POD Signed)',
    defaultDesc: 'Consignee verified freight and signed electronic POD.',
    color: AppColors.emerald,
  ),
  completedPayoutReleased(
    defaultLabel: 'Completed & Paid',
    defaultDesc: 'Escrow released payment directly to carrier wallet.',
    color: AppColors.emerald,
  );

  final String defaultLabel;
  final String defaultDesc;
  final Color color;

  const LoadStatus({
    required this.defaultLabel,
    required this.defaultDesc,
    required this.color,
  });

  String get label {
    final translated = 'statuses.$name'.tr();
    return translated != 'statuses.$name' ? translated : defaultLabel;
  }

  String get description {
    final key = 'statuses.${name}Desc';
    final translated = key.tr();
    return translated != key ? translated : defaultDesc;
  }

  /// Get the next logical state in the shipment state machine
  LoadStatus? get nextStatus {
    if (index < LoadStatus.values.length - 1) {
      return LoadStatus.values[index + 1];
    }
    return null;
  }

  /// Check if a user role is permitted to advance to the next state
  bool canAdvance(UserRole role) {
    if (role == UserRole.admin) {
      return this != LoadStatus.completedPayoutReleased;
    }
    switch (this) {
      case LoadStatus.created:
      case LoadStatus.pendingBid:
        return role == UserRole.shipper;
      case LoadStatus.carrierAssigned:
        return role == UserRole.shipper; // Fund escrow
      case LoadStatus.escrowFunded:
        return role == UserRole.carrier || role == UserRole.driver;
      case LoadStatus.goingToPickup:
      case LoadStatus.arrivedAtPickup:
      case LoadStatus.loading:
      case LoadStatus.inTransit:
      case LoadStatus.arrivedAtDestination:
      case LoadStatus.unloading:
      case LoadStatus.delivered:
        return role == UserRole.driver || role == UserRole.carrier;
      case LoadStatus.completedPayoutReleased:
        return false;
    }
  }

  String getActionTitle(UserRole role) {
    switch (this) {
      case LoadStatus.created:
        return 'actions.openForBidding'.tr();
      case LoadStatus.pendingBid:
        return 'actions.acceptSelectedBid'.tr();
      case LoadStatus.carrierAssigned:
        return 'actions.fundEscrow'.tr();
      case LoadStatus.escrowFunded:
        return 'actions.departForPickup'.tr();
      case LoadStatus.goingToPickup:
        return 'actions.confirmArrivalAtPickup'.tr();
      case LoadStatus.arrivedAtPickup:
        return 'actions.startCargoLoading'.tr();
      case LoadStatus.loading:
        return 'actions.confirmLoaded'.tr();
      case LoadStatus.inTransit:
        return 'actions.confirmArrivalAtDest'.tr();
      case LoadStatus.arrivedAtDestination:
        return 'actions.beginUnloading'.tr();
      case LoadStatus.unloading:
        return 'actions.completeInspectionSignPod'.tr();
      case LoadStatus.delivered:
        return 'actions.releaseEscrowPayout'.tr();
      case LoadStatus.completedPayoutReleased:
        return 'actions.orderArchived'.tr();
    }
  }
}
