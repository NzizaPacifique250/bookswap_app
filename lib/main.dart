import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'data/services/firebase_service.dart';
import 'presentation/screens/auth/welcome_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try to initialize Firebase before running the app
  // If it fails, the app will still start and show an error screen
  try {
    await FirebaseService.instance.initializeFirebase();
  } catch (e) {
    // Firebase initialization failed, but we'll still run the app
    // The MainApp widget will handle showing the error screen
    debugPrint('Firebase initialization failed in main(): $e');
  }
  
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkFirebaseInitialization();
  }

  Future<void> _checkFirebaseInitialization() async {
    // Check if Firebase is already initialized (from main())
    if (FirebaseService.instance.isInitialized) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
      return;
    }

    // If not initialized, try to initialize now
    try {
      final initialized =
          await FirebaseService.instance.initializeFirebase();
      
      if (mounted) {
        setState(() {
          _isInitialized = initialized;
          _isLoading = false;
          if (!initialized) {
            _errorMessage = FirebaseService.instance.initializationError;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookSwapp',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: _isLoading
          ? const FirebaseLoadingScreen()
          : _isInitialized
              ? const AuthWrapper()
              : FirebaseErrorScreen(errorMessage: _errorMessage),
    );
  }
}

/// Auth wrapper that checks authentication state and shows appropriate screen
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        // If user is signed in, show main screen
        if (user != null) {
          return const MainScreen();
        }
        // If user is not signed in, show welcome screen
        return const WelcomeScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.primaryBackground,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      ),
      error: (error, stackTrace) => const WelcomeScreen(),
    );
  }
}

/// Loading screen shown during Firebase initialization
class FirebaseLoadingScreen extends StatelessWidget {
  const FirebaseLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing Firebase...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown when Firebase initialization fails
class FirebaseErrorScreen extends StatelessWidget {
  final String? errorMessage;

  const FirebaseErrorScreen({
    super.key,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final error = errorMessage ??
        FirebaseService.instance.initializationError ??
        'Unknown error occurred';

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Firebase Initialization Failed',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to connect to Firebase services.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  // Retry Firebase initialization
                  final retryInitialized =
                      await FirebaseService.instance.initializeFirebase();
                  if (retryInitialized && context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AuthWrapper(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
