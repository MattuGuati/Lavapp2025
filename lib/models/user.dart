class UserModel {
  final String username;
  final String password;
  final String role; // 'admin' o 'user'
  final String? phone;
  final String? whatsappApiKey;
  final String? countryCode; // ej: '54' para Argentina, '1' para USA
  final Map<String, bool> permissions;
  final DateTime createdAt;

  UserModel({
    required this.username,
    required this.password,
    this.role = 'user',
    this.phone,
    this.whatsappApiKey,
    this.countryCode = '54', // Default Argentina
    Map<String, bool>? permissions,
    DateTime? createdAt,
  })  : permissions = permissions ?? _defaultPermissions(),
        createdAt = createdAt ?? DateTime.now();

  static Map<String, bool> _defaultPermissions() {
    return {
      'preferences': false,
      'consultTickets': true,
      'reports': false,
      'costs': false,
      'clients': true,
      'users': false, // Solo admin puede ver usuarios
    };
  }

  static Map<String, bool> adminPermissions() {
    return {
      'preferences': true,
      'consultTickets': true,
      'reports': true,
      'costs': true,
      'clients': true,
      'users': true,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'phone': phone,
      'whatsappApiKey': whatsappApiKey,
      'countryCode': countryCode,
      'permissions': permissions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    print('DEBUG UserModel.fromMap: Starting parse with map keys: ${map.keys.toList()}');

    // Parse campos string de manera segura con try-catch individual
    String parseString(String fieldName, dynamic value, String defaultValue) {
      try {
        if (value == null) {
          print('DEBUG UserModel.fromMap: $fieldName is null, using default: $defaultValue');
          return defaultValue;
        }
        final result = value.toString();
        print('DEBUG UserModel.fromMap: $fieldName = "$result"');
        return result;
      } catch (e) {
        print('DEBUG ERROR UserModel.fromMap: Failed to parse $fieldName: $e');
        return defaultValue;
      }
    }

    String? parseNullableString(String fieldName, dynamic value) {
      try {
        if (value == null) {
          print('DEBUG UserModel.fromMap: $fieldName is null');
          return null;
        }
        final result = value.toString();
        print('DEBUG UserModel.fromMap: $fieldName = "$result"');
        return result;
      } catch (e) {
        print('DEBUG ERROR UserModel.fromMap: Failed to parse $fieldName: $e');
        return null;
      }
    }

    // Parse createdAt de manera segura
    DateTime parsedCreatedAt = DateTime.now();
    try {
      if (map['createdAt'] != null) {
        final createdAtValue = map['createdAt'];
        print('DEBUG UserModel.fromMap: createdAt type: ${createdAtValue.runtimeType}');
        if (createdAtValue is String) {
          parsedCreatedAt = DateTime.parse(createdAtValue);
        } else if (createdAtValue is DateTime) {
          parsedCreatedAt = createdAtValue;
        } else {
          // Timestamp de Firestore
          try {
            parsedCreatedAt = (createdAtValue as dynamic).toDate() as DateTime;
          } catch (e) {
            print('DEBUG ERROR UserModel.fromMap: Failed to parse createdAt as Timestamp: $e');
            parsedCreatedAt = DateTime.now();
          }
        }
      }
      print('DEBUG UserModel.fromMap: createdAt parsed successfully: $parsedCreatedAt');
    } catch (e) {
      print('DEBUG ERROR UserModel.fromMap: Failed to parse createdAt: $e');
      parsedCreatedAt = DateTime.now();
    }

    // Parse permissions de manera segura
    Map<String, bool> parsedPermissions = _defaultPermissions();
    try {
      if (map['permissions'] != null) {
        final perms = map['permissions'];
        print('DEBUG UserModel.fromMap: permissions type: ${perms.runtimeType}');
        if (perms is Map) {
          parsedPermissions = {};
          perms.forEach((key, value) {
            try {
              final keyStr = key.toString();
              final valueBool = value == true || value.toString().toLowerCase() == 'true';
              parsedPermissions[keyStr] = valueBool;
              print('DEBUG UserModel.fromMap: permission $keyStr = $valueBool');
            } catch (e) {
              print('DEBUG ERROR UserModel.fromMap: Failed to parse permission $key: $e');
            }
          });
        }
      }
      print('DEBUG UserModel.fromMap: permissions parsed: $parsedPermissions');
    } catch (e) {
      print('DEBUG ERROR UserModel.fromMap: Failed to parse permissions: $e');
      parsedPermissions = _defaultPermissions();
    }

    try {
      final result = UserModel(
        username: parseString('username', map['username'], ''),
        password: parseString('password', map['password'], ''),
        role: parseString('role', map['role'], 'user'),
        phone: parseNullableString('phone', map['phone']),
        whatsappApiKey: parseNullableString('whatsappApiKey', map['whatsappApiKey']),
        countryCode: parseString('countryCode', map['countryCode'], '54'),
        permissions: parsedPermissions,
        createdAt: parsedCreatedAt,
      );
      print('DEBUG UserModel.fromMap: Successfully created UserModel for ${result.username}');
      return result;
    } catch (e, st) {
      print('DEBUG ERROR UserModel.fromMap: Failed to create UserModel: $e');
      print('DEBUG ERROR UserModel.fromMap: Stack trace: $st');
      rethrow;
    }
  }

  UserModel copyWith({
    String? username,
    String? password,
    String? role,
    String? phone,
    String? whatsappApiKey,
    String? countryCode,
    Map<String, bool>? permissions,
    DateTime? createdAt,
  }) {
    return UserModel(
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      whatsappApiKey: whatsappApiKey ?? this.whatsappApiKey,
      countryCode: countryCode ?? this.countryCode,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
