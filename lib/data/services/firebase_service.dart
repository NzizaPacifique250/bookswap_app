import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../firebase_options.dart';

/// Firebase service singleton for managing Firebase initialization and instances
class FirebaseService {
  // Private constructor
  FirebaseService._();

  // Singleton instance
  static FirebaseService? _instance;

  // Firebase instances
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseStorage? _storage;

  // Initialization status
  bool _isInitialized = false;
  String? _initializationError;

  /// Get singleton instance
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  /// Initialize Firebase
  /// Returns true if successful, false otherwise
  Future<bool> initializeFirebase() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Initialize Firebase Core with platform-specific options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firebase services
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;

      // Enable persistence for Firestore (optional, but recommended)
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _isInitialized = true;
      _initializationError = null;

      return true;
    } catch (e) {
      _initializationError = e.toString();
      _isInitialized = false;
      return false;
    }
  }

  /// Get FirebaseAuth instance
  /// Throws if Firebase is not initialized
  FirebaseAuth get auth {
    if (!_isInitialized || _auth == null) {
      throw Exception(
        'Firebase not initialized. Call initializeFirebase() first.',
      );
    }
    return _auth!;
  }

  /// Get FirebaseFirestore instance
  /// Throws if Firebase is not initialized
  FirebaseFirestore get firestore {
    if (!_isInitialized || _firestore == null) {
      throw Exception(
        'Firebase not initialized. Call initializeFirebase() first.',
      );
    }
    return _firestore!;
  }

  /// Get FirebaseStorage instance
  /// Throws if Firebase is not initialized
  FirebaseStorage get storage {
    if (!_isInitialized || _storage == null) {
      throw Exception(
        'Firebase not initialized. Call initializeFirebase() first.',
      );
    }
    return _storage!;
  }

  /// Check if Firebase is initialized
  bool get isInitialized => _isInitialized;

  /// Get initialization error message (if any)
  String? get initializationError => _initializationError;

  /// Reset the service (useful for testing)
  void reset() {
    _auth = null;
    _firestore = null;
    _storage = null;
    _isInitialized = false;
    _initializationError = null;
  }
}

