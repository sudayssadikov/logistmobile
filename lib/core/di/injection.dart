import 'package:get_it/get_it.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/presentation/bloc/admin_dashboard_bloc.dart';
import '../../features/admin/presentation/bloc/admin_disputes_bloc.dart';
import '../../features/admin/presentation/bloc/admin_finance_bloc.dart';
import '../../features/admin/presentation/bloc/user_moderation_bloc.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/calls/data/repositories/call_repository_impl.dart';
import '../../features/calls/domain/repositories/call_repository.dart';
import '../../features/calls/presentation/bloc/call_bloc.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/disputes/data/repositories/dispute_repository_impl.dart';
import '../../features/disputes/domain/repositories/dispute_repository.dart';
import '../../features/disputes/presentation/bloc/dispute_bloc.dart';
import '../../features/documents/data/repositories/document_repository_impl.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
import '../../features/documents/presentation/bloc/document_bloc.dart';
import '../../features/fleet/data/repositories/fleet_repository_impl.dart';
import '../../features/fleet/domain/repositories/fleet_repository.dart';
import '../../features/fleet/presentation/bloc/fleet_bloc.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/pod/data/repositories/pod_repository_impl.dart';
import '../../features/pod/domain/repositories/pod_repository.dart';
import '../../features/pod/presentation/bloc/pod_bloc.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/shipments/data/repositories/shipment_repository_impl.dart';
import '../../features/shipments/domain/repositories/shipment_repository.dart';
import '../../features/shipments/presentation/bloc/shipment_bloc.dart';
import '../../features/sos/data/repositories/sos_repository_impl.dart';
import '../../features/sos/domain/repositories/sos_repository.dart';
import '../../features/sos/presentation/bloc/sos_bloc.dart';
import '../../features/tracking/data/repositories/tracking_repository_impl.dart';
import '../../features/tracking/domain/repositories/tracking_repository.dart';
import '../../features/tracking/presentation/bloc/tracking_bloc.dart';
import '../../features/tracking/presentation/bloc/navigation_bloc.dart';
import '../../features/wallet_escrow/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet_escrow/domain/repositories/wallet_repository.dart';
import '../../features/wallet_escrow/presentation/bloc/wallet_bloc.dart';
import '../localization/app_localizations.dart';
import '../network/dio_client.dart';
import '../network/websocket_service.dart';
import '../storage/local_storage_service.dart';
import '../sync/offline_sync_manager.dart';
import '../../features/tracking/data/services/osrm_routing_service.dart';
import '../../features/tracking/data/services/device_location_service.dart';
import '../../features/pod/data/services/media_picker_service.dart';
import '../../features/pod/data/services/pdf_cmr_generator_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core Storage & Network
  final storageService = LocalStorageService();
  getIt.registerSingleton<ILocalStorageService>(storageService);
  
  final dioClient = DioClient(storage: getIt<ILocalStorageService>());
  getIt.registerSingleton<DioClient>(dioClient);

  final wsService = WebSocketService(storage: getIt<ILocalStorageService>());
  getIt.registerSingleton<WebSocketService>(wsService);

  final offlineSync = OfflineSyncManager(dioClient: dioClient);
  await offlineSync.init();
  getIt.registerSingleton<OfflineSyncManager>(offlineSync);

  // Native & Free Services
  getIt.registerLazySingleton<OsrmRoutingService>(() => OsrmRoutingService());
  getIt.registerLazySingleton<DeviceLocationService>(() => DeviceLocationService());
  getIt.registerLazySingleton<MediaPickerService>(() => MediaPickerService());
  getIt.registerLazySingleton<PdfCmrGeneratorService>(() => PdfCmrGeneratorService());

  // Feature Repositories
  getIt.registerLazySingleton<IAuthRepository>(
    () => AuthRepositoryImpl(getIt<ILocalStorageService>(), getIt<DioClient>()),
  );
  getIt.registerLazySingleton<IShipmentRepository>(
    () => ShipmentRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<IWalletRepository>(
    () => WalletRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ITrackingRepository>(
    () => TrackingRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<IPodRepository>(
    () => PodRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<IChatRepository>(
    () => ChatRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ICallRepository>(
    () => CallRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ISosRepository>(
    () => SosRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<IDocumentRepository>(
    () => DocumentRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ISettingsRepository>(
    () => SettingsRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<IFleetRepository>(
    () => FleetRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<IDisputeRepository>(
    () => DisputeRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<INotificationRepository>(
    () => NotificationRepositoryImpl(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<IAdminRepository>(
    () => AdminRepositoryImpl(dioClient: getIt<DioClient>()),
  );

  // Blocs
  getIt.registerLazySingleton<LocalizationBloc>(
    () => LocalizationBloc(storage: getIt<ILocalStorageService>())..add(LoadSavedLanguageEvent()),
  );
  getIt.registerFactory<AdminDashboardBloc>(
    () => AdminDashboardBloc(repository: getIt<IAdminRepository>()),
  );
  getIt.registerFactory<UserModerationBloc>(
    () => UserModerationBloc(repository: getIt<IAdminRepository>()),
  );
  getIt.registerFactory<AdminFinanceBloc>(
    () => AdminFinanceBloc(repository: getIt<IAdminRepository>()),
  );
  getIt.registerFactory<AdminDisputesBloc>(
    () => AdminDisputesBloc(repository: getIt<IAdminRepository>()),
  );
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<IAuthRepository>()));
  getIt.registerFactory<ShipmentBloc>(() => ShipmentBloc(getIt<IShipmentRepository>()));
  getIt.registerFactory<WalletBloc>(() => WalletBloc(getIt<IWalletRepository>()));
  getIt.registerFactory<TrackingBloc>(() => TrackingBloc(getIt<ITrackingRepository>()));
  getIt.registerFactory<NavigationBloc>(() => NavigationBloc());
  getIt.registerFactory<SosBloc>(() => SosBloc(repository: getIt<ISosRepository>()));
  getIt.registerFactory<PodBloc>(() => PodBloc(getIt<IPodRepository>()));
  getIt.registerFactory<ChatBloc>(() => ChatBloc(getIt<IChatRepository>()));
  getIt.registerFactory<CallBloc>(() => CallBloc(getIt<ICallRepository>()));
  getIt.registerFactory<DocumentBloc>(() => DocumentBloc(repository: getIt<IDocumentRepository>()));
  getIt.registerFactory<SettingsBloc>(() => SettingsBloc(repository: getIt<ISettingsRepository>()));
  getIt.registerFactory<FleetBloc>(() => FleetBloc(repository: getIt<IFleetRepository>()));
  getIt.registerFactory<DisputeBloc>(() => DisputeBloc(repository: getIt<IDisputeRepository>()));
  getIt.registerFactory<NotificationBloc>(() => NotificationBloc(repository: getIt<INotificationRepository>()));
}
