import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../shipments/domain/models/load_status.dart';
import '../../../shipments/domain/models/shipment_model.dart';
import '../../../shipments/presentation/bloc/shipment_bloc.dart';
import '../../../shipments/presentation/bloc/shipment_event.dart';
import '../../../shipments/presentation/bloc/shipment_state.dart';
import '../../../shipments/presentation/widgets/shipment_card.dart';

class ShipperMyLoadsScreen extends StatefulWidget {
  const ShipperMyLoadsScreen({super.key});

  @override
  State<ShipperMyLoadsScreen> createState() => _ShipperMyLoadsScreenState();
}

class _ShipperMyLoadsScreenState extends State<ShipperMyLoadsScreen> {
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    context.read<ShipmentBloc>().add(
          const LoadShipmentsRequested(role: UserRole.shipper),
        );
  }

  List<ShipmentModel> _filterShipments(List<ShipmentModel> list) {
    if (_selectedFilterIndex == 1) {
      // Faol: created, pendingBid, carrierAssigned, escrowFunded, inTransit, etc.
      return list.where((s) =>
        s.status != LoadStatus.delivered &&
        s.status != LoadStatus.completedPayoutReleased &&
        s.status != LoadStatus.cancelled
      ).toList();
    } else if (_selectedFilterIndex == 2) {
      // Yetkazilgan / Yakunlangan
      return list.where((s) =>
        s.status == LoadStatus.delivered ||
        s.status == LoadStatus.completedPayoutReleased
      ).toList();
    } else if (_selectedFilterIndex == 3) {
      // Bekor qilingan
      return list.where((s) => s.status == LoadStatus.cancelled).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = [
      'common.all'.tr(),
      'Faol',
      'Yetkazilgan',
      'Bekor qilingan',
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        title: Text(
          'nav.myLoads'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryBlue),
            tooltip: 'shipments.postNewLoad'.tr(),
            onPressed: () => context.push('/create-load'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: List.generate(filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filters[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilterIndex = index);
                        }
                      },
                      selectedColor: AppColors.primaryBlue,
                      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Content List
            Expanded(
              child: BlocBuilder<ShipmentBloc, ShipmentState>(
                builder: (context, state) {
                  if (state.isLoading && state.shipments.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == ShipmentStateStatus.error && state.shipments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              state.errorMessage ?? 'Xatolik yuz berdi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetch,
                              child: Text('common.retry'.tr()),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final displayed = _filterShipments(state.shipments);

                  if (displayed.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async => _fetch(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: EmptyStateView(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'nav.myLoads'.tr(),
                                  description: 'Hozircha yuklar mavjud emas.',
                                  actionText: 'shipments.postNewLoad'.tr(),
                                  onAction: () => context.push('/create-load'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _fetch(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: displayed.length,
                      itemBuilder: (context, index) {
                        final item = displayed[index];
                        return ShipmentCard(
                          shipment: item,
                          onTap: () => context.push('/shipments/${item.id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
