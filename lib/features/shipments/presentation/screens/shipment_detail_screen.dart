import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/load_status.dart';
import '../../domain/models/shipment_model.dart';
import '../bloc/shipment_bloc.dart';
import '../bloc/shipment_event.dart';
import '../bloc/shipment_state.dart';
import '../widgets/negotiation_sheet_widget.dart';

class ShipmentDetailScreen extends StatelessWidget {
  final String shipmentId;

  const ShipmentDetailScreen({super.key, required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,###', 'en_US');
    final currentUser = context.watch<AuthBloc>().state.user ??
        const UserModel(
          id: 'USR-01',
          fullName: 'Shipper',
          email: 'shipper@logiflow.uz',
          phone: '+998 90 000 00 00',
          role: UserRole.shipper,
        );

    return BlocConsumer<ShipmentBloc, ShipmentState>(
      listener: (context, state) {
        if (state.status == ShipmentStateStatus.actionSuccess && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.emerald,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final shipment = state.shipments.firstWhere(
          (e) => e.id == shipmentId,
          orElse: () => state.selectedShipment ??
              ShipmentModel(
                id: shipmentId,
                trackingCode: 'LF-UZ-0000',
                shipperId: 'USR-SHIPPER-01',
                shipperName: 'Agro Export Holding',
                status: LoadStatus.inTransit,
                origin: LocationPoint(
                  city: 'Tashkent',
                  address: 'Sergeli Hub',
                  latitude: 41.22,
                  longitude: 69.21,
                  scheduledTime: DateTime.now(),
                ),
                destination: LocationPoint(
                  city: 'Samarkand',
                  address: 'Ulugbek Logistics',
                  latitude: 39.65,
                  longitude: 66.95,
                  scheduledTime: DateTime.now().add(const Duration(hours: 4)),
                ),
                cargoTitle: 'Fresh Pomegranates',
                cargoType: 'Refrigerated',
                weightTons: 20.0,
                volumeM3: 80.0,
                price: 15000000.0,
                isEscrowFunded: true,
                distanceKm: 310.0,
                eta: '2h 30m',
                createdAt: DateTime.now(),
              ),
        );

        final nextStatus = shipment.status.nextStatus;
        final canAdvance = shipment.status.canAdvance(currentUser.role);

        return Scaffold(
          appBar: AppBar(
            title: Text(shipment.trackingCode),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share Tracking',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${'shipments.liveMap'.tr()}: http://logiflow.uz/track/${shipment.trackingCode}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card with Escrow & Status
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'shipments.shipmentValue'.tr(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${currencyFormatter.format(shipment.price)} UZS',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                StatusBadge(
                                  label: shipment.status.label,
                                  color: shipment.status.color,
                                  fontSize: 12,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  shipment.isEscrowFunded ? Icons.lock_rounded : Icons.lock_open_rounded,
                                  size: 16,
                                  color: shipment.isEscrowFunded ? AppColors.emerald : AppColors.amber,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    shipment.isEscrowFunded
                                        ? '${'shipments.escrowLocked'.tr()}: ${'shipments.escrowGuaranteeDesc'.tr()}'
                                        : 'shipments.escrowPending'.tr(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // State Machine Step Visualizer
                      _buildStateTimeline(context, shipment.status),
                      const SizedBox(height: 20),

                      // Quick Action Badges (Map, Chat, POD, Bids)
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.map_outlined,
                              label: 'shipments.liveMap'.tr(),
                              accentColor: AppColors.primary,
                              onTap: () => context.push('/tracking/${shipment.id}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'shipments.directChat'.tr(),
                              accentColor: AppColors.indigo,
                              onTap: () => context.push('/chat/${shipment.id}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.gavel_rounded,
                              label: 'bidding.title'.tr(),
                              accentColor: AppColors.amber,
                              onTap: () => NegotiationSheetWidget.show(context, shipment),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.draw_outlined,
                              label: 'shipments.signPod'.tr(),
                              accentColor: AppColors.emerald,
                              onTap: () => context.push('/pod/${shipment.id}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Route Details
                      _SectionHeader(title: 'shipments.routeSchedule'.tr()),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            _RouteStop(
                              isOrigin: true,
                              city: shipment.origin.city.tr(),
                              address: shipment.origin.address,
                              time: DateFormat('MMM dd, HH:mm').format(shipment.origin.scheduledTime),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 2,
                                    height: 28,
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${shipment.distanceKm.toStringAsFixed(0)} km (${shipment.eta})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _RouteStop(
                              isOrigin: false,
                              city: shipment.destination.city.tr(),
                              address: shipment.destination.address,
                              time: DateFormat('MMM dd, HH:mm').format(shipment.destination.scheduledTime),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Cargo Specs
                      _SectionHeader(title: 'shipments.cargoSpecs'.tr()),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          children: [
                            _SpecRow(label: 'shipments.cargoTitle'.tr(), value: shipment.cargoTitle.tr()),
                            const Divider(height: 16),
                            _SpecRow(label: 'shipments.category'.tr(), value: shipment.cargoType.tr()),
                            const Divider(height: 16),
                            _SpecRow(label: 'shipments.weight'.tr(), value: '${shipment.weightTons} T'),
                            const Divider(height: 16),
                            _SpecRow(label: 'shipments.volume'.tr(), value: '${shipment.volumeM3} m³'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Carrier / Driver Info Card
                      if (shipment.carrierName != null) ...[
                        _SectionHeader(title: 'shipments.assignedCarrier'.tr()),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shipment.carrierName!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Driver: ${shipment.driverName ?? "Assigned Unit"}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (shipment.driverPhone != null)
                                    IconButton(
                                      icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.emerald),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Calling driver at ${shipment.driverPhone}'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                              if (shipment.vehiclePlate != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Vehicle: ${shipment.vehiclePlate}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Carrier Bidding Section (if status is pendingBid)
                      if (shipment.status == LoadStatus.pendingBid && shipment.bids.isNotEmpty) ...[
                        _SectionHeader(title: '${'shipments.activeCarrierBids'.tr()} (${shipment.bids.length})'),
                        const SizedBox(height: 10),
                        ...shipment.bids.map((bid) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bid.carrierName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${bid.vehicleModel} • Rating: ${bid.carrierRating} ★',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${currencyFormatter.format(bid.bidAmount)} UZS',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (currentUser.role == UserRole.shipper || currentUser.role == UserRole.admin)
                                  AppButton(
                                    text: 'actions.acceptSelectedBid'.tr(),
                                    height: 36,
                                    borderRadius: 8,
                                    onPressed: () {
                                      context.read<ShipmentBloc>().add(
                                            AcceptBidSubmitted(
                                              shipmentId: shipment.id,
                                              bidId: bid.id,
                                            ),
                                          );
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom State Machine Trigger Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      if (nextStatus != null && canAdvance)
                        Expanded(
                          child: AppButton(
                            text: shipment.status.getActionTitle(currentUser.role),
                            suffixIcon: Icons.arrow_forward_rounded,
                            onPressed: () {
                              context.read<ShipmentBloc>().add(
                                    AdvanceShipmentStatusSubmitted(
                                      shipmentId: shipment.id,
                                      nextStatus: nextStatus,
                                      currentRole: currentUser.role,
                                    ),
                                  );
                            },
                          ),
                        )
                      else if (currentUser.role == UserRole.carrier && shipment.status == LoadStatus.pendingBid)
                        Expanded(
                          child: AppButton(
                            text: 'shipments.submitBid'.tr(),
                            onPressed: () {
                              context.read<ShipmentBloc>().add(
                                    SubmitBidSubmitted(
                                      shipmentId: shipment.id,
                                      bid: BidModel(
                                        id: 'BID-${DateTime.now().millisecondsSinceEpoch % 1000}',
                                        carrierId: currentUser.id,
                                        carrierName: currentUser.companyName ?? currentUser.fullName,
                                        driverName: 'Sardor Qosimov',
                                        vehicleModel: 'Volvo FH16 (2023)',
                                        plateNumber: '01 842 TAA',
                                        bidAmount: shipment.price * 0.95,
                                        carrierRating: currentUser.rating,
                                        createdAt: DateTime.now(),
                                      ),
                                    ),
                                  );
                            },
                          ),
                        )
                      else
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                shipment.status == LoadStatus.completedPayoutReleased
                                    ? 'actions.orderArchived'.tr()
                                    : '${shipment.status.label} (${'common.loading'.tr()})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStateTimeline(BuildContext context, LoadStatus currentStatus) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSteps = LoadStatus.values.length;
    final currentStepIndex = currentStatus.index;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'shipments.lifecycleStateMachine'.tr(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              Text(
                '${'shipments.step'.tr()} ${currentStepIndex + 1} ${'shipments.of'.tr()} $totalSteps',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentStepIndex + 1) / totalSteps,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(currentStatus.color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currentStatus.description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  final bool isOrigin;
  final String city;
  final String address;
  final String time;

  const _RouteStop({
    required this.isOrigin,
    required this.city,
    required this.address,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOrigin
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.emerald.withValues(alpha: 0.15),
          ),
          child: Icon(
            isOrigin ? Icons.circle_rounded : Icons.location_on_rounded,
            color: isOrigin ? AppColors.primary : AppColors.emerald,
            size: 14,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                city,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                address,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: accentColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
