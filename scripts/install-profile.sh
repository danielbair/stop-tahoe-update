#!/bin/sh

set -eu

PROFILE="${1:-profiles/deferral-major-90days-only.mobileconfig}"

if [ ! -f "$PROFILE" ]; then
  echo "Profile not found: $PROFILE" >&2
  exit 1
fi

# Generate two distinct UUIDs
UUID1=$(uuidgen)
UUID2=$(uuidgen)

# Create profile with UUIDs inserted
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
TEMP_PROFILE="$TEMP_DIR/profile.mobileconfig"
sed -e "s/PAYLOAD-UUID/$UUID1/" -e "s/PROFILE-UUID/$UUID2/" "$PROFILE" > "$TEMP_PROFILE"

echo "Installing profile: $PROFILE"
echo "  Payload UUID: $UUID1"
echo "  Profile UUID: $UUID2"

# Try CLI first; fall back to UI if it fails
if sudo /usr/bin/profiles install -type configuration -path "$TEMP_PROFILE" 2>/dev/null; then
  echo "Done. Check System Settings → Privacy & Security → Profiles to verify."
  open "x-apple.systempreferences:com.apple.preferences.configurationprofiles"
else
  echo "Opening profile in System Settings for manual approval..."
  open "$TEMP_PROFILE"
  open "x-apple.systempreferences:com.apple.preferences.configurationprofiles"
  echo "Press Enter after you've approved (or declined) the profile in System Settings."
  # shellcheck disable=SC2034 suppress "unused variable" message.
  read -r junk
  defaults write com.apple.systempreferences AttentionPrefBundleIDs 0
  killall Dock
  echo "You may need to reboot for the profile to take effect."
fi
