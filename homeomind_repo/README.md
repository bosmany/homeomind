# HomeoMind

Offline-first homeopathic case-taking app (Flutter, Material 3 "Botanical Green").
Local SQLite storage (web-compatible), 12-section case records, AI remedy
suggestions (OpenAI, key stored in encrypted device storage), zip backup/restore,
follow-up tracking.

## Structure
```
lib/
├── main.dart                 # theme (Fraunces/Inter) + routes
├── models/case_model.dart    # full case schema, JSON + SQLite mapping
├── data/
│   ├── db_helper.dart        # sqflite CRUD, search, zip export/import
│   ├── backup_service.dart   # cross-platform backup download
│   └── ai_service.dart       # OpenAI integration (real, key from Settings)
└── ui/
    ├── ui_dashboard.dart     # search, case list, Instagram bridge card
    ├── ui_case_detail.dart   # view/edit/delete, follow-ups, AI analyze
    └── ui_settings.dart      # secure API key management
```

## Run locally
```bash
flutter create . --platforms web,android    # generates platform folders
flutter pub get
dart run sqflite_common_ffi_web:setup       # required once for web
flutter run -d chrome
```

## Deploy — Option A: GitHub Pages (automatic)
Push to `main`. The included workflow (`.github/workflows/deploy.yml`) builds
and deploys automatically. One-time setup: repo **Settings → Pages → Source:
GitHub Actions**. Live at `https://<username>.github.io/homeomind/`.

## Deploy — Option B: Firebase Hosting
```bash
flutter build web --release
npm install -g firebase-tools
firebase login
firebase init hosting        # public dir: build/web · single-page app: Yes
firebase deploy
```

## Notes
- Web data lives in IndexedDB — clearing browser data erases it. Use ⋮ → Backup.
- AI requires an OpenAI key: ⋮ → Settings → save key (encrypted keystore only).
