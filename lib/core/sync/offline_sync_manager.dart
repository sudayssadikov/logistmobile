import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../network/dio_client.dart';
import 'sync_action_model.dart';

enum NetworkStatus { online, offline }

class OfflineSyncManager {
  static const String queueBoxName = 'logiflow_sync_queue';
  final DioClient dioClient;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final _networkStatusController = StreamController<NetworkStatus>.broadcast();
  final _queueCountController = StreamController<int>.broadcast();

  bool _isSyncing = false;
  Box<String>? _queueBox;

  Stream<NetworkStatus> get networkStatusStream => _networkStatusController.stream;
  Stream<int> get queueCountStream => _queueCountController.stream;

  OfflineSyncManager({required this.dioClient});

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _queueBox = await Hive.openBox<String>(queueBoxName);
    } catch (_) {
      // In-memory or web fallback if IndexedDB is initializing
    }

    _updateQueueCount();

    // Check initial connectivity safely
    try {
      final initialResult = await _connectivity.checkConnectivity().timeout(const Duration(milliseconds: 300));
      _handleConnectivityChange(initialResult);
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    } catch (_) {
      _networkStatusController.add(NetworkStatus.online);
    }
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;
    _networkStatusController.add(isOnline ? NetworkStatus.online : NetworkStatus.offline);

    if (isOnline) {
      flushQueue();
    }
  }

  Future<void> enqueueAction(SyncActionModel action) async {
    if (_queueBox != null) {
      await _queueBox!.put(action.id, action.toRawJson());
    }
    _updateQueueCount();

    // If online, immediately try to sync
    final currentNet = await _connectivity.checkConnectivity();
    if (currentNet != ConnectivityResult.none) {
      flushQueue();
    }
  }

  Future<void> flushQueue() async {
    if (_isSyncing || _queueBox == null || _queueBox!.isEmpty) return;

    _isSyncing = true;

    try {
      final keys = _queueBox!.keys.toList();
      for (final key in keys) {
        final raw = _queueBox!.get(key);
        if (raw == null) continue;

        final action = SyncActionModel.fromRawJson(raw);

        try {
          // Execute HTTP request
          switch (action.method.toUpperCase()) {
            case 'POST':
              await dioClient.post(action.endpoint, data: action.payload);
              break;
            case 'PUT':
              await dioClient.put(action.endpoint, data: action.payload);
              break;
            case 'PATCH':
              await dioClient.patch(action.endpoint, data: action.payload);
              break;
          }

          // Successfully executed, remove from offline queue
          await _queueBox!.delete(key);
        } catch (e) {
          // If permanent failure (e.g. 400 Bad Request), or max retries exceeded, drop
          if (action.retryCount >= 5) {
            await _queueBox!.delete(key);
          } else {
            final updatedAction = action.copyWith(retryCount: action.retryCount + 1);
            await _queueBox!.put(key, updatedAction.toRawJson());
            break; // Stop loop and retry later on network event
          }
        }
      }
    } finally {
      _isSyncing = false;
      _updateQueueCount();
    }
  }

  void _updateQueueCount() {
    final count = _queueBox?.length ?? 0;
    _queueCountController.add(count);
  }

  int get pendingQueueCount => _queueBox?.length ?? 0;

  void dispose() {
    _connectivitySubscription?.cancel();
    _networkStatusController.close();
    _queueCountController.close();
  }
}
