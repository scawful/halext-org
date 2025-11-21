#!/bin/bash

# Compatibility shim: the project now prefers SideStore (tetherless) builds.
# This wrapper delegates to build-for-sidestore.sh so existing commands keep working.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "⚠️  AltStore path deprecated. Redirecting to SideStore builder..."
exec "$PROJECT_DIR/build-for-sidestore.sh" "$@"
