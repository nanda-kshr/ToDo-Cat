#!/bin/bash
set -e

rm -rf flutter
git clone --depth 1 -b stable https://github.com/flutter/flutter.git flutter
flutter/bin/flutter config --enable-web
flutter/bin/flutter pub get
flutter/bin/flutter build web --release
