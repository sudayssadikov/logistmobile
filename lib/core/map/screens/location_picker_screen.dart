import 'dart:async';
import 'package:flutter/material.dart';
import '../../di/injection.dart';
import '../../localization/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/neu_design_system.dart';
import '../../theme/neu_shadows.dart';
import '../../widgets/app_button.dart';
import '../map_provider.dart';
import '../uzbekistan_regions.dart';

class LocationPickerScreen extends StatefulWidget {
  final String title;
  final GeoPoint? initialLocation;
  final IMapProvider? mapProvider;

  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initialLocation,
    this.mapProvider,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final IMapProvider _mapProvider;
  late GeoPoint _currentCenter;
  double _currentZoom = 13.0;

  final TextEditingController _searchController = TextEditingController();
  List<MapSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingAddress = false;
  Timer? _debounceTimer;
  Timer? _searchDebounceTimer;

  LocationResult? _selectedResult;
  Key _mapKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _mapProvider = widget.mapProvider ?? getIt<IMapProvider>();
    // Default to Tashkent coordinates if not provided
    _currentCenter = widget.initialLocation ?? const GeoPoint(41.2995, 69.2401);
    _fetchAddressForCenter(_currentCenter);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onPositionChanged(GeoPoint newCenter) {
    _currentCenter = newCenter;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _fetchAddressForCenter(_currentCenter);
      }
    });
  }

  Future<void> _fetchAddressForCenter(GeoPoint center) async {
    setState(() => _isLoadingAddress = true);
    try {
      final res = await _mapProvider.reverseGeocode(center.latitude, center.longitude);
      if (mounted) {
        setState(() {
          _selectedResult = res;
          _isLoadingAddress = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedResult = LocationResult(
            lat: center.latitude,
            lng: center.longitude,
            address: 'Koordinata: ${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}',
            region: UzbekistanRegions.toshkentShahar,
            city: 'Toshkent',
          );
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    _searchDebounceTimer?.cancel();
    if (val.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 700), () async {
      setState(() => _isSearching = true);
      final results = await _mapProvider.searchAddress(val);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(MapSearchResult item) {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _currentCenter = GeoPoint(item.lat, item.lng);
      _currentZoom = 15.0;
      _mapKey = UniqueKey();
      _selectedResult = LocationResult(
        lat: item.lat,
        lng: item.lng,
        address: item.displayName,
        region: item.region ?? UzbekistanRegions.toshkentShahar,
        city: item.city ?? 'Shahar',
      );
    });
  }

  Future<void> _moveToCurrentLocation() async {
    final myPos = await _mapProvider.currentLocation();
    if (myPos != null) {
      setState(() {
        _currentCenter = myPos;
        _currentZoom = 15.0;
        _mapKey = UniqueKey();
      });
      _fetchAddressForCenter(myPos);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('location.permissionDeniedHint'.tr().isNotEmpty
                ? 'location.permissionDeniedHint'.tr()
                : 'GPS ruxsati berilmadi. Xaritadan yoki qidiruv orqali tanlang.'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
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
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // 1. Asosiy xarita vidjeti (MapProvider orqali render qilinadi)
          Positioned.fill(
            child: _mapProvider.buildMap(
              key: _mapKey,
              initialCenter: _currentCenter,
              initialZoom: _currentZoom,
              onPositionChanged: _onPositionChanged,
              isDark: isDark,
            ),
          ),

          // 2. Markazdagi Pin belgisi
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 28,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Tepada Qidiruv paneli va natijalar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                NeuCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  borderRadius: 14,
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'common.searchPlaceholder'.tr().isNotEmpty
                                ? 'common.searchPlaceholder'.tr()
                                : 'Manzil yoki shaharni qidiring...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        ),
                      if (_isSearching)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                // Qidiruv natijalari dropdown
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      boxShadow: NeuShadows.elevation(isDark: isDark, blur: 12, offset: 4),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      itemBuilder: (context, idx) {
                        final item = _searchResults[idx];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
                          title: Text(
                            item.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          subtitle: item.region != null
                              ? Text(
                                  '${item.region} • ${item.city}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.lightTextSecondary),
                                )
                              : null,
                          onTap: () => _selectSearchResult(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 4. "Mening joylashuvim" Floating Button
          Positioned(
            right: 16,
            bottom: 190,
            child: NeuIconButton(
              icon: Icons.my_location_rounded,
              size: 48,
              iconSize: 22,
              onPressed: _moveToCurrentLocation,
            ),
          ),

          // 5. Pastki Tanlangan manzil kartochkasi va Tasdiqlash tugmasi
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: NeuCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 22,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedResult?.region ?? UzbekistanRegions.toshkentShahar,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (_isLoadingAddress)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'common.loading'.tr(),
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              )
                            else
                              Text(
                                _selectedResult?.address ?? 'Joylashuv aniqlanmoqda...',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'common.confirm'.tr().isNotEmpty ? 'common.confirm'.tr() : 'Tasdiqlash',
                    isLoading: _isLoadingAddress,
                    onPressed: _selectedResult != null
                        ? () {
                            Navigator.of(context).pop(_selectedResult);
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

