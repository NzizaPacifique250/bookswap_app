import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

/// Edit profile screen for updating user information
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize with current user's display name after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserAsync = ref.read(currentUserProvider);
      currentUserAsync.whenData((user) {
        if (user != null && _nameController.text.isEmpty) {
          _nameController.text = user.displayName ?? '';
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Handle saving profile
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = await currentUserAsync.value;

    if (currentUser == null) {
      SnackbarUtils.showErrorSnackbar(
        context,
        'User not found. Please sign in again.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final newDisplayName = _nameController.text.trim();

      // Update in Firebase Auth
      await ref.read(authNotifierProvider.notifier).updateDisplayName(newDisplayName);

      // Update in Firestore if user document exists
      final userNotifier = ref.read(userNotifierProvider.notifier);
      await userNotifier.updateDisplayName(currentUser.uid, newDisplayName);

      if (mounted) {
        SnackbarUtils.showSuccessSnackbar(
          context,
          'Profile updated successfully',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Failed to update profile: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.accent,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _handleSave,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: currentUserAsync.when(
        data: (currentUser) {
          if (currentUser == null) {
            return const Center(
              child: Text(
                'User not found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          // Get UserModel for more complete user info
          final userModelAsync = ref.watch(currentUserModelProvider(currentUser.uid));
          
          return userModelAsync.when(
            data: (userModel) {
              // Initialize controller with current name if not already set
              final displayName = userModel?.displayName ?? 
                                currentUser.displayName ?? 
                                currentUser.email?.split('@').first ?? 
                                '';
              if (_nameController.text.isEmpty && displayName.isNotEmpty) {
                _nameController.text = displayName;
              }
              
              return _buildEditForm(currentUser, userModel);
            },
            loading: () => _buildEditForm(currentUser, null),
            error: (error, stackTrace) => _buildEditForm(currentUser, null),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
        error: (error, stackTrace) => const Center(
          child: Text(
            'Error loading profile',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm(dynamic currentUser, dynamic userModel) {
    // Initialize controller with current name if not already set
    final displayName = userModel?.displayName ?? 
                       currentUser.displayName ?? 
                       currentUser.email?.split('@').first ?? 
                       '';
    if (_nameController.text.isEmpty && displayName.isNotEmpty) {
      _nameController.text = displayName;
    }

    final avatarInitial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (currentUser.email?.isNotEmpty == true 
            ? currentUser.email![0].toUpperCase() 
            : 'U');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      avatarInitial,
                      style: const TextStyle(
                        color: AppColors.primaryBackground,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Profile Picture',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      SnackbarUtils.showInfoSnackbar(
                        context,
                        'Profile picture upload coming soon',
                      );
                    },
                    child: const Text(
                      'Change Photo',
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Name field
            Text(
              'Display Name',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                if (value.trim().length > 50) {
                  return 'Name must be less than 50 characters';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            // Email field (read-only)
            Text(
              'Email',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Text(
                currentUser.email ?? 'No email',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Email cannot be changed',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

