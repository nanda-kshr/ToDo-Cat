---
type: Feature
title: Push Notifications (Firebase Cloud Messaging)
description: Cross-platform push notifications via Firebase Admin SDK backend and Flutter FCM client integration.
tags: [notifications, fcm, firebase, reminders]
status: active
last_updated: 2026-10-25
---

# Push Notifications (FCM)

## Overview
Allows sending task alerts, reminder notifications, and friendship updates directly to user devices via Firebase Cloud Messaging (FCM).

## Components & Architecture
- **Web Backend**:
  - `Web/lib/firebaseAdmin.ts` - Firebase Admin SDK initialization using service account credentials and `sendPushNotification()` helper.
  - `Web/app/api/user/fcm-token/route.ts` - Endpoints to register (`POST`) or unregister (`DELETE`) device tokens into `user.fcmTokens`.
- **Mobile (Flutter)**:
  - `app/lib/services/fcm_service.dart` - Initializes Firebase, requests notification permissions, registers device tokens, and listens for foreground and background events.
  - `app/android/app/google-services.json` - Google Services configuration for Android client.

## API Contracts
- `POST /api/user/fcm-token`: `{ token: string }` $\rightarrow$ registers token to user account.
- `DELETE /api/user/fcm-token`: `{ token: string }` $\rightarrow$ removes token upon logout.
