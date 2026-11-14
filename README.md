<p align="center">
  <img src="app/assets/logo.png" alt="TodoCat Logo" width="190" />
</p>

<h1 align="center">TodoCat</h1>

<p align="center">
  <em>Visual task management powered by animated companion runners that pace with your daily productivity.</em>
</p>

<p align="center">
  <a href="https://github.com/nanda-kshr/ToDo-Cat/releases/latest">
    <img src="https://img.shields.io/github/v/release/nanda-kshr/ToDo-Cat?color=blue&label=Latest%20Release&style=flat-square" alt="Latest Release" />
  </a>
  <a href="https://play.google.com/store/apps/details?id=com.todocat.app">
    <img src="https://img.shields.io/badge/Google_Play-TodoCat-34A853?style=flat-square&logo=google-play&logoColor=white" alt="Google Play Store" />
  </a>
  <a href="https://to-do-cat.vercel.app">
    <img src="https://img.shields.io/badge/Web_App-Live-000000?style=flat-square&logo=vercel&logoColor=white" alt="Web App" />
  </a>
  <a href="https://github.com/nanda-kshr/ToDo-Cat/releases/latest">
    <img src="https://img.shields.io/badge/Platforms-Android%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-6c5ce7?style=flat-square" alt="Supported Platforms" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square" alt="MIT License" />
  </a>
  <a href="https://github.com/nanda-kshr/ToDo-Cat/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/nanda-kshr/ToDo-Cat/release.yml?branch=main&label=Build&style=flat-square" alt="Build Status" />
  </a>
</p>

<p align="center">
  <img src="app/assets/cat_runner.gif" alt="TodoCat Animated Runner" width="96" />
</p>

---

## Overview

**TodoCat** transforms daily task execution into a visual, gamified experience. Inspired by classic system-monitor runners, your productivity completion velocity directly controls a lively animated companion:

- **Active goals pending**: Your companion runs faster as you cross items off your list.
- **All goals completed**: Your companion rests peacefully, providing immediate visual feedback on your daily progress.
- **Multiple companions**: Choose between **Cat**, **Bunny**, and **Axolotl** with light, dark, and auto-contrast themes.
- **Native integrations everywhere**: Floating screen overlays on Android, status menu bar runners on macOS, system tray indicators on Linux, and an accessible Web dashboard.

---

## Downloads & Availability

All desktop installers and APK packages always point dynamically to the **newest available release** without hardcoded version strings.

| Platform | Package Format | Source | Action |
| :--- | :--- | :--- | :--- |
| **Android** | Google Play Store | Official Store | [Get on Google Play](https://play.google.com/store/apps/details?id=com.todocat.app) |
| **Android** | Universal APK | Direct GitHub Release | [Download Latest APK](https://github.com/nanda-kshr/ToDo-Cat/releases/latest) |
| **macOS** | DMG Installer (Apple Silicon & Intel) | Direct GitHub Release | [Download Latest macOS DMG](https://github.com/nanda-kshr/ToDo-Cat/releases/latest) |
| **Linux** | AppImage (x86_64) | Direct GitHub Release | [Download Latest Linux AppImage](https://github.com/nanda-kshr/ToDo-Cat/releases/latest) |
| **Linux** | Standalone Tarball (x86_64) | Direct GitHub Release | [Download Latest Linux Tarball](https://github.com/nanda-kshr/ToDo-Cat/releases/latest) |
| **Web** | Responsive Dashboard / PWA | Vercel Cloud | [Open Web Dashboard](https://to-do-cat.vercel.app) |

---

## Google Play Store (Android)

Install TodoCat directly on Android devices with automated background updates and seamless Google Play Integrity:

- **Store Page**: [TodoCat on Google Play Store](https://play.google.com/store/apps/details?id=com.todocat.app)
- **Package Identifier**: `com.todocat.app`
- **Supported Android Versions**: Android 5.0 (API 21) and newer

### Android Native Features
- **Floating Companion Overlay**: Uses `SYSTEM_ALERT_WINDOW` to place your running cat over any screen. Tap the companion anytime to expand your daily tasks, check items off, or quick-add tasks without switching applications.
- **Home Screen Widgets**: Clean, resizable Android home screen widgets displaying pending items and runner animations.
- **Offline First**: Works with zero network latency; automatically synchronizes when connectivity is restored.

---

## macOS Installation Guide

TodoCat for macOS includes both the full task workspace and a native AppKit status bar companion running directly in your macOS menu bar next to Wi-Fi and Control Center.

### Compatibility
- macOS 11.0 (Big Sur) or later
- Universal binary supporting both Apple Silicon (M1/M2/M3/M4) and Intel Macs

### Step-by-Step Installation
1. **Download the Installer**:
   Grab the latest `.dmg` installer directly from the [GitHub Latest Releases](https://github.com/nanda-kshr/ToDo-Cat/releases/latest) page.

   Alternatively, download the latest macOS release directly via terminal:
   ```bash
   curl -s https://api.github.com/repos/nanda-kshr/ToDo-Cat/releases/latest \
     | grep "browser_download_url.*macos.dmg" \
     | cut -d : -f 2,3 \
     | tr -d \" \
     | xargs curl -LO
   ```

2. **Mount and Install**:
   - Double-click the downloaded `TodoCat-*-macos.dmg` file.
   - Drag **TodoCat.app** into your `/Applications` directory.

3. **First Launch & Security Notice**:
   Because TodoCat is distributed directly via GitHub outside the Mac App Store, macOS Gatekeeper may show a notice on first launch:
   
   - **Method A (Finder)**: Open `/Applications` in Finder, right-click (or Control-click) `TodoCat.app`, select **Open**, and click **Open** in the confirmation dialog. You only need to perform this step once.
   - **Method B (Terminal)**: Remove the quarantine flag:
     ```bash
     xattr -cr /Applications/TodoCat.app
     ```

### macOS Native Menu Bar Companion
- Your companion animates directly in the macOS menu bar (`NSStatusItem`).
- Running speed mirrors your task completion velocity in real time.
- Click the menu bar companion to view quick stats, switch active mascots, or bring the main window forward.

---

## Linux Installation Guide

TodoCat on Linux is distributed as a self-contained **AppImage** (compatible with all major distributions) and as a standalone tarball archive.

### Prerequisites
TodoCat requires GTK 3 and Ayatana AppIndicator for desktop windowing and tray support. Ensure runtime dependencies are installed:

- **Ubuntu / Debian / Linux Mint**:
  ```bash
  sudo apt update && sudo apt install -y libgtk-3-0 libayatana-appindicator3-1
  ```
- **Fedora / RHEL / CentOS**:
  ```bash
  sudo dnf install -y gtk3 libayatana-appindicator
  ```
- **Arch Linux / Manjaro**:
  ```bash
  sudo pacman -S --needed gtk3 libayatana-appindicator
  ```

---

### Method A: AppImage (Recommended)

The AppImage runs out-of-the-box without altering your system directories.

1. **Download Latest AppImage**:
   Download `TodoCat-*-x86_64.AppImage` from [GitHub Latest Releases](https://github.com/nanda-kshr/ToDo-Cat/releases/latest).

   Or fetch the latest release directly with a single terminal command:
   ```bash
   curl -s https://api.github.com/repos/nanda-kshr/ToDo-Cat/releases/latest \
     | grep "browser_download_url.*AppImage" \
     | cut -d : -f 2,3 \
     | tr -d \" \
     | xargs curl -LO
   ```

2. **Make Executable**:
   ```bash
   chmod +x TodoCat-*-x86_64.AppImage
   ```

3. **Run**:
   ```bash
   ./TodoCat-*-x86_64.AppImage
   ```

*(Optional: Use [AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher) or create a desktop shortcut with `app/linux/todocat.desktop` to integrate directly into your desktop application menu).*

---

### Method B: Standalone Tarball

1. **Download and Extract**:
   Download `TodoCat-*-linux-x64.tar.gz` from [GitHub Latest Releases](https://github.com/nanda-kshr/ToDo-Cat/releases/latest).

   ```bash
   mkdir -p ~/todocat
   curl -s https://api.github.com/repos/nanda-kshr/ToDo-Cat/releases/latest \
     | grep "browser_download_url.*linux-x64.tar.gz" \
     | cut -d : -f 2,3 \
     | tr -d \" \
     | xargs curl -LO
   tar -xzf TodoCat-*-linux-x64.tar.gz -C ~/todocat
   ```

2. **Launch**:
   ```bash
   ~/todocat/todocat
   ```

---

## Key Features

- **Pacing Runner Companion**: Speed scales dynamically with your task completion velocity. Choose between Cat, Bunny, or Axolotl in auto, black, or white variants.
- **Android Floating Overlay**: System overlay companion allows you to check off tasks, add new goals, and check progress over any running mobile application.
- **macOS Menu Bar Runner**: Native system menu bar integration mirroring your progress throughout the workday.
- **Android Home Widgets**: Resizable home screen widgets with one-tap completion.
- **Smart Organization**: Categorize tasks by Priority (Low, Medium, High) and Domain (Work, Personal, Study, Health, Shopping, General).
- **Productivity Analytics**: Visual charts tracking weekly velocity, completion distribution, and consistency streaks.
- **100% Offline-First Architecture**: Full local database persistence with background cloud synchronization.
- **Zero Ads & Privacy First**: No ad tracking SDKs, no telemetry selling, and full one-click account and data deletion.

---

## Tech Stack & Architecture

```
todocat/
├── app/                  # Mobile & Desktop Client (Flutter / Dart)
│   ├── android/          # Native Android companion service & widgets
│   ├── macos/            # Native macOS AppKit menu bar companion
│   ├── linux/            # Linux desktop runner & desktop integration
│   └── lib/              # Shared presentation, state, and domain models
├── Web/                  # Web Dashboard & Backend API (Next.js / TypeScript)
│   ├── app/              # Next.js App Router (pages & API routes)
│   ├── components/       # Shared UI components
│   └── public/           # Static assets, runners, and icons
└── features/             # Google Open Knowledge Format (OKF) specification
```

- **Client Application**: Built with Flutter (Dart), utilizing native platform channels for Android floating overlays and macOS AppKit menu bar integration.
- **Web Application & API Server**: Built with Next.js (App Router, TypeScript, Tailwind CSS).
- **Database & Auth**: MongoDB Atlas with JWT session authentication and Google OAuth support.
- **Push Notifications**: Firebase Cloud Messaging (FCM).

---

## Local Development

### Prerequisites
- Flutter SDK (3.10+)
- Node.js (18+) & npm
- Android SDK (API 21+) / Xcode (for macOS)

### Running the Flutter Client
```bash
cd app
flutter pub get
flutter run
```

### Running the Web Dashboard & API
```bash
cd Web
npm install
npm run dev
```

### Running Tests
```bash
# Flutter Client Tests
cd app
flutter test

# Backend API Tests
npm test
```

---

## Legal & Compliance

- **Privacy Policy**: [https://to-do-cat.vercel.app/privacy](https://to-do-cat.vercel.app/privacy)
- **Terms of Service**: [https://to-do-cat.vercel.app/terms](https://to-do-cat.vercel.app/terms)
- **Account Deletion**: [https://to-do-cat.vercel.app/delete-account](https://to-do-cat.vercel.app/delete-account)
- **Developer**: Nandakishore P ([nandakishorep212@gmail.com](mailto:nandakishorep212@gmail.com))
- **Support the Project**: [Buy Me a Coffee](https://buymeacoffee.com/nanda_kshr)

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
