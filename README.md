# flutter run // to run the app
# php artisan serve // in Laravel API folder

# HungerRush Mobile

Flutter mobile app connected to a Laravel backend through REST APIs.

## Laravel Connection Setup

Production API base URL:
```bash
https://hungerrush.site/api
```

The app reads the base URL from `API_BASE_URL` and defaults to the production
HTTPS API.

Run against production:
```bash
flutter run --dart-define=API_BASE_URL=https://hungerrush.site/api
```

Build production Android artifacts:
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://hungerrush.site/api
flutter build appbundle --release --dart-define=API_BASE_URL=https://hungerrush.site/api
```

Local Android emulator development:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api --dart-define=ALLOW_INSECURE_HTTP=true
```

1. Start Laravel locally if needed:
```bash
php artisan serve --host=0.0.0.0 --port=8000
```

Notes:
- Android debug/profile builds allow local cleartext HTTP for development.
- Android release builds do not allow cleartext traffic by default.
- iOS production uses normal HTTPS App Transport Security without SSL bypasses.
- Release builds must use HTTPS API URLs. In release mode, insecure HTTP is rejected unless `ALLOW_INSECURE_HTTP=true` is explicitly set for a non-production local build.

## Expected API Endpoints

- `POST /api/v1/auth/login`
  - Body: `email`, `password`, `device_name`
- `POST /api/v1/auth/register`
  - Hungry user body: `name`, `email`, `phone`, `password`, `password_confirmation`, `role=customer`, `device_name`
  - Restaurant body: `name` (restaurant name), `email`, `phone`, `password`, `password_confirmation`, `role=restaurant_owner`, `device_name`
- `POST /api/v1/auth/refresh`
  - Body: `refresh_token`, `device_name`
- `POST /api/auth/google`
  - Body: `id_token`
- `GET /api/v1/auth/me`
- `POST /api/v1/auth/logout`
- `GET /api/v1/restaurant/profile`
- `GET /api/v1/restaurant/menu/items`
- `GET /api/v1/customer/videos/feed`
- `POST /api/v1/customer/videos/searches`
- `POST /api/v1/customer/videos/{video}/engagements`
- `DELETE /api/v1/customer/videos/{video}/engagements/{type}`
- `GET /api/v1/customer/videos/{video}/comments`
- `POST /api/v1/customer/videos/{video}/comments`
- `GET /api/v1/customer/restaurants/following`
- `POST /api/v1/customer/restaurants/{restaurant}/follow`
- `DELETE /api/v1/customer/restaurants/{restaurant}/follow`

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

## Seeder Test Credentials

If the target database has the Laravel sample seeders loaded, these accounts exist:
- `owner@hungerrush.local` / `password`
- `customer@hungerrush.local` / `password`

These are documented for testing only and are not hardcoded into the app UI.

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
```
