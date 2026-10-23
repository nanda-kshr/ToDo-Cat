#!/bin/bash
set -e

echo "==> Cloning Flutter SDK..."
rm -rf flutter
git clone https://github.com/flutter/flutter.git flutter --depth 1 -b stable

export PATH="$PATH:$(pwd)/flutter/bin"

echo "==> Configuring Flutter for web..."
flutter config --enable-web
flutter doctor

echo "==> Building..."
flutter pub get
flutter build web --release
