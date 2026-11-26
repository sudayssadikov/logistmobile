import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../domain/models/load_model.dart';
import '../../domain/repositories/loads_repository.dart';

class ShipperEditLoadScreen extends StatefulWidget {
  final String loadId;
  final ILoadsRepository? repository;

  const ShipperEditLoadScreen({
    super.key,
    required this.loadId,
    this.repository,
  });

  @override
  State<ShipperEditLoadScreen> createState() => _ShipperEditLoadScreenState();
}

class _ShipperEditLoadScreenState extends State<ShipperEditLoadScreen> {
  late final ILoadsRepository _repository;
  CreatedLoadModel? _originalLoad;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Controllers & Form State
  late final TextEditingController _cargoNameController;
  late final TextEditingController _weightController;
  late final TextEditingController _volumeController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  String _selectedCargoType = 'oziq_ovqat';
  String _selectedTruckType = 'TENT';
  late DateTime _pickupDate;
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
    _repository = widget.repository ?? getIt<ILoadsRepository>();
    _cargoNameController = TextEditingController();
    _weightController = TextEditingController();
    _volumeController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _pickupDate = DateTime.now();

    _loadData();
  }

  @override
  void dispose() {
    _cargoNameController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repository.getLoadById(widget.loadId);
    if (!mounted) return;

    if (res is ApiSuccess<CreatedLoadModel>) {
      final load = res.data;
      setState(() {
        _originalLoad = load;
        _cargoNameController.text = load.cargoName;
        _weightController.text = load.weightTons.toString();
        _volumeController.text = load.volumeM3?.toString() ?? '';
        _priceController.text = load.priceUzs != null ? load.priceUzs!.toStringAsFixed(0) : '';
        _descriptionController.text = load.description ?? '';
        _selectedCargoType = load.cargoType;
        _selectedTruckType = load.truckType;
        _pickupDate = load.pickupDate;
        _priceNegotiable = load.priceNegotiable;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res.errorOrNull ?? 'Xatolik yuz berdi';
        _isLoading = false;
      });
    }
  }

  bool _hasChanges() {
    if (_originalLoad == null) return false;
    final load = _originalLoad!;

    if (_cargoNameController.text.trim() != load.cargoName) return true;
    final double? weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight != null && weight != load.weightTons) return true;

    final double? volume = double.tryParse(_volumeController.text.replaceAll(',', '.'));
    if (volume != load.volumeM3) return true;

    if (_selectedCargoType != load.cargoType) return true;
    if (_selectedTruckType != load.truckType) return true;
    if (_priceNegotiable != load.priceNegotiable) return true;

    final double? price = double.tryParse(_priceController.text.replaceAll(' ', ''));
    if (price != load.priceUzs) return true;

    if (_descriptionController.text.trim() != (load.description ?? '')) return true;
    if (_pickupDate != load.pickupDate) return true;

    return false;
  }

  Future<void> _selectPickupTime(bool isAssigned) async {
    if (isAssigned) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_pickupDate),
      );
      if (time != null && mounted) {
        setState(() {
          _pickupDate = DateTime(
            _pickupDate.year,
            _pickupDate.month,
            _pickupDate.day,
            time.hour,
            time.minute,
          );
        });
      }
    } else {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: _pickupDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 90)),
      );
      if (pickedDate != null && mounted) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_pickupDate),
        );
        if (mounted) {
          setState(() {
            _pickupDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              time?.hour ?? _pickupDate.hour,
              time?.minute ?? _pickupDate.minute,
            );
          });
        }
      }
    }
  }

  Future<void> _showConflictDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tahrirlashda to\'qnashuv'),
        content: const Text(
          'Yuk ma\'lumotlari boshqa joyda o\'zgartirilgan. Eng so\'nggi ma\'lumotlarni olish uchun yangilang.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Yangilash'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_originalLoad == null) return;
    final isAssigned = _originalLoad!.status == 'ASSIGNED';

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'updatedAt': _originalLoad!.updatedAt.toIso8601String(),
    };

    if (isAssigned) {
      payload['description'] = _descriptionController.text.trim();
      payload['pickupDate'] = _pickupDate.toIso8601String();
    } else {
      payload['cargoName'] = _cargoNameController.text.trim();
      payload['cargoType'] = _selectedCargoType;
      payload['weightTons'] = double.tryParse(_weightController.text.replaceAll(',', '.')) ?? _originalLoad!.weightTons;
      final vol = double.tryParse(_volumeController.text.replaceAll(',', '.'));
      if (vol != null) payload['volumeM3'] = vol;
      payload['truckType'] = _selectedTruckType;
      payload['pickupDate'] = _pickupDate.toIso8601String();
      payload['priceNegotiable'] = _priceNegotiable;
      if (!_priceNegotiable) {
        payload['priceUzs'] = double.tryParse(_priceController.text.replaceAll(' ', ''));
      }
      payload['description'] = _descriptionController.text.trim();
    }

    final res = await _repository.updateLoad(widget.loadId, payload);
    if (!mounted) return;

    setState(() => _isSaving = false);

    if (res is ApiSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yuk muvaffaqiyatli saqlandi!'),
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
    } else if (res is ApiFailure) {
      final failure = res as ApiFailure;
      if (failure.statusCode == 409) {
        _showConflictDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
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
          'Yukni tahrirlash',
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
          onPressed: () => context.pop(),
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
                        child: const Text('Qayta urinish'),
                      ),
                    ],
                  ),
                )
              : _buildForm(isDark),
      bottomNavigationBar: _originalLoad != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: AppButton(
                text: 'Saqlash',
                isLoading: _isSaving,
                onPressed: _hasChanges() ? _saveChanges : null,
              ),
            )
          : null,
    );
  }

  Widget _buildForm(bool isDark) {
    final isAssigned = _originalLoad!.status == 'ASSIGNED';
    final dateStr =
        '${_pickupDate.day.toString().padLeft(2, '0')}.${_pickupDate.month.toString().padLeft(2, '0')}.${_pickupDate.year} ${_pickupDate.hour.toString().padLeft(2, '0')}:${_pickupDate.minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssigned) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Haydovchi tayinlangan: marshrut, vazn va narxni o\'zgartirib bo\'lmaydi. Faqat izoh va olib ketish soatini o\'zgartirish mumkin.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Cargo Name
          Text(
            'Yuk nomi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          AppTextField(
            controller: _cargoNameController,
            readOnly: isAssigned,
            hint: 'Masalan: Pomidor, Qurilish g\'ishti',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Cargo Type
          Text(
            'Yuk turi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedCargoType,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            ),
            items: _cargoTypeKeys.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: isAssigned
                ? null
                : (val) {
                    if (val != null) setState(() => _selectedCargoType = val);
                  },
          ),
          const SizedBox(height: 14),

          // Weight & Volume
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Og\'irligi (tonna)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _weightController,
                      readOnly: isAssigned,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hint: '10.5',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hajmi (m³)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _volumeController,
                      readOnly: isAssigned,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hint: '40',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Truck Type
          Text(
            'Mashina turi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedTruckType,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            ),
            items: _truckTypeKeys.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: isAssigned
                ? null
                : (val) {
                    if (val != null) setState(() => _selectedTruckType = val);
                  },
          ),
          const SizedBox(height: 14),

          // Pickup Date & Time
          Text(
            isAssigned ? 'Olib ketish vaqti (soat)' : 'Olib ketish sanasi va vaqti',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _selectPickupTime(isAssigned),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const Icon(Icons.access_time, size: 20, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Price
          if (!isAssigned) ...[
            Text(
              'Narx (UZS)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            AppTextField(
              controller: _priceController,
              readOnly: _priceNegotiable,
              keyboardType: TextInputType.number,
              hint: 'Masalan: 3 500 000',
              onChanged: (_) => setState(() {}),
            ),
            Row(
              children: [
                Checkbox(
                  value: _priceNegotiable,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _priceNegotiable = val ?? false;
                      if (_priceNegotiable) {
                        _priceController.clear();
                      }
                    });
                  },
                ),
                const Text('Kelishiladi'),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Description
          Text(
            'Qo\'shimcha izoh',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          AppTextField(
            controller: _descriptionController,
            hint: 'Yuklash shartlari, darvozadan kirish...',
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
