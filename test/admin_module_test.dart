import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow_mobile/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:logiflow_mobile/features/admin/domain/models/admin_kpi_model.dart';
import 'package:logiflow_mobile/features/admin/presentation/bloc/admin_dashboard_bloc.dart';
import 'package:logiflow_mobile/features/admin/presentation/bloc/user_moderation_bloc.dart';
import 'package:logiflow_mobile/features/auth/domain/models/user_model.dart';

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

    test('Admin User directory returns only registered Sudays Admin', () async {
      final usersRes = await adminRepository.getUsers();
      expect(usersRes.dataOrNull?.isNotEmpty, isTrue);
      final admin = usersRes.dataOrNull!.first;
      expect(admin.fullName, 'Sudays Admin');
      expect(admin.role, UserRole.admin);
    });

    test('User Suspension toggle updates state and creates audit log', () async {
      final usersRes = await adminRepository.getUsers();
      final targetUser = usersRes.dataOrNull!.first;
      final suspendRes = await adminRepository.toggleUserStatus(
        targetUser.id,
        isSuspended: true,
        reason: 'Security check',
      );
      expect(suspendRes.isSuccess, isTrue);

      final auditLogs = await adminRepository.getAuditLogs();
      expect(auditLogs.dataOrNull?.first.actionType, 'USER_SUSPEND');
    });

    test('AdminDashboardBloc emits KPI metrics and audit logs', () async {
      final bloc = AdminDashboardBloc(repository: adminRepository);
      bloc.add(AdminFetchDashboardDataEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AdminDashboardState>().having((s) => s.isLoading, 'isLoading', true),
          isA<AdminDashboardState>().having((s) => s.kpis?.activeLoadsInTransit, 'activeLoadsInTransit', 24),
        ]),
      );
      bloc.close();
    });

    test('UserModerationBloc emits user directory', () async {
      final bloc = UserModerationBloc(repository: adminRepository);
      bloc.add(const FetchModerationDataEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<UserModerationState>().having((s) => s.isLoading, 'isLoading', true),
          isA<UserModerationState>().having((s) => s.users.isNotEmpty, 'users.isNotEmpty', true),
        ]),
      );
      bloc.close();
    });
  });
}
