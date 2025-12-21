#!/usr/bin/env bash
set -euo pipefail
# 序列化執行 flutter test，以避免 flutter test 在本地環境的 listener/stream race
# Usage: ./scripts/run_tests_serial.sh
flutter test --concurrency=1 "$@"
