#!/bin/zsh
# Creates a wrapper app that launches TextEdit as "Notepad"/"메모장", then backs up
# TextEdit settings and switches them to plain text with smart quotes off.
#
# Usage: install.sh [app folder]   (default: /Applications)

set -euo pipefail
source "${0:A:h}/common.sh"

APP_DIR="${1:-/Applications}"
[[ -d $TARGET_APP ]] || die target_app_missing "$TARGET_APP"
mkdir -p "$APP_DIR" 2>/dev/null || true
[[ -w $APP_DIR ]] || die app_dir_not_writable "$APP_DIR"

app_path="$APP_DIR/$APP_FILE_NAME"
if [[ -e $app_path && $(bundle_id_of "$app_path") != "$APP_BUNDLE_ID" ]]; then
  die app_exists_foreign "$app_path"
fi

# Without access, wait until it is granted; if the user presses s, skip only the settings.
if acquire_textedit_prefs_access; then
  configure_textedit=true
else
  configure_textedit=false
fi

mkdir -p "$STATE_DIR"

# --- 1. Create the wrapper app ----------------------------------------------

build_app() {
  local bundle=$1
  local contents="$bundle/Contents"
  mkdir -p "$contents/MacOS" "$contents/Resources"

  cat > "$contents/MacOS/$APP_EXECUTABLE" <<EOF
#!/bin/sh
exec /usr/bin/open -b $TARGET_BUNDLE_ID
EOF
  chmod 755 "$contents/MacOS/$APP_EXECUTABLE"

  # Reuse the TextEdit icon (legacy icns + modern Assets.car)
  local res
  for res in AppIcon.icns Assets.car; do
    [[ -e "$TARGET_APP/Contents/Resources/$res" ]] &&
      cp "$TARGET_APP/Contents/Resources/$res" "$contents/Resources/"
  done

  local plist="$contents/Info.plist"
  plutil -create xml1 "$plist"
  plutil -insert CFBundleDevelopmentRegion   -string en                    "$plist"
  plutil -insert CFBundleExecutable          -string "$APP_EXECUTABLE"     "$plist"
  plutil -insert CFBundleIdentifier          -string "$APP_BUNDLE_ID"      "$plist"
  plutil -insert CFBundleName                -string "$APP_BASE_NAME"   "$plist"
  plutil -insert CFBundleDisplayName         -string "$APP_BASE_NAME"   "$plist"
  plutil -insert CFBundlePackageType         -string APPL                  "$plist"
  plutil -insert CFBundleShortVersionString  -string "$APP_VERSION"        "$plist"
  plutil -insert CFBundleVersion             -string "$APP_VERSION"        "$plist"
  plutil -insert CFBundleIconFile            -string AppIcon               "$plist"
  plutil -insert CFBundleIconName            -string AppIcon               "$plist"
  plutil -insert LSHasLocalizedDisplayName   -bool   true                  "$plist"
  plutil -insert NSHighResolutionCapable     -bool   true                  "$plist"

  # Per-locale display names (<lang>.lproj/InfoPlist.strings, read from locales/*.sh)
  local lang strings
  for lang in ${(k)LOCALIZED_NAMES}; do
    mkdir -p "$contents/Resources/$lang.lproj"
    strings="$contents/Resources/$lang.lproj/InfoPlist.strings"
    plutil -create binary1 "$strings"
    plutil -insert CFBundleName        -string "${LOCALIZED_NAMES[$lang]}" "$strings"
    plutil -insert CFBundleDisplayName -string "${LOCALIZED_NAMES[$lang]}" "$strings"
  done
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

log app_creating "$app_path"
build_app "$tmp/$APP_FILE_NAME"
rm -rf "$app_path"
mv "$tmp/$APP_FILE_NAME" "$app_path"
print -r -- "$app_path" > "$STATE_APP_PATH"

"$LSREGISTER" -f "$app_path" || warn lsregister_failed

# --- 2. Back up TextEdit settings -------------------------------------------
# An existing backup (reinstall) is never overwritten, to preserve the original values.
# Format: key <TAB> type <TAB> value   (type is "-" for keys that were not set)
# When skipped for lack of access, steps 2-3 are not run; only a marker is left so uninstall skips the restore.

if ! $configure_textedit; then
  # Mark as skipped only if no earlier install changed the settings (no backup)
  [[ -f $STATE_DEFAULTS_BACKUP ]] || : > "$STATE_TEXTEDIT_SKIPPED"
elif [[ -f $STATE_DEFAULTS_BACKUP ]]; then
  log backup_kept "$STATE_DEFAULTS_BACKUP"
else
  log backup_creating "$STATE_DEFAULTS_BACKUP"
  backup_tmp="$STATE_DEFAULTS_BACKUP.tmp"
  : > "$backup_tmp"
  for key in ${(k)TEXTEDIT_SETTINGS}; do
    if value=$(defaults read "$TARGET_BUNDLE_ID" "$key" 2>/dev/null); then
      type=$(defaults read-type "$TARGET_BUNDLE_ID" "$key")
      type=${type#Type is }
      case $type in
        boolean) type=bool; [[ $value == 1 ]] && value=true || value=false ;;
        integer) type=int ;;
        float|string) ;;
        *) warn backup_type_unsupported "$key" "$type"; continue ;;
      esac
      print -r -- "$key"$'\t'"$type"$'\t'"$value" >> "$backup_tmp"
    else
      print -r -- "$key"$'\t-\t' >> "$backup_tmp"
    fi
  done
  mv "$backup_tmp" "$STATE_DEFAULTS_BACKUP"
fi

# --- 3. Apply TextEdit settings ---------------------------------------------

if $configure_textedit; then
  rm -f "$STATE_TEXTEDIT_SKIPPED"
  for key in ${(k)TEXTEDIT_SETTINGS}; do
    read -r type value <<< "${TEXTEDIT_SETTINGS[$key]}"
    log setting_apply "$key" "$value"
    defaults write "$TARGET_BUNDLE_ID" "$key" "-$type" "$value"
  done

  if pgrep -xq TextEdit; then
    warn textedit_running_apply
  fi
fi

# --- 4. Spotlight indexing ---------------------------------------------------

if index_in_spotlight "$app_path"; then
  log install_done "$(search_terms)"
else
  log install_done_pending "$(search_terms)"
fi

if ! $configure_textedit; then
  warn textedit_skipped "$HOST_APP_LABEL" "$(reinstall_command "$APP_DIR")"
fi
