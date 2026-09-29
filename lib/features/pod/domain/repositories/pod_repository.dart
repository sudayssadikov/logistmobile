import '../../../../core/network/api_result.dart';
import '../models/pod_submission_model.dart';

abstract class IPodRepository {
  Future<ApiResult<PodSubmissionModel>> submitPod(PodSubmissionModel submission);
  Future<ApiResult<PodSubmissionModel?>> getPodDetails(String shipmentId);
}
