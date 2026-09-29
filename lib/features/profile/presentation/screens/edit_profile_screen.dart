import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehiclePlateController;
  late TextEditingController _licenseController;
  late TextEditingController _bankCardController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user ??
        const UserModel(
          id: 'USR-ME',
          fullName: 'Rustam Karimov',
          email: 'rustam.driver@logiflow.uz',
          phone: '+998 90 123 45 67',
          role: UserRole.driver,
        );

    _nameController = TextEditingController(text: user.fullName);
    _phoneController = TextEditingController(text: user.phone);
    _companyController = TextEditingController(text: user.companyName ?? 'Toshkent Auto Trans');
    _vehicleModelController = TextEditingController(text: user.vehicleModel ?? 'Volvo FH16 (Refrigerated)');
    _vehiclePlateController = TextEditingController(text: user.vehiclePlate ?? '01 A 777 AA');
    _licenseController = TextEditingController(text: user.driverLicenseNumber ?? 'AA 9812450');
    _bankCardController = TextEditingController(text: user.bankCardNumber ?? '8600 4910 8821 4819');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _licenseController.dispose();
    _bankCardController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final current = context.read<AuthBloc>().state.user;
    if (current == null) return;

    final updated = current.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      companyName: _companyController.text.trim(),
      vehicleModel: _vehicleModelController.text.trim(),
      vehiclePlate: _vehiclePlateController.text.trim(),
      driverLicenseNumber: _licenseController.text.trim(),
      bankCardNumber: _bankCardController.text.trim(),
    );

    context.read<AuthBloc>().add(AuthUpdateProfileSubmitted(updated));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('common.success'.tr()),
        backgroundColor: AppColors.emerald,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('profile.editProfile'.tr()),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          final isDriver = user?.role == UserRole.driver || user?.role == UserRole.carrier;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar Center Picker
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            _nameController.text.isNotEmpty ? _nameController.text[0] : 'U',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Info Section
                Text(
                  'PERSONAL & CONTACT CREDENTIALS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Company / Fleet Entity',
                  controller: _companyController,
                  prefixIcon: const Icon(Icons.business_rounded),
                ),
                const SizedBox(height: 24),

                // Rig & Driver Specific Details
                if (isDriver) ...[
                  Text(
                    'TRUCK RIG & VEHICLE SPECIFICATIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    label: 'Truck Model & Type',
                    controller: _vehicleModelController,
                    prefixIcon: const Icon(Icons.local_shipping_outlined),
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Vehicle Plate Number',
                    controller: _vehiclePlateController,
                    prefixIcon: const Icon(Icons.pin_outlined),
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Driver License Number (Haydovchilik guvohnomasi)',
                    controller: _licenseController,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  const SizedBox(height: 14),

                  AppTextField(
                    label: 'Payout Bank Card (Uzcard / Humo)',
                    controller: _bankCardController,
                    prefixIcon: const Icon(Icons.credit_card_rounded),
                  ),
                  const SizedBox(height: 32),
                ],

                // Save Profile Button
                AppButton(
                  text: 'Save Changes',
                  onPressed: _saveProfile,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
