import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../domain/models/driver_feed_item_model.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import '../widgets/driver_feed_filter_sheet.dart';
import 'driver_load_detail_screen.dart';

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
    final bloc = context.read<DriverBloc>();
    bloc.add(const DriverVehiclesLoadRequested());
    bloc.add(const DriverFeedRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet(BuildContext context, DriverFeedFilter currentFilter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DriverFeedFilterSheet(
        initialFilter: currentFilter,
        onApply: (newFilter) {
          context.read<DriverBloc>().add(DriverFilterChanged(newFilter));
        },
      ),
    );
  }

  Color _getMatchColor(int percent) {
    if (percent >= 70) return const Color(0xFF10B981);
    if (percent >= 40) return const Color(0xFFF59E0B);
    return Colors.grey;
  }

  String _formatReason(String reasonKey) {
    switch (reasonKey) {
      case 'reason_truck_type_match':
        return 'Mashina turi mos';
      case 'reason_capacity_optimal':
        return 'Sig\'im mos';
      case 'reason_pickup_distance_close':
        return 'Yaqin masofa';
      case 'reason_route_preferred':
        return 'Afzal marshrut';
      case 'reason_price_attractive':
        return 'Yaxshi narx';
      case 'reason_date_soon':
        return 'Tez kunda';
      default:
        return reasonKey;
    }
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
        child: BlocBuilder<DriverBloc, DriverState>(
          builder: (context, state) {
            final activeFiltersCount = state.filter.activeFilterCount;

            return Column(
              children: [
                // 1. Search Bar & Filter Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
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
                                      context.read<DriverBloc>().add(const DriverSearchChanged(''));
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
                          onSubmitted: (val) {
                            context.read<DriverBloc>().add(DriverSearchChanged(val));
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.tune_rounded, size: 22),
                              color: activeFiltersCount > 0 ? AppColors.primary : null,
                              onPressed: () => _openFilterSheet(context, state.filter),
                            ),
                          ),
                          if (activeFiltersCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$activeFiltersCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Missing Vehicle Warning Banner
                if (!state.hasVehicle)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mashinangizni qo\'shing',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mashina qo\'shilgach, aqlli mos yuklar tartiblanadi.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFB45309),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () => context.push('/driver/vehicle'),
                            child: const Text('Qo\'shish', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. Sort Selector Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      _SortChip(
                        title: 'Mos',
                        icon: Icons.auto_awesome,
                        isSelected: state.filter.sort == 'match',
                        isDisabled: !state.hasVehicle,
                        onTap: () {
                          if (!state.hasVehicle) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mos yuklarni ko\'rish uchun mashinangizni qo\'shing')),
                            );
                            return;
                          }
                          context.read<DriverBloc>().add(const DriverSortChanged('match'));
                        },
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        title: 'Yangi',
                        icon: Icons.access_time,
                        isSelected: state.filter.sort == 'newest',
                        onTap: () => context.read<DriverBloc>().add(const DriverSortChanged('newest')),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        title: 'Narx',
                        icon: Icons.monetization_on_outlined,
                        isSelected: state.filter.sort == 'price',
                        onTap: () => context.read<DriverBloc>().add(const DriverSortChanged('price')),
                      ),
                      const SizedBox(width: 8),
                      _SortChip(
                        title: 'Masofa',
                        icon: Icons.near_me_outlined,
                        isSelected: state.filter.sort == 'distance',
                        onTap: () => context.read<DriverBloc>().add(const DriverSortChanged('distance')),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // 4. Feed List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<DriverBloc>().add(const DriverFeedRequested(refresh: true));
                    },
                    child: Builder(
                      builder: (context) {
                        if (state.status == DriverStatus.loading && state.feedItems.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (state.status == DriverStatus.failure && state.feedItems.isEmpty) {
                          return Center(
                            child: EmptyStateView(
                              icon: Icons.error_outline,
                              title: 'Yuklarni olib bo\'lmadi',
                              description: state.errorMessage ?? 'Tarmoq xatosi yuz berdi',
                              actionText: 'Qayta urinish',
                              onAction: () => context.read<DriverBloc>().add(const DriverFeedRequested()),
                            ),
                          );
                        }

                        if (state.feedItems.isEmpty) {
                          return Center(
                            child: EmptyStateView(
                              icon: Icons.search_off_rounded,
                              title: 'Mos yuklar topilmadi',
                              description: 'Filtr parametrlarini o\'zgartirib ko\'ring.',
                              actionText: 'Filtrlarni tozalash',
                              onAction: () {
                                context.read<DriverBloc>().add(const DriverFilterChanged(DriverFeedFilter()));
                              },
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: state.feedItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final item = state.feedItems[idx];
                            final matchColor = _getMatchColor(item.matchPercent);

                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DriverLoadDetailScreen(load: item),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Cargo name, Truck type, Match Ring
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.cargoName,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item.truckType} • ${item.weightTons} tonna',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (state.hasVehicle)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: matchColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: matchColor.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.auto_awesome, size: 12, color: matchColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${item.matchPercent}%',
                                                  style: TextStyle(
                                                    color: matchColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),

                                    // Match reasons chips
                                    if (item.matchReasons.isNotEmpty && state.hasVehicle) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: item.matchReasons.take(3).map((r) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _formatReason(r),
                                              style: const TextStyle(fontSize: 10, color: Color(0xFF10B981)),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],

                                    const Divider(height: 20),

                                    // Route info
                                    Row(
                                      children: [
                                        const Icon(Icons.radio_button_checked, size: 14, color: Color(0xFF10B981)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${item.fromCity} (${item.fromRegion})',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Container(
                                        height: 12,
                                        width: 2,
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${item.toCity} (${item.toRegion})',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    // Pickup distance & pickup date
                                    Row(
                                      children: [
                                        if (item.pickupDistanceKm != null) ...[
                                          Icon(Icons.near_me_outlined, size: 12, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Sizdan: ~${item.pickupDistanceKm!.toStringAsFixed(0)} km',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${item.pickupDate.day}.${item.pickupDate.month}.${item.pickupDate.year}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Bottom row: Price & offered badge
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.priceNegotiable
                                              ? 'Kelishiladi'
                                              : (item.priceUzs != null
                                                  ? '${(item.priceUzs! / 1000000).toStringAsFixed(1)} mln so\'m'
                                                  : 'Kelishiladi'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (item.alreadyOffered)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Taklif yuborilgan',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _SortChip({
    required this.title,
    required this.icon,
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDisabled ? Colors.grey : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDisabled ? Colors.grey : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
