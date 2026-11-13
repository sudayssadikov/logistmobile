import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/map/map_provider.dart';
import '../../../../core/map/screens/location_picker_screen.dart';
import '../../../../core/utils/distance_calculator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/services/load_draft_service.dart';
import '../../domain/models/load_model.dart';
import '../../domain/repositories/loads_repository.dart';

class ShipperCreateLoadScreen extends StatefulWidget {
  final LoadDraftService? draftService;
  final ILoadsRepository? loadsRepository;

  const ShipperCreateLoadScreen({
    super.key,
    this.draftService,
    this.loadsRepository,
  });

  @override
  State<ShipperCreateLoadScreen> createState() => _ShipperCreateLoadScreenState();
}

class _ShipperCreateLoadScreenState extends State<ShipperCreateLoadScreen> {
  late final LoadDraftService _draftService;
  late final ILoadsRepository _loadsRepository;

  int _currentStep = 0; // 0..3
  bool _isLoading = false;
  bool _isPublishing = false;
  CreatedLoadModel? _publishedLoad;

  // Step 1: Locations
  LocationResult? _fromLocation;
  LocationResult? _toLocation;
  double? _approxDistanceKm;

  // Step 2: Cargo
  final TextEditingController _cargoNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCargoType = 'oziq_ovqat';

  // Step 3: Truck & Date
  String _selectedTruckType = 'TENT';
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));

  // Step 4: Pricing
  final TextEditingController _priceController = TextEditingController();
  bool _priceNegotiable = false;

  final List<String> _cargoTypeKeys = [
    'oziq_ovqat',
    'qurilish_materiallari',
    'mebel_maishiy',
    'qishloq_xojaligi',
    'kiyim_tekstil',
    'texnika',
    'kimyo_xavfli',
    'boshqa',
  ];

  final List<String> _truckTypeKeys = [
    'TENT',
    'REFRIGERATOR',
    'ISOTHERMAL',
    'FLATBED',
    'CONTAINER',
    'DUMP',
    'TANKER',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    _draftService = widget.draftService ?? getIt<LoadDraftService>();
    _loadsRepository = widget.loadsRepository ?? getIt<ILoadsRepository>();
    _loadDraft();
  }

  @override
  void dispose() {
    _cargoNameController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    setState(() => _isLoading = true);
    final draft = await _draftService.getDraft();
    if (draft != null && mounted) {
      setState(() {
        _currentStep = draft.step;
        _fromLocation = draft.fromLocation;
        _toLocation = draft.toLocation;
        _cargoNameController.text = draft.cargoName;
        _selectedCargoType = draft.cargoType;
        _weightController.text = draft.weightTons;
        _volumeController.text = draft.volumeM3;
        _descriptionController.text = draft.description;
        _selectedTruckType = draft.truckType;
        if (draft.pickupDate != null) _pickupDate = draft.pickupDate!;
        _priceController.text = draft.priceUzs;
        _priceNegotiable = draft.priceNegotiable;
        _calculateDistance();
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveCurrentDraft() async {
    final draft = CreateLoadDraft(
      step: _currentStep,
      fromLocation: _fromLocation,
      toLocation: _toLocation,
      cargoName: _cargoNameController.text,
      cargoType: _selectedCargoType,
      weightTons: _weightController.text,
      volumeM3: _volumeController.text,
      truckType: _selectedTruckType,
      pickupDate: _pickupDate,
      priceUzs: _priceController.text,
      priceNegotiable: _priceNegotiable,
      description: _descriptionController.text,
    );
    await _draftService.saveDraft(draft);
  }

  void _calculateDistance() {
    if (_fromLocation != null && _toLocation != null) {
      _approxDistanceKm = DistanceCalculator.calculateDistanceKm(
        lat1: _fromLocation!.lat,
        lon1: _fromLocation!.lng,
        lat2: _toLocation!.lat,
        lon2: _toLocation!.lng,
      );
    } else {
      _approxDistanceKm = null;
    }
  }

  Future<void> _pickLocation({required bool isFrom}) async {
    final initialPoint = isFrom
        ? (_fromLocation != null ? GeoPoint(_fromLocation!.lat, _fromLocation!.lng) : null)
        : (_toLocation != null ? GeoPoint(_toLocation!.lat, _toLocation!.lng) : null);

    final title = isFrom ? 'createLoad.fromLabel'.tr() : 'createLoad.toLabel'.tr();

    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: title,
          initialLocation: initialPoint,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromLocation = result;
        } else {
          _toLocation = result;
        }
        _calculateDistance();
      });
      await _saveCurrentDraft();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.rose,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_fromLocation == null || _toLocation == null) {
        _showErrorSnackBar('createLoad.locationsError'.tr());
        return false;
      }
      if (_approxDistanceKm != null && _approxDistanceKm! < 1.0) {
        _showErrorSnackBar('createLoad.distError'.tr());
        return false;
      }
      return true;
    } else if (step == 1) {
      if (_cargoNameController.text.trim().isEmpty) {
        _showErrorSnackBar('createLoad.nameError'.tr());
        return false;
      }
      final weight = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
      if (weight < 0.1 || weight > 60.0) {
        _showErrorSnackBar('createLoad.weightError'.tr());
        return false;
      }
      return true;
    } else if (step == 2) {
      final now = DateTime.now().subtract(const Duration(hours: 1));
      if (_pickupDate.isBefore(now)) {
        _showErrorSnackBar('createLoad.dateError'.tr());
        return false;
      }
      return true;
    } else if (step == 3) {
      if (!_priceNegotiable) {
        final cleanPrice = _priceController.text.replaceAll(' ', '').replaceAll(',', '');
        final price = double.tryParse(cleanPrice) ?? 0.0;
        if (price <= 0) {
          _showErrorSnackBar('createLoad.priceError'.tr());
          return false;
        }
      }
      return true;
    }
    return true;
  }

  void _goNext() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < 3) {
        setState(() => _currentStep++);
        _saveCurrentDraft();
      }
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _saveCurrentDraft();
    }
  }

  Future<void> _submitLoad() async {
    if (_isPublishing) return; // Idempotency: ikki marta bosishdan himoya
    if (!_validateStep(3)) return;

    setState(() => _isPublishing = true);

    final draft = CreateLoadDraft(
      fromLocation: _fromLocation,
      toLocation: _toLocation,
      cargoName: _cargoNameController.text.trim(),
      cargoType: _selectedCargoType,
      weightTons: _weightController.text.trim(),
      volumeM3: _volumeController.text.trim(),
      truckType: _selectedTruckType,
      pickupDate: _pickupDate,
      priceUzs: _priceController.text.trim(),
      priceNegotiable: _priceNegotiable,
      description: _descriptionController.text.trim(),
    );

    final result = await _loadsRepository.createLoad(draft: draft);

    if (!mounted) return;
    setState(() => _isPublishing = false);

    result.when(
      success: (load) async {
        await _draftService.clearDraft();
        setState(() {
          _publishedLoad = load;
        });
      },
      failure: (message, code, data) {
        _showErrorSnackBar(message);
      },
    );
  }

  void _resetForm() {
    setState(() {
      _publishedLoad = null;
      _currentStep = 0;
      _fromLocation = null;
      _toLocation = null;
      _approxDistanceKm = null;
      _cargoNameController.clear();
      _weightController.clear();
      _volumeController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _priceNegotiable = false;
      _pickupDate = DateTime.now().add(const Duration(days: 1));
    });
  }

  IconData _getTruckIcon(String type) {
    switch (type) {
      case 'REFRIGERATOR':
        return Icons.ac_unit_rounded;
      case 'ISOTHERMAL':
        return Icons.kitchen_rounded;
      case 'FLATBED':
        return Icons.view_agenda_outlined;
      case 'CONTAINER':
        return Icons.view_in_ar_rounded;
      case 'DUMP':
        return Icons.electric_rickshaw_rounded;
      case 'TANKER':
        return Icons.water_drop_outlined;
      case 'TENT':
      default:
        return Icons.local_shipping_rounded;
    }
  }

  String _formatNumber(String val) {
    if (val.isEmpty) return '';
    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final chars = digits.split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(' ');
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_publishedLoad != null) {
      return _buildSuccessView(isDark);
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: NeuAppBar(
        title: 'createLoad.title'.tr(),
        actions: [
          Tooltip(
            message: 'common.clear'.tr(),
            child: NeuIconButton(
              icon: Icons.refresh_rounded,
              onPressed: () async {
                await _draftService.clearDraft();
                _resetForm();
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator (4 qadam)
            _buildProgressIndicator(isDark),

            // Wizard qadamlari
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildCurrentStepContent(isDark),
              ),
            ),

            // Pastki navigatsiya tugmalari (Orqaga / Keyingi / E'lon qilish)
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    final stepTitles = [
      'createLoad.stepRoute'.tr(),
      'createLoad.stepCargo'.tr(),
      'createLoad.stepTruck'.tr(),
      'createLoad.stepPrice'.tr(),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          final color = isCurrent
              ? (isDark ? Colors.white : AppColors.primary)
              : isCompleted
                  ? AppColors.emerald
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isCurrent && isDark ? Colors.black : Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              stepTitles[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrent
                                    ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < 3) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Route(isDark);
      case 1:
        return _buildStep2Cargo(isDark);
      case 2:
        return _buildStep3TruckAndDate(isDark);
      case 3:
      default:
        return _buildStep4PriceAndReview(isDark);
    }
  }

  // 1-QADAM: MARSHRUT (Qayerdan - Qayerga)
  Widget _buildStep1Route(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLocationCard(
          isFrom: true,
          location: _fromLocation,
          isDark: isDark,
          onTap: () => _pickLocation(isFrom: true),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_downward_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildLocationCard(
          isFrom: false,
          location: _toLocation,
          isDark: isDark,
          onTap: () => _pickLocation(isFrom: false),
        ),
        const SizedBox(height: 20),
        if (_approxDistanceKm != null)
          NeuCard(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.straighten_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'createLoad.approxDistance'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'createLoad.approxKm'.tr(args: {'km': _approxDistanceKm!.toStringAsFixed(1)}),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationCard({
    required bool isFrom,
    required LocationResult? location,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final title = isFrom ? 'createLoad.fromLabel'.tr() : 'createLoad.toLabel'.tr();
    final isSelected = location != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: NeuCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isFrom ? AppColors.primary : AppColors.emerald).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isFrom ? Icons.trip_origin_rounded : Icons.location_on_rounded,
                size: 22,
                color: isFrom ? AppColors.primary : AppColors.emerald,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isSelected) ...[
                    Text(
                      location.address,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${location.region} • ${location.city}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'createLoad.selectFromMap'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ],
        ),
      ),
    );
  }

  // 2-QADAM: YUK TAFSILOTLARI
  Widget _buildStep2Cargo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'createLoad.cargoName'.tr(),
          hint: 'createLoad.cargoNameHint'.tr(),
          controller: _cargoNameController,
          prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
          onChanged: (_) => _saveCurrentDraft(),
        ),
        const SizedBox(height: 16),

        // Cargo type dropdown
        Text(
          'createLoad.cargoType'.tr(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCargoType,
              dropdownColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              items: _cargoTypeKeys.map((key) {
                return DropdownMenuItem(
                  value: key,
                  child: Text(
                    'cargoTypes.$key'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCargoType = val);
                  _saveCurrentDraft();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              flex: 3,
              child: AppTextField(
                label: 'createLoad.weightTons'.tr(),
                hint: 'createLoad.weightHint'.tr(),
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.scale_outlined, size: 20),
                onChanged: (_) => _saveCurrentDraft(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppTextField(
                label: 'createLoad.volumeM3'.tr(),
                hint: 'createLoad.volumeHint'.tr(),
                controller: _volumeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.view_in_ar_outlined, size: 20),
                onChanged: (_) => _saveCurrentDraft(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        AppTextField(
          label: 'createLoad.description'.tr(),
          hint: 'createLoad.descriptionHint'.tr(),
          controller: _descriptionController,
          maxLines: 3,
          prefixIcon: const Icon(Icons.description_outlined, size: 20),
          onChanged: (_) => _saveCurrentDraft(),
        ),
      ],
    );
  }

  // 3-QADAM: MASHINA VA VAQT
  Widget _buildStep3TruckAndDate(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'createLoad.truckType'.tr(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),

        // Grid of Truck Types
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _truckTypeKeys.length,
          itemBuilder: (context, idx) {
            final key = _truckTypeKeys[idx];
            final isSelected = _selectedTruckType == key;
            final icon = _getTruckIcon(key);

            return InkWell(
              onTap: () {
                setState(() => _selectedTruckType = key);
                _saveCurrentDraft();
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.primary)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'truckTypes.$key'.tr(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        Text(
          'createLoad.pickupDate'.tr(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _pickupDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (picked != null && mounted) {
              setState(() => _pickupDate = picked);
              _saveCurrentDraft();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: NeuCard(
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  '${_pickupDate.day.toString().padLeft(2, '0')}.${_pickupDate.month.toString().padLeft(2, '0')}.${_pickupDate.year}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.edit_calendar_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 4-QADAM: NARX VA KO'RIB CHIQISH
  Widget _buildStep4PriceAndReview(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NeuCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'createLoad.priceSection'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 12),

              // "Narx kelishiladi" Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'createLoad.priceNegotiable'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'createLoad.priceNegotiableDesc'.tr(),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _priceNegotiable,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _priceNegotiable = val);
                      _saveCurrentDraft();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Summa kiritish maydoni (agar kelishiladi yoqilmagan bo'lsa)
              if (!_priceNegotiable)
                AppTextField(
                  label: 'createLoad.priceUzs'.tr(),
                  hint: 'createLoad.priceHint'.tr(),
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                  onChanged: (val) {
                    final formatted = _formatNumber(val);
                    if (formatted != val) {
                      _priceController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                    _saveCurrentDraft();
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // KO'RIB CHIQISH (Review Summary Card)
        Text(
          'createLoad.summaryTitle'.tr(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 10),

        NeuCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryRow('createLoad.fromLabel'.tr(), _fromLocation?.address ?? '-', isDark),
              const Divider(height: 16),
              _buildSummaryRow('createLoad.toLabel'.tr(), _toLocation?.address ?? '-', isDark),
              const Divider(height: 16),
              _buildSummaryRow('createLoad.approxDistance'.tr(), '${_approxDistanceKm?.toStringAsFixed(1) ?? '0'} km', isDark),
              const Divider(height: 16),
              _buildSummaryRow('createLoad.cargoName'.tr(), _cargoNameController.text.trim(), isDark),
              const Divider(height: 16),
              _buildSummaryRow('createLoad.weightTons'.tr(), '${_weightController.text.trim()} t', isDark),
              const Divider(height: 16),
              _buildSummaryRow('createLoad.truckType'.tr(), 'truckTypes.$_selectedTruckType'.tr(), isDark),
              const Divider(height: 16),
              _buildSummaryRow(
                'createLoad.priceSection'.tr(),
                _priceNegotiable ? 'createLoad.priceNegotiable'.tr() : '${_priceController.text.trim()} UZS',
                isDark,
                isHighlight: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight
                  ? AppColors.primary
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final isLastStep = _currentStep == 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          if (_currentStep > 0) ...[
            Expanded(
              flex: 2,
              child: AppButton(
                text: 'common.back'.tr(),
                variant: AppButtonVariant.secondary,
                onPressed: _isPublishing ? null : _goBack,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 3,
            child: AppButton(
              text: isLastStep ? 'createLoad.publish'.tr() : 'common.next'.tr(),
              isLoading: _isPublishing,
              onPressed: isLastStep ? _submitLoad : _goNext,
            ),
          ),
        ],
      ),
    );
  }

  // MUVAFFAQIYAT KO'RINISHI (Success View)
  Widget _buildSuccessView(bool isDark) {
    final load = _publishedLoad!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'createLoad.successTitle'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'createLoad.successDesc'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Yaratilgan yuk kartochkasi
                NeuCard(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            load.cargoName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              load.status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.route_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${load.fromCity} ➔ ${load.toCity} (${load.distanceKm.toStringAsFixed(1)} km)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.scale_outlined, size: 16, color: AppColors.indigo),
                          const SizedBox(width: 8),
                          Text(
                            '${load.weightTons} t • truckTypes.${load.truckType}'.tr(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            load.priceNegotiable
                                ? 'createLoad.priceNegotiable'.tr()
                                : '${load.priceUzs?.toStringAsFixed(0)} UZS',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Tugmalar: [Yana yuk qo'shish], [Yuklarimga o'tish]
                AppButton(
                  text: 'createLoad.addAnother'.tr(),
                  variant: AppButtonVariant.secondary,
                  onPressed: _resetForm,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'createLoad.goToMyLoads'.tr(),
                  onPressed: () {
                    _resetForm();
                    context.go('/shipper/my-loads');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
