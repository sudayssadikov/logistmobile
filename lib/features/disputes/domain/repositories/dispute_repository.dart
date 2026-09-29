import '../models/dispute_model.dart';

abstract class IDisputeRepository {
  Future<List<DisputeModel>> getDisputes();
  Future<DisputeModel> getDisputeById(String id);
  Future<DisputeModel> createDispute({
    required String shipmentId,
    required String trackingCode,
    required String claimantName,
    required DisputeReason reason,
    required String description,
    required double claimAmount,
    required List<String> evidencePhotos,
  });
}
