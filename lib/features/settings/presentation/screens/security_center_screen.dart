import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettingsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('MMM dd, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.securityTitle'.tr()),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.emerald,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final sec = state.security;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'settings.securityDesc'.tr(),
                  style: const TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 20),

                // Biometrics Switch Card
                _SecurityToggleCard(
                  icon: Icons.fingerprint_rounded,
                  title: 'settings.biometricAuth'.tr(),
                  description: 'settings.biometricDesc'.tr(),
                  value: sec.isBiometricEnabled,
                  onChanged: (val) {
                    context.read<SettingsBloc>().add(ToggleBiometricsRequested(val));
                  },
                ),
                const SizedBox(height: 12),

                // 2FA Switch Card
                _SecurityToggleCard(
                  icon: Icons.phonelink_lock_rounded,
                  title: 'settings.twoFactor'.tr(),
                  description: 'settings.twoFactorDesc'.tr(),
                  value: sec.is2FAEnabled,
                  onChanged: (val) {
                    context.read<SettingsBloc>().add(Toggle2FARequested(val));
                  },
                ),
                const SizedBox(height: 28),

                // Active Sessions Header + Terminate Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'settings.activeSessions'.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                    if (sec.sessions.length > 1)
                      InkWell(
                        onTap: () {
                          context.read<SettingsBloc>().add(TerminateOtherSessionsRequested());
                        },
                        child: Text(
                          'settings.terminateOthers'.tr(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sessions List
                ...sec.sessions.map((sess) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sess.isCurrent
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: sess.isCurrent
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            sess.deviceModel.contains('iPhone') || sess.deviceModel.contains('Samsung')
                                ? Icons.phone_iphone_rounded
                                : Icons.computer_rounded,
                            size: 20,
                            color: sess.isCurrent ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sess.deviceModel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                  if (sess.isCurrent)
                                    StatusBadge(
                                      label: 'settings.currentDevice'.tr(),
                                      color: AppColors.emerald,
                                      fontSize: 10,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${sess.ipAddress} • ${sess.location}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${'settings.lastActive'.tr()}: ${timeFormat.format(sess.lastActive)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (sec.sessions.length > 1) ...[
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'settings.terminateOthers'.tr(),
                    variant: AppButtonVariant.outline,
                    prefixIcon: Icons.phonelink_erase_rounded,
                    onPressed: () {
                      context.read<SettingsBloc>().add(TerminateOtherSessionsRequested());
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SecurityToggleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SecurityToggleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
