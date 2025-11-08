# BookSwap 📚

A modern Flutter application that connects book lovers to swap and exchange books. BookSwap provides a seamless platform for users to discover, list, and trade books with other readers in their community.

## 📱 Overview

BookSwap is a cross-platform mobile application built with Flutter that enables users to:
- Browse available books from other users
- List their own books for swapping
- Send and receive swap offers
- Chat with book owners in real-time
- Manage their profile and book listings

The app features a beautiful dark theme UI with smooth animations and intuitive navigation, making book swapping an enjoyable experience.

## ✨ Features

### 🔐 Authentication
- **Email/Password Sign Up & Sign In**: Secure authentication with email verification
- **Google Sign In**: Quick authentication using Google accounts (Android & Web)
- **Password Recovery**: Forgot password functionality with email reset links
- **Session Management**: Persistent login sessions with automatic token refresh

<!-- Screenshot placeholder for Authentication -->
<!-- ![Welcome Screen](screenshots/auth/welcome_screen.png) -->
<!-- ![Login Screen](screenshots/auth/login_screen.png) -->
<!-- ![Sign Up Screen](screenshots/auth/signup_screen.png) -->

### 📖 Browse Books
- **Book Discovery**: Browse all available books from other users
- **Book Details**: View comprehensive book information including:
  - Book cover image
  - Title and author
  - Condition status (New, Like New, Good, Used)
  - Owner information
  - Availability status
- **Direct Messaging**: Chat icon on each book card to instantly message the owner
- **Search & Filter**: Find books quickly (coming soon)

<!-- Screenshot placeholder for Browse Screen -->
<!-- ![Browse Screen](screenshots/browse/browse_screen.png) -->
<!-- ![Book Detail Screen](screenshots/browse/book_detail_screen.png) -->

### 📚 My Listings
- **My Books Tab**: 
  - View all your listed books
  - Add new books with image upload or URL
  - Edit existing book listings
  - Delete books from your collection
  - Book count badge showing total listings
- **My Offers Tab**:
  - View all swap requests (sent and received)
  - Visual tags to distinguish "Sent" vs "Received" offers
  - Accept, reject, or cancel swap offers
  - Confirmation dialogs for important actions
  - Real-time status updates

<!-- Screenshot placeholder for My Listings -->
<!-- ![My Listings Screen](screenshots/my_listings/my_listings_screen.png) -->
<!-- ![Add Book Screen](screenshots/my_listings/add_book_screen.png) -->
<!-- ![My Offers Tab](screenshots/my_listings/my_offers_tab.png) -->

### 💬 Real-Time Chat
- **Chat List**: View all your active conversations
- **Chat Details**: 
  - Real-time messaging with other users
  - Message read/unread indicators
  - Timestamp display with smart formatting
  - Date dividers for message organization
  - Auto-scroll to latest messages
- **Unread Count Badge**: 
  - Total unread messages displayed on Chats tab in bottom navigation
  - Individual unread counts per conversation
  - Automatic badge updates when messages are read
- **Message Status**: 
  - Single checkmark (✓) for sent messages
  - Double checkmark (✓✓) for read messages
  - Color-coded indicators for quick status recognition

<!-- Screenshot placeholder for Chat -->
<!-- ![Chats List Screen](screenshots/chats/chats_screen.png) -->
<!-- ![Chat Detail Screen](screenshots/chats/chat_detail_screen.png) -->

### 👤 Profile & Settings
- **User Profile**: 
  - Display logged-in user's name and email
  - Profile avatar with initials
  - Edit profile functionality
- **Edit Profile**: 
  - Update display name
  - Email display (read-only)
  - Profile picture upload (coming soon)
- **Settings**: 
  - Notification preferences
  - Email update preferences
  - About section with app information
  - Logout functionality

<!-- Screenshot placeholder for Settings -->
<!-- ![Settings Screen](screenshots/settings/settings_screen.png) -->
<!-- ![Edit Profile Screen](screenshots/settings/edit_profile_screen.png) -->

### 🔄 Swap Management
- **Swap Offers**: 
  - Send swap requests to book owners
  - Receive swap offers from other users
  - Accept or reject offers with confirmation
  - Cancel your own pending offers
  - Real-time status tracking (Pending, Accepted, Rejected)
- **Swap History**: Track all your swap activities

<!-- Screenshot placeholder for Swap Offers -->
<!-- ![Swap Request Card](screenshots/swaps/swap_request_card.png) -->

## 🏗️ Architecture

### Tech Stack
- **Framework**: Flutter 3.6.1+
- **State Management**: Riverpod 2.6.0
- **Backend**: Firebase
  - Authentication (Firebase Auth)
  - Database (Cloud Firestore)
  - Storage (Firebase Storage)
- **Additional Libraries**:
  - `google_sign_in`: Google authentication
  - `cached_network_image`: Optimized image loading
  - `image_picker`: Image selection and upload
  - `intl`: Date and time formatting
  - `uuid`: Unique identifier generation

### Project Structure
```
lib/
├── core/                    # Core utilities and constants
│   ├── constants/          # Firebase constants
│   ├── theme/              # App theme and colors
│   └── utils/              # Utility functions
├── data/                   # Data layer
│   ├── models/             # Data models (Book, User, Chat, Swap)
│   ├── repositories/       # Firestore operations
│   └── services/           # Firebase services
└── presentation/           # UI layer
    ├── providers/          # Riverpod providers
    ├── screens/            # App screens
    └── widgets/            # Reusable widgets
```

## 🚀 How It Works

### User Flow

1. **Authentication**
   - New users sign up with email/password or Google
   - Existing users sign in to access their account
   - Session persists across app restarts

2. **Browsing Books**
   - Users browse available books on the home screen
   - Tap any book to view detailed information
   - Use the chat icon to message the book owner

3. **Listing Books**
   - Users add books to their collection
   - Upload book cover image or provide image URL
   - Set book condition and details
   - Books appear in "My Books" tab

4. **Swap Offers**
   - Users send swap offers to book owners
   - Owners receive notifications and can accept/reject
   - Both parties can track offer status
   - Offers appear in "My Offers" tab with clear tags

5. **Messaging**
   - Users can chat with book owners directly
   - Real-time message delivery
   - Read receipts show message status
   - Unread count badge on navigation bar

6. **Profile Management**
   - Users can edit their display name
   - View and manage account settings
   - Customize notification preferences

### Data Flow

- **State Management**: Riverpod providers manage app-wide state
- **Real-time Updates**: StreamProviders for live data synchronization
- **Offline Support**: Firestore handles offline data persistence
- **Image Storage**: Firebase Storage for book cover images

## 📸 Screenshots

### Welcome & Authentication
<!-- Add screenshots here -->
<!-- ![Welcome Screen](screenshots/welcome_screen.png) -->
<!-- ![Login Screen](screenshots/login_screen.png) -->
<!-- ![Sign Up Screen](screenshots/signup_screen.png) -->

### Browse & Discovery
<!-- Add screenshots here -->
<!-- ![Browse Screen](screenshots/browse_screen.png) -->
<!-- ![Book Detail Screen](screenshots/book_detail_screen.png) -->

### My Listings
<!-- Add screenshots here -->
<!-- ![My Books Tab](screenshots/my_books_tab.png) -->
<!-- ![Add Book Screen](screenshots/add_book_screen.png) -->
<!-- ![My Offers Tab](screenshots/my_offers_tab.png) -->
<!-- ![Swap Request Card](screenshots/swap_request_card.png) -->

### Chat & Messaging
<!-- Add screenshots here -->
<!-- ![Chats List](screenshots/chats_list.png) -->
<!-- ![Chat Conversation](screenshots/chat_conversation.png) -->

### Profile & Settings
<!-- Add screenshots here -->
<!-- ![Settings Screen](screenshots/settings_screen.png) -->
<!-- ![Edit Profile](screenshots/edit_profile.png) -->

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK 3.6.1 or higher
- Dart SDK (included with Flutter)
- Firebase project with:
  - Authentication enabled (Email/Password & Google)
  - Cloud Firestore database
  - Firebase Storage
  - iOS/Android/Web apps configured

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/NzizaPacifique250/bookswap_app
   cd bookswapp_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Configure Firebase for your platforms

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication:
   - Email/Password provider
   - Google Sign-In provider
3. Create Firestore database
4. Set up Firebase Storage
5. Add your platform apps (Android/iOS/Web)
6. Download configuration files and add to project

## 📋 Features in Detail

### Book Management
- **Add Books**: Upload cover images or use image URLs
- **Edit Books**: Update title, author, and condition
- **Delete Books**: Remove books from your collection
- **Status Tracking**: Books can be Available, Pending, or Swapped

### Swap System
- **Send Offers**: Request to swap with another user
- **Receive Offers**: Get notified of incoming swap requests
- **Status Management**: Track offer status in real-time
- **Confirmation Dialogs**: Prevent accidental actions

### Chat System
- **Real-time Messaging**: Instant message delivery
- **Read Receipts**: Know when your messages are read
- **Unread Tracking**: Never miss a message
- **Chat History**: Persistent message storage

### User Experience
- **Dark Theme**: Easy on the eyes with modern design
- **Smooth Animations**: Polished UI transitions
- **Bottom Navigation**: Quick access to main features
- **Loading States**: Clear feedback during operations
- **Error Handling**: User-friendly error messages

## 🔒 Security & Privacy

- **Firebase Authentication**: Secure user authentication
- **Firestore Security Rules**: Data access control
- **Storage Security**: Protected image uploads
- **User Data Privacy**: Personal information protection

## 🚧 Future Enhancements

- [ ] Book search and filtering
- [ ] Push notifications for swaps and messages
- [ ] Book recommendations
- [ ] User ratings and reviews
- [ ] Swap history tracking
- [ ] Book wishlist feature
- [ ] Location-based book discovery
- [ ] Profile picture upload

## 📄 License

This project is licensed under the MIT License.

## 👥 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

**Built with ❤️ using Flutter and Firebase**

