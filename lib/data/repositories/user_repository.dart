import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../../core/constants/firebase_constants.dart';

/// Repository for user-related Firestore operations
/// 
/// This repository handles all database operations for user documents,
/// including CRUD operations, real-time updates, and transaction support.
class UserRepository {
  // Private constructor
  UserRepository._();

  // Singleton instance
  static UserRepository? _instance;

  /// Get singleton instance
  static UserRepository get instance {
    _instance ??= UserRepository._();
    return _instance!;
  }

  /// Get FirebaseFirestore instance from FirebaseService
  FirebaseFirestore get _firestore => FirebaseService.instance.firestore;

  /// Get reference to users collection
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirebaseConstants.usersCollection);

  /// Creates a new user document in Firestore
  /// 
  /// [user] - UserModel instance to create
  /// 
  /// Throws [FirebaseException] if creation fails
  /// 
  /// Example:
  /// ```dart
  /// final user = UserModel(...);
  /// await UserRepository.instance.createUser(user);
  /// ```
  Future<void> createUser(UserModel user) async {
    try {
      print('[UserRepository] Creating user: ${user.uid}');
      
      final userData = user.toMap();
      await _usersCollection.doc(user.uid).set(userData);
      
      print('[UserRepository] User created successfully: ${user.uid}');
    } on FirebaseException catch (e) {
      print('[UserRepository] Error creating user ${user.uid}: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('[UserRepository] Unexpected error creating user ${user.uid}: $e');
      rethrow;
    }
  }

  /// Gets a user document by UID
  /// 
  /// [uid] - User's unique identifier
  /// 
  /// Returns [UserModel] if found, null if not found
  /// Returns null instead of throwing for not found errors
  /// 
  /// Example:
  /// ```dart
  /// final user = await UserRepository.instance.getUser('123');
  /// if (user != null) {
  ///   print('User found: ${user.displayName}');
  /// }
  /// ```
  Future<UserModel?> getUser(String uid) async {
    try {
      print('[UserRepository] Getting user: $uid');
      
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists) {
        print('[UserRepository] User not found: $uid');
        return null;
      }

      final user = UserModel.fromFirestore(doc);
      print('[UserRepository] User retrieved successfully: $uid');
      return user;
    } on FirebaseException catch (e) {
      print('[UserRepository] Error getting user $uid: ${e.code} - ${e.message}');
      // Return null for not found instead of throwing
      if (e.code == 'not-found') {
        return null;
      }
      rethrow;
    } catch (e) {
      print('[UserRepository] Unexpected error getting user $uid: $e');
      rethrow;
    }
  }

  /// Gets a real-time stream of user updates
  /// 
  /// [uid] - User's unique identifier
  /// 
  /// Returns a [Stream] that emits [UserModel] whenever the user document changes
  /// Emits null if the document is deleted
  /// 
  /// Example:
  /// ```dart
  /// UserRepository.instance.getUserStream('123').listen((user) {
  ///   if (user != null) {
  ///     print('User updated: ${user.displayName}');
  ///   } else {
  ///     print('User deleted');
  ///   }
  /// });
  /// ```
  Stream<UserModel?> getUserStream(String uid) {
    print('[UserRepository] Setting up stream for user: $uid');
    
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        print('[UserRepository] User document does not exist: $uid');
        return null;
      }

      try {
        return UserModel.fromFirestore(doc);
      } catch (e) {
        print('[UserRepository] Error parsing user from stream $uid: $e');
        return null;
      }
    });
  }

  /// Updates user document fields using a transaction
  /// 
  /// [uid] - User's unique identifier
  /// [data] - Map of fields to update
  /// 
  /// Uses Firestore transaction to prevent conflicts
  /// Automatically adds updatedAt timestamp
  /// 
  /// Throws [FirebaseException] if update fails
  /// 
  /// Example:
  /// ```dart
  /// await UserRepository.instance.updateUser('123', {
  ///   'displayName': 'New Name',
  ///   'emailVerified': true,
  /// });
  /// ```
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      print('[UserRepository] Updating user: $uid with data: $data');
      
      // Add updatedAt timestamp
      final updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      // Use transaction to prevent conflicts
      await _firestore.runTransaction((transaction) async {
        final userRef = _usersCollection.doc(uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User document does not exist: $uid');
        }

        transaction.update(userRef, updateData);
      });

      print('[UserRepository] User updated successfully: $uid');
    } on FirebaseException catch (e) {
      print('[UserRepository] Error updating user $uid: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('[UserRepository] Unexpected error updating user $uid: $e');
      rethrow;
    }
  }

  /// Updates user's notification settings
  /// 
  /// [uid] - User's unique identifier
  /// [settings] - Map of notification settings to update
  /// 
  /// Merges with existing settings (does not replace entire map)
  /// 
  /// Example:
  /// ```dart
  /// await UserRepository.instance.updateNotificationSettings('123', {
  ///   'swaps': false,
  ///   'chats': true,
  /// });
  /// ```
  Future<void> updateNotificationSettings(
    String uid,
    Map<String, bool> settings,
  ) async {
    try {
      print('[UserRepository] Updating notification settings for user: $uid');
      
      // Use transaction to get current settings and merge
      await _firestore.runTransaction((transaction) async {
        final userRef = _usersCollection.doc(uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User document does not exist: $uid');
        }

        // Get current notification settings
        final currentData = userDoc.data() as Map<String, dynamic>;
        final currentSettings = currentData['notificationSettings'] as Map<String, bool>? ??
            {'swaps': true, 'chats': true};

        // Merge with new settings
        final updatedSettings = Map<String, bool>.from(currentSettings);
        updatedSettings.addAll(settings);

        transaction.update(userRef, {
          'notificationSettings': updatedSettings,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      print('[UserRepository] Notification settings updated successfully: $uid');
    } on FirebaseException catch (e) {
      print(
        '[UserRepository] Error updating notification settings for user $uid: '
        '${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      print('[UserRepository] Unexpected error updating notification settings: $e');
      rethrow;
    }
  }

  /// Updates the last login timestamp for a user
  /// 
  /// [uid] - User's unique identifier
  /// 
  /// Sets lastLoginAt to current server timestamp
  /// 
  /// Example:
  /// ```dart
  /// await UserRepository.instance.updateLastLogin('123');
  /// ```
  Future<void> updateLastLogin(String uid) async {
    try {
      print('[UserRepository] Updating last login for user: $uid');
      
      await _usersCollection.doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('[UserRepository] Last login updated successfully: $uid');
    } on FirebaseException catch (e) {
      print('[UserRepository] Error updating last login for user $uid: ${e.code} - ${e.message}');
      
      // If document doesn't exist, don't throw (user might not have profile yet)
      if (e.code == 'not-found') {
        print('[UserRepository] User document not found, skipping last login update: $uid');
        return;
      }
      
      rethrow;
    } catch (e) {
      print('[UserRepository] Unexpected error updating last login: $e');
      rethrow;
    }
  }

  /// Checks if a user document exists in Firestore
  /// 
  /// [uid] - User's unique identifier
  /// 
  /// Returns true if user exists, false otherwise
  /// 
  /// Example:
  /// ```dart
  /// final exists = await UserRepository.instance.userExists('123');
  /// if (exists) {
  ///   print('User exists');
  /// }
  /// ```
  Future<bool> userExists(String uid) async {
    try {
      print('[UserRepository] Checking if user exists: $uid');
      
      final doc = await _usersCollection.doc(uid).get();
      final exists = doc.exists;
      
      print('[UserRepository] User $uid exists: $exists');
      return exists;
    } on FirebaseException catch (e) {
      print('[UserRepository] Error checking if user exists $uid: ${e.code} - ${e.message}');
      // Return false for not found, rethrow for other errors
      if (e.code == 'not-found') {
        return false;
      }
      rethrow;
    } catch (e) {
      print('[UserRepository] Unexpected error checking if user exists: $e');
      rethrow;
    }
  }

  /// Deletes a user document (optional helper method)
  /// 
  /// [uid] - User's unique identifier
  /// 
  /// Use with caution - this permanently deletes the user document
  /// 
  /// Example:
  /// ```dart
  /// await UserRepository.instance.deleteUser('123');
  /// ```
  Future<void> deleteUser(String uid) async {
    try {
      print('[UserRepository] Deleting user: $uid');
      
      await _usersCollection.doc(uid).delete();
      
      print('[UserRepository] User deleted successfully: $uid');
    } on FirebaseException catch (e) {
      print('[UserRepository] Error deleting user $uid: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('[UserRepository] Unexpected error deleting user: $e');
      rethrow;
    }
  }

  /// Gets multiple users by their UIDs
  /// 
  /// [uids] - List of user UIDs to retrieve
  /// 
  /// Returns a list of UserModel instances (may contain nulls for missing users)
  /// 
  /// Example:
  /// ```dart
  /// final users = await UserRepository.instance.getUsers(['123', '456']);
  /// ```
  Future<List<UserModel?>> getUsers(List<String> uids) async {
    try {
      print('[UserRepository] Getting multiple users: ${uids.length}');
      
      if (uids.isEmpty) {
        return [];
      }

      // Use batch get for efficiency
      final docs = await Future.wait(
        uids.map((uid) => _usersCollection.doc(uid).get()),
      );

      final users = docs.map((doc) {
        if (!doc.exists) {
          return null;
        }
        try {
          return UserModel.fromFirestore(doc);
        } catch (e) {
          print('[UserRepository] Error parsing user ${doc.id}: $e');
          return null;
        }
      }).toList();

      print('[UserRepository] Retrieved ${users.where((u) => u != null).length} users');
      return users;
    } on FirebaseException catch (e) {
      print('[UserRepository] Error getting multiple users: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('[UserRepository] Unexpected error getting multiple users: $e');
      rethrow;
    }
  }
}

