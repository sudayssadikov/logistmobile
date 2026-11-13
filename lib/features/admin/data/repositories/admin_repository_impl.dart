import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/admin_dispute_model.dart';
import '../../domain/models/admin_kpi_model.dart';
import '../../domain/models/admin_user_item_model.dart';
import '../../domain/models/audit_log_entry_model.dart';
import '../../domain/models/escrow_ledger_item_model.dart';
import '../../domain/models/verification_request_model.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../../features/auth/domain/models/user_model.dart';

class AdminRepositoryImpl implements IAdminRepository {
  final DioClient? _dioClient;

  AdminRepositoryImpl({DioClient? dioClient}) : _dioClient = dioClient;

  DioClient? get dioClient => _dioClient;

  @override
  Future<ApiResult<AdminKpiModel>> getKpis() async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final response = await _dioClient!.get('/admin/stats');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ApiSuccess(AdminKpiModel.fromJson(data));
      }
      return ApiFailure(message: response.data?['message'] ?? 'KPI ma\'lumotlarini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<List<VerificationRequestModel>>> getPendingVerifications() async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final response = await _dioClient!.get('/admin/verifications');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        final items = raw.map((e) => VerificationRequestModel.fromJson(e as Map<String, dynamic>)).toList();
        return ApiSuccess(items);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Verifikatsiya ro\'yxatini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<bool>> moderateVerification(String id, VerificationStatus status, {String? reason}) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final response = await _dioClient!.patch(
        '/admin/verifications/$id',
        data: {'status': status.key, 'reason': reason},
      );
      if (response.statusCode == 200) {
        return const ApiSuccess(true);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Moderatsiya bajarilmadi');
    } catch (e) {
      return ApiFailure(message: 'Xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<List<AdminUserItemModel>>> getUsers({String? search, UserRole? roleFilter}) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (roleFilter != null) queryParams['role'] = roleFilter.key;

      final response = await _dioClient!.get('/admin/users', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        final items = raw.map((e) => AdminUserItemModel.fromJson(e as Map<String, dynamic>)).toList();
        return ApiSuccess(items);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Foydalanuvchilar ro\'yxatini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<bool>> toggleUserStatus(String userId, {required bool isSuspended, String? reason}) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final response = await _dioClient!.patch(
        '/admin/users/$userId/status',
        data: {'is_suspended': isSuspended, 'reason': reason},
      );
      if (response.statusCode == 200) {
        return const ApiSuccess(true);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Foydalanuvchi holatini o\'zgartirib bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<List<EscrowLedgerItemModel>>> getEscrowLedger() async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final response = await _dioClient!.get('/admin/escrow-ledger');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        final items = raw.map((e) => EscrowLedgerItemModel.fromJson(e as Map<String, dynamic>)).toList();
        return ApiSuccess(items);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Eskrou jurnalini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<bool>> executeEscrowIntervention(String escrowId, EscrowInterventionAction action) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final response = await _dioClient!.post(
        '/admin/escrow-ledger/$escrowId/intervene',
        data: {'action': action.key},
      );
      if (response.statusCode == 200) {
        return const ApiSuccess(true);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Eskrou aralashuvi bajarilmadi');
    } catch (e) {
      return ApiFailure(message: 'Xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<List<AdminDisputeCaseModel>>> getDisputes() async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final response = await _dioClient!.get('/disputes');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        final items = raw.map((e) {
          final m = e as Map<String, dynamic>;
          return AdminDisputeCaseModel(
            id: m['id'] ?? '',
            shipmentId: m['shipment_id'] ?? '',
            trackingCode: m['tracking_code'] ?? 'LF-UZ',
            complainantName: m['claimant_name'] ?? 'Da\'vogar',
            respondentName: m['respondent_name'] ?? 'Javobgar',
            category: DisputeCategory.fromKey(m['category'] as String?),
            disputedAmount: (m['claimed_amount'] as num?)?.toDouble() ?? 0.0,
            description: m['reason'] ?? '',
            shipperManifestUrl: m['manifest_url'] ?? '',
            podEvidencePhotos: List<String>.from(m['evidence_urls'] ?? []),
            status: m['status'] ?? 'OPEN',
            createdAt: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
          );
        }).toList();
        return ApiSuccess(items);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Nizolarni yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<bool>> resolveDispute(String disputeId, DisputeVerdict verdict, {String? reason}) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final response = await _dioClient!.post(
        '/disputes/$disputeId/resolve',
        data: {'resolution': verdict.key, 'admin_notes': reason},
      );
      if (response.statusCode == 200) {
        return const ApiSuccess(true);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Nizoni hal qilib bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<List<AuditLogEntryModel>>> getAuditLogs({String? category}) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Tarmoq mijozi mavjud emas');
    }
    try {
      final response = await _dioClient!.get('/admin/audit-logs');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        final items = raw.map((e) {
          final m = e as Map<String, dynamic>;
          return AuditLogEntryModel(
            id: m['id'] ?? '',
            actorId: m['user_id'] ?? 'SYS',
            actorName: 'Administrator',
            targetId: m['resource_id'] ?? '',
            actionType: m['action'] ?? '',
            description: '${m['resource_type']}: ${m['action']}',
            ipAddress: m['ip_address'] ?? '127.0.0.1',
            deviceFingerprint: 'Web Admin',
            timestamp: DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now(),
          );
        }).toList();
        return ApiSuccess(items);
      }
      return ApiFailure(message: response.data?['message'] ?? 'Audit jurnalini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }
}
