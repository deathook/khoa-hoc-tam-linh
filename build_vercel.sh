#!/bin/bash
set -e

echo "=== Vercel Build: Khoa Hoc Tam Linh (Flutter Web) ==="

# 1. Clone Flutter stable SDK
if [ ! -d "_flutter" ]; then
  echo "Cloning Flutter stable SDK..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
else
  echo "Using existing Flutter SDK..."
fi

export PATH="$PATH:$(pwd)/_flutter/bin"

# 2. Check Flutter version
flutter --version

# 3. Disable analytics
flutter config --no-analytics

# 4. Get dependencies
echo "Getting Flutter packages..."
flutter pub get

# 5. Build Web Release
echo "Building Flutter Web release..."
flutter build web --release --no-tree-shake-icons

echo "=== Build Finished Successfully! ==="
