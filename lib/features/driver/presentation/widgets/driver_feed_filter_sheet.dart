import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/models/driver_feed_item_model.dart';

const List<String> uzbekistanRegions = [
  'Toshkent shahri',
  'Toshkent viloyati',
  'Samarqand viloyati',
  'Buxoro viloyati',
  'Andijon viloyati',
  'Farg\'ona viloyati',
  'Namangan viloyati',
  'Qashqadaryo viloyati',
  'Surxondaryo viloyati',
  'Jizzax viloyati',
  'Sirdaryo viloyati',
  'Navoiy viloyati',
  'Xorazm viloyati',
  'Qoraqalpog\'iston Respublikasi',
];

const List<String> availableTruckTypes = [
  'TENT',
  'REFRIGERATOR',
  'ISOTHERMAL',
  'FLATBED',
  'CONTAINER',
  'DUMP',
  'TANKER',
  'OTHER',
];

class DriverFeedFilterSheet extends StatefulWidget {
  final DriverFeedFilter initialFilter;
  final ValueChanged<DriverFeedFilter> onApply;

  const DriverFeedFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<DriverFeedFilterSheet> createState() => _DriverFeedFilterSheetState();
}

class _DriverFeedFilterSheetState extends State<DriverFeedFilterSheet> {
  late List<String> _selectedTruckTypes;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _maxTonsController;
  late bool _includeNegotiable;
  String? _fromRegion;
  String? _toRegion;

  @override
  void initState() {
    super.initState();
    _selectedTruckTypes = List.from(widget.initialFilter.truckTypes);
    _minPriceController = TextEditingController(
      text: widget.initialFilter.minPrice != null ? widget.initialFilter.minPrice!.toStringAsFixed(0) : '',
    );
    _maxPriceController = TextEditingController(
      text: widget.initialFilter.maxPrice != null ? widget.initialFilter.maxPrice!.toStringAsFixed(0) : '',
    );
    _maxTonsController = TextEditingController(
      text: widget.initialFilter.maxTons != null ? widget.initialFilter.maxTons!.toStringAsFixed(1) : '',
    );
    _includeNegotiable = widget.initialFilter.includeNegotiable;
    _fromRegion = widget.initialFilter.fromRegion;
    _toRegion = widget.initialFilter.toRegion;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _maxTonsController.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _selectedTruckTypes.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _maxTonsController.clear();
      _includeNegotiable = true;
      _fromRegion = null;
      _toRegion = null;
    });
  }

  void _apply() {
    final minP = double.tryParse(_minPriceController.text.trim());
    final maxP = double.tryParse(_maxPriceController.text.trim());
    final maxT = double.tryParse(_maxTonsController.text.trim());

    final updated = widget.initialFilter.copyWith(
      truckTypes: _selectedTruckTypes,
      minPrice: minP,
      maxPrice: maxP,
      maxTons: maxT,
      includeNegotiable: _includeNegotiable,
      fromRegion: _fromRegion,
      toRegion: _toRegion,
    );

    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtrlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _clear,
                  child: const Text('Tozalash'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Truck Types
            Text(
              'Mashina turi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTruckTypes.map((type) {
                final isSelected = _selectedTruckTypes.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedTruckTypes.add(type);
                      } else {
                        _selectedTruckTypes.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Max Tons
            Text(
              'Maksimal og\'irlik (tonna)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _maxTonsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Masalan: 20',
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Price range
            Text(
              'Narx oralig\'i (so\'m)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Dan',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Gacha',
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kelishiladigan narxlarni ham ko\'rsatish', style: TextStyle(fontSize: 14)),
              value: _includeNegotiable,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _includeNegotiable = val),
            ),
            const SizedBox(height: 12),

            // Regions
            Text(
              'Qayerdan (viloyat)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _fromRegion,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Barcha viloyatlar')),
                ...uzbekistanRegions.map((r) => DropdownMenuItem(value: r, child: Text(r))),
              ],
              onChanged: (val) => setState(() => _fromRegion = val),
            ),
            const SizedBox(height: 16),

            Text(
              'Qayerga (viloyat)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _toRegion,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Barcha viloyatlar')),
                ...uzbekistanRegions.map((r) => DropdownMenuItem(value: r, child: Text(r))),
              ],
              onChanged: (val) => setState(() => _toRegion = val),
            ),
            const SizedBox(height: 24),

            // Apply Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _apply,
              child: const Text('Qo\'llash', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
