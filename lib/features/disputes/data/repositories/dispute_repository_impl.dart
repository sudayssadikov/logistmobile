import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/dispute_model.dart';
import '../../domain/repositories/dispute_repository.dart';

class DisputeRepositoryImpl implements IDisputeRepository {
  final DioClient? _dioClient;

  final List<DisputeModel> _disputes = [
    DisputeModel(
      id: 'DSP-801',
      shipmentId: 'SHP-1002',
      trackingCode: 'LF-UZ-8492',
      claimantName: 'Agro Export Holding',
      reason: DisputeReason.damagedCargo,
      description: '3 out of 10 pallets of ceramic tiles sustained corner fractures during transit on rough road section.',
      claimAmount: 3500000.0,
      evidencePhotos: const [
        'https://docs.logiflow.uz/demo/damaged_tile_1.jpg',
        'https://docs.logiflow.uz/demo/damaged_tile_2.jpg',
      ],
      status: DisputeStatus.evidenceRequested,
      timeline: [
        DisputeTimelineItem(
          status: DisputeStatus.underReview,
          message: 'Claim opened by Shipper with damage photos attached.',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        DisputeTimelineItem(
          status: DisputeStatus.evidenceRequested,
          message: 'Mediator requested carrier waybill and seal inspection photos.',
          timestamp: DateTime.now().subtract(const Duration(hours: 18)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    DisputeModel(
      id: 'DSP-802',
      shipmentId: 'SHP-1004',
      trackingCode: 'LF-UZ-9910',
      claimantName: 'Samarkand Cotton Gin',
      reason: DisputeReason.lateDelivery,
      description: 'Carrier arrived 36 hours past agreed delivery window causing factory shutdown.',
      claimAmount: 5000000.0,
      evidencePhotos: const [],
      status: DisputeStatus.refundProcessed,
      timeline: [
        DisputeTimelineItem(
          status: DisputeStatus.underReview,
          message: 'Late delivery claim filed.',
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
        ),
        DisputeTimelineItem(
          status: DisputeStatus.resolved,
          message: 'GPS logs confirmed delay. Mediator ruled partial penalty fee.',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        DisputeTimelineItem(
          status: DisputeStatus.refundProcessed,
          message: 'Penalty refund transferred back to Shipper escrow balance.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  DisputeRepositoryImpl([this._dioClient]);

  @override
  Future<List<DisputeModel>> getDisputes() async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/disputes');
        if (response.statusCode == 200 && response.data != null) {
          final List raw = response.data['data'] ?? [];
          if (raw.isNotEmpty) {
            return raw.map((e) => DisputeModel.fromJson(e)).toList();
          }
        }
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 150));
    return List.from(_disputes);
  }

  @override
  Future<DisputeModel> getDisputeById(String id) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get('/disputes/$id');
        if (response.statusCode == 200 && response.data != null) {
          return DisputeModel.fromJson(response.data['data']);
        }
      } catch (_) {
        // Fallback
      }
    }
    await Future.delayed(const Duration(milliseconds: 100));
    return _disputes.firstWhere((d) => d.id == id, orElse: () => _disputes.first);
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
    if (_dioClient != null) {
      try {
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
        if (response.statusCode == 200 && response.data != null) {
          final created = DisputeModel.fromJson(response.data['data']);
          _disputes.insert(0, created);
          return created;
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    final newDispute = DisputeModel(
      id: 'DSP-${const Uuid().v4().substring(0, 6).toUpperCase()}',
      shipmentId: shipmentId,
      trackingCode: trackingCode,
      claimantName: claimantName,
      reason: reason,
      description: description,
      claimAmount: claimAmount,
      evidencePhotos: evidencePhotos,
      status: DisputeStatus.underReview,
      timeline: [
        DisputeTimelineItem(
          status: DisputeStatus.underReview,
          message: 'Claim filed and queued for independent mediator investigation.',
          timestamp: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
    );
    _disputes.insert(0, newDispute);
    return newDispute;
  }
}
