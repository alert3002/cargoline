import 'package:cargo_line_tj/l10n/app_strings.dart';

class Parcel {
  const Parcel({
    required this.id,
    required this.trackCode,
    required this.status,
    required this.marketplace,
    required this.createdAt,
    required this.lastUpdate,
    this.progress = 0.0,
    this.notifiedKhujand = false,
  });

  final String id;
  final String trackCode;
  final ParcelStatusKey status;
  final MarketplaceKey marketplace;
  final DateTime createdAt;
  final DateTime lastUpdate;
  final double progress;
  final bool notifiedKhujand;

  Parcel copyWith({
    String? id,
    String? trackCode,
    ParcelStatusKey? status,
    MarketplaceKey? marketplace,
    DateTime? createdAt,
    DateTime? lastUpdate,
    double? progress,
    bool? notifiedKhujand,
  }) {
    return Parcel(
      id: id ?? this.id,
      trackCode: trackCode ?? this.trackCode,
      status: status ?? this.status,
      marketplace: marketplace ?? this.marketplace,
      createdAt: createdAt ?? this.createdAt,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      progress: progress ?? this.progress,
      notifiedKhujand: notifiedKhujand ?? this.notifiedKhujand,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trackCode': trackCode,
        'status': status.name,
        'marketplace': marketplace.name,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdate': lastUpdate.toIso8601String(),
        'progress': progress,
        'notifiedKhujand': notifiedKhujand,
      };

  factory Parcel.fromJson(Map<String, dynamic> json) {
    return Parcel(
      id: json['id'].toString(),
      trackCode: (json['trackCode'] ?? json['track_code']) as String,
      status: ParcelStatusKey.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => ParcelStatusKey.chinaWarehouse,
      ),
      marketplace: MarketplaceKey.values.firstWhere(
        (e) => e.name == (json['marketplace'] as String?),
        orElse: () => MarketplaceKey.pinduoduo,
      ),
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']) as String,
      ),
      lastUpdate: DateTime.parse(
        (json['lastUpdate'] ?? json['updated_at'] ?? json['createdAt'] ?? json['created_at'])
            as String,
      ),
      progress: (json['progress'] as num?)?.toDouble() ??
          progressForStatus(
            ParcelStatusKey.values.firstWhere(
              (e) => e.name == (json['status'] as String?),
              orElse: () => ParcelStatusKey.chinaWarehouse,
            ),
          ),
      notifiedKhujand: json['notifiedKhujand'] as bool? ??
          (json['status'] == ParcelStatusKey.tajikistanWarehouse.name ||
              json['status'] == ParcelStatusKey.delivery.name ||
              json['status'] == ParcelStatusKey.received.name),
    );
  }

  /// Map backend ParcelOut JSON.
  factory Parcel.fromApi(Map<String, dynamic> json) => Parcel.fromJson(json);

  static double progressForStatus(ParcelStatusKey status) {
    switch (status) {
      case ParcelStatusKey.pendingMatch:
        return 0.0;
      case ParcelStatusKey.chinaWarehouse:
        return 0.1;
      case ParcelStatusKey.inTransit:
        return 0.35;
      case ParcelStatusKey.sorting:
        return 0.5;
      case ParcelStatusKey.tajikistanWarehouse:
        return 0.75;
      case ParcelStatusKey.delivery:
        return 0.9;
      case ParcelStatusKey.received:
        return 1.0;
    }
  }

  String lastUpdateLabel(AppStrings s) {
    final diff = DateTime.now().difference(lastUpdate);
    if (diff.inMinutes < 60) {
      return s.isRu ? '${diff.inMinutes} мин. назад' : '${diff.inMinutes} дақ. пеш';
    }
    if (diff.inHours < 24) {
      return s.isRu ? '${diff.inHours} ч. назад' : '${diff.inHours} соат пеш';
    }
    return s.isRu ? '${diff.inDays} дн. назад' : '${diff.inDays} рӯз пеш';
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.trackCode,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? trackCode;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      read: read ?? this.read,
      trackCode: trackCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'trackCode': trackCode,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      read: json['read'] as bool? ?? false,
      trackCode: json['trackCode'] as String?,
    );
  }
}
