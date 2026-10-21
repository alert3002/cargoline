class UserProfile {
  const UserProfile({
    required this.clientCode,
    required this.phone,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.workPhone,
    this.address,
    this.avatarPath,
    this.profileComplete = false,
    this.unreadNotifications = 0,
    this.regNumber = 0,
  });

  final String clientCode;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? birthDate;
  final String? workPhone;
  final String? address;
  final String? avatarPath;
  final bool profileComplete;
  final int unreadNotifications;
  final int regNumber;

  String get name {
    final f = (firstName ?? '').trim();
    final l = (lastName ?? '').trim();
    if (f.isNotEmpty && l.isNotEmpty) return '$f $l';
    if (f.isNotEmpty) return f;
    if (l.isNotEmpty) return l;
    return 'Клиент';
  }

  String get displayFirst =>
      (firstName ?? '').trim().isEmpty ? name : firstName!.trim();

  String get formattedPhone {
    if (phone.length >= 12) {
      return '+${phone.substring(0, 3)} ${phone.substring(3, 5)} ${phone.substring(5, 8)} ${phone.substring(8)}';
    }
    return phone.startsWith('+') ? phone : '+$phone';
  }

  /// Скобка (N) для адреса склада.
  String get warehouseSuffix {
    if (regNumber > 0) return '($regNumber)';
    return clientCode;
  }

  UserProfile copyWith({
    String? clientCode,
    String? phone,
    String? firstName,
    String? lastName,
    String? birthDate,
    String? workPhone,
    String? address,
    String? avatarPath,
    bool? profileComplete,
    int? unreadNotifications,
    int? regNumber,
  }) {
    return UserProfile(
      clientCode: clientCode ?? this.clientCode,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      workPhone: workPhone ?? this.workPhone,
      address: address ?? this.address,
      avatarPath: avatarPath ?? this.avatarPath,
      profileComplete: profileComplete ?? this.profileComplete,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      regNumber: regNumber ?? this.regNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientCode': clientCode,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'birthDate': birthDate,
        'workPhone': workPhone,
        'address': address,
        'avatarPath': avatarPath,
        'profileComplete': profileComplete,
        'unreadNotifications': unreadNotifications,
        'regNumber': regNumber,
        'name': name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final first = json['firstName'] as String? ??
        json['first_name'] as String? ??
        (json['name'] as String?);
    final email = json['email'] as String?;
    return UserProfile(
      clientCode: json['clientCode'] as String? ??
          json['client_code'] as String? ??
          'TJ0000',
      phone: (json['phone'] as String? ?? '').replaceAll(RegExp(r'\D'), ''),
      firstName: first ?? (email != null ? email.split('@').first : null),
      lastName: json['lastName'] as String? ?? json['last_name'] as String?,
      birthDate: json['birthDate'] as String? ?? json['birth_date'] as String?,
      workPhone: json['workPhone'] as String? ?? json['work_phone'] as String?,
      address: json['address'] as String?,
      avatarPath: json['avatarPath'] as String? ?? json['avatar_url'] as String?,
      profileComplete: json['profileComplete'] as bool? ??
          json['profile_complete'] as bool? ??
          false,
      unreadNotifications: json['unreadNotifications'] as int? ??
          json['unread_notifications'] as int? ??
          0,
      regNumber: json['regNumber'] as int? ??
          json['reg_number'] as int? ??
          0,
    );
  }
}

enum PickupPoint {
  didor('Напротив ресторана Дидор (трасса Худжанд — Гафуров)');

  const PickupPoint(this.labelRu);
  final String labelRu;

  String label(bool isRu) => isRu
      ? 'Напротив ресторана Дидор (на трассе Худжанд — Гафуров)'
      : 'Муқобили ресторани Дидор (роҳи Хуҷанд — Ғафуров)';

  /// Google Maps search for Didar / Gafurov road.
  static const mapUrl =
      'https://www.google.com/maps/search/?api=1&query=Дидор+ресторан+Худжанд+Гафуров';
}
