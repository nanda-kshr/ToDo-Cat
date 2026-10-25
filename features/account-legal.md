---
type: Feature
title: Account Management & Legal Compliance
description: User account deletion flows, privacy policies, and terms of service required for Play Store and web compliance.
tags: [account, compliance, privacy, terms, legal]
status: active
last_updated: 2026-10-25
---

# Account Management & Legal Compliance

## Overview
Ensures complete privacy compliance, GDPR/Play Store account deletion standards, and transparency:
- **Account Deletion**: Dedicated deletion portal at `/delete-account` allowing users to permanently remove their account, profile data, and associated tasks.
- **Privacy Policy**: Hosted at `/privacy` and accessible within the app via `legal_screen.dart`.
- **Terms of Service**: Hosted at `/terms` and embedded in the app.
- **About TodoCat**: App versioning, developer links, and attribution in `about_screen.dart`.

## Components & Architecture
- **Web**:
  - `Web/app/delete-account/page.tsx` - Account deletion request form and automated deletion.
  - `Web/app/privacy/page.tsx` - Privacy policy.
  - `Web/app/terms/page.tsx` - Terms of service.
  - `Web/app/about/page.tsx` - Web about page.
- **Mobile (Flutter)**:
  - `app/lib/presentation/screens/legal_screen.dart` - In-app viewer for Privacy Policy and Terms.
  - `app/lib/presentation/screens/about_screen.dart` - Developer credits and links.
