# flutter run // to run the app
# php artisan serve // in hungerRush-web/api folder

# HungerRush Mobile

Flutter mobile app connected to a Laravel backend through REST APIs.

## Laravel Connection Setup

1. Start Laravel (example):
```bash
php artisan serve --host=0.0.0.0 --port=8000
```

2. Run Flutter with your backend base URL:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
```

Notes:
- Android emulator can use `http://10.0.2.2:8000`.
- iOS simulator can use `http://127.0.0.1:8000` (if Laravel runs locally).

## Expected API Endpoints

- `POST /api/v1/auth/login`
  - Body: `email`, `password`, `device_name`
- `POST /api/v1/auth/register`
  - Hungry user body: `name`, `email`, `phone`, `password`, `password_confirmation`, `role=customer`, `device_name`
  - Restaurant body: `name` (restaurant name), `email`, `phone`, `password`, `password_confirmation`, `role=restaurant_owner`, `device_name`

The app expects JSON responses and reads:
- `message`
- `data.token` or `data.access_token` (if returned)
- `data.user` (optional object)

## Useful Commands

```bash
flutter pub get
flutter analyze
```
