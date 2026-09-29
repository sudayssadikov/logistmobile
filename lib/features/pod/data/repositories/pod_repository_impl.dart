import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/pod_submission_model.dart';
import '../../domain/repositories/pod_repository.dart';

class PodRepositoryImpl implements IPodRepository {
  final DioClient? _dioClient;
  final Map<String, PodSubmissionModel> _podCache = {};

  PodRepositoryImpl([this._dioClient]);

  @override
  Future<ApiResult<PodSubmissionModel>> submitPod(PodSubmissionModel submission) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.post(
          '/shipments/${submission.shipmentId}/pod',
          data: {
            'receiver_name': submission.receiverName,
            'receiver_phone': submission.receiverPhone,
            'notes': submission.notes,
            'signed_at': submission.signedAt.toIso8601String(),
            'latitude': submission.latitude,
            'longitude': submission.longitude,
            'is_approved': submission.isApproved,
          },
        );
        if (response.statusCode == 200) {
          // Success
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    _podCache[submission.shipmentId] = submission;
    return ApiSuccess(submission);
  }

  @override
  Future<ApiResult<PodSubmissionModel?>> getPodDetails(String shipmentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ApiSuccess(_podCache[shipmentId]);
  }
}
