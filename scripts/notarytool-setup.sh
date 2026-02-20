#!/usr/bin/env bash
set -euo pipefail

PROFILE="${NOTARYTOOL_PROFILE:-TunaNotary}"
KEY_ID="${NOTARYTOOL_KEY_ID:-}"
ISSUER_ID="${NOTARYTOOL_ISSUER_ID:-}"
KEY_PATH="${NOTARYTOOL_KEY_PATH:-}"
APPLE_ID="${NOTARYTOOL_APPLE_ID:-}"
APPLE_PASSWORD="${NOTARYTOOL_APP_PASSWORD:-}"
TEAM_ID="${NOTARYTOOL_TEAM_ID:-}"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found; install Xcode Command Line Tools." >&2
  exit 1
fi

if [[ -n "$KEY_ID" || -n "$ISSUER_ID" || -n "$KEY_PATH" ]]; then
  if [[ -z "$KEY_ID" || -z "$ISSUER_ID" || -z "$KEY_PATH" ]]; then
    echo "Set NOTARYTOOL_KEY_ID, NOTARYTOOL_ISSUER_ID, and NOTARYTOOL_KEY_PATH." >&2
    exit 1
  fi
  xcrun notarytool store-credentials "$PROFILE" --key "$KEY_PATH" --key-id "$KEY_ID" --issuer "$ISSUER_ID"
  echo "Stored notarytool API key credentials in profile '$PROFILE'."
  exit 0
fi

if [[ -n "$APPLE_ID" || -n "$APPLE_PASSWORD" || -n "$TEAM_ID" ]]; then
  if [[ -z "$APPLE_ID" || -z "$APPLE_PASSWORD" ]]; then
    echo "Set NOTARYTOOL_APPLE_ID and NOTARYTOOL_APP_PASSWORD for Apple ID auth." >&2
    exit 1
  fi
  ARGS=(--apple-id "$APPLE_ID" --password "$APPLE_PASSWORD")
  if [[ -n "$TEAM_ID" ]]; then
    ARGS+=(--team-id "$TEAM_ID")
  fi
  xcrun notarytool store-credentials "$PROFILE" "${ARGS[@]}"
  echo "Stored notarytool Apple ID credentials in profile '$PROFILE'."
  exit 0
fi

echo "No credentials provided. Set API key vars or Apple ID vars." >&2
exit 1
