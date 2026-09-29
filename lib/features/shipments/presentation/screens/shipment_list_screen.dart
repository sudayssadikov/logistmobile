import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/models/load_status.dart';
import '../bloc/shipment_bloc.dart';
import '../bloc/shipment_event.dart';
import '../bloc/shipment_state.dart';
import '../widgets/shipment_card.dart';

class ShipmentListScreen extends StatefulWidget {
  const ShipmentListScreen({super.key});

  @override
  State<ShipmentListScreen> createState() => _ShipmentListScreenState();
}

class _ShipmentListScreenState extends State<ShipmentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    LoadStatus? status;
    if (_selectedFilterIndex == 1) {
      status = LoadStatus.inTransit;
    } else if (_selectedFilterIndex == 2) {
      status = LoadStatus.pendingBid;
    } else if (_selectedFilterIndex == 3) {
      status = LoadStatus.completedPayoutReleased;
    }

    context.read<ShipmentBloc>().add(
          LoadShipmentsRequested(
            searchQuery: _searchController.text,
            filterStatus: status,
          ),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthBloc>().state.user;
    final isShipper = user?.role == UserRole.shipper;

    final filters = [
      'common.all'.tr(),
      'statuses.inTransit'.tr(),
      'statuses.pendingBid'.tr(),
      'statuses.completedPayoutReleased'.tr(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isShipper ? 'nav.myLoads'.tr() : 'nav.loadBoard'.tr()),
        actions: [
          if (isShipper)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'shipments.postNewLoad'.tr(),
              onPressed: () => context.push('/create-load'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _fetch(),
              decoration: InputDecoration(
                hintText: 'common.searchPlaceholder'.tr(),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetch();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        _fetch();
                      }
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // List View
          Expanded(
            child: BlocBuilder<ShipmentBloc, ShipmentState>(
              builder: (context, state) {
                if (state.status == ShipmentStateStatus.loading) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: 4,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SkeletonLoader(width: double.infinity, height: 140, borderRadius: 14),
                    ),
                  );
                }

                if (state.status == ShipmentStateStatus.error) {
                  return EmptyStateView(
                    icon: Icons.error_outline_rounded,
                    title: 'common.error'.tr(),
                    description: state.errorMessage ?? 'Failed to load shipments',
                    actionText: 'common.resetFilters'.tr(),
                    onAction: _fetch,
                  );
                }

                if (state.shipments.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.inventory_2_outlined,
                    title: 'common.noData'.tr(),
                    description: 'No freight routes found matching the active search filters.',
                    actionText: isShipper ? 'shipments.postNewLoad'.tr() : 'common.resetFilters'.tr(),
                    onAction: () {
                      if (isShipper) {
                        context.push('/create-load');
                      } else {
                        _searchController.clear();
                        setState(() => _selectedFilterIndex = 0);
                        _fetch();
                      }
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _fetch(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: state.shipments.length,
                    itemBuilder: (context, index) {
                      final shipment = state.shipments[index];
                      return ShipmentCard(
                        shipment: shipment,
                        onTap: () => context.push('/shipments/${shipment.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isShipper
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-load'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'shipments.postNewLoad'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            )
          : null,
    );
  }
}
