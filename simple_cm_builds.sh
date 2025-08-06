#!/usr/bin/env bash
set -e

# --- Color definitions ---
if [[ -t 1 ]]; then
  GREEN="\033[0;32m"
  YELLOW="\033[1;33m"
  RED="\033[0;31m"
  NC="\033[0m"
else
  GREEN=""; YELLOW=""; RED=""; NC=""
fi

log() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${GREEN}$1${NC}"; }
error() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${RED}$1${NC}"; }

usage() {
  echo -e "${GREEN}Usage:${NC} cm-build [-p|--prestep] [ENV] [VERSION]"
  echo
  echo "Options:"
  echo "  -p, --prestep    Run cleaning/prepare steps before build"
  echo "  -h, --help       Show this help"
  echo
  echo "Arguments:"
  echo "  ENV      Build environment (defaults from .env, e.g. dev, test, prod)"
  echo "  VERSION  Version string (defaults from .env)"
  echo
  echo "Examples:"
  echo "  cm-build                # Build with .env settings, no prestep"
  echo "  cm-build dev            # Build for 'dev' environment, no prestep"
  echo "  cm-build -p test        # Build for 'test' with prestep enabled"
  echo "  cm-build -p             # Build with .env settings, but with prestep"
  echo "  cm-build -h             # Show this help"
}

# --- Load configuration variables from .env ---
VARS_FILE="$(dirname "$0")/.env"
if [[ ! -f "$VARS_FILE" ]]; then
  echo "Config file not found: $VARS_FILE"
  echo "Copy .env.example to .env and configure it."
  exit 1
fi
source "$VARS_FILE"

# --- Process arguments: help and prestep flag ---
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

PRESTEP=false
if [[ "$1" == "-p" || "$1" == "--prestep" ]]; then
  PRESTEP=true
  shift
fi

# Allow help after -p too
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

ENV="${1:-$ENV}"
VERSION="${2:-$VERSION}"

log "Starting build ..."
log "PRESTEP:     $PRESTEP"
log "PROJECT_DIR: $PROJECT_DIR"
log "ENV:         $ENV"
log "VERSION:     $VERSION"

cd "$PROJECT_DIR" || { error "Could not access $PROJECT_DIR"; exit 1; }

if [[ "$PRESTEP" == "true" ]]; then
  log "Cleaning previous dependencies and files..."
  rm -rf node_modules out dist .vite package-lock.json
  log "Installing npm dependencies..."
  npm install
  log "Rebuilding native electron modules (electron-rebuild)..."
  npx electron-rebuild
else
  log "PRESTEP not enabled, skipping dependency cleanup and (re)install steps."
fi

log "Running Electron build..."
npm run make:"$ENV"

UNAMES=$(uname -s 2>/dev/null || echo Windows)

DEB="out/make/deb/x64/smowlcm_${VERSION}_amd64.deb"
DMG_PATH_X64="out/make/SmowlCM-${VERSION}-x64.dmg"
DMG_PATH_ARM="out/make/SmowlCM-${VERSION}-arm64.dmg"
APP_NAME="SmowlCM.app"

if [[ "$UNAMES" == "Linux" ]]; then
  log "Looking for DEB package: $DEB"
  if [[ ! -f "$DEB" ]]; then
      error "Package $DEB not found"
      exit 2
  fi
  log "Removing previous package installation (if exists)..."
  sudo dpkg -r smowlcm 2>/dev/null || true
  log "Installing new package..."
  sudo dpkg -i "$DEB"
  log "Installation completed successfully on Linux!"
elif [[ "$UNAMES" == "Darwin" ]]; then
  ARCH=$(uname -m)
  if [[ "$ARCH" == "arm64" ]]; then
    DMG_PATH="$DMG_PATH_ARM"
  else
    DMG_PATH="$DMG_PATH_X64"
  fi
  log "Looking for DMG image: $DMG_PATH"
  if [[ ! -f "$DMG_PATH" ]]; then
      error "DMG not found: $DMG_PATH"
      exit 2
  fi
  log "Mounting $DMG_PATH..."
  if ! MOUNT_OUTPUT=$(hdiutil attach "$DMG_PATH" -nobrowse 2>&1); then
      error "Could not mount DMG volume. Details:"
      echo "$MOUNT_OUTPUT"
      exit 3
  fi
  log "Mount output: $MOUNT_OUTPUT"
  MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep -o '/Volumes/[^ ]*' | head -n1)
  if [[ -z "$MOUNT_POINT" ]]; then
      error "Could not detect the DMG mount point."
      hdiutil detach "$DMG_PATH" || true
      exit 4
  fi
  log "Volume mounted at $MOUNT_POINT."
  if [[ ! -d "$MOUNT_POINT/$APP_NAME" ]]; then
    error "$APP_NAME not found in $MOUNT_POINT"
    hdiutil detach "$MOUNT_POINT" -quiet
    exit 5
  fi
  log "Removing previous app version (if exists) in /Applications/$APP_NAME..."
  rm -rf "/Applications/$APP_NAME"
  log "Copying new app to /Applications..."
  cp -R "$MOUNT_POINT/$APP_NAME" /Applications/
  log "Unmounting DMG image..."
  hdiutil detach "$MOUNT_POINT" -force -quiet
  log "Installation completed successfully on macOS! You can open $APP_NAME from /Applications."
elif [[ "$UNAMES" == "Windows_NT" || "$UNAMES" == "MINGW"* || "$UNAMES" == "MSYS"* || "$(uname -o 2>/dev/null)" == "Msys" ]]; then
  EXE_PATH=$(find out/make -name "*.exe" | head -n1)
  if [[ -f "$EXE_PATH" ]]; then
    log "Build completed. The installer is located at:"
    log "$EXE_PATH"
    log "Please run the installer manually to install the application."
  else
    error "No generated installer (.exe) found in the 'out/make' folder."
    exit 5
  fi
else
  error "Operating system NOT supported by this script: $UNAMES"
  exit 10
fi