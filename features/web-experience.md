---
type: Feature
title: Web Landing & Web Dashboard
description: Next.js responsive web application featuring marketing landing page, interactive demo, and full desktop task dashboard.
tags: [web, nextjs, landing, dashboard, responsive]
status: active
last_updated: 2026-10-25
---

# Web Landing & Web Dashboard

## Overview
A web experience matching the mobile application:
- **Landing Page (`/`)**: Product showcase, hero section with cat animation, feature callouts, and download links.
- **Web Dashboard (`/dashboard`)**: Full web-based task management supporting task creation, due dates, priority labels, completion toggles, and status filtering.
- **Authentication**: JWT cookie-based session management seamlessly integrated with the backend API.

## Components & Architecture
- `Web/app/page.tsx` - Marketing landing page.
- `Web/app/dashboard/page.tsx` - Web dashboard interface.
- `Web/components/CatAnimation.tsx` - Canvas-based cat running animation for Web.
- `Web/components/Icons.tsx` - Custom SVG iconography (Coffee, Heart, Google, etc.).
