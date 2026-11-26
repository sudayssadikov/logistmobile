import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logiflow_mobile/core/network/api_result.dart';
import 'package:logiflow_mobile/core/widgets/status_badge.dart';
import 'package:logiflow_mobile/features/shipper/data/services/load_draft_service.dart';
import 'package:logiflow_mobile/features/shipper/domain/models/load_model.dart';
import 'package:logiflow_mobile/features/shipper/domain/repositories/loads_repository.dart';
import 'package:logiflow_mobile/features/shipper/presentation/screens/shipper_my_loads_screen.dart';
import 'package:logiflow_mobile/features/shipper/presentation/screens/shipper_load_detail_screen.dart';
import 'package:logiflow_mobile/features/shipper/presentation/screens/shipper_edit_load_screen.dart';

class FakeLoadsRepository implements ILoadsRepository {
  List<LoadSummaryModel> activeItems = [];
  List<LoadSummaryModel> inProgressItems = [];
  List<LoadSummaryModel> historyItems = [];
  CreatedLoadModel? detailLoad;
  List<LoadEventModel> events = [];

  String? lastCancelledId;
  String? lastCancelledReason;
  String? lastDuplicatedId;
  Map<String, dynamic>? lastUpdateData;
  int updateStatusCode = 200;

  @override
  Future<ApiResult<CreatedLoadModel>> createLoad({required CreateLoadDraft draft}) async {
    return const ApiFailure<CreatedLoadModel>(message: 'Not implemented');
  }

  @override
  Future<ApiResult<CreatedLoadModel>> getLoadById(String id) async {
    if (detailLoad != null) {
      return ApiSuccess(detailLoad!);
    }
    return const ApiFailure<CreatedLoadModel>(message: 'Not found');
  }

  @override
  Future<ApiResult<PaginatedLoadSummary>> getMyLoads({
    required String statusGroup,
    int page = 1,
    int limit = 20,
  }) async {
    List<LoadSummaryModel> list = [];
    if (statusGroup == 'active') list = activeItems;
    if (statusGroup == 'in_progress') list = inProgressItems;
    if (statusGroup == 'history') list = historyItems;
    return ApiSuccess(
      PaginatedLoadSummary(
        items: list,
        total: list.length,
        page: page,
        limit: limit,
        pages: 1,
      ),
    );
  }

  @override
  Future<ApiResult<CreatedLoadModel>> updateLoad(String id, Map<String, dynamic> data) async {
    lastUpdateData = data;
    if (updateStatusCode == 409) {
      return const ApiFailure<CreatedLoadModel>(
        message: 'Yuk boshqa joyda o\'zgartirilgan',
        statusCode: 409,
      );
    }
    return ApiSuccess(detailLoad!);
  }

  @override
  Future<ApiResult<void>> cancelLoad(String id, {String? reason}) async {
    lastCancelledId = id;
    lastCancelledReason = reason;
    return const ApiSuccess(null);
  }

  @override
  Future<ApiResult<CreatedLoadModel>> duplicateLoad(String id) async {
    lastDuplicatedId = id;
    return ApiSuccess(detailLoad!);
  }

  @override
  Future<ApiResult<List<LoadEventModel>>> getLoadEvents(String id) async {
    return ApiSuccess(events);
  }
}

void main() {
  late FakeLoadsRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeLoadsRepository();
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Shipper MyLoads Screen Widget Tests', () {
    testWidgets('Renders 3 tabs: Faol, Jarayonda, Tarix and loads empty state', (tester) async {
      await tester.pumpWidget(buildTestWidget(ShipperMyLoadsScreen(repository: fakeRepo)));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'Faol'), findsOneWidget);
      expect(find.text('Jarayonda'), findsOneWidget);
      expect(find.text('Tarix'), findsOneWidget);

      // On active tab, empty state has "Yuk qo'shish" button
      expect(find.text('Sizda hali faol yuklar yo\'q'), findsOneWidget);
      expect(find.text('Yuk qo\'shish'), findsOneWidget);

      // Tap Jarayonda tab
      await tester.tap(find.text('Jarayonda'));
      await tester.pumpAndSettle();

      expect(find.text('Ayni paytda jarayonda bo\'lgan yuklar yo\'q'), findsOneWidget);
      expect(find.text('Yuk qo\'shish'), findsNothing);

      // Tap Tarix tab
      await tester.tap(find.text('Tarix'));
      await tester.pumpAndSettle();

      expect(find.text('Yuklar tarixi bo\'sh'), findsOneWidget);
      expect(find.text('Yuk qo\'shish'), findsNothing);
    });

    testWidgets('Renders active load card with price, status badge, and popup actions', (tester) async {
      fakeRepo.activeItems = [
        LoadSummaryModel(
          id: 'LOAD-101',
          cargoName: 'Olma yuklangan',
          cargoType: 'oziq_ovqat',
          weightTons: 15.0,
          truckType: 'REFRIGERATOR',
          fromCity: 'Namangan',
          fromRegion: 'Namangan viloyati',
          toCity: 'Toshkent',
          toRegion: 'Toshkent shahri',
          priceUzs: 4000000.0,
          priceNegotiable: false,
          status: 'ACTIVE',
          pickupDate: DateTime.now().add(const Duration(days: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(ShipperMyLoadsScreen(repository: fakeRepo)));
      await tester.pumpAndSettle();

      expect(find.text('Olma yuklangan'), findsOneWidget);
      expect(find.text('Namangan (Namangan viloyati)'), findsOneWidget);
      expect(find.text('Toshkent (Toshkent shahri)'), findsOneWidget);
      expect(find.text('15.0 t • REFRIGERATOR'), findsOneWidget);
      expect(find.text('4 000 000 UZS'), findsOneWidget);
      expect(find.byType(StatusBadge), findsOneWidget);

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Tahrirlash'), findsOneWidget);
      expect(find.text('Nusxa ko\'chirish'), findsOneWidget);
      expect(find.text('Bekor qilish'), findsOneWidget);
    });

    testWidgets('Cancellation dialog confirms and triggers cancelLoad', (tester) async {
      fakeRepo.activeItems = [
        LoadSummaryModel(
          id: 'LOAD-CANCEL-TEST',
          cargoName: 'Bekor qilinadigan yuk',
          cargoType: 'boshqa',
          weightTons: 5.0,
          truckType: 'TENT',
          fromCity: 'Farg\'ona',
          fromRegion: 'Farg\'ona viloyati',
          toCity: 'Andijon',
          toRegion: 'Andijon viloyati',
          priceNegotiable: true,
          status: 'ACTIVE',
          pickupDate: DateTime.now().add(const Duration(days: 1)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildTestWidget(ShipperMyLoadsScreen(repository: fakeRepo)));
      await tester.pumpAndSettle();

      // Open popup
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Click Bekor qilish
      await tester.tap(find.text('Bekor qilish'));
      await tester.pumpAndSettle();

      expect(find.text('Yukni bekor qilish'), findsOneWidget);
      // Confirm dialog button
      final cancelButtons = find.widgetWithText(ElevatedButton, 'Bekor qilish');
      expect(cancelButtons, findsOneWidget);
      await tester.tap(cancelButtons);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastCancelledId, 'LOAD-CANCEL-TEST');
    });
  });

  group('Shipper Load Detail Screen Widget Tests', () {
    testWidgets('Renders full detail: route, specs, timeline, and driver placeholder', (tester) async {
      fakeRepo.detailLoad = CreatedLoadModel(
        id: 'LOAD-DETAIL-01',
        shipperId: 'USR-01',
        status: 'ACTIVE',
        cargoName: 'Super G\'ishtlar',
        cargoType: 'qurilish_materiallari',
        weightTons: 20.0,
        volumeM3: 50.0,
        truckType: 'FLATBED',
        fromLat: 41.2995,
        fromLng: 69.2401,
        fromAddress: 'Zangiota tumani 14',
        fromRegion: 'Toshkent viloyati',
        fromCity: 'Zangiota',
        toLat: 39.6542,
        toLng: 66.9597,
        toAddress: 'Samarqand markaz',
        toRegion: 'Samarqand viloyati',
        toCity: 'Samarqand',
        distanceKm: 275.0,
        pickupDate: DateTime(2026, 12, 1, 10, 0),
        priceUzs: 6500000.0,
        priceNegotiable: false,
        description: 'Ehtiyotkorlik bilan yuklansin',
        createdAt: DateTime(2026, 11, 20),
        updatedAt: DateTime(2026, 11, 20),
      );

      fakeRepo.events = [
        LoadEventModel(
          id: 'EV-1',
          loadId: 'LOAD-DETAIL-01',
          eventType: 'CREATED',
          payload: const {},
          createdAt: DateTime(2026, 11, 20, 9, 30),
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          ShipperLoadDetailScreen(loadId: 'LOAD-DETAIL-01', repository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Super G\'ishtlar'), findsOneWidget);
      expect(find.text('Marshrut (~ taxminan 275 km)'), findsOneWidget);
      expect(find.text('20.0 tonna'), findsOneWidget);
      expect(find.text('50.0 m³'), findsOneWidget);
      expect(find.text('FLATBED'), findsOneWidget);
      expect(find.text('Haydovchi hali tayinlanmagan'), findsOneWidget);
      expect(find.text('Yuk e\'lon qilindi'), findsOneWidget);

      // Active status buttons: Tahrirlash and Bekor qilish
      expect(find.text('Tahrirlash'), findsOneWidget);
      expect(find.text('Bekor qilish'), findsOneWidget);
    });
  });

  group('Shipper Edit Load Screen Widget Tests', () {
    testWidgets('ASSIGNED status restricts fields and displays notice banner', (tester) async {
      fakeRepo.detailLoad = CreatedLoadModel(
        id: 'LOAD-ASSIGNED-01',
        shipperId: 'USR-01',
        status: 'ASSIGNED',
        cargoName: 'Muzlatilgan go\'sht',
        cargoType: 'oziq_ovqat',
        weightTons: 12.0,
        truckType: 'REFRIGERATOR',
        fromLat: 41.2995,
        fromLng: 69.2401,
        fromAddress: 'Omborxona 1',
        fromRegion: 'Toshkent shahri',
        fromCity: 'Toshkent',
        toLat: 40.8154,
        toLng: 72.2837,
        toAddress: 'Bozor 2',
        toRegion: 'Andijon viloyati',
        toCity: 'Andijon',
        distanceKm: 340.0,
        pickupDate: DateTime(2026, 12, 5, 8, 30),
        priceUzs: 5000000.0,
        priceNegotiable: false,
        description: 'Harorat -18 daraja bo\'lsin',
        createdAt: DateTime(2026, 11, 20),
        updatedAt: DateTime(2026, 11, 20),
      );

      await tester.pumpWidget(
        buildTestWidget(
          ShipperEditLoadScreen(loadId: 'LOAD-ASSIGNED-01', repository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Check warning notice
      expect(find.textContaining('Haydovchi tayinlangan: marshrut, vazn va narxni o\'zgartirib bo\'lmaydi'), findsOneWidget);

      // In ASSIGNED, price field is not shown
      expect(find.text('Narx (UZS)'), findsNothing);

      // Modify description to enable Saqlash
      await tester.enterText(find.widgetWithText(TextField, 'Harorat -18 daraja bo\'lsin'), 'Harorat -20 daraja bo\'lsin');
      await tester.pumpAndSettle();

      // Tap Saqlash
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastUpdateData, isNotNull);
      expect(fakeRepo.lastUpdateData!['description'], 'Harorat -20 daraja bo\'lsin');
      // Did NOT send cargoName / weight / price
      expect(fakeRepo.lastUpdateData!.containsKey('cargoName'), isFalse);
    });

    testWidgets('Shows 409 Conflict dialog when optimistic lock fails', (tester) async {
      fakeRepo.detailLoad = CreatedLoadModel(
        id: 'LOAD-ACTIVE-01',
        shipperId: 'USR-01',
        status: 'ACTIVE',
        cargoName: 'Pamidor',
        cargoType: 'oziq_ovqat',
        weightTons: 8.0,
        truckType: 'TENT',
        fromLat: 41.2995,
        fromLng: 69.2401,
        fromAddress: 'Manzil A',
        fromRegion: 'Toshkent',
        fromCity: 'Toshkent',
        toLat: 40.8154,
        toLng: 72.2837,
        toAddress: 'Manzil B',
        toRegion: 'Andijon',
        toCity: 'Andijon',
        distanceKm: 340.0,
        pickupDate: DateTime(2026, 12, 5, 8, 30),
        priceUzs: 3000000.0,
        priceNegotiable: false,
        createdAt: DateTime(2026, 11, 20),
        updatedAt: DateTime(2026, 11, 20),
      );
      fakeRepo.updateStatusCode = 409;

      await tester.pumpWidget(
        buildTestWidget(
          ShipperEditLoadScreen(loadId: 'LOAD-ACTIVE-01', repository: fakeRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Change cargo name
      await tester.enterText(find.widgetWithText(TextField, 'Pamidor'), 'Bodring');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Saqlash'));
      await tester.pumpAndSettle();

      // Conflict dialog should appear
      expect(find.text('Tahrirlashda to\'qnashuv'), findsOneWidget);
      expect(find.text('Yangilash'), findsOneWidget);
    });
  });
}
