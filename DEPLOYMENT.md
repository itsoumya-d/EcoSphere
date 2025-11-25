# EcoSphere Deployment Guide

## Prerequisites

- Flutter SDK (3.9.2+)
- Firebase CLI installed (`npm install -g firebase-tools`)
- Firebase project created
- Android Studio / Xcode configured
- Google Cloud account (for Firebase)

## Initial Setup

### 1. Firebase Configuration

```bash
# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init

# Select:
# - Firestore
# - Firebase Storage
# - Hosting (optional for web)
# - Functions (optional for backend)
```

### 2. Install Dependencies

```bash
cd /path/to/EcoSphare
flutter pub get
```

### 3. Configure Firebase for Flutter

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure
```

This will:
- Create `firebase_options.dart`
- Register your apps with Firebase
- Configure iOS/Android Firebase SDK

## Deploy Security Rules

### Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Storage Rules
```bash
firebase deploy --only storage
```

### Deploy Indexes
```bash
firebase deploy --only firestore:indexes
```

## Build for Production

### Android

```bash
# Create release build
flutter build apk --release

# Or create App Bundle (recommended for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
# Create release build
flutter build ios --release

# Then open Xcode to archive and submit
open ios/Runner.xcworkspace
```

### Web

```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## Environment Configuration

### Development
- Use `lib/firebase_options_dev.dart`
- Firebase project: `ecosphere-dev`

### Production
- Use `lib/firebase_options.dart`
- Firebase project: `ecosphere-prod`


## Testing Before Release

### 1. Run Tests
```bash
flutter test
```

### 2. Check for Issues
```bash
flutter analyze
```

### 3. Test on Real Devices
- Android: Multiple devices with different OS versions
- iOS: iPhone and iPad
- Web: Chrome, Safari, Firefox

## App Store Submission

### Google Play Store

1. **Prepare Assets**
   - App icon (512x512 PNG)
   - Feature graphic (1024x500)
   - Screenshots (min 2, max 8)
   - Privacy policy URL
   - app description

2. **Create Release**
   - Go to Google Play Console
   - Create new app
   - Upload app bundle (`.aab`)
   - Fill in store listing
   - Set pricing (Free)
   - Submit for review

### Apple App Store

1. **Prepare Assets**
   - App icon (1024x1024)
   - Screenshots for all device sizes
   - App preview videos (optional)
   - Privacy policy URL

2. **Create Release**
   - Open Xcode
   - Archive app
   - Upload to App Store Connect
   - Fill in app information
   - Submit for review

## Post-Deployment

### 1. Monitor Analytics
```bash
firebase open analytics
```

### 2. Check Crashlytics
```bash
firebase open crashlytics
```

### 3. Monitor Performance
```bash
firebase open performance
```

## Environment Variables

Create `.env` file (DO NOT commit to git):

```env
# Firebase
FIREBASE_API_KEY=your_api_key
FIREBASE_APP_ID=your_app_id
FIREBASE_PROJECT_ID=ecosphere-prod

# Google Maps (if using)
GOOGLE_MAPS_API_KEY=your_maps_key

# Analytics
GOOGLE_ANALYTICS_ID=GA-XXXXX

# Other
APP_VERSION=1.0.0
BUILD_NUMBER=1
```

## Troubleshooting

### Build Fails

```bash
# Clean build
flutter clean
flutter pub get
flutter build apk
```

### Firebase Connection Issues

```bash
# Reconfigure
flutterfire configure --force
```

### Dependency Conflicts

```bash
# Update dependencies
flutter pub upgrade
```

## Continuous Deployment (CI/CD)

### GitHub Actions Example

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter test
    - run: flutter build apk --release
    
    - name: Upload APK
      uses: actions/upload-artifact@v2
      with:
        name: app-release
        path: build/app/outputs/apk/release/app-release.apk
```

## Security Checklist

- [ ] Firestore rules deployed
- [ ] Storage rules deployed
- [ ] API keys secured
- [ ] OAuth credentials configured
- [ ] SSL/HTTPS enabled
- [ ] Rate limiting configured
- [ ] Input validation implemented
- [ ] Privacy policy published
- [ ] Terms of service published

## Performance Optimization

- [ ] Images optimized and compressed
- [ ] Lazy loading implemented
- [ ] Pagination for large lists
- [ ] Caching enabled
- [ ] Code splitting (web)
- [ ] Tree shaking enabled

## Monitoring

### Key Metrics to Track
- Daily Active Users (DAU)
- Monthly Active Users (MAU)
- Average session duration
- Retention rate
- Crash-free rate
- Activities logged per user
- Challenges completed
- Social engagement rate

## Support

For deployment issues:
- Email: dev@ecosphere.app
- Documentation: https://ecosphere.app/docs
- GitHub Issues: https://github.com/ecosphere/app/issues
