import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

/// Email verification screen shown after user signup
/// 
/// Informs users to verify their email and provides options to
/// resend verification email or open email app
class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  int _resendCooldown = 0;
  bool _isResending = false;
  bool _isCheckingVerification = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Starts the resend cooldown timer
  void _startCooldown() {
    setState(() {
      _resendCooldown = 60;
    });

    // Cancel existing timer if any
    _cooldownTimer?.cancel();

    // Update countdown every second
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCooldown > 0) {
            _resendCooldown--;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  /// Handles resending verification email
  Future<void> _handleResendEmail() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.sendVerificationEmail();

      if (mounted) {
        SnackbarUtils.showSuccessSnackbar(
          context,
          'Verification email sent successfully!',
        );
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  /// Opens the default email app
  /// 
  /// Note: This is a simplified implementation.
  /// For full functionality, add url_launcher package to pubspec.yaml
  Future<void> _handleOpenEmailApp() async {
    // Show instructions to user
    if (mounted) {
      SnackbarUtils.showInfoSnackbar(
        context,
        'Please check your email app for the verification link',
      );
    }
    
    // TODO: To enable actual email app opening, add url_launcher to pubspec.yaml:
    // url_launcher: ^6.0.0
    // Then uncomment the code below:
    /*
    try {
      final uri = Uri.parse('mailto:');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          SnackbarUtils.showInfoSnackbar(
            context,
            'Please check your email app manually',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Unable to open email app. Please check your email manually.',
        );
      }
    }
    */
  }

  /// Checks if email has been verified
  Future<void> _checkVerification() async {
    setState(() {
      _isCheckingVerification = true;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final isVerified = await authNotifier.checkEmailVerification();

      if (mounted) {
        if (isVerified) {
          SnackbarUtils.showSuccessSnackbar(
            context,
            'Email verified successfully!',
          );
          // Navigate to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                preFilledEmail: widget.email,
              ),
            ),
          );
        } else {
          SnackbarUtils.showInfoSnackbar(
            context,
            'Email not verified yet. Please check your inbox.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Error checking verification status. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  /// Navigates back to login screen
  void _handleBackToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          preFilledEmail: widget.email,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: _handleBackToLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Email Icon with animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Icon(
                    Icons.mark_email_read,
                    size: 120,
                    color: AppColors.accent,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Message with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'We\'ve sent a verification link to',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Email address with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  widget.email,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Instructions with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Please click the link in the email to verify your account. '
                    'You can then sign in to continue.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Resend Email Button with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: (_resendCooldown > 0 || _isResending)
                        ? null
                        : _handleResendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primaryBackground,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppColors.accent.withOpacity(0.6),
                    ),
                    icon: _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryBackground,
                              ),
                            ),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    label: Text(
                      _isResending
                          ? 'Sending...'
                          : _resendCooldown > 0
                              ? 'Resend Email (${_resendCooldown}s)'
                              : 'Resend Email',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Open Email App Button with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _handleOpenEmailApp,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(
                        color: AppColors.accent,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.email, size: 20),
                    label: const Text(
                      'Open Email App',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Check Verification Button with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: TextButton.icon(
                  onPressed: _isCheckingVerification ? null : _checkVerification,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: _isCheckingVerification
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textSecondary,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    _isCheckingVerification
                        ? 'Checking...'
                        : 'I\'ve verified my email',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Back to Login Button with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: TextButton(
                  onPressed: _handleBackToLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textSecondary,
                    ),
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

