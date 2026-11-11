---
type: Feature
title: App Update Notification & Version Management
description: Platform-aware client-side detection of app updates with dynamic redirection (Google Play Store for Android, GitHub Releases for macOS and Linux) and daily reminder postponement.
tags: [update, play-store, github-releases, versioning, android, macos, linux]
status: active
last_updated: 2026-11-11
---

# App Update Notification & Version Management

## Overview
Keeps TodoCat users up-to-date across mobile and desktop environments by checking for newer releases whenever the application starts or resumes:
- **Strict Version Comparison**: Uses semver + build number comparison (`isNewerVersion`). Prompt appears **strictly if the server version/build is greater** than the running app. If the version is equal, older, or untouched, no update prompt appears.
- **Platform-Aware Store Redirection**:
  - **Android**: Redirects users to Google Play Store (`https://play.google.com/store/apps/details?id=com.todocat.app`).
  - **macOS**: Redirects users to GitHub Releases (`https://github.com/nanda-kshr/ToDo-Cat/releases/latest`) to download the `.dmg` installer.
  - **Linux**: Redirects users to GitHub Releases (`https://github.com/nanda-kshr/ToDo-Cat/releases/latest`) to download the `.AppImage` or `.tar.gz` package.
  - **iOS**: Redirects users to Apple App Store (`https://apps.apple.com/app/todocat/id6738900000`).
- **Daily Reminder Postponement**: Selecting "Remind Me Later" suppresses update prompts for the remainder of the calendar day, checking again the next day when the user re-opens the app.
- **Silent Fallback**: Network failures or offline states never show errors or disrupt application flow.

## Architecture & Components
- **Backend API**:
  - `Web/app/api/app-version/route.ts`: Public `GET /api/app-version?platform=<android|ios|macos|linux|web>` providing current target version, build number, and platform-specific update URL.
    - Android: `APP_ANDROID_UPDATE_URL` (default: Play Store).
    - macOS: `APP_MACOS_UPDATE_URL` (default: GitHub Releases latest).
    - Linux: `APP_LINUX_UPDATE_URL` (default: GitHub Releases latest).
- **Client (Flutter)**:
  - `app/lib/models/app_version_info.dart`: Model parsing platform version contracts.
  - `app/lib/services/app_update_service.dart`: Detects OS platform (`Platform.isAndroid`, `Platform.isMacOS`, `Platform.isLinux`, etc.) and fetches the corresponding update metadata from the API. Compares device version and `buildNumber` from `package_info_plus` using `isNewerVersion`. Manages suppression via `app_update_remind_later_date` in `SharedPreferences`.
  - `app/lib/presentation/widgets/app_update_dialog.dart`: Theme-aware modal with "Update" and "Remind Me Later" actions adhering to zero-emoji and typography rules.
  - `app/lib/presentation/screens/home_screen.dart`: Triggers non-blocking update check on initial load and on lifecycle resume.

## API Contracts
- `GET /api/app-version?platform=android`:
  - Returns `200 OK`:
    ```json
    {
      "platform": "android",
      "latestVersion": "1.0.2",
      "latestBuildNumber": 6,
      "minSupportedVersion": "1.0.0",
      "minSupportedBuildNumber": 1,
      "updateUrl": "https://play.google.com/store/apps/details?id=com.todocat.app"
    }
    ```
- `GET /api/app-version?platform=macos`:
  - Returns `200 OK`:
    ```json
    {
      "platform": "macos",
      "latestVersion": "1.0.2",
      "latestBuildNumber": 8,
      "minSupportedVersion": "1.0.0",
      "minSupportedBuildNumber": 1,
      "updateUrl": "https://github.com/nanda-kshr/ToDo-Cat/releases/latest"
    }
    ```
- `GET /api/app-version?platform=linux`:
  - Returns `200 OK`:
    ```json
    {
      "platform": "linux",
      "latestVersion": "1.0.2",
      "latestBuildNumber": 8,
      "minSupportedVersion": "1.0.0",
      "minSupportedBuildNumber": 1,
      "updateUrl": "https://github.com/nanda-kshr/ToDo-Cat/releases/latest"
    }
    ```
- Returns `400 Bad Request` if platform query param is unsupported.
