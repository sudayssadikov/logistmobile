import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../bloc/fleet_bloc.dart';
import '../bloc/fleet_event.dart';
import '../bloc/fleet_state.dart';
import '../widgets/add_edit_truck_modal.dart';
import '../widgets/assign_driver_modal.dart';

class FleetManagementScreen extends StatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  State<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends State<FleetManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<FleetBloc>().add(LoadFleetRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('fleet.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: 'fleet.addTruck'.tr(),
            onPressed: () => AddEditTruckModal.show(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          tabs: [
            Tab(text: 'fleet.trucksTab'.tr(), icon: const Icon(Icons.local_shipping_outlined, size: 20)),
            Tab(text: 'fleet.driversTab'.tr(), icon: const Icon(Icons.people_outline_rounded, size: 20)),
          ],
        ),
      ),
      body: BlocConsumer<FleetBloc, FleetState>(
        listener: (context, state) {
          if (state.successMessage != null) {
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
          if (state.status == FleetStateStatus.loading && state.trucks.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SkeletonLoader(width: double.infinity, height: 120),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Trucks Inventory
              RefreshIndicator(
                onRefresh: () async {
                  context.read<FleetBloc>().add(LoadFleetRequested());
                },
                child: state.trucks.isEmpty
                    ? EmptyStateView(
                        icon: Icons.local_shipping_outlined,
                        title: 'common.noData'.tr(),
                        description: 'No trucks added to fleet yet.',
                        actionText: 'fleet.addTruck'.tr(),
                        onAction: () => AddEditTruckModal.show(context),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: state.trucks.length,
                        itemBuilder: (context, index) {
                          final truck = state.trucks[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        ),
                                      ),
                                      child: Text(
                                        truck.plateNumber,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    StatusBadge(
                                      label: truck.bodyType.labelKey.tr(),
                                      color: AppColors.primary,
                                      icon: truck.bodyType.icon,
                                      fontSize: 10,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  truck.model,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Max Load: ${truck.maxWeightTons} T • Volume: ${truck.maxVolumeM3} m³',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 16,
                                      color: truck.assignedDriverName != null ? AppColors.emerald : AppColors.darkTextMuted,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        truck.assignedDriverName != null
                                            ? '${'fleet.assignedDriver'.tr()}: ${truck.assignedDriverName}'
                                            : 'fleet.unassigned'.tr(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: truck.assignedDriverName != null
                                              ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                              : AppColors.darkTextMuted,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => AssignDriverModal.show(context, truck),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          truck.assignedDriverName != null ? 'fleet.assignDriver'.tr() : 'fleet.assignDriver'.tr(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Tab 2: Drivers Directory
              RefreshIndicator(
                onRefresh: () async {
                  context.read<FleetBloc>().add(LoadFleetRequested());
                },
                child: state.drivers.isEmpty
                    ? EmptyStateView(
                        icon: Icons.people_outline_rounded,
                        title: 'common.noData'.tr(),
                        description: 'No registered drivers found.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: state.drivers.length,
                        itemBuilder: (context, index) {
                          final driver = state.drivers[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      driver.fullName[0],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              driver.fullName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                          ),
                                          StatusBadge(
                                            label: driver.status.labelKey.tr(),
                                            color: driver.status.color,
                                            fontSize: 10,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${driver.phone} • ${driver.completedTrips} trips',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        driver.assignedVehiclePlate != null
                                            ? 'Truck: ${driver.assignedVehiclePlate}'
                                            : 'No assigned vehicle',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: driver.assignedVehiclePlate != null
                                              ? AppColors.primary
                                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddEditTruckModal.show(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('fleet.addTruck'.tr()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
