import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/book_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';

/// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = 0;
    double startY = 0;

    // Top border
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + dashWidth, startY),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Right border
    startX = size.width;
    startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    // Bottom border
    startX = 0;
    startY = size.height;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + dashWidth, startY),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Left border
    startX = 0;
    startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Add/Edit book screen matching the "Post a Book" design
/// 
/// Handles both add and edit modes with exact styling from screenshot
class AddEditBookScreen extends ConsumerStatefulWidget {
  final BookModel? book;

  const AddEditBookScreen({
    super.key,
    this.book,
  });

  @override
  ConsumerState<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends ConsumerState<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _swapForController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _titleFocusNode = FocusNode();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes; // Store bytes for mobile preview
  BookCondition? _selectedCondition;
  bool _isSaving = false;
  bool _useImageUrl = false; // Toggle between URL and file upload
  bool _hasChanges = false; // Track if form has been modified

  bool get _isEditMode => widget.book != null;

  @override
  void initState() {
    super.initState();
    
    // Prefill form in edit mode
    if (_isEditMode) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _selectedCondition = widget.book!.condition;
      // Note: Swap For field doesn't exist in BookModel yet
      // This can be added later if needed
    } else {
      // Auto-focus on title field in add mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }
    
    // Add listeners to track changes
    _titleController.addListener(_markAsChanged);
    _authorController.addListener(_markAsChanged);
    _swapForController.addListener(_markAsChanged);
    _imageUrlController.addListener(_markAsChanged);
  }
  
  /// Mark form as changed
  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_markAsChanged);
    _authorController.removeListener(_markAsChanged);
    _swapForController.removeListener(_markAsChanged);
    _imageUrlController.removeListener(_markAsChanged);
    _titleController.dispose();
    _authorController.dispose();
    _swapForController.dispose();
    _imageUrlController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }
  
  /// Handle back button - confirm if there are unsaved changes
  Future<bool> _onWillPop() async {
    if (!_hasChanges || _isSaving) {
      return true;
    }
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Discard Changes?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return shouldPop ?? false;
  }

  /// Builds image preview widget
  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return const SizedBox.shrink();
    }

    if (kIsWeb) {
      // For web, use Image.network with the path
      return Image.network(
        _selectedImage!.path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.image_not_supported,
            color: AppColors.textSecondary,
            size: 48,
          ),
        ),
      );
    } else {
      // For mobile, use Image.memory with bytes (works on both platforms)
      if (_selectedImageBytes != null) {
        return Image.memory(
          _selectedImageBytes!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              Icons.image_not_supported,
              color: AppColors.textSecondary,
              size: 48,
            ),
          ),
        );
      } else {
        // Show loading indicator while bytes are being loaded
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        );
      }
    }
  }

  /// Handles image picker
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Show bottom sheet with options
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: AppColors.cardBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.accent,
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.accent,
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image; // XFile works on both web and mobile
          _selectedImageBytes = null; // Reset bytes, will load on demand
          _hasChanges = true; // Mark as changed
        });
        
        // For mobile, preload bytes for Image.memory
        if (!kIsWeb) {
          try {
            final bytes = await image.readAsBytes();
            if (mounted) {
              setState(() {
                _selectedImageBytes = bytes;
              });
            }
          } catch (e) {
            print('Error loading image bytes: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Error picking image: ${e.toString()}',
        );
      }
    }
  }

  /// Handles form submission
  Future<void> _handlePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate condition
    if (_selectedCondition == null) {
      SnackbarUtils.showErrorSnackbar(
        context,
        'Please select a condition',
      );
      return;
    }

    // Check image in add mode - either URL or file must be provided
    if (!_isEditMode) {
      if (_useImageUrl) {
        // If using URL, validate it's not empty
        if (_imageUrlController.text.trim().isEmpty) {
          SnackbarUtils.showErrorSnackbar(
            context,
            'Please enter an image URL',
          );
          return;
        }
        // Validate URL format
        final urlPattern = RegExp(
          r'^https?://.+\.(jpg|jpeg|png|gif|webp)(\?.*)?$',
          caseSensitive: false,
        );
        if (!urlPattern.hasMatch(_imageUrlController.text.trim())) {
          SnackbarUtils.showErrorSnackbar(
            context,
            'Please enter a valid image URL (must start with http:// or https:// and end with .jpg, .jpeg, .png, .gif, or .webp)',
          );
          return;
        }
      } else {
        // If using file upload, check file is selected
        if (_selectedImage == null) {
          SnackbarUtils.showErrorSnackbar(
            context,
            'Please select a book cover image',
          );
          return;
        }
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = await ref.read(currentUserProvider.future);

      if (currentUser == null) {
        throw Exception('You must be signed in to post books');
      }

      final bookNotifier = ref.read(bookNotifierProvider.notifier);

      if (_isEditMode) {
        // Edit mode - update existing book
        final updates = <String, dynamic>{};

        if (_titleController.text.trim() != widget.book!.title) {
          updates['title'] = _titleController.text.trim();
        }
        if (_authorController.text.trim() != widget.book!.author) {
          updates['author'] = _authorController.text.trim();
        }
        if (_selectedCondition != widget.book!.condition) {
          updates['condition'] = _selectedCondition!.toFirestoreValue();
        }

        if (updates.isNotEmpty) {
          await bookNotifier.updateBook(widget.book!.id, updates);
        }

        // Handle image update if new image selected
        if (_selectedImage != null) {
          // TODO: Implement image update in repository
          SnackbarUtils.showInfoSnackbar(
            context,
            'Image update will be available soon',
          );
        }

        if (mounted) {
          SnackbarUtils.showSuccessSnackbar(
            context,
            'Book updated successfully!',
          );
          Navigator.of(context).pop();
        }
      } else {
        // Add mode - create new book
        await bookNotifier.addBook(
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          condition: _selectedCondition!.toFirestoreValue(),
          imageFile: _useImageUrl ? null : _selectedImage,
          imageUrl: _useImageUrl ? _imageUrlController.text.trim() : null,
          ownerId: currentUser.uid,
          ownerName: currentUser.displayName ?? 'Unknown',
          ownerEmail: currentUser.email ?? '',
        );

        if (mounted) {
          SnackbarUtils.showSuccessSnackbar(
            context,
            'Book posted successfully!',
          );
          
          // Clear form on successful add
          _titleController.clear();
          _authorController.clear();
          _swapForController.clear();
          _imageUrlController.clear();
          setState(() {
            _selectedImage = null;
            _selectedImageBytes = null;
            _selectedCondition = null;
            _hasChanges = false;
          });
          
          Navigator.of(context).pop();
        }
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
          _isSaving = false;
        });
      }
    }
  }

  /// Get condition icon
  IconData _getConditionIcon(BookCondition condition) {
    switch (condition) {
      case BookCondition.newBook:
        return Icons.auto_awesome;
      case BookCondition.likeNew:
        return Icons.star;
      case BookCondition.good:
        return Icons.thumb_up;
      case BookCondition.used:
        return Icons.book;
    }
  }
  
  /// Get condition label
  String _getConditionLabel(BookCondition condition) {
    switch (condition) {
      case BookCondition.newBook:
        return 'New';
      case BookCondition.likeNew:
        return 'Like New';
      case BookCondition.good:
        return 'Good';
      case BookCondition.used:
        return 'Used';
    }
  }
  
  /// Get condition color
  Color _getConditionColor(BookCondition condition) {
    switch (condition) {
      case BookCondition.newBook:
        return const Color(0xFF4CAF50); // Green
      case BookCondition.likeNew:
        return const Color(0xFF4A9FF5); // Blue
      case BookCondition.good:
        return const Color(0xFFFF9800); // Orange
      case BookCondition.used:
        return const Color(0xFF9E9E9E); // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookNotifierProvider);
    final isLoading = _isSaving || bookState.isLoading;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBackground,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.accent, // Golden yellow back button
            ),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            _isEditMode ? 'Edit Book' : 'Post a Book',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Image Source Toggle
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: isLoading ? null : () {
                              setState(() {
                                _useImageUrl = false;
                                _imageUrlController.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_useImageUrl ? AppColors.accent : AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !_useImageUrl ? AppColors.accent : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Upload Image',
                                  style: TextStyle(
                                    color: !_useImageUrl ? AppColors.primaryBackground : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: isLoading ? null : () {
                              setState(() {
                                _useImageUrl = true;
                                _selectedImage = null;
                                _selectedImageBytes = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _useImageUrl ? AppColors.accent : AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _useImageUrl ? AppColors.accent : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Image URL',
                                  style: TextStyle(
                                    color: _useImageUrl ? AppColors.primaryBackground : AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Image URL Field (shown when _useImageUrl is true)
                    if (_useImageUrl) ...[
                      const Text(
                        'Image URL',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 56,
                        child: TextFormField(
                          controller: _imageUrlController,
                          enabled: !isLoading,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.url,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'https://example.com/book-cover.jpg',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                            filled: true,
                            fillColor: AppColors.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.accent,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (_useImageUrl && (value == null || value.trim().isEmpty)) {
                              return 'Please enter an image URL';
                            }
                            if (_useImageUrl && value != null && value.trim().isNotEmpty) {
                              final urlPattern = RegExp(
                                r'^https?://.+\.(jpg|jpeg|png|gif|webp)(\?.*)?$',
                                caseSensitive: false,
                              );
                              if (!urlPattern.hasMatch(value.trim())) {
                                return 'Please enter a valid image URL';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Image Picker Card (shown when _useImageUrl is false)
                    if (!_useImageUrl) ...[
                      GestureDetector(
                        onTap: isLoading ? null : _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: _selectedImage != null || 
                                    (_isEditMode && widget.book?.imageUrl.isNotEmpty == true)
                                ? null
                                : Border.all(
                                    color: AppColors.border,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _buildImagePreview(),
                                )
                              : _isEditMode && widget.book!.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        widget.book!.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: AppColors.textSecondary,
                                            size: 48,
                                          ),
                                        ),
                                      ),
                                    )
                                  : CustomPaint(
                                      painter: DashedBorderPainter(),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 48,
                                            color: AppColors.textSecondary,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Add Book Cover',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Book Title Field
                    const Text(
                      'Book Title',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: TextFormField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Enter book title',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.accent,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: Validators.validateBookTitle,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Author Field
                    const Text(
                      'Author',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: TextFormField(
                        controller: _authorController,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.name,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Enter author name',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.accent,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: Validators.validateAuthor,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Swap For Field
                    const Text(
                      'Swap For',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: TextFormField(
                        controller: _swapForController,
                        enabled: !isLoading,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'What book do you want in exchange?',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.accent,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          // Optional field, but if provided, should not be empty
                          if (value != null && value.trim().isNotEmpty && value.trim().length < 2) {
                            return 'Swap For must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Condition Dropdown
                    const Text(
                      'Condition',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: DropdownButtonFormField<BookCondition>(
                        value: _selectedCondition,
                        decoration: InputDecoration(
                          hintText: 'Select condition',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          filled: true,
                          fillColor: AppColors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.accent,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        dropdownColor: AppColors.cardBackground,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.textSecondary,
                        ),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        items: BookCondition.values.map((condition) {
                          final color = _getConditionColor(condition);
                          return DropdownMenuItem<BookCondition>(
                            value: condition,
                            child: Row(
                              children: [
                                Icon(
                                  _getConditionIcon(condition),
                                  color: color,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _getConditionLabel(condition),
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedCondition = value;
                                  _hasChanges = true;
                                });
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a condition';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Post Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handlePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primaryBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppColors.accent.withOpacity(0.6),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBackground,
                            ),
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Save Changes' : 'Post',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
