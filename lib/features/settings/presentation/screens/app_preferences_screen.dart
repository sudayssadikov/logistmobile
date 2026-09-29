import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../../domain/models/security_model.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettingsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.prefsTitle'.tr()),
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
          final prefs = state.preferences;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unit System
                _SectionTitle(title: 'settings.unitSystem'.tr()),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SegmentTab(
                          label: 'settings.metricUnit'.tr(),
                          isSelected: prefs.unitSystem == UnitSystem.metric,
                          onTap: () {
                            context.read<SettingsBloc>().add(const UpdateUnitSystemRequested(UnitSystem.metric));
                          },
                        ),
                      ),
                      Expanded(
                        child: _SegmentTab(
                          label: 'settings.imperialUnit'.tr(),
                          isSelected: prefs.unitSystem == UnitSystem.imperial,
                          onTap: () {
                            context.read<SettingsBloc>().add(const UpdateUnitSystemRequested(UnitSystem.imperial));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Currency Preference
                _SectionTitle(title: 'settings.currency'.tr()),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SegmentTab(
                          label: 'UZS (So\'m)',
                          isSelected: prefs.currency == PreferredCurrency.uzs,
                          onTap: () {
                            context.read<SettingsBloc>().add(const UpdateCurrencyRequested(PreferredCurrency.uzs));
                          },
                        ),
                      ),
                      Expanded(
                        child: _SegmentTab(
                          label: 'USD (\$)',
                          isSelected: prefs.currency == PreferredCurrency.usd,
                          onTap: () {
                            context.read<SettingsBloc>().add(const UpdateCurrencyRequested(PreferredCurrency.usd));
                          },
                        ),
                      ),
                      Expanded(
                        child: _SegmentTab(
                          label: 'RUB (₽)',
                          isSelected: prefs.currency == PreferredCurrency.rub,
                          onTap: () {
                            context.read<SettingsBloc>().add(const UpdateCurrencyRequested(PreferredCurrency.rub));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Map Engine Selector
                _SectionTitle(title: 'settings.mapEngine'.tr()),
                const SizedBox(height: 8),
                _OptionTile(
                  title: 'Yandex Maps (CIS Highway Optimized)',
                  subtitle: 'Fastest tile rendering & local street numbers in UZ',
                  icon: Icons.map_rounded,
                  isSelected: prefs.mapEngine == MapEngine.yandexMaps,
                  onTap: () {
                    context.read<SettingsBloc>().add(const UpdateMapEngineRequested(MapEngine.yandexMaps));
                  },
                ),
                _OptionTile(
                  title: 'Google Maps (Global Transit)',
                  subtitle: 'High precision satellite & global coverage',
                  icon: Icons.public_rounded,
                  isSelected: prefs.mapEngine == MapEngine.googleMaps,
                  onTap: () {
                    context.read<SettingsBloc>().add(const UpdateMapEngineRequested(MapEngine.googleMaps));
                  },
                ),
                _OptionTile(
                  title: 'OpenStreetMap (Vector Telemetry)',
                  subtitle: 'Lightweight low-bandwidth offline maps',
                  icon: Icons.layers_outlined,
                  isSelected: prefs.mapEngine == MapEngine.openStreetMap,
                  onTap: () {
                    context.read<SettingsBloc>().add(const UpdateMapEngineRequested(MapEngine.openStreetMap));
                  },
                ),
                const SizedBox(height: 24),

                // Cache Storage Manager
                _SectionTitle(title: 'settings.cacheManager'.tr()),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'settings.cacheSize'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            '${prefs.cacheSizeMB.toStringAsFixed(1)} MB',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppButton(
                        text: 'settings.clearCache'.tr(),
                        variant: AppButtonVariant.outline,
                        prefixIcon: Icons.cleaning_services_rounded,
                        height: 42,
                        borderRadius: 10,
                        onPressed: () {
                          context.read<SettingsBloc>().add(ClearCacheRequested());
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Offline-First Sync Hub
                const _SectionTitle(title: 'OFFLINE-FIRST XAVFSIZ REJIMI (INTERNETSIZ ISHLASH)'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.cloud_done_rounded, color: AppColors.emerald, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Offline Sync Engine Faol',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Internetsiz hududlarda POD va statuslar keshlanadi',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Lokal kesh holati:', style: TextStyle(fontSize: 11)),
                            Text('100% Sinxronlangan ✅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emerald)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Server bilan qayta sinxronlash',
                        variant: AppButtonVariant.outline,
                        prefixIcon: Icons.sync_rounded,
                        height: 40,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Barcha ma\'lumotlar server bilan muvaffaqiyatli sinxronlandi!'),
                              backgroundColor: AppColors.emerald,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.darkTextMuted),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.radio_button_checked_rounded, color: AppColors.primary, size: 20)
            : const Icon(Icons.radio_button_off_rounded, color: AppColors.darkTextMuted, size: 20),
      ),
    );
  }
}
