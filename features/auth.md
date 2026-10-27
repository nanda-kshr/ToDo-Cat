---
type: Feature
title: Authentication & User Profile
description: Dual authentication supporting email/password with JWT, Google OAuth 2.0, and rate-limited dual Password Reset via OTP and Link.
tags: [auth, jwt, oauth, google-signin, security, password-reset, otp, rate-limiting]
status: active
last_updated: 2026-10-25
---

# Authentication & User Profile

## Overview
TodoCat provides secure authentication for both Web and Mobile platforms:
- **Email/Password**: Standard signup and login with hashed passwords (`bcryptjs`) and JWT access + refresh tokens.
- **Google OAuth 2.0**: Native Google Sign-In on mobile passing `idToken` to `/api/auth/google`, and web-based OAuth callback. Automatically saves and updates the user's Google profile picture (`avatar`), rendering it in the header and profile screen on both mobile and web (using `referrerPolicy="no-referrer"` to prevent Google image 403 blocks).
- **Session Continuity (RFC 6819 Production Standard)**:
  - **Token Lifespans**: 24-hour JWT access tokens paired with 30-day sliding refresh tokens.
  - **Grace-Window Rotation**: Refresh tokens rotate on every refresh with a 60-second grace window in MongoDB (`user.rotatedTokens`), allowing concurrent/parallel requests across screens or tabs to succeed without revoking the session.
  - **Single-Flight Proactive Refresh**: Mobile client monitors the access token expiration (`exp`) and pre-emptively refreshes if within 90 seconds of expiry before dispatching requests.
  - **Transient Network Fault Isolation**: Tokens are only cleared when `/api/auth/refresh` explicitly responds with 401/403 (revoked/expired). Network timeouts, DNS issues, or 5xx server errors do not log the user out.
- **Password Reset (Dual Flow - Link & OTP)**:
  - Users request a reset code with their email.
  - A branded email is sent via SMTP containing both a 6-digit OTP code and a one-click reset link (15-minute expiration).
  - Web users can reset directly via `/reset-password?token=...` or via OTP.
  - Mobile app users can reset within the app via OTP modal.
  - **Rate Limiting**:
    - Password reset: IP-based rate limiting (max 5 requests / 15m) and email throttling (1 request / 60s), plus max 5 OTP failed attempts before lockout.
    - Login: IP-based rate limiting (max 10 attempts / 15m) preventing brute-force password guessing.
    - Registration: IP-based rate limiting (max 5 new registrations / hour) preventing bot account spam.
    - All existing sessions are revoked upon reset.

## Components & Architecture
- **Web Backend**:
  - `Web/app/api/auth/login/route.ts` - Email/password login.
  - `Web/app/api/auth/register/route.ts` - New user registration.
  - `Web/app/api/auth/google/route.ts` - Google ID token verification.
  - `Web/app/api/auth/forgot-password/route.ts` - Request reset OTP and link with rate limiting.
  - `Web/app/api/auth/reset-password/route.ts` - Verify OTP or link token and update password.
  - `Web/lib/rateLimit.ts` - In-memory sliding window rate limiter.
  - `Web/lib/email.ts` - SMTP email dispatcher with branded reset templates.
  - `Web/app/reset-password/page.tsx` - Responsive Next.js password reset page.
  - `Web/models/User.ts` - User schema including `resetPasswordToken`, `resetPasswordOtp`, `resetPasswordExpires`, `resetPasswordAttempts`.
- **Mobile (Flutter)**:
  - `app/lib/presentation/screens/login/widgets/forgot_password_dialog.dart` - In-app OTP reset modal.
  - `app/lib/presentation/screens/login_screen.dart` - "Forgot password?" trigger on login screen.
  - `app/lib/services/api_service.dart` - `requestPasswordReset()`, `resetPasswordWithOtp()`.
