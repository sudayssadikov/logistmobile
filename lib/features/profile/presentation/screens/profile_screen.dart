import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: ListTile(
                leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                title: Text(
                  lang.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
                subtitle: Text(lang.subTitle, style: const TextStyle(fontSize: 11)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.read<LocalizationBloc>().add(ChangeLanguageEvent(lang));
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user ??
            const UserModel(
              id: 'USR-01',
              fullName: 'Enterprise User',
              email: 'user@logiflow.uz',
              phone: '+998 90 000 00 00',
              role: UserRole.shipper,
            );

        return BlocBuilder<LocalizationBloc, LocalizationState>(
          builder: (context, locState) {
            return Scaffold(
              appBar: AppBar(
                title: Text('profile.title'.tr()),
                actions: [
                  IconButton(
                    icon: Text(locState.language.flag, style: const TextStyle(fontSize: 18)),
                    tooltip: 'profile.language'.tr(),
                    onPressed: () => _showLanguageDialog(context),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user.fullName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                        ),
                                        if (user.isVerified)
                                          StatusBadge(
                                            label: 'common.verified'.tr(),
                                            color: AppColors.emerald,
                                            icon: Icons.verified_rounded,
                                            fontSize: 10,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.companyName ?? 'Independent Operator',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${user.phone} • ${user.email}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _MetricMini(title: 'profile.rating'.tr(), value: '${user.rating} ★', color: AppColors.amber),
                              _MetricMini(title: 'profile.completed'.tr(), value: '${user.completedTrips}', color: AppColors.primary),
                              _MetricMini(
                                title: 'profile.role'.tr(),
                                value: 'roles.${user.role.name}'.tr().toUpperCase(),
                                color: AppColors.indigo,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: Text('profile.editProfile'.tr()),
                              onPressed: () => context.push('/profile/edit'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Settings Group: Enterprise Modules & Verification
                    _SectionTitle(title: 'profile.workspaceConfig'.tr()),
                    const SizedBox(height: 8),
                    _SettingTile(
                      icon: Icons.history_rounded,
                      title: 'profile.tripHistory'.tr(),
                      subtitle: 'profile.tripHistorySub'.tr(),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push('/shipments/history'),
                    ),
                    _SettingTile(
                      icon: Icons.auto_awesome_rounded,
                      title: 'profile.aiMatcher'.tr(),
                      subtitle: 'profile.aiMatcherSub'.tr(),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push('/shipments/ai-match'),
                    ),
                    _SettingTile(
                      icon: Icons.emergency_rounded,
                      title: 'profile.sosRoadside'.tr(),
                      subtitle: 'profile.sosRoadsideSub'.tr(),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push('/sos'),
                    ),
                    _SettingTile(
                      icon: Icons.verified_user_outlined,
                      title: 'profile.documentVault'.tr(),
                      subtitle: 'profile.documentVaultSub'.tr(),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push('/documents'),
                    ),
                    _SettingTile(
                      icon: Icons.shield_outlined,
                      title: 'profile.securityCenter'.tr(),
                      subtitle: 'profile.securityCenterSub'.tr(),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push('/settings/security'),
                    ),
                    _SettingTile(
                      icon: Icons.tune_rounded,
                      title: 'profile.appPreferences'.tr(),
                      subtitle: 'profile.appPreferencesSub'.tr(),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push('/settings/preferences'),
                    ),
                    _SettingTile(
                      icon: Icons.phone_in_talk_outlined,
                      title: 'calls.historyTitle'.tr(),
                      subtitle: 'calls.historySub'.tr(),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push('/calls/history'),
                    ),
                    if (user.role == UserRole.driver || user.role == UserRole.carrier)
                      _SettingTile(
                        icon: Icons.local_shipping_outlined,
                        title: 'profile.fleetManagement'.tr(),
                        subtitle: 'profile.fleetManagementSub'.tr(),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                        onTap: () => context.push('/fleet'),
                      ),
                    _SettingTile(
                      icon: Icons.gavel_rounded,
                      title: 'profile.disputesCenter'.tr(),
                      subtitle: 'profile.disputesCenterSub'.tr(),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push('/disputes'),
                    ),
                    _SettingTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'profile.notificationsHub'.tr(),
                      subtitle: 'profile.notificationsHubSub'.tr(),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => context.push('/notifications'),
                    ),
                    const SizedBox(height: 20),

                    // Settings Group: System & Language
                    _SectionTitle(title: 'profile.protocols'.tr()),
                    const SizedBox(height: 8),
                    _SettingTile(
                      icon: Icons.language_rounded,
                      title: 'profile.language'.tr(),
                      subtitle: '${locState.language.flag} ${locState.language.name} (${locState.language.subTitle})',
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () => _showLanguageDialog(context),
                    ),
                    _SettingTile(
                      icon: Icons.support_agent_outlined,
                      title: 'profile.dispatchDesk'.tr(),
                      subtitle: '+998 71 200 00 00',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // Sign Out
                    AppButton(
                      text: 'profile.signOut'.tr(),
                      variant: AppButtonVariant.outline,
                      prefixIcon: Icons.logout_rounded,
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                        context.go('/login');
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'LogiFlow v1.0.0 (Enterprise Build)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricMini extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricMini({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}
