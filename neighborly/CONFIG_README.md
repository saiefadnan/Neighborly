# API Configuration Setup

This project uses configurable backend URLs to support different development environments without exposing IP addresses in the repository.

## Setup for Local Development

### Option 1: Using Local Config File (Recommended)

1. Copy the example config file:

   ```
   cp lib/config/local_config.dart.example lib/config/local_config.dart
   ```

2. Edit `lib/config/local_config.dart` and replace the IP address with your backend server's IP:

   ```dart
   static const String backendUrl = 'http://YOUR_IP_ADDRESS:4000';
   ```

3. Uncomment the import line in `lib/config/api_config.dart`:

   ```dart
   import 'local_config.dart';
   ```

4. Uncomment the LocalConfig usage block in the same file.

### Option 2: Using Environment Variables

Run Flutter with the environment variable:

```bash
flutter run --dart-define=BACKEND_URL=http://YOUR_IP_ADDRESS:4000
```

### Option 3: Quick Local Testing

For quick localhost testing, no setup required. The system defaults to `http://localhost:4000`.

## Files Overview

- `lib/config/api_config.dart` - Main configuration (committed to Git)
- `lib/config/local_config.dart.example` - Template file (committed to Git)
- `lib/config/local_config.dart` - Your local config (ignored by Git)
- `.env.example` - Environment variable template

## Security

- ✅ `local_config.dart` is ignored by Git
- ✅ `.env` files are ignored by Git
- ✅ Only template/example files are committed
- ✅ Actual IP addresses never appear in the repository
