import 'dart:async';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/dispute_model.dart';
import '../../domain/repositories/dispute_repository.dart';

class DisputeRepositoryImpl implements IDisputeRepository {
  final DioClient? _dioClient;

  DisputeRepositoryImpl([this._dioClient]);

  @override
  Future<List<DisputeModel>> getDisputes() async {
    if (_dioClient == null) return [];
    try {
      final response = await _dioClient!.get('/disputes');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data['data'] ?? [];
        return raw.map((e) => DisputeModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<DisputeModel> getDisputeById(String id) async {
    if (_dioClient == null) {
      throw Exception('Server bilan aloqa mavjud emas');
    }
    final response = await _dioClient!.get('/disputes/$id');
    if (response.statusCode == 200 && response.data != null) {
      return DisputeModel.fromJson(response.data['data']);
    }
    throw Exception(response.data?['message'] ?? 'Nizo topilmadi');
  }

  @override
  Future<DisputeModel> createDispute({
    required String shipmentId,
    required String trackingCode,
    required String claimantName,
    required DisputeReason reason,
    required String description,
    required double claimAmount,
    required List<String> evidencePhotos,
  }) async {
    if (_dioClient == null) {
      throw Exception('Server bilan aloqa mavjud emas');
    }
    final response = await _dioClient!.post(
      '/disputes',
      data: {
        'shipment_id': shipmentId,
        'reason': reason.name,
        'description': description,
        'claim_amount': claimAmount,
        'evidence_photos': evidencePhotos,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return DisputeModel.fromJson(response.data['data']);
    }
    throw Exception(response.data?['message'] ?? 'Nizoni yaratib bo\'lmadi');
  }
}
