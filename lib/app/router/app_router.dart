import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/neu_design_system.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/chat/presentation/screens/chat_conversation_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/calls/presentation/screens/active_call_screen.dart';
import '../../features/calls/presentation/screens/call_history_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/disputes/presentation/screens/create_dispute_screen.dart';
import '../../features/disputes/presentation/screens/dispute_detail_screen.dart';
import '../../features/disputes/presentation/screens/dispute_list_screen.dart';
import '../../features/documents/presentation/screens/document_vault_screen.dart';
import '../../features/fleet/presentation/screens/fleet_management_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/pod/presentation/screens/pod_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/app_preferences_screen.dart';
import '../../features/settings/presentation/screens/security_center_screen.dart';
import '../../features/shipments/presentation/bloc/shipment_bloc.dart';
import '../../features/shipments/presentation/screens/create_load_wizard_screen.dart';
import '../../features/shipments/presentation/screens/shipment_detail_screen.dart';
import '../../features/shipments/presentation/screens/shipment_list_screen.dart';
import '../../features/shipments/presentation/screens/ai_load_matcher_screen.dart';
import '../../features/shipments/presentation/screens/driver_trip_history_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/sos/presentation/screens/sos_roadside_screen.dart';
import '../../features/tracking/presentation/screens/tracking_map_screen.dart';
import '../../features/tracking/presentation/screens/turn_by_turn_navigation_screen.dart';
import '../../features/wallet_escrow/presentation/screens/wallet_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Auth & Entry Routes
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp-verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpVerificationScreen(
            phone: extra['phone'] as String? ?? '+998901234567',
            role: extra['role'] as UserRole? ?? UserRole.shipper,
          );
        },
      ),

      // Main App Shell with Dynamic Bottom Navigation Bar
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/shipments',
            builder: (context, state) => const ShipmentListScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Deep Detail & Modal Routes
      GoRoute(
        path: '/create-load',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateLoadWizardScreen(),
      ),
      GoRoute(
        path: '/shipments/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'SHP-1001';
          return ShipmentDetailScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/tracking/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'SHP-1001';
          return TrackingMapScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/pod/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'SHP-1001';
          return PodScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'SHP-1001';
          return ChatConversationScreen(shipmentId: id);
        },
      ),

      // VoIP Calling Routes
      GoRoute(
        path: '/calls/active',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ActiveCallScreen(),
      ),
      GoRoute(
        path: '/calls/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CallHistoryScreen(),
      ),

      // Driver Intelligence, Navigation & Emergency Routes
      GoRoute(
        path: '/shipments/ai-match',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AILoadMatcherScreen(),
      ),
      GoRoute(
        path: '/shipments/history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DriverTripHistoryScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/sos',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SosRoadsideScreen(),
      ),
      GoRoute(
        path: '/navigation/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'SHP-1001';
          final shipmentState = context.read<ShipmentBloc>().state;
          final shp = shipmentState.shipments.firstWhere(
            (s) => s.id == id,
            orElse: () => shipmentState.shipments.first,
          );
          return TurnByTurnNavigationScreen(shipment: shp);
        },
      ),

      // Enterprise Feature Routes
      GoRoute(
        path: '/documents',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DocumentVaultScreen(),
      ),
      GoRoute(
        path: '/settings/security',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SecurityCenterScreen(),
      ),
      GoRoute(
        path: '/settings/preferences',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AppPreferencesScreen(),
      ),
      GoRoute(
        path: '/fleet',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FleetManagementScreen(),
      ),
      GoRoute(
        path: '/disputes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DisputeListScreen(),
      ),
      GoRoute(
        path: '/disputes/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CreateDisputeScreen(
            initialShipmentId: extra['shipmentId'] as String?,
            initialTrackingCode: extra['trackingCode'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/disputes/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'DSP-801';
          return DisputeDetailScreen(disputeId: id);
        },
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationCenterScreen(),
      ),
    ],
  );
}

class _ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const _ScaffoldWithNavBar({required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/shipments')) return 1;
    if (location.startsWith('/wallet')) return 2;
    if (location.startsWith('/chat')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/shipments');
        break;
      case 2:
        context.go('/wallet');
        break;
      case 3:
        context.go('/chat');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  List<NeuNavItem> _buildRoleItems(UserRole role) {
    switch (role) {
      case UserRole.shipper:
        return [
          NeuNavItem(icon: Icons.home_rounded, label: 'nav.home'.tr()),
          NeuNavItem(icon: Icons.inventory_2_rounded, label: 'nav.myLoads'.tr()),
          NeuNavItem(icon: Icons.shield_rounded, label: 'nav.escrow'.tr()),
          NeuNavItem(icon: Icons.chat_bubble_rounded, label: 'nav.messages'.tr()),
          NeuNavItem(icon: Icons.person_rounded, label: 'nav.profile'.tr()),
        ];
      case UserRole.admin:
        return [
          const NeuNavItem(icon: Icons.admin_panel_settings_rounded, label: 'Admin'),
          NeuNavItem(icon: Icons.inventory_2_rounded, label: 'nav.loads'.tr()),
          NeuNavItem(icon: Icons.account_balance_wallet_rounded, label: 'nav.escrow'.tr()),
          NeuNavItem(icon: Icons.chat_bubble_rounded, label: 'nav.messages'.tr()),
          NeuNavItem(icon: Icons.person_rounded, label: 'nav.profile'.tr()),
        ];
      case UserRole.driver:
      case UserRole.carrier:
        return [
          NeuNavItem(icon: Icons.dashboard_rounded, label: 'nav.home'.tr()),
          NeuNavItem(icon: Icons.local_shipping_rounded, label: 'nav.loadBoard'.tr()),
          NeuNavItem(icon: Icons.account_balance_wallet_rounded, label: 'nav.fleetWallet'.tr()),
          NeuNavItem(icon: Icons.chat_bubble_rounded, label: 'nav.messages'.tr()),
          NeuNavItem(icon: Icons.person_rounded, label: 'nav.profile'.tr()),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final role = user?.role ?? UserRole.shipper;
    final navItems = _buildRoleItems(role);
    final selectedIndex = _calculateSelectedIndex(context);
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 240,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.local_shipping_rounded,
                          color: isDark ? Colors.black : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'LogiFlow',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView.separated(
                      itemCount: navItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = navItems[index];
                        final isSelected = index == selectedIndex;
                        return NeuCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          borderRadius: 12,
                          isPressed: isSelected,
                          onTap: () => _onItemTapped(index, context),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isSelected
                                    ? (isDark ? Colors.white : AppColors.primary)
                                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark ? Colors.white : AppColors.primary)
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NeuBottomNav(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        items: navItems,
      ),
    );
  }
}
