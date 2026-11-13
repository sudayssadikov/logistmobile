import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../core/di/injection.dart';
import '../../core/localization/app_localizations.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/shipper/presentation/screens/shipper_home_screen.dart';
import '../../features/shipper/presentation/screens/shipper_create_load_screen.dart';
import '../../features/shipper/presentation/screens/shipper_my_loads_screen.dart';
import '../../features/driver/presentation/screens/driver_loads_feed_screen.dart';
import '../../features/driver/presentation/screens/driver_my_trips_screen.dart';
import '../../features/chat/presentation/screens/chat_conversation_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/calls/presentation/screens/active_call_screen.dart';
import '../../features/calls/presentation/screens/call_history_screen.dart';
import '../../features/disputes/presentation/screens/create_dispute_screen.dart';
import '../../features/disputes/presentation/screens/dispute_detail_screen.dart';
import '../../features/disputes/presentation/screens/dispute_list_screen.dart';
import '../../features/documents/presentation/screens/document_vault_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/pod/presentation/screens/pod_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/app_preferences_screen.dart';
import '../../features/settings/presentation/screens/security_center_screen.dart';
import '../../features/shipments/presentation/bloc/shipment_bloc.dart';
import '../../features/shipments/presentation/screens/create_load_wizard_screen.dart';
import '../../features/shipments/presentation/screens/shipment_detail_screen.dart';
import '../../features/sos/presentation/screens/sos_roadside_screen.dart';
import '../../features/tracking/presentation/screens/tracking_map_screen.dart';
import '../../features/tracking/presentation/screens/turn_by_turn_navigation_screen.dart';
import '../../features/wallet_escrow/presentation/screens/wallet_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shipperShellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _driverShellNavigatorKey = GlobalKey<NavigatorState>();

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(getIt<AuthBloc>().stream),
    redirect: (context, state) {
      final authState = getIt<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated && authState.user != null;
      final location = state.matchedLocation;

      final isPublicRoute = location == '/' ||
          location == '/onboarding' ||
          location == '/login' ||
          location == '/register' ||
          location == '/otp-verify';

      // 1. Agar login qilinmagan bo'lsa
      if (!isAuthenticated) {
        if (isPublicRoute) return null;
        return '/login';
      }

      final role = authState.user!.role;

      // 2. Agar login qilingan bo'lsa va auth yo'llarida bo'lsa -> o'z bosh sahifasiga
      if (isPublicRoute) {
        return role == UserRole.shipper ? '/shipper/home' : '/driver/loads';
      }

      // 3. Eski yo'llar (/dashboard, /shipments)
      if (location == '/dashboard' || location == '/shipments') {
        return role == UserRole.shipper ? '/shipper/home' : '/driver/loads';
      }

      // 4. Qat'iy rol guard (foydalanuvchi boshqa rolning sahifasiga qo'lda o'ta olmaydi)
      if (role == UserRole.shipper && location.startsWith('/driver')) {
        return '/shipper/home';
      }
      if (role == UserRole.driver && location.startsWith('/shipper')) {
        return '/driver/loads';
      }

      return null;
    },
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

      // =======================================================================
      // 1) SHIPPER SHELL ROUTE (5 ta tab: Bosh sahifa | Yuk qo'shish | Yuklarim | Chat | Profil)
      // =======================================================================
      ShellRoute(
        navigatorKey: _shipperShellNavigatorKey,
        builder: (context, state, child) {
          return _ShipperShellWidget(child: child);
        },
        routes: [
          GoRoute(
            path: '/shipper/home',
            builder: (context, state) => const ShipperHomeScreen(),
          ),
          GoRoute(
            path: '/shipper/create-load',
            builder: (context, state) => const ShipperCreateLoadScreen(),
          ),
          GoRoute(
            path: '/shipper/my-loads',
            builder: (context, state) => const ShipperMyLoadsScreen(),
          ),
          GoRoute(
            path: '/shipper/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/shipper/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // =======================================================================
      // 2) DRIVER SHELL ROUTE (4 ta tab: Yuklar | Reyslarim | Chat | Profil)
      // =======================================================================
      ShellRoute(
        navigatorKey: _driverShellNavigatorKey,
        builder: (context, state, child) {
          return _DriverShellWidget(child: child);
        },
        routes: [
          GoRoute(
            path: '/driver/loads',
            builder: (context, state) => const DriverLoadsFeedScreen(),
          ),
          GoRoute(
            path: '/driver/my-trips',
            builder: (context, state) => const DriverMyTripsScreen(),
          ),
          GoRoute(
            path: '/driver/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/driver/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Deep Detail & Shared Modal Routes
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

      // Profile, SOS & Navigation
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
        path: '/wallet',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WalletScreen(),
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

      // Shared Sub-features
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

// =============================================================================
// SHIPPER SHELL WIDGET (5 ta tab: Bosh sahifa | Yuk qo'shish | Yuklarim | Chat | Profil)
// =============================================================================
class _ShipperShellWidget extends StatelessWidget {
  final Widget child;

  const _ShipperShellWidget({required this.child});

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/shipper/home')) return 0;
    if (location.startsWith('/shipper/create-load')) return 1;
    if (location.startsWith('/shipper/my-loads')) return 2;
    if (location.startsWith('/shipper/chat')) return 3;
    if (location.startsWith('/shipper/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/shipper/home');
        break;
      case 1:
        context.go('/shipper/create-load');
        break;
      case 2:
        context.go('/shipper/my-loads');
        break;
      case 3:
        context.go('/shipper/chat');
        break;
      case 4:
        context.go('/shipper/profile');
        break;
    }
  }

  List<NeuNavItem> _buildNavItems() {
    return [
      NeuNavItem(icon: Icons.home_rounded, label: 'nav.home'.tr()),
      NeuNavItem(icon: Icons.add_circle_outline_rounded, label: 'nav.addLoad'.tr()),
      NeuNavItem(icon: Icons.inventory_2_rounded, label: 'nav.myLoads'.tr()),
      NeuNavItem(icon: Icons.chat_bubble_rounded, label: 'nav.chat'.tr()),
      NeuNavItem(icon: Icons.person_rounded, label: 'nav.profile'.tr()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _buildNavItems();
    final selectedIndex = _calculateIndex(context);
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
                          Icons.business_center_rounded,
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

// =============================================================================
// DRIVER SHELL WIDGET (4 ta tab: Yuklar | Reyslarim | Chat | Profil)
// =============================================================================
class _DriverShellWidget extends StatelessWidget {
  final Widget child;

  const _DriverShellWidget({required this.child});

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/driver/loads')) return 0;
    if (location.startsWith('/driver/my-trips')) return 1;
    if (location.startsWith('/driver/chat')) return 2;
    if (location.startsWith('/driver/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/driver/loads');
        break;
      case 1:
        context.go('/driver/my-trips');
        break;
      case 2:
        context.go('/driver/chat');
        break;
      case 3:
        context.go('/driver/profile');
        break;
    }
  }

  List<NeuNavItem> _buildNavItems() {
    return [
      NeuNavItem(icon: Icons.local_shipping_rounded, label: 'nav.loadsFeed'.tr()),
      NeuNavItem(icon: Icons.route_rounded, label: 'nav.myTrips'.tr()),
      NeuNavItem(icon: Icons.chat_bubble_rounded, label: 'nav.chat'.tr()),
      NeuNavItem(icon: Icons.person_rounded, label: 'nav.profile'.tr()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _buildNavItems();
    final selectedIndex = _calculateIndex(context);
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
