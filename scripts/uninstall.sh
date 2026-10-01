#!/bin/zsh
# Removes the wrapper app created by install.sh and restores TextEdit settings from the backup.
#
# Usage: uninstall.sh [app folder]   (default: the location recorded at install time)

set -euo pipefail
source "${0:A:h}/common.sh"

# Access is needed only when there is a backup to restore. Without access, wait until it is granted;
# if the user presses s, skip the restore and keep the backup (a reinstall reuses it as the original values).
restore_textedit=false
if [[ -f $STATE_DEFAULTS_BACKUP ]] && acquire_textedit_prefs_access; then
  restore_textedit=true
fi

# --- 1. Remove the wrapper app ----------------------------------------------

if [[ -n ${1:-} ]]; then
  app_path="$1/$APP_FILE_NAME"
elif [[ -f $STATE_APP_PATH ]]; then
  app_path=$(<"$STATE_APP_PATH")
else
  app_path="/Applications/$APP_FILE_NAME"
fi

if [[ ! -e $app_path ]]; then
  log app_already_gone "$app_path"
elif [[ $(bundle_id_of "$app_path") != "$APP_BUNDLE_ID" ]]; then
  warn app_foreign_skip "$app_path"
else
  log app_removing "$app_path"
  "$LSREGISTER" -u "$app_path" 2>/dev/null || true
  rm -rf "$app_path"
fi

# --- 2. Restore TextEdit settings -------------------------------------------

if $restore_textedit; then
  while IFS=$'\t' read -r key type value; do
    [[ -n $key ]] || continue
    if [[ $type == - ]]; then
      log setting_restore_default "$key"
      defaults delete "$TARGET_BUNDLE_ID" "$key" 2>/dev/null || true
    else
      log setting_restore "$key" "$value"
      defaults write "$TARGET_BUNDLE_ID" "$key" "-$type" "$value"
    fi
  done < "$STATE_DEFAULTS_BACKUP"

  if pgrep -xq TextEdit; then
    warn textedit_running_restore
  fi
  rm -rf "$STATE_DIR"

elif [[ -f $STATE_DEFAULTS_BACKUP ]]; then
  # Skipped for lack of access: keep the backup and print commands to restore it manually
  restore_cmds=()
  while IFS=$'\t' read -r key type value; do
    [[ -n $key ]] || continue
    if [[ $type == - ]]; then
      restore_cmds+=("    defaults delete $TARGET_BUNDLE_ID $key")
    else
      restore_cmds+=("    defaults write $TARGET_BUNDLE_ID $key -$type ${(q-)value}")
    fi
  done < "$STATE_DEFAULTS_BACKUP"
  rm -f "$STATE_APP_PATH" "$STATE_TEXTEDIT_SKIPPED"
  warn restore_skipped "$STATE_DEFAULTS_BACKUP" "$HOST_APP_LABEL" "${(F)restore_cmds}"

elif [[ -f $STATE_TEXTEDIT_SKIPPED ]]; then
  log restore_not_needed
  rm -rf "$STATE_DIR"

else
  warn backup_missing
  rm -rf "$STATE_DIR"
fi

log uninstall_done
