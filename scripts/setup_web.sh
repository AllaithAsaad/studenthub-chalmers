#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
dart run sqflite_common_ffi_web:setup --force
sqlite_version="$(python3 - <<'PY'
from pathlib import Path
import re
lock = Path('pubspec.lock').read_text()
block = re.search(r'^  sqlite3:\n(.*?)(?=^  \w|\Z)', lock, re.M | re.S)
if not block:
    raise SystemExit('sqlite3 missing from pubspec.lock')
print(re.search(r'version: "([^"]+)"', block.group(1)).group(1))
PY
)"
curl --fail --location "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${sqlite_version}/sqlite3.wasm" --output web/sqlite3.wasm
printf 'SQLite worker and WASM ready for version %s\n' "$sqlite_version"
