import 'dart:convert';

import 'package:cargo_line_tj/l10n/app_strings.dart';
import 'package:cargo_line_tj/models/parcel.dart';
import 'package:cargo_line_tj/models/user_profile.dart';
import 'package:cargo_line_tj/services/local_store.dart';
import 'package:cargo_line_tj/services/parcel_api.dart';
import 'package:flutter/foundation.dart';

class ParcelProvider extends ChangeNotifier {
  ParcelProvider(this._store, {ParcelApi? api}) : _api = api ?? ParcelApi();

  final LocalStore _store;
  final ParcelApi _api;

  final List<Parcel> _parcels = [];
  final List<AppNotification> _notifications = [];
  final Set<String> _selectedIds = {};
  final Set<String> _adminTracksAtKhujand = {};

  String? _accessToken;
  PickupPoint _pickupPoint = PickupPoint.didor;
  bool _selectionMode = false;
  bool _loaded = false;
  bool _online = false;

  /// Visible parcels only (pendingMatch hidden until China scan).
  List<Parcel> get parcels => List.unmodifiable(
        _parcels.where((p) => p.status != ParcelStatusKey.pendingMatch),
      );

  List<Parcel> get pendingParcels => List.unmodifiable(
        _parcels.where((p) => p.status == ParcelStatusKey.pendingMatch),
      );

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get selectionMode => _selectionMode;
  bool get isReady => _loaded;
  bool get isOnline => _online;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  List<Parcel> byStatus(ParcelStatusKey status) {
    if (status == ParcelStatusKey.pendingMatch) return const [];
    return [
      for (final p in _parcels)
        if (p.status == status) p,
    ];
  }

  int countByStatus(ParcelStatusKey status) {
    if (status == ParcelStatusKey.pendingMatch) return 0;
    var n = 0;
    for (final p in _parcels) {
      if (p.status == status) n++;
    }
    return n;
  }

  void setSession({
    String? accessToken,
    PickupPoint? pickupPoint,
  }) {
    final tokenChanged = accessToken != _accessToken;
    final pickupChanged =
        pickupPoint != null && pickupPoint != _pickupPoint;
    _accessToken = accessToken;
    if (pickupPoint != null) _pickupPoint = pickupPoint;
    if (_loaded && (tokenChanged || pickupChanged)) {
      syncFromServer();
    }
  }

  Future<void> load() async {
    _adminTracksAtKhujand
      ..clear()
      ..addAll(_store.adminTracks);

    _loadLocalParcels();
    _loadLocalNotifications();

    // Demo seed отключён — только реальные треки с API / локальный pending.

    _purgeStaleReceived(persist: false);
    refreshStatuses(persist: false);
    await _persistAll();

    _loaded = true;
    notifyListeners();
    // Sync after UI is ready — do not block splash / first paint.
    // ignore: unawaited_futures
    syncFromServer().then((_) => _purgeStaleReceived(persist: true));
  }

  void _loadLocalParcels() {
    final parcelsRaw = _store.parcelsJson;
    if (parcelsRaw == null || parcelsRaw.isEmpty) return;
    try {
      final list = jsonDecode(parcelsRaw) as List<dynamic>;
      _parcels
        ..clear()
        ..addAll(list.map((e) => Parcel.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      _parcels.clear();
    }
  }

  void _loadLocalNotifications() {
    final notesRaw = _store.notificationsJson;
    if (notesRaw == null || notesRaw.isEmpty) return;
    try {
      final list = jsonDecode(notesRaw) as List<dynamic>;
      _notifications
        ..clear()
        ..addAll(
          list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)),
        );
    } catch (_) {
      _notifications.clear();
    }
  }

  Future<void> syncFromServer() async {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      _online = false;
      return;
    }
    try {
      final remote = await _api.listParcels(token);
      final pendingLocal = _parcels
          .where((p) => p.status == ParcelStatusKey.pendingMatch)
          .toList();
      final remoteTracks = remote.map((p) => p.trackCode).toSet();
      _parcels
        ..clear()
        ..addAll(remote)
        // Keep pending tracks that are not yet matched on server.
        ..addAll(
          pendingLocal.where((p) => !remoteTracks.contains(p.trackCode)),
        );
      for (final p in _parcels) {
        if (p.status == ParcelStatusKey.tajikistanWarehouse ||
            p.status == ParcelStatusKey.delivery ||
            p.status == ParcelStatusKey.received) {
          _pushKhujandNotification(p.trackCode, persist: false);
        }
      }
      _online = true;
      await _persistAll();
      notifyListeners();
    } catch (_) {
      _online = false;
      // Keep shared_preferences cache.
    }
  }

  Future<void> _seedSampleData() async {
    final now = DateTime.now();
    _parcels.addAll([
      Parcel(
        id: '1',
        trackCode: 'YT7438291045678',
        status: ParcelStatusKey.chinaWarehouse,
        marketplace: MarketplaceKey.pinduoduo,
        createdAt: now.subtract(const Duration(days: 1)),
        lastUpdate: now.subtract(const Duration(hours: 2)),
        progress: 0.1,
      ),
      Parcel(
        id: '2',
        trackCode: 'SF1234567890123',
        status: ParcelStatusKey.chinaWarehouse,
        marketplace: MarketplaceKey.alibaba1688,
        createdAt: now.subtract(const Duration(days: 5)),
        lastUpdate: now.subtract(const Duration(days: 5)),
        progress: 0.15,
      ),
      Parcel(
        id: '3',
        trackCode: 'JD9988776655443',
        status: ParcelStatusKey.sorting,
        marketplace: MarketplaceKey.taobao,
        createdAt: now.subtract(const Duration(days: 10)),
        lastUpdate: now.subtract(const Duration(hours: 8)),
        progress: 0.5,
      ),
      Parcel(
        id: '4',
        trackCode: 'ZT5566778899001',
        status: ParcelStatusKey.tajikistanWarehouse,
        marketplace: MarketplaceKey.pinduoduo,
        createdAt: now.subtract(const Duration(days: 18)),
        lastUpdate: now.subtract(const Duration(hours: 1)),
        progress: 0.75,
        notifiedKhujand: true,
      ),
      Parcel(
        id: '5',
        trackCode: 'TB3344556677889',
        status: ParcelStatusKey.delivery,
        marketplace: MarketplaceKey.taobao,
        createdAt: now.subtract(const Duration(days: 20)),
        lastUpdate: now.subtract(const Duration(minutes: 30)),
        progress: 0.9,
      ),
      Parcel(
        id: '6',
        trackCode: 'PD1122334455667',
        status: ParcelStatusKey.received,
        marketplace: MarketplaceKey.pinduoduo,
        createdAt: now.subtract(const Duration(days: 30)),
        lastUpdate: now.subtract(const Duration(days: 2)),
        progress: 1.0,
      ),
    ]);

    if (_notifications.isEmpty) {
      _pushKhujandNotification('ZT5566778899001', persist: false);
    }
  }

  Future<void> _persistAll() async {
    await _store.setParcelsJson(
      jsonEncode(_parcels.map((e) => e.toJson()).toList()),
    );
    await _store.setNotificationsJson(
      jsonEncode(_notifications.map((e) => e.toJson()).toList()),
    );
    await _store.setAdminTracks(_adminTracksAtKhujand.toList());
  }

  void _purgeStaleReceived({bool persist = true}) {
    final cutoff = DateTime.now().subtract(const Duration(days: 20));
    final before = _parcels.length;
    _parcels.removeWhere(
      (p) =>
          p.status == ParcelStatusKey.received &&
          p.lastUpdate.isBefore(cutoff),
    );
    if (_parcels.length != before) {
      notifyListeners();
      if (persist) {
        _persistAll();
      }
    }
  }

  void refreshStatuses({bool persist = true}) {
    _purgeStaleReceived(persist: persist);

    if (_online && _accessToken != null) {
      // Server is source of truth while online.
      return;
    }

    final now = DateTime.now();
    var changed = false;

    for (var i = 0; i < _parcels.length; i++) {
      final p = _parcels[i];
      final ageDays = now.difference(p.createdAt).inDays;

      if (p.status == ParcelStatusKey.chinaWarehouse && ageDays >= 3) {
        _parcels[i] = p.copyWith(
          status: ParcelStatusKey.inTransit,
          lastUpdate: now,
          progress: 0.35,
        );
        changed = true;
      }
    }

    for (var i = 0; i < _parcels.length; i++) {
      final p = _parcels[i];
      if (_adminTracksAtKhujand.contains(p.trackCode) &&
          p.status != ParcelStatusKey.tajikistanWarehouse &&
          p.status != ParcelStatusKey.delivery &&
          p.status != ParcelStatusKey.received) {
        _parcels[i] = p.copyWith(
          status: ParcelStatusKey.tajikistanWarehouse,
          lastUpdate: now,
          progress: 0.75,
          notifiedKhujand: true,
        );
        _pushKhujandNotification(p.trackCode, persist: false);
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
      if (persist) {
        _persistAll();
      }
    }
  }

  /// Returns error key or null on success.
  /// empty | short | invalid | duplicate
  Future<String?> addTrackCode(
    String trackCode,
    MarketplaceKey marketplace,
  ) async {
    final trimmed = trackCode.trim().toUpperCase();
    if (trimmed.isEmpty) return 'empty';
    if (trimmed.length < 8 || trimmed.length > 32) return 'short';
    if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(trimmed)) return 'invalid';
    if (_parcels.any((p) => p.trackCode == trimmed)) return 'duplicate';

    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      try {
        final created = await _api.addParcel(
          token: token,
          trackCode: trimmed,
          marketplace: marketplace,
          pickupPoint: _pickupPoint.name,
        );
        // Keep pending locally (hidden from Склад Китай until mass-scan).
        final stored = created.status == ParcelStatusKey.pendingMatch
            ? created
            : created.copyWith(status: ParcelStatusKey.pendingMatch, progress: 0);
        _parcels.insert(0, stored);
        _online = true;
        notifyListeners();
        await _persistAll();
        return null;
      } on ApiException catch (e) {
        if (e.statusCode == 409) return 'duplicate';
        // Fall through to local.
      } catch (_) {
        // Fall through to local offline cache.
      }
    }

    final now = DateTime.now();
    _parcels.insert(
      0,
      Parcel(
        id: now.microsecondsSinceEpoch.toString(),
        trackCode: trimmed,
        status: ParcelStatusKey.pendingMatch,
        marketplace: marketplace,
        createdAt: now,
        lastUpdate: now,
        progress: 0,
      ),
    );
    _online = false;
    notifyListeners();
    await _persistAll();
    return null;
  }

  Future<void> adminMassScan(List<String> scannedTracks) async {
    for (final t in scannedTracks) {
      final track = t.trim().toUpperCase();
      _adminTracksAtKhujand.add(track);
      try {
        final updated = await _api.adminScan(
          trackCode: track,
          newStatus: ParcelStatusKey.tajikistanWarehouse.name,
        );
        final i = _parcels.indexWhere((p) => p.trackCode == track);
        if (i >= 0) {
          _parcels[i] = updated.copyWith(notifiedKhujand: true);
        } else {
          _parcels.insert(0, updated.copyWith(notifiedKhujand: true));
        }
        _pushKhujandNotification(track, persist: false);
        _online = true;
      } catch (_) {
        // Offline local transition below.
      }
    }
    refreshStatuses(persist: false);
    await _persistAll();
    notifyListeners();
  }

  Future<void> simulateArrivalAtKhujand(String trackCode) =>
      adminMassScan([trackCode]);

  void _pushKhujandNotification(String trackCode, {bool persist = true}) {
    final already = _notifications.any((n) => n.trackCode == trackCode);
    if (already) return;

    _notifications.insert(
      0,
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'Посылка на складе в Худжанде',
        body:
            'Ваша посылка $trackCode на складе в Худжанде (Гафуров, ДИДОР). '
            'Можете заказать бесплатную доставку или забрать товар сами.',
        createdAt: DateTime.now(),
        trackCode: trackCode,
      ),
    );
    if (persist) {
      _persistAll();
    }
  }

  Parcel? searchByTrackCode(String query) {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return null;
    for (final p in _parcels) {
      if (p.trackCode.contains(q)) return p;
    }
    return null;
  }

  void toggleSelectionMode([bool? enabled]) {
    _selectionMode = enabled ?? !_selectionMode;
    if (!_selectionMode) _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelect(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAllReceived() {
    _selectionMode = true;
    _selectedIds
      ..clear()
      ..addAll(
        _parcels
            .where((p) => p.status == ParcelStatusKey.received)
            .map((p) => p.id),
      );
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final toDelete = _parcels
        .where((p) => _selectedIds.contains(p.id))
        .map((p) => p.trackCode)
        .toList();
    final token = _accessToken;
    if (token != null) {
      for (final track in toDelete) {
        try {
          await _api.deleteParcel(token, track);
          _online = true;
        } catch (_) {
          _online = false;
        }
      }
    }
    _parcels.removeWhere((p) => _selectedIds.contains(p.id));
    _selectedIds.clear();
    _selectionMode = false;
    notifyListeners();
    await _persistAll();
  }

  Future<void> deleteById(String id) async {
    final i = _parcels.indexWhere((p) => p.id == id);
    if (i < 0) return;
    final track = _parcels[i].trackCode;
    final token = _accessToken;
    if (token != null) {
      try {
        await _api.deleteParcel(token, track);
        _online = true;
      } catch (_) {
        _online = false;
      }
    }
    _parcels.removeAt(i);
    _selectedIds.remove(id);
    notifyListeners();
    await _persistAll();
  }

  Future<void> deleteReceived() async {
    final toDelete = _parcels
        .where((p) => p.status == ParcelStatusKey.received)
        .map((p) => p.trackCode)
        .toList();
    final token = _accessToken;
    if (token != null) {
      for (final track in toDelete) {
        try {
          await _api.deleteParcel(token, track);
        } catch (_) {}
      }
    }
    _parcels.removeWhere((p) => p.status == ParcelStatusKey.received);
    _selectedIds.clear();
    _selectionMode = false;
    notifyListeners();
    await _persistAll();
  }

  Future<void> markNotificationRead(String id) async {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i < 0) return;
    _notifications[i] = _notifications[i].copyWith(read: true);
    notifyListeners();
    await _persistAll();
  }

  Future<void> markAllNotificationsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    notifyListeners();
    await _persistAll();
  }

  Future<void> requestFreeDelivery(String trackCode) async {
    await _updateStatusRemoteOrLocal(
      trackCode,
      ParcelStatusKey.delivery,
      progress: 0.9,
    );
  }

  Future<void> markReceived(String trackCode) async {
    await _updateStatusRemoteOrLocal(
      trackCode,
      ParcelStatusKey.received,
      progress: 1.0,
    );
  }

  Future<void> markManyReceived(Iterable<String> trackCodes) async {
    for (final track in trackCodes) {
      await markReceived(track);
    }
  }

  Future<void> updatePaymentMethod(
    String method, {
    List<String>? trackCodes,
  }) async {
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _api.updatePayment(
          token: token,
          paymentMethod: method,
          trackCodes: trackCodes,
        );
        _online = true;
      } catch (_) {
        _online = false;
      }
    }
    notifyListeners();
  }

  Future<void> updateFulfillmentMode(
    String mode, {
    List<String>? trackCodes,
  }) async {
    final codes = trackCodes?.map((t) => t.trim().toUpperCase()).toList();
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _api.updateFulfillment(
          token: token,
          fulfillment: mode,
          trackCodes: codes,
        );
        _online = true;
        await syncFromServer();
        notifyListeners();
        return;
      } catch (_) {
        _online = false;
      }
    }

    final now = DateTime.now();
    for (var i = 0; i < _parcels.length; i++) {
      final p = _parcels[i];
      if (codes != null && codes.isNotEmpty && !codes.contains(p.trackCode)) {
        continue;
      }
      if (p.status != ParcelStatusKey.tajikistanWarehouse &&
          p.status != ParcelStatusKey.delivery) {
        continue;
      }
      _parcels[i] = p.copyWith(
        status: mode == 'delivery'
            ? ParcelStatusKey.delivery
            : ParcelStatusKey.tajikistanWarehouse,
        lastUpdate: now,
        progress: mode == 'delivery' ? 0.9 : 0.75,
      );
    }
    notifyListeners();
    await _persistAll();
  }

  Future<void> _updateStatusRemoteOrLocal(
    String trackCode,
    ParcelStatusKey status, {
    required double progress,
  }) async {
    final track = trackCode.trim().toUpperCase();
    try {
      final updated = await _api.adminScan(
        trackCode: track,
        newStatus: status.name,
      );
      final i = _parcels.indexWhere((p) => p.trackCode == track);
      if (i >= 0) {
        _parcels[i] = updated;
      }
      _online = true;
      notifyListeners();
      await _persistAll();
      return;
    } catch (_) {
      _online = false;
    }

    final i = _parcels.indexWhere((p) => p.trackCode == track);
    if (i < 0) return;
    _parcels[i] = _parcels[i].copyWith(
      status: status,
      lastUpdate: DateTime.now(),
      progress: progress,
    );
    notifyListeners();
    await _persistAll();
  }
}
