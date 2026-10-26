---
type: Feature
title: Push Notifications & In-App Alerts (Firebase Cloud Messaging)
description: Cross-platform push notifications via Firebase Admin SDK backend and Flutter FCM client integration with in-app banner alerts.
tags: [notifications, fcm, firebase, reminders, in-app-alerts, friend-requests]
status: active
last_updated: 2026-10-26
---

# Push Notifications & In-App Alerts (FCM)

## Overview
Allows sending task alerts, reminder notifications, and friendship updates directly to user devices via Firebase Cloud Messaging (FCM), alongside instant in-app notification banners when the user is actively using the app.

## Components & Architecture
- **Web Backend**:
  - `Web/lib/firebaseAdmin.ts` - Firebase Admin SDK initialization using service account credentials and `sendPushNotification()` multicast helper with explicit failure logging.
  - `Web/app/api/friends/route.ts` - Sends push notifications with payload data (`type: "friend_request"`) on new incoming requests.
  - `Web/app/api/friends/[id]/route.ts` - Sends push notifications with payload data (`type: "friend_accepted"`) on request acceptances.
  - `Web/app/api/user/fcm-token/route.ts` - Endpoints to register (`POST`) or unregister (`DELETE`) device tokens into `user.fcmTokens`.
- **Mobile (Flutter)**:
  - `app/android/app/src/main/kotlin/com/todocat/app/MainActivity.kt` - Programmatically creates the `todocat_reminders` high-importance Android Notification Channel on app startup.
  - `app/lib/services/fcm_service.dart` - Initializes Firebase, requests notification permissions, persists device tokens locally in `SharedPreferences`, syncs tokens to server on auth/resume, and broadcasts `InAppNotificationPayload` via `onInAppNotification` stream.
  - `app/lib/presentation/widgets/in_app_notification_banner.dart` - Animated floating in-app banner for real-time foreground alerts with direct action button ("View") to jump to Friends tab.
  - `app/lib/presentation/screens/home_screen.dart` - Listens to `onInAppNotification`, runs 25-second background polling for pending incoming requests, and displays in-app banner and bottom bar badges.
  - `app/lib/presentation/screens/home/widgets/home_bottom_bar.dart` - Displays badge count on Friends tab when pending requests exist.
- **Web Frontend**:
  - `Web/app/dashboard/page.tsx` - In-app notification banner for new friend requests, pending requests badge on Friends tab pill, and 25-second polling interval.

## API Contracts
- `POST /api/user/fcm-token`: `{ token: string }` $\rightarrow$ registers token to user account.
- `DELETE /api/user/fcm-token`: `{ token: string }` $\rightarrow$ removes token upon logout.
