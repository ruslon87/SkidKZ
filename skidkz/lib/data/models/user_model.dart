// lib/data/models/user_model.dart

enum UserRole { buyer, seller, wanghong, admin }

/// ---------------------------------------------------------------------------
/// LEGACY DTO (чтобы проект собирался)
/// ---------------------------------------------------------------------------
/// В проекте есть старые репозитории/mock_database, которые используют AppUser.
/// Мы оставляем AppUser как совместимый DTO, а канон по Firestore = UserModel+profiles.
///
/// Чтобы не ловить ошибки компиляции "No named parameter ...",
/// AppUser содержит наиболее частые поля анкет/заявок и extra для всего остального.
class AppUser {
  final String id;

  // базовые
  final String? name;
  final String? phoneNumber;

  // роли
  final UserRole? role; // legacy
  final List<UserRole>? roles; // new
  final UserRole? activeRole; // new

  // buyer анкета (минимум)
  final String? fullName;
  final String? city;
  final String? street;
  final String? apartment;
  final String? comment;
  final String? contactPhone;
  final bool? acceptedTerms;

  // общие оферты / чекбоксы
  final bool? offerAccepted;

  // wanghong
  final String? promoCode;
  final String? kaspiPhone; // mock_database может передавать kaspiPhone
  final String? kaspiNumber; // иногда называют так
  final Map<String, dynamic>? wallet; // например {balance, hold...}

  // seller
  final String? storeName;
  final bool? isServiceSeller;
  final String? status; // pending/approved/rejected

  // запасной контейнер под любые будущие поля
  final Map<String, dynamic>? extra;

  const AppUser({
    required this.id,

    this.name,
    this.phoneNumber,

    this.role,
    this.roles,
    this.activeRole,

    this.fullName,
    this.city,
    this.street,
    this.apartment,
    this.comment,
    this.contactPhone,
    this.acceptedTerms,

    this.offerAccepted,

    this.promoCode,
    this.kaspiPhone,
    this.kaspiNumber,
    this.wallet,

    this.storeName,
    this.isServiceSeller,
    this.status,

    this.extra,
  });

  static UserRole _roleFromString(String? s) {
    final v = (s ?? 'buyer').trim().toLowerCase();
    return UserRole.values.firstWhere(
      (r) => r.name == v,
      orElse: () => UserRole.buyer,
    );
  }

  static List<UserRole> _rolesFromAny(dynamic rawRoles, String? rawRoleLegacy) {
    if (rawRoles is List) {
      final out = <UserRole>[];
      for (final x in rawRoles) {
        if (x is String) out.add(_roleFromString(x));
      }
      if (out.isNotEmpty) return out.toSet().toList();
    }

    if (rawRoleLegacy is String && rawRoleLegacy.trim().isNotEmpty) {
      return [_roleFromString(rawRoleLegacy)];
    }

    return [UserRole.buyer];
  }

  /// В старом коде у тебя вызывается `AppUser.fromMap(uid, data)`
  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    final phone =
        (data['phoneNumber'] as String?) ?? (data['phone'] as String?);

    final displayName = (data['displayName'] as String?) ??
        (data['name'] as String?) ??
        (data['fullName'] as String?);

    final parsedRoles = _rolesFromAny(data['roles'], data['role']);
    final parsedActive = _roleFromString(
      (data['activeRole'] as String?) ?? (data['role'] as String?),
    );

    // profiles может содержать данные анкет
    final profilesRaw = data['profiles'];
    Map? buyerRaw;
    Map? sellerRaw;
    Map? whRaw;

    if (profilesRaw is Map) {
      final b = profilesRaw['buyer'];
      final s = profilesRaw['seller'];
      final w = profilesRaw['wanghong'];
      if (b is Map) buyerRaw = b;
      if (s is Map) sellerRaw = s;
      if (w is Map) whRaw = w;
    }

    // promoCode
    String? promo = (data['promoCode'] as String?)?.trim();
    promo ??= (whRaw?['promoCode'] as String?)?.trim();

    // kaspi
    String? kaspi =
        (data['kaspiPhone'] as String?)?.trim() ?? (data['kaspiNumber'] as String?)?.trim();
    kaspi ??= (whRaw?['kaspiPhone'] as String?)?.trim() ?? (whRaw?['kaspiNumber'] as String?)?.trim();

    // wallet
    Map<String, dynamic>? wallet;
    final w1 = data['wallet'];
    if (w1 is Map<String, dynamic>) wallet = w1;
    final w2 = whRaw?['wallet'];
    if (wallet == null && w2 is Map) {
      wallet = Map<String, dynamic>.from(w2 as Map);
    }

    // offerAccepted
    final offer = (data['offerAccepted'] as bool?) ??
        (buyerRaw?['offerAccepted'] as bool?) ??
        (sellerRaw?['offerAccepted'] as bool?) ??
        (whRaw?['offerAccepted'] as bool?);

    // seller fields
    final storeName = (data['storeName'] as String?)?.trim() ??
        (sellerRaw?['storeName'] as String?)?.trim();

    final isServiceSeller = (data['isServiceSeller'] as bool?) ??
        (sellerRaw?['isServiceSeller'] as bool?);

    final status = (data['status'] as String?)?.trim() ??
        (sellerRaw?['status'] as String?)?.trim();

    // buyer fields
    final fullName = (data['fullName'] as String?)?.trim() ??
        (buyerRaw?['fullName'] as String?)?.trim();

    final city = (data['city'] as String?)?.trim() ??
        (buyerRaw?['city'] as String?)?.trim();

    final street = (data['street'] as String?)?.trim() ??
        (buyerRaw?['street'] as String?)?.trim();

    final apartment = (data['apartment'] as String?)?.trim() ??
        (buyerRaw?['apartment'] as String?)?.trim();

    final comment = (data['comment'] as String?)?.trim() ??
        (buyerRaw?['comment'] as String?)?.trim();

    final contactPhone = (data['contactPhone'] as String?)?.trim() ??
        (buyerRaw?['contactPhone'] as String?)?.trim();

    final acceptedTerms = (data['acceptedTerms'] as bool?) ??
        (buyerRaw?['acceptedTerms'] as bool?);

    return AppUser(
      id: uid,

      name: (displayName is String && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : null,
      phoneNumber:
          (phone is String && phone.trim().isNotEmpty) ? phone.trim() : null,

      role: _roleFromString(
        (data['role'] as String?) ?? (data['activeRole'] as String?),
      ),
      roles: parsedRoles,
      activeRole: parsedActive,

      // buyer
      fullName: fullName,
      city: city,
      street: street,
      apartment: apartment,
      comment: comment,
      contactPhone: contactPhone,
      acceptedTerms: acceptedTerms,

      // offer
      offerAccepted: offer,

      // wanghong
      promoCode: promo,
      kaspiPhone: kaspi,
      kaspiNumber: kaspi,
      wallet: wallet,

      // seller
      storeName: storeName,
      isServiceSeller: isServiceSeller,
      status: status,

      extra: (data['extra'] is Map<String, dynamic>)
          ? (data['extra'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'displayName': name,
      'phoneNumber': phoneNumber,
      'phone': phoneNumber,

      'role': (role ?? UserRole.buyer).name,
      'roles': (roles ?? const [UserRole.buyer]).map((r) => r.name).toList(),
      'activeRole': (activeRole ?? role ?? UserRole.buyer).name,

      if (fullName != null) 'fullName': fullName,
      if (city != null) 'city': city,
      if (street != null) 'street': street,
      if (apartment != null) 'apartment': apartment,
      if (comment != null) 'comment': comment,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (acceptedTerms != null) 'acceptedTerms': acceptedTerms,

      if (offerAccepted != null) 'offerAccepted': offerAccepted,

      if (promoCode != null) 'promoCode': promoCode,
      if (kaspiPhone != null) 'kaspiPhone': kaspiPhone,
      if (kaspiNumber != null) 'kaspiNumber': kaspiNumber,
      if (wallet != null) 'wallet': wallet,

      if (storeName != null) 'storeName': storeName,
      if (isServiceSeller != null) 'isServiceSeller': isServiceSeller,
      if (status != null) 'status': status,

      if (extra != null) 'extra': extra,
    };
  }
}

/// ---------------------------------------------------------------------------
/// CANON MODEL (основной для проекта)
/// ---------------------------------------------------------------------------

class UserModel {
  final String uid;
  final String? phone;
  final List<UserRole> roles;
  final UserRole activeRole;

  final BuyerProfile buyerProfile;
  final SellerProfile sellerProfile;
  final WanghongProfile wanghongProfile;

  UserModel({
    required this.uid,
    required this.roles,
    required this.activeRole,
    this.phone,
    required this.buyerProfile,
    required this.sellerProfile,
    required this.wanghongProfile,
  });

  static UserRole _roleFromString(String? s) {
    final v = (s ?? 'buyer').trim().toLowerCase();
    return UserRole.values.firstWhere(
      (r) => r.name == v,
      orElse: () => UserRole.buyer,
    );
  }

  static List<UserRole> _rolesFromAny(dynamic rawRoles, String? rawRoleLegacy) {
    if (rawRoles is List) {
      final out = <UserRole>[];
      for (final x in rawRoles) {
        if (x is String) out.add(_roleFromString(x));
      }
      if (out.isNotEmpty) return out.toSet().toList();
    }

    if (rawRoleLegacy is String && rawRoleLegacy.trim().isNotEmpty) {
      return [_roleFromString(rawRoleLegacy)];
    }

    return [UserRole.buyer];
  }

  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    final phone = (data['phone'] as String?) ?? (data['phoneNumber'] as String?);

    final roles = _rolesFromAny(data['roles'], data['role']);
    final active = _roleFromString(
      (data['activeRole'] as String?) ?? (data['role'] as String?),
    );

    final fixedActive = roles.contains(active) ? active : roles.first;

    final profiles = (data['profiles'] is Map<String, dynamic>)
        ? (data['profiles'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final buyerMap = (profiles['buyer'] is Map<String, dynamic>)
        ? (profiles['buyer'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final sellerMap = (profiles['seller'] is Map<String, dynamic>)
        ? (profiles['seller'] as Map<String, dynamic>)
        : <String, dynamic>{};

    final wanghongMap = (profiles['wanghong'] is Map<String, dynamic>)
        ? (profiles['wanghong'] as Map<String, dynamic>)
        : <String, dynamic>{};

    return UserModel(
      uid: uid,
      phone: phone,
      roles: roles,
      activeRole: fixedActive,
      buyerProfile: BuyerProfile.fromMap(buyerMap),
      sellerProfile: SellerProfile.fromMap(sellerMap),
      wanghongProfile: WanghongProfile.fromMap(wanghongMap),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'phone': phone,
      'phoneNumber': phone,
      'roles': roles.map((r) => r.name).toList(),
      'activeRole': activeRole.name,
      'profiles': {
        'buyer': buyerProfile.toMap(),
        'seller': sellerProfile.toMap(),
        'wanghong': wanghongProfile.toMap(),
      },
    };
  }
}

class BuyerProfile {
  final bool completed;
  final String firstName;
  final String lastName;
  final String city;
  final String street;
  final String apartment;
  final String comment;
  final String contactPhone;
  final String kaspiPhone; // номер Kaspi для выплат (если станет партнером)
  final bool acceptedTerms;

  const BuyerProfile({
    required this.completed,
    required this.firstName,
    required this.lastName,
    required this.city,
    required this.street,
    required this.apartment,
    required this.comment,
    required this.contactPhone,
    required this.kaspiPhone,
    required this.acceptedTerms,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory BuyerProfile.empty() => const BuyerProfile(
        completed: false,
        firstName: '',
        lastName: '',
        city: 'Алматы',
        street: '',
        apartment: '',
        comment: '',
        contactPhone: '',
        kaspiPhone: '',
        acceptedTerms: false,
      );

  factory BuyerProfile.fromMap(Map<String, dynamic> m) {
    // Обратная совместимость: если было fullName — разбиваем
    final legacyFull = (m['fullName'] as String?) ?? '';
    final parts = legacyFull.split(' ');
    final legacyFirst = parts.isNotEmpty ? parts.first : '';
    final legacyLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    return BuyerProfile(
      completed: (m['completed'] as bool?) ?? false,
      firstName: (m['firstName'] as String?) ?? legacyFirst,
      lastName: (m['lastName'] as String?) ?? legacyLast,
      city: (m['city'] as String?) ?? 'Алматы',
      street: (m['street'] as String?) ?? '',
      apartment: (m['apartment'] as String?) ?? '',
      comment: (m['comment'] as String?) ?? '',
      contactPhone: (m['contactPhone'] as String?) ?? '',
      kaspiPhone: (m['kaspiPhone'] as String?) ?? (m['kaspiNumber'] as String?) ?? '',
      acceptedTerms: (m['acceptedTerms'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'completed': completed,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'city': city,
        'street': street,
        'apartment': apartment,
        'comment': comment,
        'contactPhone': contactPhone,
        'kaspiPhone': kaspiPhone,
        'acceptedTerms': acceptedTerms,
      };
}

class SellerProfile {
  final bool completed;
  final String storeName;
  final String storeDescription;
  final String ownerName;
  final String ownerPhone;
  final String city;
  final String address;
  final String bin; // БИН/ИИН
  final String kaspiPhone; // номер Kaspi для выплат
  final String instagramUrl;
  final bool isServiceSeller;
  final String status; // pending / approved / rejected

  const SellerProfile({
    required this.completed,
    required this.storeName,
    required this.storeDescription,
    required this.ownerName,
    required this.ownerPhone,
    required this.city,
    required this.address,
    required this.bin,
    required this.kaspiPhone,
    required this.instagramUrl,
    required this.isServiceSeller,
    required this.status,
  });

  factory SellerProfile.empty() => const SellerProfile(
        completed: false,
        storeName: '',
        storeDescription: '',
        ownerName: '',
        ownerPhone: '',
        city: 'Алматы',
        address: '',
        bin: '',
        kaspiPhone: '',
        instagramUrl: '',
        isServiceSeller: false,
        status: 'pending',
      );

  factory SellerProfile.fromMap(Map<String, dynamic> m) {
    return SellerProfile(
      completed: (m['completed'] as bool?) ?? false,
      storeName: (m['storeName'] as String?) ?? '',
      storeDescription: (m['storeDescription'] as String?) ?? '',
      ownerName: (m['ownerName'] as String?) ?? '',
      ownerPhone: (m['ownerPhone'] as String?) ?? '',
      city: (m['city'] as String?) ?? 'Алматы',
      address: (m['address'] as String?) ?? '',
      bin: (m['bin'] as String?) ?? '',
      kaspiPhone: (m['kaspiPhone'] as String?) ?? '',
      instagramUrl: (m['instagramUrl'] as String?) ?? '',
      isServiceSeller: (m['isServiceSeller'] as bool?) ?? false,
      status: (m['status'] as String?) ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() => {
        'completed': completed,
        'storeName': storeName,
        'storeDescription': storeDescription,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'city': city,
        'address': address,
        'bin': bin,
        'kaspiPhone': kaspiPhone,
        'instagramUrl': instagramUrl,
        'isServiceSeller': isServiceSeller,
        'status': status,
      };
}

class WanghongProfile {
  final bool completed;
  final String firstName;
  final String lastName;
  final String kaspiPhone; // номер Kaspi для выплат
  final String promoCode; // уникальный промокод
  final double balance;
  final double totalEarned;
  final int totalSales;
  final String status; // active / pending / blocked

  const WanghongProfile({
    required this.completed,
    required this.firstName,
    required this.lastName,
    required this.kaspiPhone,
    required this.promoCode,
    required this.balance,
    required this.totalEarned,
    required this.totalSales,
    required this.status,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory WanghongProfile.empty() => const WanghongProfile(
        completed: false,
        firstName: '',
        lastName: '',
        kaspiPhone: '',
        promoCode: '',
        balance: 0.0,
        totalEarned: 0.0,
        totalSales: 0,
        status: 'pending',
      );

  factory WanghongProfile.fromMap(Map<String, dynamic> m) {
    return WanghongProfile(
      completed: (m['completed'] as bool?) ?? false,
      firstName: (m['firstName'] as String?) ?? '',
      lastName: (m['lastName'] as String?) ?? '',
      kaspiPhone: (m['kaspiPhone'] as String?) ?? '',
      promoCode: (m['promoCode'] as String?) ?? '',
      balance: ((m['balance'] as num?) ?? 0).toDouble(),
      totalEarned: ((m['totalEarned'] as num?) ?? 0).toDouble(),
      totalSales: ((m['totalSales'] as num?) ?? 0).toInt(),
      status: (m['status'] as String?) ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() => {
        'completed': completed,
        'firstName': firstName,
        'lastName': lastName,
        'kaspiPhone': kaspiPhone,
        'promoCode': promoCode,
        'balance': balance,
        'totalEarned': totalEarned,
        'totalSales': totalSales,
        'status': status,
      };
}
