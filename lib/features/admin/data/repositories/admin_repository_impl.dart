import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../../domain/models/admin_dispute_model.dart';
import '../../domain/models/admin_kpi_model.dart';
import '../../domain/models/admin_user_item_model.dart';
import '../../domain/models/audit_log_entry_model.dart';
import '../../domain/models/escrow_ledger_item_model.dart';
import '../../domain/models/verification_request_model.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements IAdminRepository {
  final DioClient? _dioClient;

  AdminRepositoryImpl({DioClient? dioClient}) : _dioClient = dioClient;

  DioClient? get dioClient => _dioClient;

  // In-Memory state caches
  final List<VerificationRequestModel> _verifications = [];

  final List<AdminUserItemModel> _users = [
    AdminUserItemModel(
      id: 'USR-ADMIN-001',
      fullName: 'Sudays Admin',
      emailOrPhone: 'sudaysadmin',
      role: UserRole.admin,
      companyName: 'LogiFlow Supreme Control Tower',
      isVerified: true,
      isSuspended: false,
      rating: 5.0,
      completedTrips: 1500,
      walletBalance: 150000000.0,
      registeredAt: DateTime.now(),
      lastActiveDevice: 'Admin Web Terminal',
    ),
  ];

  final List<EscrowLedgerItemModel> _escrowItems = [];

  final List<AdminDisputeCaseModel> _disputes = [];

  final List<AuditLogEntryModel> _auditLogs = [];

  @override
  Future<ApiResult<AdminKpiModel>> getKpis() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const ApiSuccess(
      AdminKpiModel(
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
      ),
    );
  }

  @override
  Future<ApiResult<List<VerificationRequestModel>>> getPendingVerifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ApiSuccess(List.unmodifiable(_verifications));
  }

  @override
  Future<ApiResult<bool>> moderateVerification(String id, VerificationStatus status, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _verifications.indexWhere((v) => v.id == id);
    if (index != -1) {
      _verifications[index] = _verifications[index].copyWith(
        status: status,
        rejectionReason: reason,
      );
      _auditLogs.insert(
        0,
        AuditLogEntryModel(
          id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
          actorId: 'USR-ADMIN-001',
          actorName: 'Sudays Admin',
          targetId: id,
          actionType: 'KYC_MODERATION',
          description: 'Hujjat holati ${status.label} ga o\'zgartirildi${reason != null ? ': $reason' : ''}.',
          ipAddress: '127.0.0.1',
          deviceFingerprint: 'Admin Web Workspace',
          timestamp: DateTime.now(),
        ),
      );
    }
    return const ApiSuccess(true);
  }

  @override
  Future<ApiResult<List<AdminUserItemModel>>> getUsers({String? search, UserRole? roleFilter}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var list = _users;
    if (roleFilter != null) {
      list = list.where((u) => u.role == roleFilter).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((u) => u.fullName.toLowerCase().contains(q) || u.emailOrPhone.toLowerCase().contains(q)).toList();
    }
    return ApiSuccess(List.unmodifiable(list));
  }

  @override
  Future<ApiResult<bool>> toggleUserStatus(String userId, {required bool isSuspended, String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(isSuspended: isSuspended);
      _auditLogs.insert(
        0,
        AuditLogEntryModel(
          id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
          actorId: 'USR-ADMIN-001',
          actorName: 'Sudays Admin',
          targetId: userId,
          actionType: isSuspended ? 'USER_SUSPEND' : 'USER_UNSUSPEND',
          description: '${_users[index].fullName} hisobi ${isSuspended ? "bloklandi" : "faollashtirildi"}${reason != null ? ': $reason' : ''}.',
          ipAddress: '127.0.0.1',
          deviceFingerprint: 'Admin Web Workspace',
          timestamp: DateTime.now(),
        ),
      );
    }
    return const ApiSuccess(true);
  }

  @override
  Future<ApiResult<List<EscrowLedgerItemModel>>> getEscrowLedger() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ApiSuccess(List.unmodifiable(_escrowItems));
  }

  @override
  Future<ApiResult<bool>> executeEscrowIntervention(String escrowId, EscrowInterventionAction action) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _escrowItems.indexWhere((e) => e.id == escrowId);
    if (index != -1) {
      String newStatus = 'HOLD';
      if (action == EscrowInterventionAction.freezeHold) newStatus = 'FROZEN';
      if (action == EscrowInterventionAction.forceRelease) newStatus = 'RELEASED';
      if (action == EscrowInterventionAction.refundShipper) newStatus = 'REFUNDED';

      _escrowItems[index] = _escrowItems[index].copyWith(status: newStatus);
      _auditLogs.insert(
        0,
        AuditLogEntryModel(
          id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
          actorId: 'USR-ADMIN-001',
          actorName: 'Sudays Admin',
          targetId: escrowId,
          actionType: 'ESCROW_INTERVENTION',
          description: 'Eskrou operatsiyasi: ${action.label}. Yangi holat: $newStatus.',
          ipAddress: '127.0.0.1',
          deviceFingerprint: 'Admin Web Workspace',
          timestamp: DateTime.now(),
        ),
      );
    }
    return const ApiSuccess(true);
  }

  @override
  Future<ApiResult<List<AdminDisputeCaseModel>>> getDisputes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ApiSuccess(List.unmodifiable(_disputes));
  }

  @override
  Future<ApiResult<bool>> resolveDispute(String disputeId, DisputeVerdict verdict, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _disputes.indexWhere((d) => d.id == disputeId);
    if (index != -1) {
      _disputes[index] = _disputes[index].copyWith(
        status: 'RESOLVED',
        finalVerdict: verdict,
        resolutionNotes: reason,
      );
      _auditLogs.insert(
        0,
        AuditLogEntryModel(
          id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
          actorId: 'USR-ADMIN-001',
          actorName: 'Sudays Admin',
          targetId: disputeId,
          actionType: 'DISPUTE_VERDICT',
          description: 'Nizo arbitraj qarori qabul qilindi: ${verdict.label}${reason != null ? ' ($reason)' : ''}.',
          ipAddress: '127.0.0.1',
          deviceFingerprint: 'Admin Web Workspace',
          timestamp: DateTime.now(),
        ),
      );
    }
    return const ApiSuccess(true);
  }

  @override
  Future<ApiResult<List<AuditLogEntryModel>>> getAuditLogs({String? category}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ApiSuccess(List.unmodifiable(_auditLogs));
  }
}
