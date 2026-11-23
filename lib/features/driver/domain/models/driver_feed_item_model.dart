class DriverFeedItemModel {
  final String id;
  final String cargoName;
  final String cargoType;
  final double weightTons;
  final double? volumeM3;
  final String truckType;
  final String fromAddress;
  final String fromRegion;
  final String fromCity;
  final double fromLat;
  final double fromLng;
  final String toAddress;
  final String toRegion;
  final String toCity;
  final double toLat;
  final double toLng;
  final double distanceKm;
  final DateTime pickupDate;
  final double? priceUzs;
  final bool priceNegotiable;
  final String? description;
  final List<String> photos;
  final int matchPercent;
  final List<String> matchReasons;
  final double? pickupDistanceKm;
  final bool alreadyOffered;
  final DateTime createdAt;

  const DriverFeedItemModel({
    required this.id,
    required this.cargoName,
    required this.cargoType,
    required this.weightTons,
    this.volumeM3,
    required this.truckType,
    required this.fromAddress,
    required this.fromRegion,
    required this.fromCity,
    required this.fromLat,
    required this.fromLng,
    required this.toAddress,
    required this.toRegion,
    required this.toCity,
    required this.toLat,
    required this.toLng,
    required this.distanceKm,
    required this.pickupDate,
    this.priceUzs,
    required this.priceNegotiable,
    this.description,
    this.photos = const [],
    required this.matchPercent,
    this.matchReasons = const [],
    this.pickupDistanceKm,
    this.alreadyOffered = false,
    required this.createdAt,
  });

  factory DriverFeedItemModel.fromJson(Map<String, dynamic> json) {
    return DriverFeedItemModel(
      id: json['id'] as String? ?? '',
      cargoName: json['cargo_name'] as String? ?? '',
      cargoType: json['cargo_type'] as String? ?? '',
      weightTons: (json['weight_tons'] as num?)?.toDouble() ?? 0.0,
      volumeM3: (json['volume_m3'] as num?)?.toDouble(),
      truckType: json['truck_type'] as String? ?? 'TENT',
      fromAddress: json['from_address'] as String? ?? '',
      fromRegion: json['from_region'] as String? ?? '',
      fromCity: json['from_city'] as String? ?? '',
      fromLat: (json['from_lat'] as num?)?.toDouble() ?? 0.0,
      fromLng: (json['from_lng'] as num?)?.toDouble() ?? 0.0,
      toAddress: json['to_address'] as String? ?? '',
      toRegion: json['to_region'] as String? ?? '',
      toCity: json['to_city'] as String? ?? '',
      toLat: (json['to_lat'] as num?)?.toDouble() ?? 0.0,
      toLng: (json['to_lng'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      pickupDate: json['pickup_date'] != null ? DateTime.parse(json['pickup_date']) : DateTime.now(),
      priceUzs: (json['price_uzs'] as num?)?.toDouble(),
      priceNegotiable: json['price_negotiable'] as bool? ?? false,
      description: json['description'] as String?,
      photos: (json['photos'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      matchPercent: (json['match_percent'] as num?)?.toInt() ?? 0,
      matchReasons: (json['match_reasons'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      pickupDistanceKm: (json['pickup_distance_km'] as num?)?.toDouble(),
      alreadyOffered: json['already_offered'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class DriverFeedResponseModel {
  final List<DriverFeedItemModel> items;
  final bool hasVehicle;
  final int total;

  const DriverFeedResponseModel({
    required this.items,
    required this.hasVehicle,
    required this.total,
  });

  factory DriverFeedResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return DriverFeedResponseModel(
      items: rawItems.map((e) => DriverFeedItemModel.fromJson(e as Map<String, dynamic>)).toList(),
      hasVehicle: json['has_vehicle'] as bool? ?? false,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class DriverFeedFilter {
  final String sort; // match, newest, price, distance
  final double? minPrice;
  final double? maxPrice;
  final bool includeNegotiable;
  final double? maxTons;
  final List<String> truckTypes;
  final String? fromRegion;
  final String? toRegion;

  const DriverFeedFilter({
    this.sort = 'match',
    this.minPrice,
    this.maxPrice,
    this.includeNegotiable = true,
    this.maxTons,
    this.truckTypes = const [],
    this.fromRegion,
    this.toRegion,
  });

  int get activeFilterCount {
    int count = 0;
    if (minPrice != null || maxPrice != null) count++;
    if (!includeNegotiable) count++;
    if (maxTons != null) count++;
    if (truckTypes.isNotEmpty) count += truckTypes.length;
    if (fromRegion != null && fromRegion!.isNotEmpty) count++;
    if (toRegion != null && toRegion!.isNotEmpty) count++;
    return count;
  }

  DriverFeedFilter copyWith({
    String? sort,
    double? minPrice,
    double? maxPrice,
    bool? includeNegotiable,
    double? maxTons,
    List<String>? truckTypes,
    String? fromRegion,
    String? toRegion,
  }) {
    return DriverFeedFilter(
      sort: sort ?? this.sort,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      includeNegotiable: includeNegotiable ?? this.includeNegotiable,
      maxTons: maxTons ?? this.maxTons,
      truckTypes: truckTypes ?? this.truckTypes,
      fromRegion: fromRegion ?? this.fromRegion,
      toRegion: toRegion ?? this.toRegion,
    );
  }
}

