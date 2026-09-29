import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PodSubmissionModel extends Equatable {
  final String shipmentId;
  final String receiverName;
  final String receiverPhone;
  final String notes;
  final DateTime signedAt;
  final double latitude;
  final double longitude;
  final List<String> cargoPhotos;
  final List<List<Offset>> signatureStrokes;
  final bool isApproved;

  const PodSubmissionModel({
    required this.shipmentId,
    required this.receiverName,
    required this.receiverPhone,
    required this.notes,
    required this.signedAt,
    required this.latitude,
    required this.longitude,
    this.cargoPhotos = const [],
    this.signatureStrokes = const [],
    this.isApproved = true,
  });

  @override
  List<Object?> get props => [
        shipmentId,
        receiverName,
        receiverPhone,
        notes,
        signedAt,
        latitude,
        longitude,
        cargoPhotos,
        signatureStrokes,
        isApproved,
      ];
}
