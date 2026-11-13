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
  });

  factory CreatedLoadModel.fromJson(Map<String, dynamic> json) => CreatedLoadModel(
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
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : json['createdAt'] != null
                ? DateTime.parse(json['createdAt'] as String)
                : DateTime.now(),
      );

  @override
  List<Object?> get props => [id, shipperId, status, cargoName, pickupDate];
}

