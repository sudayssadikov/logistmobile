import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection.dart';
import '../core/localization/app_localizations.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/chat/presentation/bloc/chat_bloc.dart';
import '../features/calls/presentation/bloc/call_bloc.dart';
import '../features/disputes/presentation/bloc/dispute_bloc.dart';
import '../features/documents/presentation/bloc/document_bloc.dart';
import '../features/fleet/presentation/bloc/fleet_bloc.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/pod/presentation/bloc/pod_bloc.dart';
import '../features/settings/presentation/bloc/settings_bloc.dart';
import '../features/shipments/presentation/bloc/shipment_bloc.dart';
import '../features/shipments/presentation/bloc/shipment_event.dart';
import '../features/tracking/presentation/bloc/tracking_bloc.dart';
import '../features/tracking/presentation/bloc/navigation_bloc.dart';
import '../features/sos/presentation/bloc/sos_bloc.dart';
import '../features/wallet_escrow/presentation/bloc/wallet_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class LogiFlowApp extends StatelessWidget {
  const LogiFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocalizationBloc>.value(
          value: getIt<LocalizationBloc>(),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<ShipmentBloc>(
          create: (_) => getIt<ShipmentBloc>()..add(const LoadShipmentsRequested()),
        ),
        BlocProvider<WalletBloc>(
          create: (_) => getIt<WalletBloc>(),
        ),
        BlocProvider<TrackingBloc>(
          create: (_) => getIt<TrackingBloc>(),
        ),
        BlocProvider<NavigationBloc>(
          create: (_) => getIt<NavigationBloc>(),
        ),
        BlocProvider<SosBloc>(
          create: (_) => getIt<SosBloc>(),
        ),
        BlocProvider<PodBloc>(
          create: (_) => getIt<PodBloc>(),
        ),
        BlocProvider<ChatBloc>(
          create: (_) => getIt<ChatBloc>(),
        ),
        BlocProvider<CallBloc>(
          create: (_) => getIt<CallBloc>(),
        ),
        BlocProvider<DocumentBloc>(
          create: (_) => getIt<DocumentBloc>(),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => getIt<SettingsBloc>(),
        ),
        BlocProvider<FleetBloc>(
          create: (_) => getIt<FleetBloc>(),
        ),
        BlocProvider<DisputeBloc>(
          create: (_) => getIt<DisputeBloc>(),
        ),
        BlocProvider<NotificationBloc>(
          create: (_) => getIt<NotificationBloc>(),
        ),
      ],
      child: BlocBuilder<LocalizationBloc, LocalizationState>(
        builder: (context, locState) {
          return MaterialApp.router(
            title: 'LogiFlow Mobile',
            debugShowCheckedModeBanner: false,
            locale: locState.locale,
            supportedLocales: const [
              Locale('uz'),
              Locale('ru'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark, // Default to dark Linear/Stripe high-end SaaS aesthetic
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
