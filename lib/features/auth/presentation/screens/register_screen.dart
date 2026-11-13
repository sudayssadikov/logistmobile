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
  UserRole _selectedRole = UserRole.shipper;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || phone.isEmpty || password.isEmpty) {
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

    setState(() => _isSubmitting = true);

    final generatedId = _selectedRole == UserRole.shipper
        ? 'USR-SHIPPER-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
        : 'USR-DRIVER-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final newUser = UserModel(
      id: generatedId,
      fullName: fullName,
      email: email.isNotEmpty ? email : 'user_${DateTime.now().millisecondsSinceEpoch}@logiflow.uz',
      phone: phone,
      role: _selectedRole,
      companyName: _selectedRole == UserRole.shipper ? '$fullName korxonasi' : null,
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

    await Future.delayed(const Duration(milliseconds: 500));

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
      'registeredEmail': email.isNotEmpty ? email : phone,
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
              Text(
                'auth.registerSubtitle'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // 2 ta SEGMENT: "Yuk beruvchi" | "Haydovchi"
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.2,
                  ),
                  boxShadow: NeuShadows.elevation(isDark: isDark, blur: 6, offset: 2),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    // Segment 1: Yuk beruvchi
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = UserRole.shipper),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.shipper
                                ? (isDark ? Colors.white : AppColors.primary)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedRole == UserRole.shipper
                                ? [
                                    BoxShadow(
                                      color: (_selectedRole == UserRole.shipper && isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business_center_rounded,
                                size: 18,
                                color: _selectedRole == UserRole.shipper
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'roles.shipper'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedRole == UserRole.shipper ? FontWeight.w700 : FontWeight.w600,
                                  color: _selectedRole == UserRole.shipper
                                      ? (isDark ? Colors.black : Colors.white)
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Segment 2: Haydovchi
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = UserRole.driver),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == UserRole.driver
                                ? (isDark ? Colors.white : AppColors.primary)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedRole == UserRole.driver
                                ? [
                                    BoxShadow(
                                      color: (_selectedRole == UserRole.driver && isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_shipping_rounded,
                                size: 18,
                                color: _selectedRole == UserRole.driver
                                    ? (isDark ? Colors.black : Colors.white)
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'roles.driver'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedRole == UserRole.driver ? FontWeight.w700 : FontWeight.w600,
                                  color: _selectedRole == UserRole.driver
                                      ? (isDark ? Colors.black : Colors.white)
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Faqat umumiy asosiy maydonlar:
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
              const SizedBox(height: 14),

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

              // Ro'yxatdan o'tish tugmasi
              AppButton(
                text: 'auth.register'.tr(),
                isLoading: _isSubmitting,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: 16),

              // Tizimga kirish havolasi
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
}
