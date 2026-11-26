import 'package:equatable/equatable.dart';

class CreatedLoadModel extends Equatable {
  final String id;
  final String shipperId;
  final String status;
  final String cargoName;
  final String cargoType;
  final double weightTons;
  final double? volumeM3;
  final String truckType;
  final double fromLat;
  final double fromLng;
  final String fromAddress;
  final String fromRegion;
  final String fromCity;
  final double toLat;
  final double toLng;
  final String toAddress;
  final String toRegion;
  final String toCity;
  final double distanceKm;
  final DateTime pickupDate;
  final double? priceUzs;
  final bool priceNegotiable;
  final String? description;
  final List<String> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreatedLoadModel({
    required this.id,
    required this.shipperId,
    required this.status,
    required this.cargoName,
    required this.cargoType,
    required this.weightTons,
    this.volumeM3,
    required this.truckType,
    required this.fromLat,
    required this.fromLng,
    required this.fromAddress,
    required this.fromRegion,
    required this.fromCity,
    required this.toLat,
    required this.toLng,
    required this.toAddress,
    required this.toRegion,
    required this.toCity,
    required this.distanceKm,
    required this.pickupDate,
    this.priceUzs,
    required this.priceNegotiable,
    this.description,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory CreatedLoadModel.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now();

    final updated = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : created;

    return CreatedLoadModel(
      id: json['id'] as String? ?? '',
      shipperId: json['shipper_id'] as String? ?? json['shipperId'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      cargoName: json['cargo_name'] as String? ?? json['cargoName'] as String? ?? '',
      cargoType: json['cargo_type'] as String? ?? json['cargoType'] as String? ?? 'oziq_ovqat',
      weightTons: (json['weight_tons'] as num? ?? json['weightTons'] as num? ?? 0.0).toDouble(),
      volumeM3: (json['volume_m3'] as num? ?? json['volumeM3'] as num?)?.toDouble(),
      truckType: json['truck_type'] as String? ?? json['truckType'] as String? ?? 'TENT',
      fromLat: (json['from_lat'] as num? ?? json['fromLat'] as num? ?? 0.0).toDouble(),
      fromLng: (json['from_lng'] as num? ?? json['fromLng'] as num? ?? 0.0).toDouble(),
      fromAddress: json['from_address'] as String? ?? json['fromAddress'] as String? ?? '',
      fromRegion: json['from_region'] as String? ?? json['fromRegion'] as String? ?? '',
      fromCity: json['from_city'] as String? ?? json['fromCity'] as String? ?? '',
      toLat: (json['to_lat'] as num? ?? json['toLat'] as num? ?? 0.0).toDouble(),
      toLng: (json['to_lng'] as num? ?? json['toLng'] as num? ?? 0.0).toDouble(),
      toAddress: json['to_address'] as String? ?? json['toAddress'] as String? ?? '',
      toRegion: json['to_region'] as String? ?? json['toRegion'] as String? ?? '',
      toCity: json['to_city'] as String? ?? json['toCity'] as String? ?? '',
      distanceKm: (json['distance_km'] as num? ?? json['distanceKm'] as num? ?? 0.0).toDouble(),
      pickupDate: json['pickup_date'] != null
          ? DateTime.parse(json['pickup_date'] as String)
          : json['pickupDate'] != null
              ? DateTime.parse(json['pickupDate'] as String)
              : DateTime.now(),
      priceUzs: (json['price_uzs'] as num? ?? json['priceUzs'] as num?)?.toDouble(),
      priceNegotiable: json['price_negotiable'] as bool? ?? json['priceNegotiable'] as bool? ?? false,
      description: json['description'] as String?,
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: created,
      updatedAt: updated,
    );
  }

  @override
  List<Object?> get props => [id, shipperId, status, cargoName, pickupDate, updatedAt];
}

class LoadSummaryModel extends Equatable {
  final String id;
  final String cargoName;
  final String cargoType;
  final double weightTons;
  final String truckType;
  final String fromCity;
  final String fromRegion;
  final String toCity;
  final String toRegion;
  final double? priceUzs;
  final bool priceNegotiable;
  final String status;
  final DateTime pickupDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoadSummaryModel({
    required this.id,
    required this.cargoName,
    required this.cargoType,
    required this.weightTons,
    required this.truckType,
    required this.fromCity,
    required this.fromRegion,
    required this.toCity,
    required this.toRegion,
    this.priceUzs,
    required this.priceNegotiable,
    required this.status,
    required this.pickupDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoadSummaryModel.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now();

    final updated = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : created;

    return LoadSummaryModel(
      id: json['id'] as String? ?? '',
      cargoName: json['cargoName'] as String? ?? json['cargo_name'] as String? ?? '',
      cargoType: json['cargoType'] as String? ?? json['cargo_type'] as String? ?? 'oziq_ovqat',
      weightTons: (json['weightTons'] as num? ?? json['weight_tons'] as num? ?? 0.0).toDouble(),
      truckType: json['truckType'] as String? ?? json['truck_type'] as String? ?? 'TENT',
      fromCity: json['fromCity'] as String? ?? json['from_city'] as String? ?? '',
      fromRegion: json['fromRegion'] as String? ?? json['from_region'] as String? ?? '',
      toCity: json['toCity'] as String? ?? json['to_city'] as String? ?? '',
      toRegion: json['toRegion'] as String? ?? json['to_region'] as String? ?? '',
      priceUzs: (json['priceUzs'] as num? ?? json['price_uzs'] as num?)?.toDouble(),
      priceNegotiable: json['priceNegotiable'] as bool? ?? json['price_negotiable'] as bool? ?? false,
      status: json['status'] as String? ?? 'ACTIVE',
      pickupDate: json['pickupDate'] != null
          ? DateTime.parse(json['pickupDate'] as String)
          : json['pickup_date'] != null
              ? DateTime.parse(json['pickup_date'] as String)
              : DateTime.now(),
      createdAt: created,
      updatedAt: updated,
    );
  }

  @override
  List<Object?> get props => [id, cargoName, status, pickupDate, updatedAt];
}

class PaginatedLoadSummary extends Equatable {
  final List<LoadSummaryModel> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  const PaginatedLoadSummary({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory PaginatedLoadSummary.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?)
            ?.map((e) => LoadSummaryModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PaginatedLoadSummary(
      items: list,
      total: (json['total'] as num? ?? list.length).toInt(),
      page: (json['page'] as num? ?? 1).toInt(),
      limit: (json['limit'] as num? ?? 20).toInt(),
      pages: (json['pages'] as num? ?? 1).toInt(),
    );
  }

  @override
  List<Object?> get props => [items, total, page, limit, pages];
}

class LoadEventModel extends Equatable {
  final String id;
  final String loadId;
  final String eventType;
  final String? actorId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const LoadEventModel({
    required this.id,
    required this.loadId,
    required this.eventType,
    this.actorId,
    required this.payload,
    required this.createdAt,
  });

  factory LoadEventModel.fromJson(Map<String, dynamic> json) {
    return LoadEventModel(
      id: json['id'] as String? ?? '',
      loadId: json['loadId'] as String? ?? json['load_id'] as String? ?? '',
      eventType: json['eventType'] as String? ?? json['event_type'] as String? ?? '',
      actorId: json['actorId'] as String? ?? json['actor_id'] as String?,
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, loadId, eventType, createdAt];
}
