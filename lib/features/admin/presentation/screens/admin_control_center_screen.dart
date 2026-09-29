import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../bloc/admin_dashboard_bloc.dart';
import '../bloc/admin_disputes_bloc.dart';
import '../bloc/admin_finance_bloc.dart';
import '../bloc/user_moderation_bloc.dart';
import 'views/admin_analytics_view.dart';
import 'views/admin_audit_logs_view.dart';
import 'views/admin_dispute_arbitration_view.dart';
import 'views/admin_escrow_governance_view.dart';
import 'views/admin_fleet_surveillance_view.dart';
import 'views/admin_kyc_moderation_view.dart';
import 'views/admin_user_directory_view.dart';

class AdminControlCenterScreen extends StatefulWidget {
  const AdminControlCenterScreen({super.key});

  @override
  State<AdminControlCenterScreen> createState() => _AdminControlCenterScreenState();
}

class _AdminControlCenterScreenState extends State<AdminControlCenterScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    AdminAnalyticsView(),
    AdminKycModerationView(),
    AdminUserDirectoryView(),
    AdminFleetSurveillanceView(),
    AdminEscrowGovernanceView(),
    AdminDisputeArbitrationView(),
    AdminAuditLogsView(),
  ];

  final List<String> _titles = const [
    'Control Tower • Analitika',
    'KYC / KYB Moderatsiya',
    'Foydalanuvchilar Katalogi',
    'Jonli Avtopark Surveillance',
    'Eskrou & Moliya Boshqaruvi',
    'Arbitraj & Nizolar Markazi',
    'Xavfsizlik & Audit Jurnali',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth >= 800;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AdminDashboardBloc>()..add(AdminFetchDashboardDataEvent()),
        ),
        BlocProvider(
          create: (_) => getIt<UserModerationBloc>()..add(const FetchModerationDataEvent()),
        ),
        BlocProvider(
          create: (_) => getIt<AdminFinanceBloc>()..add(FetchEscrowLedgerEvent()),
        ),
        BlocProvider(
          create: (_) => getIt<AdminDisputesBloc>()..add(FetchDisputesEvent()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'LOGIFLOW HQ',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _titles[_currentIndex],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
        body: isTabletOrDesktop
            ? Row(
                children: [
                  // Side Navigation Rail for Desktop/Tablet
                  NavigationRail(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) => setState(() => _currentIndex = index),
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: Text('Analitika')),
                      NavigationRailDestination(icon: Icon(Icons.verified_user_outlined), selectedIcon: Icon(Icons.verified_user_rounded), label: Text('KYC')),
                      NavigationRailDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: Text('A\'zolar')),
                      NavigationRailDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: Text('Avtopark')),
                      NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet_rounded), label: Text('Eskrou')),
                      NavigationRailDestination(icon: Icon(Icons.gavel_outlined), selectedIcon: Icon(Icons.gavel_rounded), label: Text('Arbitraj')),
                      NavigationRailDestination(icon: Icon(Icons.security_outlined), selectedIcon: Icon(Icons.security_rounded), label: Text('Audit')),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: _views[_currentIndex]),
                ],
              )
            : _views[_currentIndex],
        bottomNavigationBar: !isTabletOrDesktop
            ? BottomNavigationBar(
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                onTap: (index) => setState(() => _currentIndex = index),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard_rounded), label: 'Boshqaruv'),
                  BottomNavigationBarItem(icon: Icon(Icons.verified_user_outlined), activeIcon: Icon(Icons.verified_user_rounded), label: 'KYC'),
                  BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), activeIcon: Icon(Icons.people_rounded), label: 'A\'zolar'),
                  BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map_rounded), label: 'Radar'),
                  BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Eskrou'),
                  BottomNavigationBarItem(icon: Icon(Icons.gavel_outlined), activeIcon: Icon(Icons.gavel_rounded), label: 'Arbitraj'),
                  BottomNavigationBarItem(icon: Icon(Icons.security_outlined), activeIcon: Icon(Icons.security_rounded), label: 'Audit'),
                ],
              )
            : null,
      ),
    );
  }
}
