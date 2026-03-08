# 🖍️ Wonder Crayon

> **AI-Powered Children's Storybook Creator**

A Flutter web app that lets users craft personalized children's stories page by page, choose an art style, and watch AI-generated illustrations bring their words to life — all backed by Firebase for real user accounts and cloud-synced data.

[![Live Demo](https://img.shields.io/badge/🔗_Live_Demo-GitHub_Pages-blue?style=for-the-badge)](https://kibo-heavenly.github.io/wonder-crayon/)
[![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth_%2B_Firestore-FFCA28?style=flat-square&logo=firebase)](https://firebase.google.com)
[![AI](https://img.shields.io/badge/AI-Pollinations_%2B_HuggingFace-9B59B6?style=flat-square)](https://pollinations.ai)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?style=flat-square&logo=githubactions)](https://github.com/KIBO-Heavenly/wonder-crayon/actions)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📝 **Story Authoring** | Write text for each page individually with a guided flow |
| 🎨 **AI Illustrations** | Generates unique artwork per page via Pollinations.ai + HuggingFace fallback |
| 🖌️ **Art Styles** | Watercolor, Comic Book, Oil Painting, Claymation |
| 🔐 **Firebase Auth** | Real email/password accounts — share books across devices |
| ☁️ **Cloud Firestore** | User preferences and terms acceptance synced to the cloud |
| 💾 **Offline Storage** | Books saved locally with Hive for instant access |
| 📖 **Page-Turn Reader** | Swipe or use arrow keys to flip through your storybook |
| 🌙 **Dark Mode** | System-aware theme toggle in settings |
| ✨ **Particle Backgrounds** | Animated visual effects throughout the UI |
| 📱 **Mobile-First Web** | Phone frame wrapper for a polished GitHub Pages demo |

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.29+ (Dart) — single codebase for Web, iOS, Android |
| **State Management** | Provider (ChangeNotifier pattern) |
| **Authentication** | Firebase Auth (email/password) |
| **Cloud Database** | Cloud Firestore |
| **Local Storage** | Hive + SharedPreferences |
| **AI — Text** | Pollinations.ai text API (OpenAI, Gemini, Mistral models) |
| **AI — Images** | Pollinations.ai image API (Flux models) + HuggingFace Inference fallback |
| **CI/CD** | GitHub Actions → GitHub Pages |
| **UI** | Google Fonts, Animated Backgrounds, Material 3 |

---

## 🚀 Live Demo

👉 **[Open Wonder Crayon](https://kibo-heavenly.github.io/wonder-crayon/)**

> The live demo is auto-deployed on every push to `main` via GitHub Actions.

---

## 🛠️ Getting Started (Local Development)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.29+
- [Firebase CLI](https://firebase.google.com/docs/cli) — `npm install -g firebase-tools`
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) — `dart pub global activate flutterfire_cli`
- A Firebase project with **Authentication** (Email/Password) and **Cloud Firestore** enabled

### 1. Clone & Install

```bash
git clone https://github.com/KIBO-Heavenly/wonder-crayon.git
cd wonder-crayon
flutter pub get
```

### 2. Configure Firebase (⚠️ Required — app won't compile without this)

`lib/firebase_options.dart` is **git-ignored** to protect API keys. You must create it locally.

**Option A — Automatic (recommended):**
```bash
firebase login
flutterfire configure
```
This generates `lib/firebase_options.dart` automatically from your Firebase project.

**Option B — Manual:**
```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
```
Then open `lib/firebase_options.dart` and replace every `YOUR_..._HERE` placeholder with your real values from the [Firebase Console](https://console.firebase.google.com/) → Project Settings → Your apps.

### 3. Set Up API Keys

Copy `.env.example` to `.env` and fill in your keys:

```bash
cp .env.example .env
```

| Key | Where to get it |
|-----|----------------|
| `POLLINATIONS_KEY` | [pollinations.ai](https://pollinations.ai) |
| `HF_TOKEN` | [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) |

### 4. Run Locally

```bash
# Web (Chrome)
flutter run -d chrome \
  --dart-define=POLLINATIONS_KEY=pk_your_key \
  --dart-define=HF_TOKEN=hf_your_token

# Android
flutter run \
  --dart-define=POLLINATIONS_KEY=pk_your_key \
  --dart-define=HF_TOKEN=hf_your_token
```

---

## 🔄 CI/CD — GitHub Actions

The project includes a fully automated deployment pipeline:

```
Push to main → Build Flutter Web → Deploy to GitHub Pages
```

### Setup (one-time)

1. **Enable GitHub Pages**: Repo → Settings → Pages → Source → **"GitHub Actions"**
2. **Add Secrets**: Repo → Settings → Secrets and variables → Actions → **New repository secret**

   | Secret Name | Value |
   |-------------|-------|
   | `POLLINATIONS_KEY` | Your Pollinations API key |
   | `HF_TOKEN` | Your HuggingFace token |
   | `FIREBASE_WEB_API_KEY` | Your Firebase web API key (from Firebase Console → Project Settings → Web app) |
   | `FIREBASE_WEB_APP_ID` | Your Firebase web App ID (e.g. `1:123456:web:abc123`) |

3. Push to `main` — the workflow will build and deploy automatically.

---

## 📁 Project Architecture

```
wonder_crayon_v2/
├── lib/
│   ├── main.dart                    # App entry point, Firebase init
│   ├── firebase_options.dart        # ⚠️ Git-ignored — created locally or by CI
│   ├── firebase_options.dart.example # Safe template with placeholders
│   ├── helpers/
│   │   ├── pollinations_ai.dart     # AI text & image generation service
│   │   └── dialogs.dart             # Shared UI dialogs
│   ├── services/
│   │   └── auth_service.dart        # Firebase Auth + Firestore logic
│   ├── models/
│   │   ├── book.dart                # Book & BookPage data models (Hive)
│   │   └── book.g.dart              # Auto-generated Hive type adapters
│   ├── providers/
│   │   ├── book_provider.dart       # Book state management
│   │   └── settings_provider.dart   # App settings (dark mode, etc.)
│   └── screens/
│       ├── splash_screen.dart       # Animated splash screen
│       ├── auth_wrapper.dart        # Auth state routing
│       ├── login_screen.dart        # Sign in
│       ├── register_screen.dart     # Sign up
│       ├── main_menu_screen.dart    # Home hub
│       ├── new_book_screen.dart     # Create & generate storybooks
│       ├── my_books_screen.dart     # Saved books gallery
│       ├── story_book_screen.dart   # Page-turn book reader
│       └── settings_screen.dart     # Preferences
├── assets/                          # Images & logos
├── web/                             # Web entry point & manifest
├── .github/workflows/deploy.yml     # CI/CD pipeline
├── .env.example                     # Template for API keys
├── .gitignore                       # Excludes secrets & build artifacts
└── pubspec.yaml                     # Dependencies
```

---

## 🔐 Security

| Item | Approach |
|------|----------|
| **API Keys** (Pollinations, HuggingFace) | Injected at build time via `--dart-define`. Never committed to source. |
| **Firebase Config** (`firebase_options.dart`) | **Git-ignored.** Never committed. Generated at build time in CI from GitHub Secrets. Locally created via `flutterfire configure` or copied from `.dart.example` template. |
| **google-services.json** | Excluded from git via `.gitignore` |
| **Secrets in CI/CD** | Stored as GitHub encrypted repository secrets. The workflow generates `firebase_options.dart` on the runner, builds, and discards it. |
| **Firestore Rules** | Should be configured to restrict read/write to authenticated users only |

### Recommended Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 📄 License

Copyright © 2025-2026 Wonder Crayon. All rights reserved.
This project is for **educational and portfolio purposes only**. See [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with ❤️ using Flutter, Firebase & AI
</p>
