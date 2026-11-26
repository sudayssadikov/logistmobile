import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logiflow_mobile/core/network/api_result.dart';
import 'package:logiflow_mobile/core/widgets/empty_state_view.dart';
import 'package:logiflow_mobile/features/driver/domain/models/driver_feed_item_model.dart';
import 'package:logiflow_mobile/features/driver/domain/models/driver_vehicle_model.dart';
import 'package:logiflow_mobile/features/driver/domain/repositories/driver_repository.dart';
import 'package:logiflow_mobile/features/driver/presentation/bloc/driver_bloc.dart';
import 'package:logiflow_mobile/features/driver/presentation/screens/driver_loads_feed_screen.dart';
import 'package:logiflow_mobile/features/driver/presentation/widgets/driver_feed_filter_sheet.dart';

class FakeDriverRepository implements IDriverRepository {
  List<DriverVehicleModel> vehicles = [];
  List<DriverFeedItemModel> feedItems = [];
  bool hasVehicleInFeed = false;
  String? errorMessage;
  int delayMs = 0;

  @override
  Future<ApiResult<List<DriverVehicleModel>>> getVehicles() async {
    if (errorMessage != null) {
      return ApiFailure(message: errorMessage!);
    }
    return ApiSuccess(vehicles);
  }

  @override
  Future<ApiResult<DriverVehicleModel>> addVehicle({
    required String truckType,
    required double capacityTons,
    String? plateNumber,
    bool isPrimary = true,
  }) async {
    final v = DriverVehicleModel(
      id: 'V-1',
      driverId: 'D-1',
      truckType: truckType,
      capacityTons: capacityTons,
      plateNumber: plateNumber,
      isPrimary: isPrimary,
      createdAt: DateTime.now(),
    );
    vehicles.add(v);
    return ApiSuccess(v);
  }

  @override
  Future<ApiResult<void>> updateLocation({required double lat, required double lng}) async {
    return const ApiSuccess(null);
  }

  @override
  Future<ApiResult<DriverFeedResponseModel>> getFeed({
    required DriverFeedFilter filter,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    if (errorMessage != null) {
      return ApiFailure(message: errorMessage!);
    }
    return ApiSuccess(
      DriverFeedResponseModel(
        items: feedItems,
        total: feedItems.length,
        hasVehicle: hasVehicleInFeed,
      ),
    );
  }
}

void main() {
  late FakeDriverRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeDriverRepository();
  });

  Widget createTestWidget(Widget child, {DriverBloc? bloc}) {
    return MaterialApp(
      home: bloc != null
          ? BlocProvider<DriverBloc>.value(value: bloc, child: child)
          : BlocProvider<DriverBloc>(
              create: (_) => DriverBloc(fakeRepo),
              child: child,
            ),
    );
  }

  group('DriverFeedFilterSheet Widget Tests', () {
    testWidgets('No fields are required; applies with empty price and defaults', (tester) async {
      DriverFeedFilter? appliedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DriverFeedFilterSheet(
              initialFilter: const DriverFeedFilter(),
              onApply: (f) {
                appliedFilter = f;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yuklarni filtrlash'), findsOneWidget);

      // Tap "Filtrni qo'llash" without typing any price
      final applyButton = find.widgetWithText(ElevatedButton, 'Filtrni qo\'llash');
      expect(applyButton, findsOneWidget);
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.minPrice, isNull);
      expect(appliedFilter!.maxPrice, isNull);
      expect(appliedFilter!.fromRegion, isNull);
    });

    testWidgets('Selecting truck type and min price updates applied filter', (tester) async {
      DriverFeedFilter? appliedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DriverFeedFilterSheet(
              initialFilter: const DriverFeedFilter(),
              onApply: (f) {
                appliedFilter = f;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select TENT
      await tester.tap(find.widgetWithText(FilterChip, 'TENT'));
      await tester.pumpAndSettle();

      // Enter min price
      final minPriceField = find.widgetWithText(TextField, '0');
      expect(minPriceField, findsOneWidget);
      await tester.enterText(minPriceField, '2500000');
      await tester.pumpAndSettle();

      // Tap apply
      await tester.tap(find.widgetWithText(ElevatedButton, 'Filtrni qo\'llash'));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter!.truckTypes, contains('TENT'));
      expect(appliedFilter!.minPrice, 2500000.0);
    });
  });

  group('DriverLoadsFeedScreen Widget Tests', () {
    testWidgets('Renders empty state when no loads in feed', (tester) async {
      fakeRepo.feedItems = [];
      fakeRepo.hasVehicleInFeed = true;

      await tester.pumpWidget(createTestWidget(const DriverLoadsFeedScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('Mos yuklar topilmadi'), findsOneWidget);
    });

    testWidgets('Renders error state with retry button when feed fails', (tester) async {
      fakeRepo.errorMessage = 'Internet aloqasi mavjud emas';

      await tester.pumpWidget(createTestWidget(const DriverLoadsFeedScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Internet aloqasi mavjud emas'), findsOneWidget);
      expect(find.text('Qayta urinish'), findsOneWidget);
    });

    testWidgets('Shows banner and disables Mos sort when hasVehicle is false', (tester) async {
      fakeRepo.feedItems = [];
      fakeRepo.hasVehicleInFeed = false;

      await tester.pumpWidget(createTestWidget(const DriverLoadsFeedScreen()));
      await tester.pumpAndSettle();

      // Check banner
      expect(find.text('Mashinangizni qo\'shing'), findsOneWidget);
      expect(find.text('Mashina qo\'shilgach, aqlli mos yuklar tartiblanadi.'), findsOneWidget);

      // Tap Mos sort chip
      await tester.tap(find.text('Mos'));
      await tester.pumpAndSettle();

      // SnackBar prompt should appear
      expect(find.text('Mos yuklarni ko\'rish uchun mashinangizni qo\'shing'), findsOneWidget);
    });

    testWidgets('Hides banner when hasVehicle is true', (tester) async {
      fakeRepo.feedItems = [];
      fakeRepo.hasVehicleInFeed = true;

      await tester.pumpWidget(createTestWidget(const DriverLoadsFeedScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mashinangizni qo\'shing'), findsNothing);
    });
  });
}
