import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/load_status.dart';
import '../../domain/models/shipment_model.dart';
import '../bloc/shipment_bloc.dart';
import '../bloc/shipment_event.dart';

class CreateLoadWizardScreen extends StatefulWidget {
  const CreateLoadWizardScreen({super.key});

  @override
  State<CreateLoadWizardScreen> createState() => _CreateLoadWizardScreenState();
}

class _CreateLoadWizardScreenState extends State<CreateLoadWizardScreen> {
  int _currentStep = 0;

  // Step 1: Route Controllers
  final _originCityController = TextEditingController(text: 'Tashkent');
  final _originAddressController = TextEditingController(text: 'Chilanzar Industrial District, Gate 2');
  final _destCityController = TextEditingController(text: 'Samarkand');
  final _destAddressController = TextEditingController(text: 'Ulugbek Central Logistics Terminal');
  final _distanceController = TextEditingController(text: '310');

  // Step 2: Cargo Controllers
  final _cargoTitleController = TextEditingController(text: 'Electronics & Component Assembly Parts');
  final _weightController = TextEditingController(text: '18.5');
  final _volumeController = TextEditingController(text: '75.0');
  String _selectedCargoType = 'Standard Box / Curtain';

  // Step 3: Budget & Escrow
  final _priceController = TextEditingController(text: '14500000');

  final List<String> _cargoTypes = [
    'Standard Box / Curtain',
    'Refrigerated (+2..+8°C)',
    'Heavy Machinery / Flatbed',
    'Hazardous / ADR',
    'Bulk Agricultural',
  ];

  @override
  void dispose() {
    _originCityController.dispose();
    _originAddressController.dispose();
    _destCityController.dispose();
    _destAddressController.dispose();
    _distanceController.dispose();
    _cargoTitleController.dispose();
    _weightController.dispose();
    _volumeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final newShipment = ShipmentModel(
      id: 'SHP-${DateTime.now().millisecondsSinceEpoch % 10000}',
      trackingCode: 'LF-UZ-${1000 + DateTime.now().millisecond}',
      shipperId: 'USR-SHIPPER-01',
      shipperName: 'Agro Export Holding',
      status: LoadStatus.created,
      origin: LocationPoint(
        city: _originCityController.text,
        address: _originAddressController.text,
        latitude: 41.2995,
        longitude: 69.2401,
        scheduledTime: DateTime.now().add(const Duration(hours: 3)),
      ),
      destination: LocationPoint(
        city: _destCityController.text,
        address: _destAddressController.text,
        latitude: 39.6542,
        longitude: 66.9597,
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      ),
      cargoTitle: _cargoTitleController.text,
      cargoType: _selectedCargoType,
      weightTons: double.tryParse(_weightController.text) ?? 20.0,
      volumeM3: double.tryParse(_volumeController.text) ?? 80.0,
      price: double.tryParse(_priceController.text) ?? 14500000.0,
      isEscrowFunded: false,
      distanceKm: double.tryParse(_distanceController.text) ?? 310.0,
      eta: '4h 30m',
      createdAt: DateTime.now(),
    );

    context.read<ShipmentBloc>().add(CreateShipmentSubmitted(newShipment));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('shipments.postNewLoad'.tr()),
      ),
      body: Column(
        children: [
          // Step Progress Tracker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                _StepIndicator(index: 0, title: 'shipments.routeSchedule'.tr(), currentStep: _currentStep),
                _StepDivider(isActive: _currentStep > 0),
                _StepIndicator(index: 1, title: 'shipments.cargoSpecs'.tr(), currentStep: _currentStep),
                _StepDivider(isActive: _currentStep > 1),
                _StepIndicator(index: 2, title: 'shipments.offerRate'.tr(), currentStep: _currentStep),
              ],
            ),
          ),

          // Wizard Form Pages
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildCurrentStepContent(context),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: AppButton(
                        text: 'common.back'.tr(),
                        variant: AppButtonVariant.outline,
                        onPressed: () => setState(() => _currentStep--),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      text: _currentStep == 2 ? 'common.submit'.tr() : 'common.next'.tr(),
                      suffixIcon: _currentStep == 2 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      onPressed: () {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
                          _handleSubmit();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Route();
      case 1:
        return _buildStep2Cargo();
      case 2:
        return _buildStep3PriceAndEscrow();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Route() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormSectionHeader(title: 'shipments.originLocation'.tr(), icon: Icons.trip_origin_rounded),
        const SizedBox(height: 12),
        AppTextField(
          label: 'shipments.originCity'.tr(),
          controller: _originCityController,
          prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'shipments.pickupAddress'.tr(),
          controller: _originAddressController,
          prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
        ),
        const SizedBox(height: 24),
        _FormSectionHeader(title: 'shipments.destinationLocation'.tr(), icon: Icons.location_on_rounded),
        const SizedBox(height: 12),
        AppTextField(
          label: 'shipments.destCity'.tr(),
          controller: _destCityController,
          prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'shipments.deliveryAddress'.tr(),
          controller: _destAddressController,
          prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'shipments.distance'.tr(),
          controller: _distanceController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.straighten_rounded, size: 20),
        ),
      ],
    );
  }

  Widget _buildStep2Cargo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormSectionHeader(title: 'shipments.cargoSpecs'.tr(), icon: Icons.inventory_2_rounded),
        const SizedBox(height: 12),
        AppTextField(
          label: 'shipments.cargoTitle'.tr(),
          controller: _cargoTitleController,
          prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
        ),
        const SizedBox(height: 16),
        Text(
          'shipments.category'.tr(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCargoType,
          items: _cargoTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13)));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCargoType = val);
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'shipments.weight'.tr(),
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.scale_rounded, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                label: 'shipments.volume'.tr(),
                controller: _volumeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.view_in_ar_rounded, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3PriceAndEscrow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormSectionHeader(title: 'shipments.offerRate'.tr(), icon: Icons.payments_rounded),
        const SizedBox(height: 12),
        AppTextField(
          label: 'shipments.targetRate'.tr(),
          controller: _priceController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
          suffixIcon: const Padding(
            padding: EdgeInsets.all(14),
            child: Text('UZS', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user_rounded, color: AppColors.emerald, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'shipments.escrowGuarantee'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'shipments.escrowGuaranteeDesc'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        height: 1.3,
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
}

class _FormSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _FormSectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int index;
  final String title;
  final int currentStep;

  const _StepIndicator({
    required this.index,
    required this.title,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = currentStep > index;
    final isActive = currentStep == index;

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isDone ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isActive || isDone ? AppColors.primary : AppColors.darkBorder,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.darkTextMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.darkTextMuted,
          ),
        ),
      ],
    );
  }
}

class _StepDivider extends StatelessWidget {
  final bool isActive;
  const _StepDivider({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        height: 1.5,
        color: isActive ? AppColors.primary : AppColors.darkBorderSubtle,
      ),
    );
  }
}
