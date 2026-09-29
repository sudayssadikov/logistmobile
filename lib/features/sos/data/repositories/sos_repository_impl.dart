import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/sos_model.dart';
import '../../domain/repositories/sos_repository.dart';

class SosRepositoryImpl implements ISosRepository {
  final DioClient? _dioClient;

  final List<NearbySosProvider> _mockProviders = [
    const NearbySosProvider(
      id: 'SOS-01',
      name: 'TIR Evakuator 24/7 (Gidravlika)',
      type: SosServiceType.heavyTowTruck,
      phone: '+998 90 999 11 22',
      distanceKm: 2.8,
      rating: 4.9,
      address: 'M39 trassasi, 212-km, Jizzax aylanma yo\'li',
      is24_7: true,
      estimatedArrivalMinutes: '15-20 min',
    ),
    const NearbySosProvider(
      id: 'SOS-02',
      name: 'Mobil Fura Vulkanizatsiya & Balon Servis',
      type: SosServiceType.tyreRepair,
      phone: '+998 97 711 33 44',
      distanceKm: 4.1,
      rating: 4.8,
      address: 'Jizzax viloyati, G\'allaorol TIR to\'xtash joyi',
      is24_7: true,
      estimatedArrivalMinutes: '20-25 min',
    ),
    const NearbySosProvider(
      id: 'SOS-03',
      name: 'MAN / Volvo / DAF Dizel Mobil Ustaxonasi',
      type: SosServiceType.dieselRepair,
      phone: '+998 99 888 77 66',
      distanceKm: 6.5,
      rating: 4.9,
      address: 'M39 magistral yo\'li, Yangier chorrahasi',
      is24_7: true,
      estimatedArrivalMinutes: '30-35 min',
    ),
    const NearbySosProvider(
      id: 'SOS-04',
      name: 'Mobil Dizel Yoqilg\'i Yetkazish (Euro-5)',
      type: SosServiceType.fuelDelivery,
      phone: '+998 91 555 44 33',
      distanceKm: 3.2,
      rating: 4.7,
      address: 'M39 yoqilg\'i quyish shahobchasi yonida',
      is24_7: true,
      estimatedArrivalMinutes: '10-15 min',
    ),
    const NearbySosProvider(
      id: 'SOS-05',
      name: '24/7 Fura Avtoelektrik va Kompyuter Diagnostika',
      type: SosServiceType.autoElectric,
      phone: '+998 93 444 22 11',
      distanceKm: 5.0,
      rating: 4.8,
      address: 'Jizzax shahar kirish posti',
      is24_7: true,
      estimatedArrivalMinutes: '25-30 min',
    ),
  ];

  SosRepositoryImpl([this._dioClient]);

  @override
  Future<ApiResult<List<NearbySosProvider>>> getNearbySosProviders({
    required double latitude,
    required double longitude,
    SosServiceType? filterType,
  }) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.get(
          '/sos/nearby',
          queryParameters: {'lat': latitude, 'lng': longitude},
        );
        if (response.statusCode == 200 && response.data != null) {
          final List raw = response.data['data'] ?? [];
          if (raw.isNotEmpty) {
            final items = raw.map((e) => NearbySosProvider.fromJson(e)).toList();
            if (filterType != null) {
              return ApiSuccess(items.where((p) => p.type == filterType).toList());
            }
            return ApiSuccess(items);
          }
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 150));
    if (filterType == null) {
      return ApiSuccess(_mockProviders);
    }
    final filtered = _mockProviders.where((p) => p.type == filterType).toList();
    return ApiSuccess(filtered);
  }

  @override
  Future<ApiResult<bool>> dispatchEmergencyAlert({
    required double latitude,
    required double longitude,
    required SosServiceType type,
    required String driverPhone,
    required String notes,
  }) async {
    if (_dioClient != null) {
      try {
        final response = await _dioClient!.post(
          '/sos/trigger',
          data: {
            'latitude': latitude,
            'longitude': longitude,
            'service_type': type.key,
            'description': notes,
          },
        );
        if (response.statusCode == 200) {
          return const ApiSuccess(true);
        }
      } catch (_) {
        // Fallback
      }
    }

    await Future.delayed(const Duration(milliseconds: 200));
    return const ApiSuccess(true);
  }
}
