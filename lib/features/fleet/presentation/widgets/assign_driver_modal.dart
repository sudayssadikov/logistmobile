import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/truck_model.dart';
import '../bloc/fleet_bloc.dart';
import '../bloc/fleet_event.dart';
import '../bloc/fleet_state.dart';

class AssignDriverModal extends StatelessWidget {
  final TruckModel truck;

  const AssignDriverModal({super.key, required this.truck});

  static Future<void> show(BuildContext context, TruckModel truck) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<FleetBloc>(),
        child: AssignDriverModal(truck: truck),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BlocBuilder<FleetBloc, FleetState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${'fleet.assignDriver'.tr()} • ${truck.plateNumber}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                truck.model,
                style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 16),

              ...state.drivers.map((driver) {
                final isCurrent = driver.id == truck.assignedDriverId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        driver.fullName[0],
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                    title: Text(
                      driver.fullName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${driver.phone} • Rating: ${driver.rating} ★',
                      style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                    ),
                    trailing: StatusBadge(
                      label: driver.status.labelKey.tr(),
                      color: driver.status.color,
                      fontSize: 10,
                    ),
                    onTap: () {
                      context.read<FleetBloc>().add(
                            AssignDriverSubmitted(
                              truckId: truck.id,
                              driverId: driver.id,
                            ),
                          );
                      Navigator.of(context).pop();
                    },
                  ),
                );
              }),

              if (truck.assignedDriverId != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.link_off_rounded, color: AppColors.rose),
                  label: Text(
                    'fleet.unassign'.tr(),
                    style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    context.read<FleetBloc>().add(UnassignDriverSubmitted(truck.id));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
