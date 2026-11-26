import '../../../../core/network/api_result.dart';
import '../../data/services/load_draft_service.dart';
import '../models/load_model.dart';

abstract class ILoadsRepository {
  Future<ApiResult<CreatedLoadModel>> createLoad({
    required CreateLoadDraft draft,
  });

  Future<ApiResult<CreatedLoadModel>> getLoadById(String id);

  Future<ApiResult<PaginatedLoadSummary>> getMyLoads({
    required String statusGroup,
    int page = 1,
    int limit = 20,
  });

  Future<ApiResult<CreatedLoadModel>> updateLoad(
    String id,
    Map<String, dynamic> data,
  );

  Future<ApiResult<void>> cancelLoad(
    String id, {
    String? reason,
  });

  Future<ApiResult<CreatedLoadModel>> duplicateLoad(String id);

  Future<ApiResult<List<LoadEventModel>>> getLoadEvents(String id);
}
