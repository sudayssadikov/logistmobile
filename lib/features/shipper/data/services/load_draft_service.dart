import 'dart:convert';
import '../../../../core/map/map_provider.dart';
import '../../../../core/storage/local_storage_service.dart';

class CreateLoadDraft {
  final int step;
  final LocationResult? fromLocation;
  final LocationResult? toLocation;
  final String cargoName;
  final String cargoType;
  final String weightTons;
  final String volumeM3;
  final String truckType;
  final DateTime? pickupDate;
  final String priceUzs;
  final bool priceNegotiable;
  final String description;
  final List<String> photos;

  const CreateLoadDraft({
    this.step = 0,
    this.fromLocation,
    this.toLocation,
    this.cargoName = '',
    this.cargoType = 'oziq_ovqat',
    this.weightTons = '',
    this.volumeM3 = '',
    this.truckType = 'TENT',
    this.pickupDate,
    this.priceUzs = '',
    this.priceNegotiable = false,
    this.description = '',
    this.photos = const [],
  });

  Map<String, dynamic> toJson() => {
        'step': step,
        'fromLocation': fromLocation?.toJson(),
        'toLocation': toLocation?.toJson(),
        'cargoName': cargoName,
        'cargoType': cargoType,
        'weightTons': weightTons,
        'volumeM3': volumeM3,
        'truckType': truckType,
        'pickupDate': pickupDate?.toIso8601String(),
        'priceUzs': priceUzs,
        'priceNegotiable': priceNegotiable,
        'description': description,
        'photos': photos,
      };

  factory CreateLoadDraft.fromJson(Map<String, dynamic> json) => CreateLoadDraft(
        step: json['step'] as int? ?? 0,
        fromLocation: json['fromLocation'] != null
            ? LocationResult.fromJson(json['fromLocation'] as Map<String, dynamic>)
            : null,
        toLocation: json['toLocation'] != null
            ? LocationResult.fromJson(json['toLocation'] as Map<String, dynamic>)
            : null,
        cargoName: json['cargoName'] as String? ?? '',
        cargoType: json['cargoType'] as String? ?? 'oziq_ovqat',
        weightTons: json['weightTons'] as String? ?? '',
        volumeM3: json['volumeM3'] as String? ?? '',
        truckType: json['truckType'] as String? ?? 'TENT',
        pickupDate: json['pickupDate'] != null
            ? DateTime.tryParse(json['pickupDate'] as String)
            : null,
        priceUzs: json['priceUzs'] as String? ?? '',
        priceNegotiable: json['priceNegotiable'] as bool? ?? false,
        description: json['description'] as String? ?? '',
        photos: (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
}

class LoadDraftService {
  static const String _draftKey = 'create_load_draft_v1';
  final ILocalStorageService _storage;

  LoadDraftService(this._storage);

  Future<void> saveDraft(CreateLoadDraft draft) async {
    final str = jsonEncode(draft.toJson());
    await _storage.saveString(_draftKey, str);
  }

  Future<CreateLoadDraft?> getDraft() async {
    final str = await _storage.getString(_draftKey);
    if (str == null || str.isEmpty) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return CreateLoadDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDraft() async {
    await _storage.removeString(_draftKey);
  }
}

