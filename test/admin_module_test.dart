import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow_mobile/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:logiflow_mobile/features/admin/domain/models/admin_kpi_model.dart';
import 'package:logiflow_mobile/features/admin/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:logiflow_mobile/features/admin/presentation/bloc/user_moderation_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Enterprise Admin Module Tests', () {
    late AdminRepositoryImpl adminRepository;

    setUp(() {
      adminRepository = AdminRepositoryImpl();
    });

    test('AdminKpiModel serialization roundtrip', () {
      const kpi = AdminKpiModel(
        totalGmv: 4850000000.0,
        totalRevenueCommission: 72750000.0,
        activeLoadsInTransit: 24,
        pendingBidsCount: 18,
        completedDeliveriesCount: 1540,
        totalShippersCount: 380,
        totalCarriersCount: 290,
        activeDriversOnDuty: 142,
        totalEscrowHeld: 540000000.0,
        totalPayoutsReleased: 4310000000.0,
        systemUptimePercent: 99.99,
        openDisputesCount: 2,
        pendingKycCount: 3,
      );

      final json = kpi.toJson();
      final fromJson = AdminKpiModel.fromJson(json);

      expect(fromJson.totalGmv, 4850000000.0);
      expect(fromJson.activeLoadsInTransit, 24);
      expect(fromJson.systemUptimePercent, 99.99);
    });

    test('Admin User directory returns ApiFailure without mock data', () async {
      final usersRes = await adminRepository.getUsers();
      expect(usersRes.isFailure, isTrue);
      expect(usersRes.errorOrNull, isNotNull);
    });

    test('User Suspension toggle returns ApiFailure without mock data', () async {
      final suspendRes = await adminRepository.toggleUserStatus(
        'USR-1',
        isSuspended: true,
        reason: 'Security check',
      );
      expect(suspendRes.isFailure, isTrue);
    });

    test('AdminDashboardBloc emits error when repository returns failure', () async {
      final bloc = AdminDashboardBloc(repository: adminRepository);
      bloc.add(AdminFetchDashboardDataEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AdminDashboardState>().having((s) => s.isLoading, 'isLoading', true),
          isA<AdminDashboardState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ]),
      );
      bloc.close();
    });

    test('UserModerationBloc emits error state when repository fails', () async {
      final bloc = UserModerationBloc(repository: adminRepository);
      bloc.add(const FetchModerationDataEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<UserModerationState>().having((s) => s.isLoading, 'isLoading', true),
          isA<UserModerationState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.users.isEmpty, 'users.isEmpty', true),
        ]),
      );
      bloc.close();
    });
  });
}
