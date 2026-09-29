import '../../../../core/network/api_result.dart';
import '../../../../features/auth/domain/models/user_model.dart';
import '../models/admin_dispute_model.dart';
import '../models/admin_kpi_model.dart';
import '../models/admin_user_item_model.dart';
import '../models/audit_log_entry_model.dart';
import '../models/escrow_ledger_item_model.dart';
import '../models/verification_request_model.dart';

abstract class IAdminRepository {
  Future<ApiResult<AdminKpiModel>> getKpis();
  Future<ApiResult<List<VerificationRequestModel>>> getPendingVerifications();
  Future<ApiResult<bool>> moderateVerification(String id, VerificationStatus status, {String? reason});
  Future<ApiResult<List<AdminUserItemModel>>> getUsers({String? search, UserRole? roleFilter});
  Future<ApiResult<bool>> toggleUserStatus(String userId, {required bool isSuspended, String? reason});
  Future<ApiResult<List<EscrowLedgerItemModel>>> getEscrowLedger();
  Future<ApiResult<bool>> executeEscrowIntervention(String escrowId, EscrowInterventionAction action);
  Future<ApiResult<List<AdminDisputeCaseModel>>> getDisputes();
  Future<ApiResult<bool>> resolveDispute(String disputeId, DisputeVerdict verdict, {String? reason});
  Future<ApiResult<List<AuditLogEntryModel>>> getAuditLogs({String? category});
}
