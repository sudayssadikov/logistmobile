import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'load_status.dart';

enum BidNegotiationStatus {
  pending,
  accepted,
  declined,
  countered;

  String get labelKey {
    switch (this) {
      case BidNegotiationStatus.pending:
        return 'bidding.statusPending';
      case BidNegotiationStatus.accepted:
        return 'bidding.statusAccepted';
      case BidNegotiationStatus.declined:
        return 'bidding.statusDeclined';
      case BidNegotiationStatus.countered:
        return 'bidding.statusCountered';
    }
  }
}

class NegotiationStep extends Equatable {
  final String id;
  final String authorRole; // 'shipper' or 'carrier'
  final String authorName;
  final double proposedPrice;
  final String? comment;
  final DateTime timestamp;

  const NegotiationStep({
    required this.id,
    required this.authorRole,
    required this.authorName,
    required this.proposedPrice,
    this.comment,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_role': authorRole,
        'author_name': authorName,
        'proposed_price': proposedPrice,
        'comment': comment,
        'timestamp': timestamp.toIso8601String(),
      };

  factory NegotiationStep.fromJson(Map<String, dynamic> json) => NegotiationStep(
        id: json['id'] as String,
        authorRole: json['author_role'] as String,
        authorName: json['author_name'] as String,
        proposedPrice: (json['proposed_price'] as num).toDouble(),
        comment: json['comment'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  List<Object?> get props => [id, authorRole, authorName, proposedPrice, comment, timestamp];
}

class LocationPoint extends Equatable {
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime scheduledTime;

  const LocationPoint({
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.scheduledTime,
  });

  Map<String, dynamic> toJson() => {
        'city': city,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'scheduled_time': scheduledTime.toIso8601String(),
      };

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
        city: json['city'] as String? ?? 'Tashkent',
        address: json['address'] as String? ?? 'Chilanzar logistics center',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 41.2995,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 69.2401,
        scheduledTime: json['scheduled_time'] != null
            ? DateTime.parse(json['scheduled_time'] as String)
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [city, address, latitude, longitude, scheduledTime];
}

class BidModel extends Equatable {
  final String id;
  final String carrierId;
  final String carrierName;
  final String driverName;
  final String vehicleModel;
  final String plateNumber;
  final double bidAmount;
  final double? counterPrice;
  final BidNegotiationStatus negotiationStatus;
  final List<NegotiationStep> negotiationHistory;
  final double carrierRating;
  final DateTime createdAt;
  final bool isAccepted;

  const BidModel({
    required this.id,
    required this.carrierId,
    required this.carrierName,
    required this.driverName,
    required this.vehicleModel,
    required this.plateNumber,
    required this.bidAmount,
    this.counterPrice,
    this.negotiationStatus = BidNegotiationStatus.pending,
    this.negotiationHistory = const [],
    required this.carrierRating,
    required this.createdAt,
    this.isAccepted = false,
  });

  BidModel copyWith({
    String? id,
    String? carrierId,
    String? carrierName,
    String? driverName,
    String? vehicleModel,
    String? plateNumber,
    double? bidAmount,
    double? counterPrice,
    BidNegotiationStatus? negotiationStatus,
    List<NegotiationStep>? negotiationHistory,
    double? carrierRating,
    DateTime? createdAt,
    bool? isAccepted,
  }) {
    return BidModel(
      id: id ?? this.id,
      carrierId: carrierId ?? this.carrierId,
      carrierName: carrierName ?? this.carrierName,
      driverName: driverName ?? this.driverName,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      plateNumber: plateNumber ?? this.plateNumber,
      bidAmount: bidAmount ?? this.bidAmount,
      counterPrice: counterPrice ?? this.counterPrice,
      negotiationStatus: negotiationStatus ?? this.negotiationStatus,
      negotiationHistory: negotiationHistory ?? this.negotiationHistory,
      carrierRating: carrierRating ?? this.carrierRating,
      createdAt: createdAt ?? this.createdAt,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'carrier_id': carrierId,
        'carrier_name': carrierName,
        'driver_name': driverName,
        'vehicle_model': vehicleModel,
        'plate_number': plateNumber,
        'bid_amount': bidAmount,
        'counter_price': counterPrice,
        'negotiation_status': negotiationStatus.name,
        'negotiation_history': negotiationHistory.map((n) => n.toJson()).toList(),
        'carrier_rating': carrierRating,
        'created_at': createdAt.toIso8601String(),
        'is_accepted': isAccepted,
      };

  factory BidModel.fromJson(Map<String, dynamic> json) => BidModel(
        id: json['id'] as String? ?? 'BID-1',
        carrierId: json['carrier_id'] as String? ?? 'CARRIER-1',
        carrierName: json['carrier_name'] as String? ?? 'TransGlobal Logistics',
        driverName: json['driver_name'] as String? ?? 'Rustam Karimov',
        vehicleModel: json['vehicle_model'] as String? ?? 'Volvo FH 500',
        plateNumber: json['plate_number'] as String? ?? '01 777 AAA',
        bidAmount: (json['bid_amount'] as num?)?.toDouble() ?? 14500000.0,
        counterPrice: (json['counter_price'] as num?)?.toDouble(),
        negotiationStatus: BidNegotiationStatus.values.firstWhere(
          (e) => e.name == json['negotiation_status'],
          orElse: () => BidNegotiationStatus.pending,
        ),
        negotiationHistory: (json['negotiation_history'] as List<dynamic>?)
                ?.map((e) => NegotiationStep.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        carrierRating: (json['carrier_rating'] as num?)?.toDouble() ?? 4.9,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        isAccepted: json['is_accepted'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        id,
        carrierId,
        carrierName,
        driverName,
        vehicleModel,
        plateNumber,
        bidAmount,
        counterPrice,
        negotiationStatus,
        negotiationHistory,
        carrierRating,
        createdAt,
        isAccepted,
      ];
}

class ShipmentModel extends Equatable {
  final String id;
  final String trackingCode;
  final String shipperId;
  final String shipperName;
  final String? carrierId;
  final String? carrierName;
  final String? driverName;
  final String? driverPhone;
  final String? vehiclePlate;
  final LoadStatus status;
  final LocationPoint origin;
  final LocationPoint destination;
  final String cargoTitle;
  final String cargoType;
  final double weightTons;
  final double volumeM3;
  final double price;
  final bool isEscrowFunded;
  final double distanceKm;
  final String eta;
  final List<BidModel> bids;
  final String? podSignatureUrl;
  final List<String> cargoPhotos;
  final DateTime createdAt;

  String get formattedPrice => "${NumberFormat('#,###', 'en_US').format(price)} UZS";

  const ShipmentModel({
    required this.id,
    required this.trackingCode,
    required this.shipperId,
    required this.shipperName,
    this.carrierId,
    this.carrierName,
    this.driverName,
    this.driverPhone,
    this.vehiclePlate,
    required this.status,
    required this.origin,
    required this.destination,
    required this.cargoTitle,
    required this.cargoType,
    required this.weightTons,
    required this.volumeM3,
    required this.price,
    this.isEscrowFunded = false,
    required this.distanceKm,
    required this.eta,
    this.bids = const [],
    this.podSignatureUrl,
    this.cargoPhotos = const [],
    required this.createdAt,
  });

  ShipmentModel copyWith({
    String? id,
    String? trackingCode,
    String? shipperId,
    String? shipperName,
    String? carrierId,
    String? carrierName,
    String? driverName,
    String? driverPhone,
    String? vehiclePlate,
    LoadStatus? status,
    LocationPoint? origin,
    LocationPoint? destination,
    String? cargoTitle,
    String? cargoType,
    double? weightTons,
    double? volumeM3,
    double? price,
    bool? isEscrowFunded,
    double? distanceKm,
    String? eta,
    List<BidModel>? bids,
    String? podSignatureUrl,
    List<String>? cargoPhotos,
    DateTime? createdAt,
  }) {
    return ShipmentModel(
      id: id ?? this.id,
      trackingCode: trackingCode ?? this.trackingCode,
      shipperId: shipperId ?? this.shipperId,
      shipperName: shipperName ?? this.shipperName,
      carrierId: carrierId ?? this.carrierId,
      carrierName: carrierName ?? this.carrierName,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      cargoTitle: cargoTitle ?? this.cargoTitle,
      cargoType: cargoType ?? this.cargoType,
      weightTons: weightTons ?? this.weightTons,
      volumeM3: volumeM3 ?? this.volumeM3,
      price: price ?? this.price,
      isEscrowFunded: isEscrowFunded ?? this.isEscrowFunded,
      distanceKm: distanceKm ?? this.distanceKm,
      eta: eta ?? this.eta,
      bids: bids ?? this.bids,
      podSignatureUrl: podSignatureUrl ?? this.podSignatureUrl,
      cargoPhotos: cargoPhotos ?? this.cargoPhotos,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tracking_code': trackingCode,
        'shipper_id': shipperId,
        'shipper_name': shipperName,
        'carrier_id': carrierId,
        'carrier_name': carrierName,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'vehicle_plate': vehiclePlate,
        'status': status.name,
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'cargo_title': cargoTitle,
        'cargo_type': cargoType,
        'weight_tons': weightTons,
        'volume_m3': volumeM3,
        'price': price,
        'is_escrow_funded': isEscrowFunded,
        'distance_km': distanceKm,
        'eta': eta,
        'bids': bids.map((b) => b.toJson()).toList(),
        'pod_signature_url': podSignatureUrl,
        'cargo_photos': cargoPhotos,
        'created_at': createdAt.toIso8601String(),
      };

  factory ShipmentModel.fromJson(Map<String, dynamic> json) => ShipmentModel(
        id: json['id'] as String? ?? 'SHP-001',
        trackingCode: json['tracking_code'] as String? ?? json['trackingCode'] as String? ?? 'LF-UZ-0000',
        shipperId: json['shipper_id'] as String? ?? json['shipperId'] as String? ?? 'USR-SHIPPER',
        shipperName: json['shipper_name'] as String? ?? json['shipperName'] as String? ?? 'Shipper',
        carrierId: json['carrier_id'] as String? ?? json['carrierId'] as String?,
        carrierName: json['carrier_name'] as String? ?? json['carrierName'] as String?,
        driverName: json['driver_name'] as String? ?? json['driverName'] as String?,
        driverPhone: json['driver_phone'] as String? ?? json['driverPhone'] as String?,
        vehiclePlate: json['vehicle_plate'] as String? ?? json['vehiclePlate'] as String?,
        status: LoadStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String? ?? 'created'),
          orElse: () => LoadStatus.created,
        ),
        origin: json['origin'] != null
            ? LocationPoint.fromJson(Map<String, dynamic>.from(json['origin']))
            : LocationPoint(city: 'Toshkent', address: 'Toshkent', latitude: 41.2995, longitude: 69.2401, scheduledTime: DateTime.now()),
        destination: json['destination'] != null
            ? LocationPoint.fromJson(Map<String, dynamic>.from(json['destination']))
            : LocationPoint(city: 'Samarqand', address: 'Samarqand', latitude: 39.6270, longitude: 66.9749, scheduledTime: DateTime.now().add(const Duration(days: 1))),
        cargoTitle: json['cargo_title'] as String? ?? json['cargoTitle'] as String? ?? 'Cargo',
        cargoType: json['cargo_type'] as String? ?? json['cargoType'] as String? ?? 'General',
        weightTons: (json['weight_tons'] as num?)?.toDouble() ?? (json['weightTons'] as num?)?.toDouble() ?? 10.0,
        volumeM3: (json['volume_m3'] as num?)?.toDouble() ?? (json['volumeM3'] as num?)?.toDouble() ?? 40.0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        isEscrowFunded: json['is_escrow_funded'] as bool? ?? json['isEscrowFunded'] as bool? ?? false,
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? (json['distanceKm'] as num?)?.toDouble() ?? 300.0,
        eta: json['eta'] as String? ?? '6 hours',
        bids: json['bids'] != null
            ? (json['bids'] as List).map((b) => BidModel.fromJson(Map<String, dynamic>.from(b))).toList()
            : const [],
        podSignatureUrl: json['pod_signature_url'] as String? ?? json['podSignatureUrl'] as String?,
        cargoPhotos: json['cargo_photos'] != null
            ? List<String>.from(json['cargo_photos'])
            : const [],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [
        id,
        trackingCode,
        shipperId,
        shipperName,
        carrierId,
        carrierName,
        driverName,
        driverPhone,
        vehiclePlate,
        status,
        origin,
        destination,
        cargoTitle,
        cargoType,
        weightTons,
        volumeM3,
        price,
        isEscrowFunded,
        distanceKm,
        eta,
        bids,
        podSignatureUrl,
        cargoPhotos,
        createdAt,
      ];
}
