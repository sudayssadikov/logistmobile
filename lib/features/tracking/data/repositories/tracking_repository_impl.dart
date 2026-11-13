import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/tracking_data_model.dart';
import '../../domain/repositories/tracking_repository.dart';

class TrackingRepositoryImpl implements ITrackingRepository {
  final DioClient? _dioClient;
  StreamSubscription<Position>? _positionSubscription;
  StreamController<TelemetryUpdate>? _streamController;

  TrackingRepositoryImpl([this._dioClient]);

  @override
  Future<ApiResult<TrackingDataModel>> getTrackingSession(String shipmentId) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.get('/tracking/$shipmentId');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ApiSuccess(TrackingDataModel.fromJson(data));
      }
      return ApiFailure(message: response.data?['message'] ?? 'Kuzatuv ma\'lumotlarini yuklab bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'Serverga ulanishda xatolik: ${e.toString()}');
    }
  }

  @override
  Future<ApiResult<bool>> sendRealGpsLocation({
    required String shipmentId,
    required double latitude,
    required double longitude,
    double? speedKmh,
    double? headingDegrees,
  }) async {
    if (_dioClient == null) {
      return const ApiFailure(message: 'Server bilan aloqa mavjud emas');
    }
    try {
      final response = await _dioClient!.post(
        '/tracking/$shipmentId/location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'speedKmh': speedKmh ?? 0.0,
          'headingDegrees': headingDegrees ?? 0.0,
        },
      );
      if (response.statusCode == 200) {
        return const ApiSuccess(true);
      }
      return ApiFailure(message: response.data?['message'] ?? 'GPS koordinatalarini jo\'natib bo\'lmadi');
    } catch (e) {
      return ApiFailure(message: 'GPS xatoligi: ${e.toString()}');
    }
  }

  @override
  Stream<TelemetryUpdate> startTelemetrySimulation(String shipmentId) {
    stopTelemetrySimulation();
    _streamController = StreamController<TelemetryUpdate>.broadcast();

    // Start listening to real device GPS stream via Geolocator
    Geolocator.isLocationServiceEnabled().then((enabled) async {
      if (!enabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
        final update = TelemetryUpdate(
          latitude: position.latitude,
          longitude: position.longitude,
          speedKmh: position.speed * 3.6, // m/s to km/h
          headingDegrees: position.heading,
          altitudeMeters: position.altitude,
          batteryPercent: 100,
          distanceRemainingKm: 0.0,
          eta: 'Jonli GPS',
          nextWaypointName: 'Marshrut bo\'yicha',
          timestamp: DateTime.now(),
        );

        _streamController?.add(update);

        // Send to backend
        sendRealGpsLocation(
          shipmentId: shipmentId,
          latitude: position.latitude,
          longitude: position.longitude,
          speedKmh: position.speed * 3.6,
          headingDegrees: position.heading,
        );
      });
    }).catchError((_) {});

    return _streamController!.stream;
  }

  @override
  void stopTelemetrySimulation() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _streamController?.close();
    _streamController = null;
  }
}
