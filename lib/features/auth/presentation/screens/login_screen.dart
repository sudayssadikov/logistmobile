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
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneOtpController = TextEditingController();

  UserRole _selectedRole = UserRole.shipper;
  bool _useOtpMode = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _phoneOtpController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_useOtpMode) {
      final phone = _phoneOtpController.text.trim();
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iltimos, telefon raqamingizni kiriting'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      context.read<AuthBloc>().add(AuthSendOtpSubmitted(phone: phone));
    } else {
      final login = _loginController.text.trim();
      final password = _passwordController.text;
      if (login.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iltimos, elektron pochta yoki loginni kiriting'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iltimos, parolni kiriting'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      debugPrint('[_handleLogin] Submitting login: $login, role: $_selectedRole');
      context.read<AuthBloc>().add(
            AuthLoginSubmitted(
              emailOrPhone: login,
              password: password,
              role: _selectedRole,
            ),
          );
    }
  }

  void _handleBiometric() {
    context.read<AuthBloc>().add(AuthBiometricLoginSubmitted(role: _selectedRole));
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLang = context.read<LocalizationBloc>().state.language;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile.language'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            final isSelected = lang == currentLang;
            return ListTile(
              leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
              title: Text(lang.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                Navigator.of(ctx).pop();
                context.read<LocalizationBloc>().add(ChangeLanguageEvent(lang));
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated && state.user != null) {
          // Rolga qarab to'g'ri bosh sahifaga yo'naltirish
          if (state.user!.role == UserRole.shipper) {
            context.go('/shipper/home');
          } else {
            context.go('/driver/loads');
          }
        } else if (state.status == AuthStatus.otpSent) {
          context.push('/otp-verify', extra: {
            'phone': _phoneOtpController.text,
            'role': _selectedRole,
          });
        } else if (state.status == AuthStatus.error && state.errorMessage != null) {
          final errorMsg = state.errorMessage!;
          final isDriverMismatch = errorMsg.contains('haydovchi') || errorMsg.contains('водитель') || errorMsg.contains('driver');
          final isShipperMismatch = errorMsg.contains('yuk beruvchi') || errorMsg.contains('грузоотправитель') || errorMsg.contains('shipper');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.rose,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: (isDriverMismatch && _selectedRole != UserRole.driver)
                  ? SnackBarAction(
                      label: 'roles.driver'.tr(),
                      textColor: Colors.white,
                      onPressed: () => setState(() => _selectedRole = UserRole.driver),
                    )
                  : (isShipperMismatch && _selectedRole != UserRole.shipper)
                      ? SnackBarAction(
                          label: 'roles.shipper'.tr(),
                          textColor: Colors.white,
                          onPressed: () => setState(() => _selectedRole = UserRole.shipper),
                        )
                      : null,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        final locState = context.watch<LocalizationBloc>().state;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Header Logo & Language Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: NeuShadows.elevation(isDark: isDark, blur: 8, offset: 3),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2A2D31) : Colors.white.withValues(alpha: 0.8),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(Icons.local_shipping_rounded, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'common.appName'.tr(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                'common.appTagline'.tr(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _showLanguageDialog(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              Text(locState.language.flag, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                locState.language.code.toUpperCase(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'auth.welcomeBack'.tr(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'auth.selectRoleToContinue'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2 ta SEGMENT TANLASH: "Yuk beruvchi" | "Haydovchi"
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
                  const SizedBox(height: 20),

                  // Auth Method Toggle (Password vs OTP)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _useOtpMode = false),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_useOtpMode
                                    ? (isDark ? AppColors.darkSurface : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: !_useOtpMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Email / Password',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: !_useOtpMode ? FontWeight.w600 : FontWeight.w500,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _useOtpMode = true),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _useOtpMode
                                    ? (isDark ? AppColors.darkSurface : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: _useOtpMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'auth.phoneNumber'.tr(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _useOtpMode ? FontWeight.w600 : FontWeight.w500,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Inputs
                  if (!_useOtpMode) ...[
                    AppTextField(
                      label: 'auth.emailOrUsername'.tr(),
                      hint: 'user@logiflow.uz',
                      controller: _loginController,
                      prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'auth.password'.tr(),
                      hint: '••••••••',
                      isPassword: true,
                      controller: _passwordController,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                    ),
                  ] else ...[
                    AppTextField(
                      label: 'auth.phoneNumber'.tr(),
                      hint: '+998 90 123 45 67',
                      keyboardType: TextInputType.phone,
                      controller: _phoneOtpController,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Submit Button
                  AppButton(
                    text: _useOtpMode
                        ? 'auth.sendCode'.tr()
                        : '${'roles.${_selectedRole.name}'.tr().toUpperCase()} SIFATIDA KIRISH',
                    isLoading: isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 12),

                  // Biometric Fast Login
                  AppButton(
                    text: 'auth.biometricSignIn'.tr(),
                    variant: AppButtonVariant.secondary,
                    prefixIcon: Icons.fingerprint_rounded,
                    onPressed: _handleBiometric,
                  ),
                  const SizedBox(height: 24),

                  // Don't have an account? Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.noAccount'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          final result = await context.push<Map<String, dynamic>>('/register');
                          if (result != null && mounted) {
                            if (result['registeredEmail'] != null) {
                              _loginController.text = result['registeredEmail'] as String;
                            }
                            if (result['registeredRole'] != null) {
                              setState(() {
                                _selectedRole = result['registeredRole'] as UserRole;
                              });
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            'auth.register'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
