import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow_mobile/core/network/api_exceptions.dart';
import 'package:logiflow_mobile/core/sync/sync_action_model.dart';
import 'package:logiflow_mobile/features/tracking/data/services/osrm_routing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Network & Offline Sync Architecture Tests', () {
    test('ApiException correctly maps 401 Unauthorized', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/shipments'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/shipments'),
          statusCode: 401,
          data: {'detail': 'Invalid authentication credentials'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioError);
      expect(apiException.statusCode, 401);
      expect(apiException.errorCode, 'UNAUTHORIZED');
    });

    test('ApiException correctly maps connection timeouts', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/v1/shipments'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiException = ApiException.fromDioException(dioError);
      expect(apiException.errorCode, 'TIMEOUT');
    });

    test('SyncActionModel serialization and raw JSON roundtrip', () {
      final action = SyncActionModel(
        id: 'SYNC-ACT-001',
        type: SyncActionType.submitPod,
        endpoint: '/api/v1/pod/submit',
        method: 'POST',
        payload: const {
          'shipment_id': 'SHP-1001',
          'receiver_name': 'Shoxrux Abdullayev',
          'latitude': 39.6542,
          'longitude': 66.9597,
        },
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      final rawJson = action.toRawJson();
      final decoded = SyncActionModel.fromRawJson(rawJson);

      expect(decoded.id, 'SYNC-ACT-001');
      expect(decoded.type, SyncActionType.submitPod);
      expect(decoded.endpoint, '/api/v1/pod/submit');
      expect(decoded.payload['receiver_name'], 'Shoxrux Abdullayev');
      expect(decoded.retryCount, 0);
    });

    test('OsrmRoutingService converts points accurately', () {
      final routingService = OsrmRoutingService();
      final points = routingService.convertPoints([]);
      expect(points.isEmpty, isTrue);
    });
  });
}
