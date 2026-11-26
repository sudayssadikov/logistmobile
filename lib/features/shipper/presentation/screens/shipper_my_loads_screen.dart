import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/load_model.dart';
import '../../domain/repositories/loads_repository.dart';

class ShipperMyLoadsScreen extends StatefulWidget {
  final ILoadsRepository? repository;

  const ShipperMyLoadsScreen({super.key, this.repository});

  @override
  State<ShipperMyLoadsScreen> createState() => _ShipperMyLoadsScreenState();
}

class _ShipperMyLoadsScreenState extends State<ShipperMyLoadsScreen>
    with SingleTickerProviderStateMixin {
  late final ILoadsRepository _repository;
  late final TabController _tabController;

  final Map<int, List<LoadSummaryModel>> _loadsByTab = {
    0: [],
    1: [],
    2: [],
  };
  final Map<int, bool> _isLoadingByTab = {
    0: false,
    1: false,
    2: false,
  };
  final Map<int, String?> _errorByTab = {
    0: null,
    1: null,
    2: null,
  };

  final List<String> _statusGroups = ['active', 'in_progress', 'history'];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? getIt<ILoadsRepository>();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchLoads(_tabController.index);
      }
    });

    _fetchLoads(0);
    _fetchLoads(1);
    _fetchLoads(2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLoads(int tabIndex) async {
    setState(() {
      _isLoadingByTab[tabIndex] = true;
      _errorByTab[tabIndex] = null;
    });

    final result = await _repository.getMyLoads(
      statusGroup: _statusGroups[tabIndex],
      page: 1,
      limit: 50,
    );

    if (!mounted) return;

    if (result is ApiSuccess<PaginatedLoadSummary>) {
      setState(() {
        _loadsByTab[tabIndex] = result.data.items;
        _isLoadingByTab[tabIndex] = false;
      });
    } else {
      setState(() {
        _errorByTab[tabIndex] = result.errorOrNull ?? 'Xatolik yuz berdi';
        _isLoadingByTab[tabIndex] = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.primary;
      case 'ASSIGNED':
        return AppColors.warning;
      case 'IN_TRANSIT':
        return const Color(0xFF3B82F6);
      case 'DELIVERED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.lightTextSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Faol';
      case 'ASSIGNED':
        return 'Biriktirilgan';
      case 'IN_TRANSIT':
        return 'Yo\'lda';
      case 'DELIVERED':
        return 'Yetkazilgan';
      case 'CANCELLED':
        return 'Bekor qilingan';
      default:
        return status;
    }
  }

  Future<void> _duplicateLoad(String loadId) async {
    final res = await _repository.duplicateLoad(loadId);
    if (!mounted) return;
    if (res is ApiSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yuk nusxasi yaratildi va Faol yuklarga qo\'shildi'),
          backgroundColor: AppColors.success,
        ),
      );
      _fetchLoads(0);
      _tabController.animateTo(0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorOrNull ?? 'Xatolik yuz berdi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showCancelDialog(LoadSummaryModel load, int currentTab) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Yukni bekor qilish',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rostdan ham "${load.cargoName}" yukini bekor qilmoqchimisiz? Ushbu amalni ortga qaytarib bo\'lmaydi.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Bekor qilish sababi (ixtiyoriy)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ortga'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Bekor qilish'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim();
      final res = await _repository.cancelLoad(
        load.id,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (!mounted) return;
      if (res is ApiSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yuk bekor qilindi va Tarixga o\'tkazildi'),
            backgroundColor: AppColors.warning,
          ),
        );
        _fetchLoads(currentTab);
        _fetchLoads(2); // Refresh history
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorOrNull ?? 'Xatolik yuz berdi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
          'Yuklarim',
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
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            tooltip: 'Yangi yuk qo\'shish',
            onPressed: () async {
              await context.push('/create-load');
              _fetchLoads(0);
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Faol'),
            Tab(text: 'Jarayonda'),
            Tab(text: 'Tarix'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTabContent(0),
            _buildTabContent(1),
            _buildTabContent(2),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(int tabIndex) {
    final isLoading = _isLoadingByTab[tabIndex] ?? false;
    final error = _errorByTab[tabIndex];
    final items = _loadsByTab[tabIndex] ?? [];

    if (isLoading && items.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SkeletonLoader(
            width: double.infinity,
            height: 140,
            borderRadius: 16,
          ),
        ),
      );
    }

    if (error != null && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _fetchLoads(tabIndex),
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchLoads(tabIndex),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: EmptyStateView(
                  icon: Icons.inventory_2_outlined,
                  title: tabIndex == 0
                      ? 'Sizda hali faol yuklar yo\'q'
                      : tabIndex == 1
                          ? 'Ayni paytda jarayonda bo\'lgan yuklar yo\'q'
                          : 'Yuklar tarixi bo\'sh',
                  description: tabIndex == 0
                      ? 'Yangi yuk e\'lon qiling va haydovchilardan takliflar oling.'
                      : tabIndex == 1
                          ? 'Tayinlangan va yo\'ldagi yuklaringiz shu yerda aks etadi.'
                          : 'Yetkazilgan yoki bekor qilingan yuklar shu bo\'limda saqlanadi.',
                  actionText: tabIndex == 0 ? 'Yuk qo\'shish' : null,
                  onAction: tabIndex == 0
                      ? () async {
                          await context.push('/create-load');
                          _fetchLoads(0);
                        }
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchLoads(tabIndex),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final load = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLoadCard(load, tabIndex),
          );
        },
      ),
    );
  }

  Widget _buildLoadCard(LoadSummaryModel load, int currentTab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(load.status);
    final statusText = _getStatusText(load.status);

    final priceText = load.priceNegotiable
        ? 'Kelishiladi'
        : (load.priceUzs != null
            ? '${load.priceUzs!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} UZS'
            : 'Kelishiladi');

    final dateStr =
        '${load.pickupDate.day.toString().padLeft(2, '0')}.${load.pickupDate.month.toString().padLeft(2, '0')}.${load.pickupDate.year}';

    return NeuCard(
      onTap: () async {
        await context.push('/shipper/loads/${load.id}');
        _fetchLoads(currentTab);
      },
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  load.cargoName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: statusText,
                color: statusColor,
              ),
              _buildPopupMenu(load, currentTab),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${load.fromCity} (${load.fromRegion})',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 12, color: AppColors.error),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${load.toCity} (${load.toRegion})',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${load.weightTons} t • ${load.truckType}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                priceText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                'Batafsil >',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(LoadSummaryModel load, int currentTab) {
    final status = load.status;
    final canEdit = status == 'ACTIVE' || status == 'ASSIGNED';
    final canCancel = status == 'ACTIVE' || status == 'ASSIGNED';

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) async {
        if (value == 'edit') {
          await context.push('/shipper/loads/${load.id}/edit');
          _fetchLoads(currentTab);
        } else if (value == 'duplicate') {
          _duplicateLoad(load.id);
        } else if (value == 'cancel') {
          _showCancelDialog(load, currentTab);
        }
      },
      itemBuilder: (context) => [
        if (canEdit)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 18),
                const SizedBox(width: 8),
                Text(status == 'ASSIGNED' ? 'Tahrirlash (cheklangan)' : 'Tahrirlash'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 18),
              SizedBox(width: 8),
              Text('Nusxa ko\'chirish'),
            ],
          ),
        ),
        if (canCancel)
          const PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                SizedBox(width: 8),
                Text(
                  'Bekor qilish',
                  style: TextStyle(color: AppColors.error),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
