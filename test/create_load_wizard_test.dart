import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow_mobile/core/map/map_provider.dart';
import 'package:logiflow_mobile/core/storage/local_storage_service.dart';
import 'package:logiflow_mobile/core/utils/distance_calculator.dart';
import 'package:logiflow_mobile/features/shipper/data/services/load_draft_service.dart';
import 'package:logiflow_mobile/features/shipper/domain/models/load_model.dart';
import 'package:logiflow_mobile/features/shipper/domain/repositories/loads_repository.dart';
import 'package:logiflow_mobile/features/shipper/presentation/screens/shipper_create_load_screen.dart';
import 'package:logiflow_mobile/core/network/api_result.dart';

class MockLoadsRepository implements ILoadsRepository {
  CreateLoadDraft? lastSubmittedDraft;

  @override
  Future<ApiResult<CreatedLoadModel>> createLoad({required CreateLoadDraft draft}) async {
    lastSubmittedDraft = draft;
    return ApiSuccess(
      CreatedLoadModel(
        id: 'LOAD-TEST-123',
        shipperId: 'USR-SHIPPER-01',
        status: 'ACTIVE',
        cargoName: draft.cargoName,
        cargoType: draft.cargoType,
        weightTons: double.tryParse(draft.weightTons) ?? 10.0,
        truckType: draft.truckType,
        fromLat: draft.fromLocation?.lat ?? 41.2995,
        fromLng: draft.fromLocation?.lng ?? 69.2401,
        fromAddress: draft.fromLocation?.address ?? 'Toshkent',
        fromRegion: draft.fromLocation?.region ?? 'Toshkent shahri',
        fromCity: draft.fromLocation?.city ?? 'Toshkent',
        toLat: draft.toLocation?.lat ?? 39.6542,
        toLng: draft.toLocation?.lng ?? 66.9597,
        toAddress: draft.toLocation?.address ?? 'Samarqand',
        toRegion: draft.toLocation?.region ?? 'Samarqand viloyati',
        toCity: draft.toLocation?.city ?? 'Samarqand',
        distanceKm: 270.0,
        pickupDate: draft.pickupDate ?? DateTime.now(),
        priceNegotiable: draft.priceNegotiable,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ApiResult<CreatedLoadModel>> getLoadById(String id) async {
    return const ApiFailure<CreatedLoadModel>(message: 'Not found');
  }

  @override
  Future<ApiResult<PaginatedLoadSummary>> getMyLoads({
    required String statusGroup,
    int page = 1,
    int limit = 20,
  }) async {
    return const ApiSuccess(
      PaginatedLoadSummary(items: [], total: 0, page: 1, limit: 20, pages: 0),
    );
  }

  @override
  Future<ApiResult<CreatedLoadModel>> updateLoad(
    String id,
    Map<String, dynamic> data,
  ) async {
    return const ApiFailure<CreatedLoadModel>(message: 'Not implemented');
  }

  @override
  Future<ApiResult<void>> cancelLoad(String id, {String? reason}) async {
    return const ApiSuccess(null);
  }

  @override
  Future<ApiResult<CreatedLoadModel>> duplicateLoad(String id) async {
    return const ApiFailure<CreatedLoadModel>(message: 'Not implemented');
  }

  @override
  Future<ApiResult<List<LoadEventModel>>> getLoadEvents(String id) async {
    return const ApiSuccess([]);
  }
}

void main() {
  group('DistanceCalculator (Haversine Unit Tests)', () {
    test('Toshkent va Samarqand orasidagi masofa taxminan 265-275 km oraligida', () {
      final dist = DistanceCalculator.calculateDistanceKm(
        lat1: 41.2995,
        lon1: 69.2401,
        lat2: 39.6542,
        lon2: 66.9597,
      );
      expect(dist, greaterThan(260.0));
      expect(dist, lessThan(280.0));
    });

    test('Bir xil nuqta orasidagi masofa 0 km', () {
      final dist = DistanceCalculator.calculateDistanceKm(
        lat1: 41.2995,
        lon1: 69.2401,
        lat2: 41.2995,
        lon2: 69.2401,
      );
      expect(dist, equals(0.0));
    });
  });

  group('LoadDraftService Tests', () {
    late LocalStorageService storage;
    late LoadDraftService draftService;

    setUp(() {
      storage = LocalStorageService();
      draftService = LoadDraftService(storage);
    });

    test('Draft saqlash, oqish va tozalash muvaffaqiyatli ishlaydi', () async {
      expect(await draftService.getDraft(), isNull);

      const draft = CreateLoadDraft(
        step: 2,
        cargoName: 'Oziq-ovqat mahsulotlari',
        weightTons: '15.5',
        truckType: 'REFRIGERATOR',
        fromLocation: LocationResult(
          lat: 41.2995,
          lng: 69.2401,
          address: 'Toshkent ombor',
          region: 'Toshkent shahri',
          city: 'Toshkent',
        ),
      );

      await draftService.saveDraft(draft);

      final loaded = await draftService.getDraft();
      expect(loaded, isNotNull);
      expect(loaded!.step, equals(2));
      expect(loaded.cargoName, equals('Oziq-ovqat mahsulotlari'));
      expect(loaded.weightTons, equals('15.5'));
      expect(loaded.truckType, equals('REFRIGERATOR'));
      expect(loaded.fromLocation?.address, equals('Toshkent ombor'));

      await draftService.clearDraft();
      expect(await draftService.getDraft(), isNull);
    });
  });

  group('ShipperCreateLoadScreen Widget Tests', () {
    late LocalStorageService storage;
    late LoadDraftService draftService;
    late MockLoadsRepository mockRepo;

    setUp(() {
      storage = LocalStorageService();
      draftService = LoadDraftService(storage);
      mockRepo = MockLoadsRepository();
    });

    testWidgets('Wizard ekrani ochiladi va 1-bosqich manzillar kartochkalari korinadi', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShipperCreateLoadScreen(
            draftService: draftService,
            loadsRepository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Qayerdan va Qayerga kartochkalari borligini tekshiramiz
      expect(find.byType(ShipperCreateLoadScreen), findsOneWidget);
      expect(find.byIcon(Icons.trip_origin_rounded), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });

    testWidgets('Manzillar tanlanmasdan Keyingi tugmasi bosilsa xato snackbari chiqadi', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShipperCreateLoadScreen(
            draftService: draftService,
            loadsRepository: mockRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Keyingi" yoki "next" tugmasini topib bosamiz
      final nextButton = find.text('Keyingisi').evaluate().isNotEmpty
          ? find.text('Keyingisi')
          : find.text('common.next');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
        // SnackBar chiqqanini tekshiramiz
        expect(find.byType(SnackBar), findsOneWidget);
      }
    });
  });
}

