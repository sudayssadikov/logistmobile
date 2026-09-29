import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/user_model.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  UserRole _selectedRole = UserRole.driver; // Default to driver or shipper

  // Common Controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Shipper / Factory Specific Controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyStirController = TextEditingController();
  final TextEditingController _factoryAddressController = TextEditingController();
  String _selectedIndustry = 'Ishlab chiqaruvchi zavod';

  // Driver Specific Controllers
  final TextEditingController _driverLicenseController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _capacityTonsController = TextEditingController(text: '22');
  String _selectedBodyType = 'Tentli (Parda)';

  bool _isSubmitting = false;

  final List<String> _industryOptions = [
    'Ishlab chiqaruvchi zavod',
    'Oziq-ovqat va Qishloq xo\'jaligi',
    'Qurilish mollari va Kimyo',
    'Og\'ir sanoat va Metallurgiya',
    'Ulgurji savdo va Distribyutsiya',
  ];

  final List<String> _bodyTypeOptions = [
    'Tentli (Parda)',
    'Sovutgichli ref (+4°C)',
    'Izotermik furgon',
    'Bortli ochiq platforma',
    'Fura (Katta hajm 92m³)',
    'Kichik yuk mashinasi (Isuzu/Gazel)',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _companyStirController.dispose();
    _factoryAddressController.dispose();
    _driverLicenseController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _capacityTonsController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    // Validation
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.fillAllFields'.tr()),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.passwordMismatch'.tr()),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Role specific validation
    if (_selectedRole == UserRole.shipper) {
      if (_companyNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iltimos, korxona yoki zavod nomini kiriting'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else {
      if (_vehicleModelController.text.trim().isEmpty || _vehiclePlateController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iltimos, yuk mashinasi modeli va davlat raqamini kiriting'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final generatedId = _selectedRole == UserRole.shipper
        ? 'USR-SHIPPER-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
        : 'USR-DRIVER-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final newUser = UserModel(
      id: generatedId,
      fullName: fullName,
      email: email,
      phone: phone,
      role: _selectedRole,
      companyName: _selectedRole == UserRole.shipper
          ? '${_companyNameController.text.trim()} ($_selectedIndustry)'
          : '$fullName (Shaxsiy fura: ${_vehicleModelController.text.trim()})',
      vehicleModel: _selectedRole == UserRole.driver
          ? '${_vehicleModelController.text.trim()} ($_selectedBodyType)'
          : null,
      vehiclePlate: _selectedRole == UserRole.driver ? _vehiclePlateController.text.trim() : null,
      driverLicenseNumber: _selectedRole == UserRole.driver ? _driverLicenseController.text.trim() : null,
      isVerified: true,
      rating: 5.0,
      completedTrips: 0,
      walletBalance: 0.0,
    );

    context.read<AuthBloc>().add(
          AuthRegisterSubmitted(
            user: newUser,
            password: password,
          ),
        );

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text('auth.registerSuccess'.tr())),
          ],
        ),
        backgroundColor: AppColors.emerald,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.pop({
      'registeredEmail': email,
      'registeredRole': _selectedRole,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'auth.registerTitle'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header description
              Text(
                'auth.registerSubtitle'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Role Selector (Yuk beruvchi / Zavod vs Haydovchi)
              Text(
                'auth.selectRole'.tr(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  // Shipper Option
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.shipper,
                      title: 'Yuk beruvchi / Zavod',
                      subtitle: 'Korxona va yuk egalari',
                      icon: Icons.factory_outlined,
                      isSelected: _selectedRole == UserRole.shipper,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedRole = UserRole.shipper),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Driver Option
                  Expanded(
                    child: _buildRoleCard(
                      role: UserRole.driver,
                      title: 'Haydovchi',
                      subtitle: 'Fura va yuk tashuvchilar',
                      icon: Icons.local_shipping_outlined,
                      isSelected: _selectedRole == UserRole.driver,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedRole = UserRole.driver),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section: Personal & Contact Details
              _buildSectionHeader('ASOSIY ALOQA VA SHAXSIY MA\'LUMOTLAR', isDark),
              const SizedBox(height: 12),

              AppTextField(
                label: _selectedRole == UserRole.shipper
                    ? 'Mas\'ul shaxs F.I.Sh.'
                    : 'Haydovchining F.I.Sh.',
                hint: _selectedRole == UserRole.shipper ? 'Anvar Toshmatov' : 'Rustam Karimov',
                controller: _fullNameController,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'auth.phoneNumber'.tr(),
                hint: '+998 90 123 45 67',
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'auth.emailOrUsername'.tr(),
                hint: _selectedRole == UserRole.shipper ? 'zavod@korxona.uz' : 'haydovchi@logiflow.uz',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
              ),
              const SizedBox(height: 24),

              // Section: Role-Specific Details
              if (_selectedRole == UserRole.shipper) ...[
                _buildSectionHeader('ZAVOD VA KORXONA MA\'LUMOTLARI', isDark),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'auth.companyName'.tr(),
                  hint: 'Masalan: "Agro Export Holding" MChJ / Artel Zavodi',
                  controller: _companyNameController,
                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'auth.companyStir'.tr(),
                  hint: '305 128 492',
                  keyboardType: TextInputType.number,
                  controller: _companyStirController,
                  prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                ),
                const SizedBox(height: 14),

                Text(
                  'auth.activityType'.tr(),
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
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedIndustry,
                      dropdownColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      items: _industryOptions.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedIndustry = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Ombor / Zavod joylashgan manzili',
                  hint: 'Toshkent vil., Yuqorichirchiq tumani, Sanoat zonasi',
                  controller: _factoryAddressController,
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                ),
              ] else ...[
                _buildSectionHeader('FURA VA HAYDOVCHILIK MA\'LUMOTLARI', isDark),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'auth.driverLicense'.tr(),
                  hint: 'AA 9812450 (Toifa: C, E)',
                  controller: _driverLicenseController,
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppTextField(
                        label: 'auth.vehicleModel'.tr(),
                        hint: 'Volvo FH16 / MAN TGX',
                        controller: _vehicleModelController,
                        prefixIcon: const Icon(Icons.directions_bus_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: AppTextField(
                        label: 'auth.vehiclePlate'.tr(),
                        hint: '01 A 777 AA',
                        controller: _vehiclePlateController,
                        prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Text(
                  'auth.bodyType'.tr(),
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
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedBodyType,
                      dropdownColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      items: _bodyTypeOptions.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBodyType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'auth.capacityTons'.tr(),
                  hint: '22',
                  keyboardType: TextInputType.number,
                  controller: _capacityTonsController,
                  prefixIcon: const Icon(Icons.scale_outlined, size: 20),
                ),
              ],
              const SizedBox(height: 24),

              // Section: Password & Security
              _buildSectionHeader('XAVFSIZLIK VA PAROL', isDark),
              const SizedBox(height: 12),

              AppTextField(
                label: 'auth.password'.tr(),
                hint: '••••••••',
                isPassword: true,
                controller: _passwordController,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'auth.confirmPassword'.tr(),
                hint: '••••••••',
                isPassword: true,
                controller: _confirmPasswordController,
                prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
              ),
              const SizedBox(height: 28),

              // Submit Registration Button
              AppButton(
                text: 'auth.register'.tr(),
                isLoading: _isSubmitting,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: 16),

              // Already have an account? Sign In link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'auth.alreadyHaveAccount'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'auth.signIn'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
