/// Comprehensive form validation utilities
class Validators {
  Validators._(); // Private constructor to prevent instantiation

  // Email validation regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Password validation regex patterns
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _numberRegex = RegExp(r'[0-9]');

  /// Validates email format
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    // Trim whitespace
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return 'Email cannot be empty';
    }

    if (!_emailRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid email address';
    }

    return null; // Valid
  }

  /// Validates password strength
  /// Requirements: Minimum 8 characters, at least 1 uppercase, 1 lowercase, 1 number
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // Check minimum length
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // Check for uppercase letter
    if (!_uppercaseRegex.hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for lowercase letter
    if (!_lowercaseRegex.hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for number
    if (!_numberRegex.hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null; // Valid
  }

  /// Validates that a required field is not empty
  /// Returns null if valid, error message if invalid
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    // Trim and check if empty after trimming
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return '$fieldName cannot be empty';
    }

    return null; // Valid
  }

  /// Validates book title
  /// Requirements: Minimum 2 characters
  /// Returns null if valid, error message if invalid
  static String? validateBookTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Book title is required';
    }

    // Trim whitespace
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return 'Book title cannot be empty';
    }

    if (trimmedValue.length < 2) {
      return 'Book title must be at least 2 characters long';
    }

    return null; // Valid
  }

  /// Validates author name
  /// Requirements: Minimum 2 characters
  /// Returns null if valid, error message if invalid
  static String? validateAuthor(String? value) {
    if (value == null || value.isEmpty) {
      return 'Author name is required';
    }

    // Trim whitespace
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      return 'Author name cannot be empty';
    }

    if (trimmedValue.length < 2) {
      return 'Author name must be at least 2 characters long';
    }

    return null; // Valid
  }

  /// Validates phone number (optional helper)
  /// Returns null if valid, error message if invalid
  static String? validatePhoneNumber(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      if (required) {
        return 'Phone number is required';
      }
      return null; // Optional field
    }

    // Remove common phone number formatting characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it contains only digits and has reasonable length
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null; // Valid
  }

  /// Validates ISBN (optional helper)
  /// Returns null if valid, error message if invalid
  static String? validateISBN(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      if (required) {
        return 'ISBN is required';
      }
      return null; // Optional field
    }

    // Remove hyphens and spaces
    final cleaned = value.replaceAll(RegExp(r'[-\s]'), '');

    // ISBN-10 or ISBN-13 validation
    if (cleaned.length != 10 && cleaned.length != 13) {
      return 'ISBN must be 10 or 13 digits long';
    }

    // Check if it contains only digits (ISBN-13) or digits with possible X (ISBN-10)
    if (!RegExp(r'^[\dX]+$').hasMatch(cleaned)) {
      return 'ISBN can only contain numbers and X';
    }

    return null; // Valid
  }

  /// Validates price (optional helper)
  /// Returns null if valid, error message if invalid
  static String? validatePrice(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      if (required) {
        return 'Price is required';
      }
      return null; // Optional field
    }

    // Try to parse as double
    final price = double.tryParse(value.replaceAll(',', ''));

    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    return null; // Valid
  }

  /// Validates confirmation password
  /// Returns null if valid, error message if invalid
  static String? validateConfirmPassword(
    String? value,
    String? password,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null; // Valid
  }

  /// Validates minimum length
  /// Returns null if valid, error message if invalid
  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }

    return null; // Valid
  }

  /// Validates maximum length
  /// Returns null if valid, error message if invalid
  static String? validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (value.length > maxLength) {
      return '$fieldName must be no more than $maxLength characters long';
    }

    return null; // Valid
  }
}

