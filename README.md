# Football Tactics Manager

Full-stack app for coaches to manage teams, players, tactics, tactical instructions, and training sessions.  
- **Backend:** Laravel 12 + Sanctum API (see `backend/`).  
- **Frontend:** Flutter (mobile/web) hitting the API (see `frontend/`).  
- **Testing/Docs:** Postman collection + environment in `backend/` for quick API checks.

## Prerequisites
- PHP 8.2+, Composer, MySQL (or compatible), Node/NPM (only if building Laravel assets)
- Flutter SDK 3.11+ with Chrome or a device emulator

## Backend setup
```bash
cd backend
composer install
cp .env.example .env          # configure DB creds
php artisan key:generate
php artisan migrate --seed    # seeds Real Madrid 2026 roster, categories, default tactics
php artisan serve             # http://127.0.0.1:8000
```

## Frontend (Flutter) setup
```bash
cd frontend
flutter pub get
flutter config --enable-web   # one-time
flutter run -d chrome --web-browser-flag="--window-size=1024,1366"
# API base URL is hardcoded to http://127.0.0.1:8000/api in lib/services/api_service.dart
```

## Quick API testing (Postman)
Import `backend/postman_collection.json` and `backend/postman_environment.json`, then:
1) Run **Login** to store the token env variable.
2) Call Players/Teams/Tactics endpoints with your IDs.

## Project structure
- `backend/` Laravel API (routes in `routes/api.php`, models/seeders/migrations inside)
- `frontend/` Flutter UI (auth screens, basic dashboard)
- `backend/database/seeders/` seeds Real Madrid CF 2026 + Cristiano Ronaldo, categories, default tactics

## Useful commands
- Refresh DB with seed data: `php artisan migrate:fresh --seed`
- Run Flutter tests: `flutter test`
- Run Laravel tests: `cd backend && php artisan test`
