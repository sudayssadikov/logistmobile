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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
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
      context.read<AuthBloc>().add(AuthSendOtpSubmitted(phone: _phoneOtpController.text));
    } else {
      context.read<AuthBloc>().add(
            AuthLoginSubmitted(
              emailOrPhone: _loginController.text,
              password: _passwordController.text,
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
        if (state.status == AuthStatus.authenticated) {
          context.go('/dashboard');
        } else if (state.status == AuthStatus.otpSent) {
          context.push('/otp-verify', extra: {
            'phone': _phoneOtpController.text,
            'role': _selectedRole,
          });
        } else if (state.status == AuthStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.rose,
              behavior: SnackBarBehavior.floating,
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 22),
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

                  // Role Selector Grid
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
                  // Role Selector (2 Primary Roles: Yuk beruvchi vs Haydovchi/Tashuvchi)
                  Column(
                    children: [UserRole.shipper, UserRole.driver].map((role) {
                      final isSelected = _selectedRole == role;
                      final isShipper = role == UserRole.shipper;
                      final roleIcon = isShipper ? Icons.inventory_2_outlined : Icons.local_shipping_outlined;
                      final roleTitle = isShipper ? 'roles.shipperTitle'.tr() : 'roles.driverTitle'.tr();
                      final roleSub = isShipper ? 'roles.shipperSubtitle'.tr() : 'roles.driverSubtitle'.tr();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => setState(() => _selectedRole = role),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    roleIcon,
                                    size: 22,
                                    color: isSelected ? Colors.white : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        roleTitle,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        roleSub,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

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
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'auth.password'.tr(),
                      hint: '••••••••',
                      isPassword: true,
                      controller: _passwordController,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    ),
                  ] else ...[
                    AppTextField(
                      label: 'auth.phoneNumber'.tr(),
                      hint: '+998 90 123 45 67',
                      keyboardType: TextInputType.phone,
                      controller: _phoneOtpController,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
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
