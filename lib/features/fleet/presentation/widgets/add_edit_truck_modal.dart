import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/truck_model.dart';
import '../bloc/fleet_bloc.dart';
import '../bloc/fleet_event.dart';

class AddEditTruckModal extends StatefulWidget {
  const AddEditTruckModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<FleetBloc>(),
        child: const AddEditTruckModal(),
      ),
    );
  }

  @override
  State<AddEditTruckModal> createState() => _AddEditTruckModalState();
}

class _AddEditTruckModalState extends State<AddEditTruckModal> {
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _weightController = TextEditingController(text: '22.0');
  final _volumeController = TextEditingController(text: '86.0');
  TruckBodyType _selectedType = TruckBodyType.tent;

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_plateController.text.trim().isEmpty || _modelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('common.error'.tr()),
          backgroundColor: AppColors.rose,
        ),
      );
      return;
    }

    final newTruck = TruckModel(
      id: '',
      plateNumber: _plateController.text.trim().toUpperCase(),
      model: _modelController.text.trim(),
      bodyType: _selectedType,
      maxWeightTons: double.tryParse(_weightController.text.trim()) ?? 20.0,
      maxVolumeM3: double.tryParse(_volumeController.text.trim()) ?? 80.0,
      isAvailable: true,
    );

    context.read<FleetBloc>().add(AddTruckSubmitted(newTruck));
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
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'fleet.addTruck'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // Plate Number
            AppTextField(
              controller: _plateController,
              label: 'fleet.plateNumber'.tr(),
              hint: '01 777 AAA',
              prefixIcon: const Icon(Icons.featured_play_list_outlined, size: 20),
            ),
            const SizedBox(height: 14),

            // Model
            AppTextField(
              controller: _modelController,
              label: 'fleet.truckModel'.tr(),
              hint: 'Volvo FH16 / MAN TGX / Scania',
              prefixIcon: const Icon(Icons.local_shipping_outlined, size: 20),
            ),
            const SizedBox(height: 14),

            // Body Type dropdown
            Text(
              'fleet.bodyType'.tr(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TruckBodyType>(
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  items: TruckBodyType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(t.icon, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(t.labelKey.tr(), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Weight & Volume
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _weightController,
                    label: 'Weight (Tons)',
                    hint: '22.0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _volumeController,
                    label: 'Volume (m³)',
                    hint: '86.0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            AppButton(
              text: 'common.save'.tr(),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
