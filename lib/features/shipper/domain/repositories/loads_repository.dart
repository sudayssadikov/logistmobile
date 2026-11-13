import '../../../../core/network/api_result.dart';
import '../../data/services/load_draft_service.dart';
import '../models/load_model.dart';

abstract class ILoadsRepository {
  Future<ApiResult<CreatedLoadModel>> createLoad({
    required CreateLoadDraft draft,
  });

  Future<ApiResult<CreatedLoadModel>> getLoadById(String id);
}

