import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a user in the BookSwapp application
/// 
/// This model handles conversion between Firestore documents and Dart objects,
/// with proper validation and null safety.
class UserModel {
  /// Unique identifier for the user (matches Firebase Auth UID)
  final String uid;

  /// User's email address
  final String email;

  /// User's display name
  final String displayName;

  /// Whether the user's email has been verified
  final bool emailVerified;

  /// Timestamp when the user account was created
  final DateTime createdAt;

  /// Timestamp of the user's last login (nullable)
  final DateTime? lastLoginAt;

  /// Notification settings for the user
  /// Default: {swaps: true, chats: true}
  final Map<String, bool> notificationSettings;

  /// Creates a new UserModel instance
  /// 
  /// [uid] - Required: User's unique identifier
  /// [email] - Required: User's email address
  /// [displayName] - Required: User's display name
  /// [emailVerified] - Required: Email verification status
  /// [createdAt] - Required: Account creation timestamp
  /// [lastLoginAt] - Optional: Last login timestamp
  /// [notificationSettings] - Optional: Notification preferences (defaults to swaps and chats enabled)
  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.emailVerified,
    required this.createdAt,
    this.lastLoginAt,
    Map<String, bool>? notificationSettings,
  }) : notificationSettings = notificationSettings ??
            const {'swaps': true, 'chats': true};

  /// Creates a UserModel from a Map (typically from JSON or Firestore)
  /// 
  /// [map] - Map containing user data
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  /// 
  /// Example:
  /// ```dart
  /// final user = UserModel.fromMap({
  ///   'uid': '123',
  ///   'email': 'user@example.com',
  ///   'displayName': 'John Doe',
  ///   'emailVerified': true,
  ///   'createdAt': Timestamp.now(),
  /// });
  /// ```
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Validate required fields
    if (map['uid'] == null || map['uid'].toString().isEmpty) {
      throw ArgumentError('uid is required and cannot be empty');
    }
    if (map['email'] == null || map['email'].toString().isEmpty) {
      throw ArgumentError('email is required and cannot be empty');
    }
    if (map['displayName'] == null || map['displayName'].toString().isEmpty) {
      throw ArgumentError('displayName is required and cannot be empty');
    }
    if (map['emailVerified'] == null) {
      throw ArgumentError('emailVerified is required');
    }
    if (map['createdAt'] == null) {
      throw ArgumentError('createdAt is required');
    }

    // Parse createdAt
    DateTime createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is DateTime) {
      createdAt = map['createdAt'] as DateTime;
    } else if (map['createdAt'] is String) {
      createdAt = DateTime.parse(map['createdAt'] as String);
    } else if (map['createdAt'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int);
    } else {
      throw ArgumentError(
        'createdAt must be a Timestamp, DateTime, String, or int',
      );
    }

    // Parse lastLoginAt (nullable)
    DateTime? lastLoginAt;
    if (map['lastLoginAt'] != null) {
      if (map['lastLoginAt'] is Timestamp) {
        lastLoginAt = (map['lastLoginAt'] as Timestamp).toDate();
      } else if (map['lastLoginAt'] is DateTime) {
        lastLoginAt = map['lastLoginAt'] as DateTime;
      } else if (map['lastLoginAt'] is String) {
        lastLoginAt = DateTime.parse(map['lastLoginAt'] as String);
      } else if (map['lastLoginAt'] is int) {
        lastLoginAt = DateTime.fromMillisecondsSinceEpoch(
          map['lastLoginAt'] as int,
        );
      } else {
        throw ArgumentError(
          'lastLoginAt must be a Timestamp, DateTime, String, or int',
        );
      }
    }

    // Parse notificationSettings
    Map<String, bool> notificationSettings = const {'swaps': true, 'chats': true};
    if (map['notificationSettings'] != null) {
      if (map['notificationSettings'] is Map) {
        notificationSettings = Map<String, bool>.from(
          (map['notificationSettings'] as Map).map(
            (key, value) => MapEntry(key.toString(), value as bool),
          ),
        );
      }
    }

    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      emailVerified: map['emailVerified'] as bool,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      notificationSettings: notificationSettings,
    );
  }

  /// Converts UserModel to a Map (for JSON serialization or Firestore)
  /// 
  /// Returns a Map with all user data, converting DateTime to Timestamp
  /// for Firestore compatibility
  /// 
  /// Example:
  /// ```dart
  /// final map = user.toMap();
  /// await firestore.collection('users').doc(user.uid).set(map);
  /// ```
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'notificationSettings': notificationSettings,
    };
  }

  /// Creates a UserModel from a Firestore DocumentSnapshot
  /// 
  /// [doc] - Firestore DocumentSnapshot containing user data
  /// 
  /// Throws [ArgumentError] if required fields are missing
  /// 
  /// Example:
  /// ```dart
  /// final doc = await firestore.collection('users').doc('123').get();
  /// final user = UserModel.fromFirestore(doc);
  /// ```
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      throw ArgumentError('Document data is null');
    }

    // Ensure uid matches document ID
    final userData = Map<String, dynamic>.from(data);
    userData['uid'] = doc.id;

    return UserModel.fromMap(userData);
  }

  /// Creates a copy of this UserModel with updated fields
  /// 
  /// All parameters are optional. Only provided parameters will be updated.
  /// 
  /// Returns a new UserModel instance with the updated values
  /// 
  /// Example:
  /// ```dart
  /// final updatedUser = user.copyWith(
  ///   displayName: 'New Name',
  ///   emailVerified: true,
  /// );
  /// ```
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, bool>? notificationSettings,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  /// Converts UserModel to JSON string
  /// 
  /// Useful for API calls or local storage
  String toJson() {
    return toMap().toString();
  }

  /// Creates UserModel from JSON string
  /// 
  /// Note: This is a simple implementation. For production, consider
  /// using json_serializable package for more robust JSON handling.
  factory UserModel.fromJson(String json) {
    // This is a simplified version. In production, use proper JSON parsing
    throw UnimplementedError(
      'Use fromMap() with parsed JSON data instead. '
      'Consider using json_serializable for proper JSON handling.',
    );
  }

  @override
  String toString() {
    return 'UserModel('
        'uid: $uid, '
        'email: $email, '
        'displayName: $displayName, '
        'emailVerified: $emailVerified, '
        'createdAt: $createdAt, '
        'lastLoginAt: $lastLoginAt, '
        'notificationSettings: $notificationSettings'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.emailVerified == emailVerified &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt &&
        _mapEquals(other.notificationSettings, notificationSettings);
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        emailVerified.hashCode ^
        createdAt.hashCode ^
        (lastLoginAt?.hashCode ?? 0) ^
        notificationSettings.hashCode;
  }

  /// Helper method to compare maps
  bool _mapEquals(Map<String, bool> a, Map<String, bool> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

