import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/load_model.dart';
import '../../domain/repositories/loads_repository.dart';

class ShipperLoadDetailScreen extends StatefulWidget {
  final String loadId;
  final ILoadsRepository? repository;

  const ShipperLoadDetailScreen({
    super.key,
    required this.loadId,
    this.repository,
  });

  @override
  State<ShipperLoadDetailScreen> createState() => _ShipperLoadDetailScreenState();
}

class _ShipperLoadDetailScreenState extends State<ShipperLoadDetailScreen> {
  late final ILoadsRepository _repository;
  CreatedLoadModel? _load;
  List<LoadEventModel> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? getIt<ILoadsRepository>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final loadResult = await _repository.getLoadById(widget.loadId);
    final eventsResult = await _repository.getLoadEvents(widget.loadId);

    if (!mounted) return;

    if (loadResult is ApiSuccess<CreatedLoadModel>) {
      setState(() {
        _load = loadResult.data;
        if (eventsResult is ApiSuccess<List<LoadEventModel>>) {
          _events = eventsResult.data;
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = loadResult.errorOrNull ?? 'Xatolik yuz berdi';
        _isLoading = false;
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

  String _formatEventType(String type) {
    switch (type) {
      case 'CREATED':
        return 'Yuk e\'lon qilindi';
      case 'EDITED':
        return 'Yuk tahrirlandi';
      case 'CANCELLED':
        return 'Yuk bekor qilindi';
      case 'STATUS_CHANGED':
        return 'Holat o\'zgartirildi';
      case 'DUPLICATED':
        return 'Yukdan nusxa ko\'chirildi';
      default:
        return type;
    }
  }

  Future<void> _duplicateLoad() async {
    final res = await _repository.duplicateLoad(widget.loadId);
    if (!mounted) return;
    if (res is ApiSuccess<CreatedLoadModel>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yuk nusxasi yaratildi!'),
          backgroundColor: AppColors.success,
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        try {
          context.pop();
        } catch (_) {}
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorOrNull ?? 'Xatolik yuz berdi'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showCancelDialog() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yukni bekor qilish'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Haqiqatdan ham bu yukni bekor qilmoqchimisiz?'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Sabab (ixtiyoriy)',
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
        widget.loadId,
        reason: reason.isNotEmpty ? reason : null,
      );
      if (!mounted) return;
      if (res is ApiSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yuk bekor qilindi'),
            backgroundColor: AppColors.warning,
          ),
        );
        _loadData();
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
          'Yuk tafsilotlari',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              try {
                context.pop();
              } catch (_) {}
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: SkeletonLoader(width: double.infinity, height: 300),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Qayta yuklash'),
                      ),
                    ],
                  ),
                )
              : _buildContent(isDark),
      bottomNavigationBar: _load != null ? _buildBottomActions(isDark) : null,
    );
  }

  Widget _buildContent(bool isDark) {
    final load = _load!;
    final statusColor = _getStatusColor(load.status);
    final statusText = _getStatusText(load.status);

    final priceText = load.priceNegotiable
        ? 'Kelishiladi'
        : (load.priceUzs != null
            ? '${load.priceUzs!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} UZS'
            : 'Kelishiladi');

    final pickupDateStr =
        '${load.pickupDate.day.toString().padLeft(2, '0')}.${load.pickupDate.month.toString().padLeft(2, '0')}.${load.pickupDate.year} ${load.pickupDate.hour.toString().padLeft(2, '0')}:${load.pickupDate.minute.toString().padLeft(2, '0')}';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Header Card
            NeuCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      StatusBadge(
                        label: statusText,
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Narx:',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        priceText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Route Card
            NeuCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Marshrut (~ taxminan ${load.distanceKm.toStringAsFixed(0)} km)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Column(
                        children: [
                          Icon(Icons.radio_button_checked,
                              color: AppColors.primary, size: 18),
                          SizedBox(
                            height: 28,
                            child: VerticalDivider(
                              color: AppColors.primary,
                              thickness: 1.5,
                            ),
                          ),
                          Icon(Icons.location_on, color: AppColors.error, size: 18),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${load.fromCity}, ${load.fromRegion}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              load.fromAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '${load.toCity}, ${load.toRegion}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              load.toAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Specs Card
            NeuCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yuk parametrlari',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildSpecRow('Vazn:', '${load.weightTons} tonna', isDark),
                  if (load.volumeM3 != null)
                    _buildSpecRow('Hajm:', '${load.volumeM3} m³', isDark),
                  _buildSpecRow('Yuk turi:', load.cargoType, isDark),
                  _buildSpecRow('Mashina turi:', load.truckType, isDark),
                  _buildSpecRow('Yuklash vaqti:', pickupDateStr, isDark),
                  if (load.description != null && load.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Izoh:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      load.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Driver Section
            NeuCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Haydovchi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark
                            ? AppColors.darkSurfacePressed
                            : AppColors.lightSurfacePressed,
                        child: const Icon(Icons.person_outline,
                            color: AppColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          load.status == 'ACTIVE'
                              ? 'Haydovchi hali tayinlanmagan'
                              : 'Haydovchi biriktirilgan',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timeline Card
            NeuCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yuk hodisalari tarixi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const Divider(height: 20),
                  if (_events.isEmpty)
                    Text(
                      'Hodisalar mavjud emas',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    )
                  else
                    ..._events.map((event) {
                      final timeStr =
                          '${event.createdAt.day.toString().padLeft(2, '0')}.${event.createdAt.month.toString().padLeft(2, '0')}.${event.createdAt.year} ${event.createdAt.hour.toString().padLeft(2, '0')}:${event.createdAt.minute.toString().padLeft(2, '0')}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatEventType(event.eventType),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(bool isDark) {
    final status = _load!.status;
    final canEdit = status == 'ACTIVE' || status == 'ASSIGNED';
    final canCancel = status == 'ACTIVE' || status == 'ASSIGNED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          if (canEdit) ...[
            Expanded(
              child: AppButton(
                text: status == 'ASSIGNED' ? 'Tahrirlash (cheklangan)' : 'Tahrirlash',
                variant: AppButtonVariant.outline,
                onPressed: () async {
                  await context.push('/shipper/loads/${widget.loadId}/edit');
                  _loadData();
                },
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (canCancel)
            Expanded(
              child: AppButton(
                text: 'Bekor qilish',
                variant: AppButtonVariant.destructive,
                onPressed: _showCancelDialog,
              ),
            )
          else
            Expanded(
              child: AppButton(
                text: 'Nusxa ko\'chirish',
                onPressed: _duplicateLoad,
              ),
            ),
        ],
      ),
    );
  }
}
