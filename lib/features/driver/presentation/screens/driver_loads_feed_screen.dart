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

class DriverLoadsFeedScreen extends StatefulWidget {
  const DriverLoadsFeedScreen({super.key});

  @override
  State<DriverLoadsFeedScreen> createState() => _DriverLoadsFeedScreenState();
}

class _DriverLoadsFeedScreenState extends State<DriverLoadsFeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    context.read<ShipmentBloc>().add(
          LoadShipmentsRequested(
            role: UserRole.driver,
            searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        title: Text(
          'nav.loadsFeed'.tr(),
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
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Qayerdan, qayerga yoki yuk nomi...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _fetch();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _fetch(),
              ),
            ),

            // Loads Feed List
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
                              state.errorMessage ?? 'Yuklarni yuklab bo\'lmadi',
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

                  // Drivers want to see available loads (not already delivered or cancelled)
                  final availableLoads = state.shipments.where((s) =>
                    s.status == LoadStatus.created ||
                    s.status == LoadStatus.pendingBid ||
                    s.carrierId == null
                  ).toList();

                  final displayList = availableLoads.isNotEmpty ? availableLoads : state.shipments;

                  if (displayList.isEmpty) {
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
                                  icon: Icons.local_shipping_outlined,
                                  title: 'nav.loadsFeed'.tr(),
                                  description: 'Hozirda yangi yuklar e\'lon qilinmagan.',
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
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final item = displayList[index];
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
