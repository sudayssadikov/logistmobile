import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
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

  List<BottomNavigationBarItem> _buildRoleItems(UserRole role) {
    switch (role) {
      case UserRole.shipper:
        return [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home_rounded), label: 'nav.home'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.inventory_2_outlined), activeIcon: const Icon(Icons.inventory_2_rounded), label: 'nav.myLoads'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.shield_outlined), activeIcon: const Icon(Icons.shield_rounded), label: 'nav.escrow'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline_rounded), activeIcon: const Icon(Icons.chat_bubble_rounded), label: 'nav.messages'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), activeIcon: const Icon(Icons.person_rounded), label: 'nav.profile'.tr()),
        ];
      case UserRole.admin:
        return [
          BottomNavigationBarItem(icon: const Icon(Icons.admin_panel_settings_outlined), activeIcon: const Icon(Icons.admin_panel_settings_rounded), label: 'Admin'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.inventory_2_outlined), activeIcon: const Icon(Icons.inventory_2_rounded), label: 'nav.loads'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet_outlined), activeIcon: const Icon(Icons.account_balance_wallet_rounded), label: 'nav.escrow'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline_rounded), activeIcon: const Icon(Icons.chat_bubble_rounded), label: 'nav.messages'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), activeIcon: const Icon(Icons.person_rounded), label: 'nav.profile'.tr()),
        ];
      case UserRole.driver:
      case UserRole.carrier:
        return [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard_outlined), activeIcon: const Icon(Icons.dashboard_rounded), label: 'nav.home'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.local_shipping_outlined), activeIcon: const Icon(Icons.local_shipping_rounded), label: 'nav.loadBoard'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet_outlined), activeIcon: const Icon(Icons.account_balance_wallet_rounded), label: 'nav.fleetWallet'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.chat_bubble_outline_rounded), activeIcon: const Icon(Icons.chat_bubble_rounded), label: 'nav.messages'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline_rounded), activeIcon: const Icon(Icons.person_rounded), label: 'nav.profile'.tr()),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final role = user?.role ?? UserRole.shipper;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: _buildRoleItems(role),
      ),
    );
  }
}
