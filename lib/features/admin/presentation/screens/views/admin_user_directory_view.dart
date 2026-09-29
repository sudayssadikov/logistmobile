import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../auth/domain/models/user_model.dart';
import '../../bloc/user_moderation_bloc.dart';
import '../../../domain/models/admin_user_item_model.dart';

class AdminUserDirectoryView extends StatefulWidget {
  const AdminUserDirectoryView({super.key});

  @override
  State<AdminUserDirectoryView> createState() => _AdminUserDirectoryViewState();
}

class _AdminUserDirectoryViewState extends State<AdminUserDirectoryView> {
  final TextEditingController _searchController = TextEditingController();
  UserRole? _selectedRole;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<UserModerationBloc>().add(
          FetchModerationDataEvent(searchQuery: query, roleFilter: _selectedRole),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat('#,###');

    return BlocConsumer<UserModerationBloc, UserModerationState>(
      listener: (context, state) {
        if (state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
      },
      builder: (context, state) {
        final users = state.users;

        return Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Column(
                children: [
                  AppTextField(
                    controller: _searchController,
                    hint: 'Ism, telefon raqam yoki kompaniya bo\'yicha qidiruv...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    onChanged: _onSearch,
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRoleChip('Barchasi', null),
                        const SizedBox(width: 8),
                        _buildRoleChip('Yuk egalari', UserRole.shipper),
                        const SizedBox(width: 8),
                        _buildRoleChip('Tashuvchilar', UserRole.carrier),
                        const SizedBox(width: 8),
                        _buildRoleChip('Haydovchilar', UserRole.driver),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Users List
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Text(
                        'Foydalanuvchi topilmadi',
                        style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserCard(user, isDark, currencyFormatter);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleChip(String label, UserRole? role) {
    final isSelected = _selectedRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedRole = role);
        _onSearch(_searchController.text);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : null,
      ),
    );
  }

  Widget _buildUserCard(AdminUserItemModel user, bool isDark, NumberFormat currencyFormatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isSuspended ? AppColors.rose.withValues(alpha: 0.5) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0] : 'U',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${user.companyName ?? "Mustaqil"} • ${user.role.name.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(
                label: user.isSuspended ? 'BLOKLANGAN' : (user.isVerified ? 'VERIFIKATSIYA' : 'KUTILMOQDA'),
                color: user.isSuspended ? AppColors.rose : (user.isVerified ? AppColors.emerald : AppColors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${user.emailOrPhone} • ${user.completedTrips} reys • ${user.rating} ★',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              Text(
                '${currencyFormatter.format(user.walletBalance)} UZS',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: user.isSuspended ? 'Faollashtirish' : 'Bloklash',
                  variant: user.isSuspended ? AppButtonVariant.primary : AppButtonVariant.outline,
                  height: 36,
                  prefixIcon: user.isSuspended ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                  onPressed: () {
                    context.read<UserModerationBloc>().add(
                          ToggleUserSuspensionEvent(
                            userId: user.id,
                            isSuspended: !user.isSuspended,
                            reason: user.isSuspended ? 'Admin tomonidan faollashtirildi' : 'Xavfsizlik sababli bloklandi',
                          ),
                        );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
