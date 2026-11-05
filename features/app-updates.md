---
type: Feature
title: App Update Notification & Version Management
description: Automatic client-side detection of app updates with Google Play Store redirection and daily reminder postponement.
tags: [update, play-store, versioning, android]
status: active
last_updated: 2026-11-03
---

# App Update Notification & Version Management

## Overview
Keeps TodoCat users up-to-date by checking for newer releases whenever the mobile application starts or resumes from the background:
- **Strict Version Comparison**: Uses semver + build number comparison (`isNewerVersion`). Prompt appears **strictly if the server version/build is greater** than the running app. If the version is equal, older, or untouched, no update prompt appears.
- **Play Store Navigation**: Directly redirects users to `https://play.google.com/store/apps/details?id=com.todocat.app` via external application launch mode.
- **Daily Reminder Postponement**: Selecting "Remind Me Later" suppresses update prompts for the remainder of the calendar day, checking again the next day when the user re-opens the app.
- **Silent Fallback**: Network failures or offline states never show errors or disrupt application flow.

## Architecture & Components
- **Backend API**:
  - `Web/app/api/app-version/route.ts`: Public `GET /api/app-version?platform=android` providing current target version (defaults to active release `1.0.1` and build `5`) and Play Store URL. Overridable via environment variables (`APP_ANDROID_LATEST_VERSION`, `APP_ANDROID_LATEST_BUILD`, `APP_ANDROID_UPDATE_URL`).
- **Mobile (Flutter)**:
  - `app/lib/models/app_version_info.dart`: Model parsing platform version contracts.
  - `app/lib/services/app_update_service.dart`: Compares device version and `buildNumber` from `package_info_plus` using `isNewerVersion`. Manages suppression via `app_update_remind_later_date` in `SharedPreferences`.
  - `app/lib/presentation/widgets/app_update_dialog.dart`: Theme-aware modal with "Update" and "Remind Me Later" actions adhering to zero-emoji and typography rules.
  - `app/lib/presentation/screens/home_screen.dart`: Triggers non-blocking update check on initial load and on lifecycle resume.

## API Contracts
- `GET /api/app-version?platform=android`:
  - Returns `200 OK`:
    ```json
    {
      "platform": "android",
      "latestVersion": "1.0.1",
      "latestBuildNumber": 5,
      "minSupportedVersion": "1.0.0",
      "minSupportedBuildNumber": 1,
      "updateUrl": "https://play.google.com/store/apps/details?id=com.todocat.app"
    }
    ```
  - Returns `400 Bad Request` if platform query param is unsupported.
