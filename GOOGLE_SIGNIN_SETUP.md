# Google Sign-In Setup Guide

## Current Configuration

- **Bundle ID**: `com.example.bookswappApp`
- **CLIENT_ID**: `374262604171-cvsp46uiru0oug63e22lo96353c9pu2m.apps.googleusercontent.com`
- **REVERSED_CLIENT_ID**: `com.googleusercontent.apps.374262604171-cvsp46uiru0oug63e22lo96353c9pu2m`

## Fixing "GeneralOAuthFlow" Error

The error "Request details: flowName=GeneralOAuthFlow" means the OAuth client in Firebase/Google Cloud Console is not properly configured for iOS.

### Step 1: Check Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **bookswap-887d4**
3. Go to **Authentication** → **Sign-in method**
4. Click on **Google** provider
5. Make sure it's **Enabled**

### Step 2: Check Google Cloud Console OAuth Clients

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **bookswap-887d4**
3. Navigate to **APIs & Services** → **Credentials**
4. Look for OAuth 2.0 Client IDs

### Step 3: Verify iOS OAuth Client

You need to ensure there's an **iOS** OAuth client (not Web) with:

- **Application type**: iOS
- **Bundle ID**: `com.example.bookswappApp` (must match exactly)
- **No redirect URIs** (iOS doesn't need them)

### Step 4: Create iOS OAuth Client (if missing)

If you don't have an iOS OAuth client:

1. In Google Cloud Console → **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Select **Application type**: **iOS**
4. Enter **Bundle ID**: `com.example.bookswappApp`
5. Click **CREATE**

### Step 5: Update GoogleService-Info.plist (if needed)

If you created a new iOS OAuth client, you'll get a new CLIENT_ID. Update:

1. `ios/Runner/GoogleService-Info.plist` - Update CLIENT_ID
2. `ios/Runner/Info.plist` - Update CFBundleURLSchemes with new REVERSED_CLIENT_ID
3. `lib/data/services/auth_service.dart` - Update clientId for web (if different)

### Step 6: Verify Configuration Files

✅ **ios/Runner/GoogleService-Info.plist** exists
✅ **ios/Runner/Info.plist** has CFBundleURLTypes with REVERSED_CLIENT_ID
✅ **android/app/google-services.json** exists (for Android)
✅ **web/index.html** has google-signin-client_id meta tag

### Step 7: Clean and Rebuild

After making changes:

```bash
# Clean Flutter build
flutter clean

# Get dependencies
flutter pub get

# Rebuild iOS (if on Mac)
cd ios
pod install
cd ..

# Run the app
flutter run
```

## Troubleshooting

### Error: "Storagerelay URI is not allowed for 'NATIVE_IOS' client type"

- **Cause**: Using a Web OAuth client for iOS
- **Fix**: Create/use an iOS OAuth client in Google Cloud Console

### Error: "GeneralOAuthFlow"

- **Cause**: OAuth client not properly configured for iOS
- **Fix**: Follow Steps 1-4 above

### Error: "ClientID not set"

- **Cause**: Missing client ID configuration
- **Fix**: Ensure GoogleService-Info.plist is in ios/Runner/ directory

## Testing

1. **iOS**: Test on a real device (Google Sign-In may not work on simulator)
2. **Android**: Test on emulator or real device
3. **Web**: Test in browser

## Important Notes

- iOS OAuth clients don't need redirect URIs
- Bundle ID must match exactly between Xcode and Firebase Console
- GoogleService-Info.plist must be in `ios/Runner/` directory
- For iOS, don't specify `clientId` in code - it's auto-read from GoogleService-Info.plist

