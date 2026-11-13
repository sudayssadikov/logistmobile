import 'dart:async';
import '../../../../core/network/api_result.dart';
import '../models/tracking_data_model.dart';

abstract class ITrackingRepository {
  Future<ApiResult<TrackingDataModel>> getTrackingSession(String shipmentId);
  Future<ApiResult<bool>> sendRealGpsLocation({
    required String shipmentId,
    required double latitude,
    required double longitude,
    double? speedKmh,
    double? headingDegrees,
  });
  Stream<TelemetryUpdate> startTelemetrySimulation(String shipmentId);
  void stopTelemetrySimulation();
}
