# HungerRush Mobile

Flutter mobile app connected to a Laravel backend through REST APIs.

## Laravel Connection Setup

1. Start Laravel (example):
```bash
php artisan serve --host=0.0.0.0 --port=8000
```

2. Run Flutter with your backend base URL:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000 --dart-define=ALLOW_INSECURE_HTTP=true
```

Notes:
- Android emulator can use `http://10.0.2.2:8000`.
- iOS simulator can use `http://127.0.0.1:8000` (if Laravel runs locally).
- Release builds must use HTTPS API URLs. In release mode, insecure HTTP is rejected unless `ALLOW_INSECURE_HTTP=true` is explicitly set.

## Expected API Endpoints

- `POST /api/v1/auth/login`
  - Body: `email`, `password`, `device_name`
- `POST /api/v1/auth/register`
  - Hungry user body: `name`, `email`, `phone`, `password`, `password_confirmation`, `role=customer`, `device_name`
  - Restaurant body: `name` (restaurant name), `email`, `phone`, `password`, `password_confirmation`, `role=restaurant_owner`, `device_name`
- `POST /api/v1/auth/refresh`
  - Body: `refresh_token`, `device_name`

The app expects JSON responses and reads:
- `message`
- `data.token` or `data.access_token` (if returned)
- `data.refresh_token` (optional but required for automatic session refresh)
- `data.user` (optional object)

## Auth and Authorization Behavior

- Successful login now requires an access token in the response.
- Access tokens are persisted securely using `flutter_secure_storage`.
- Refresh tokens are persisted securely when provided by backend.
- App startup restores the saved session and routes authenticated users directly.
- Only restaurant roles are authorized for the current app shell:
  - `restaurant`
  - `restaurant_owner`
  - `restaurant_admin`
  - `vendor`
  - `merchant`
- Unauthorized roles are blocked from entering the restaurant feed.
- Sign out clears the secure session.
- Protected API calls can use `AuthenticatedApiClient`, which automatically:
  - retries once after `401 Unauthorized`
  - refreshes access token with `/api/v1/auth/refresh`
  - persists rotated tokens
  - clears session and throws `AuthSessionExpiredException` when refresh fails

Important backend requirement:
- Authorization must still be enforced server-side for every protected API route.

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
```
