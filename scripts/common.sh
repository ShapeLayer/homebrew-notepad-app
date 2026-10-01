# Settings and functions shared by install.sh / uninstall.sh. Not meant to be run directly.

APP_FILE_NAME="Notepad.app"
APP_BASE_NAME="Notepad"   # Base (en) display name; matches the file name, so it is always searchable.
APP_BUNDLE_ID="io.github.shapelayer.notepad"
APP_EXECUTABLE="notepad"
APP_VERSION="1.0.0"

TARGET_BUNDLE_ID="com.apple.TextEdit"
TARGET_APP="/System/Applications/TextEdit.app"

# TextEdit settings applied on install: key -> "type value"
typeset -gA TEXTEDIT_SETTINGS=(
  RichText    "bool false"  # New document format: plain text
  SmartQuotes "bool false"  # Turn off smart quotes
)

STATE_DIR="$HOME/Library/Application Support/notepad-app"
STATE_APP_PATH="$STATE_DIR/app-path"
STATE_DEFAULTS_BACKUP="$STATE_DIR/textedit-defaults.tsv"
STATE_TEXTEDIT_SKIPPED="$STATE_DIR/textedit-skipped"   # Marker: settings were skipped at install

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

# --- Locales ------------------------------------------------------------------
# Each locales/<language code>.sh is one language. It defines the script messages (MSG)
# and the wrapper app's display name in that language (LOCALE_APP_NAME).

SCRIPT_DIR="${${(%):-%x}:A:h}"   # The scripts folder containing this file
LOCALE_DIR="$SCRIPT_DIR/locales"
DEFAULT_LOCALE="ko"   # Fallback for languages/messages without a translation

# Pick the first language that has a locale file, in the order
# NOTEPAD_LANG > LC_ALL > LC_MESSAGES > LANG > macOS preferred languages.
# ko_KR.UTF-8 / ko-KR are tried as ko_KR, then ko.
resolve_locale() {
  local raw cand
  local -a candidates=(
    ${NOTEPAD_LANG:-} ${LC_ALL:-} ${LC_MESSAGES:-} ${LANG:-}
    ${(f)"$(defaults read -g AppleLanguages 2>/dev/null | sed -n 's/[[:space:]",]//g; /^[[:alpha:]]/p')"}
  )
  for raw in $candidates; do
    [[ $raw == (C|POSIX)* ]] && continue
    cand=${${raw%%[.@]*}//-/_}
    while [[ -n $cand ]]; do
      [[ -f $LOCALE_DIR/$cand.sh ]] && { print -r -- "$cand"; return; }
      [[ $cand == *_* ]] && cand=${cand%_*} || cand=
    done
  done
  print -r -- "$DEFAULT_LOCALE"
}

typeset -gA MSG
LOCALE=$(resolve_locale)
source "$LOCALE_DIR/$DEFAULT_LOCALE.sh"                              # Fallback messages
[[ $LOCALE != "$DEFAULT_LOCALE" ]] && source "$LOCALE_DIR/$LOCALE.sh"  # Overrides

# Display names from all locale files: language code -> name (en is the base name)
typeset -gA LOCALIZED_NAMES=( en "$APP_BASE_NAME" )
for _f in "$LOCALE_DIR"/*.sh(N); do
  _name=$(typeset -A MSG; LOCALE_APP_NAME=; source "$_f"; print -r -- "$LOCALE_APP_NAME")
  [[ -n $_name ]] && LOCALIZED_NAMES[${_f:t:r}]=$_name
done
unset _f _name

# msg <key> [args...]: print the current locale's message, filled in printf style.
msg() {
  local fmt=${MSG[$1]-$1}
  shift
  printf -- "$fmt" "$@"
}

log()  { print -r -- "==> $(msg "$@")"; }
warn() { print -ru2 -- "$(msg prefix_warning): $(msg "$@")"; }
die()  { print -ru2 -- "$(msg prefix_error): $(msg "$@")"; exit 1; }

# Spotlight search terms: "Notepad", "메모장"
search_terms() {
  local -a terms=("$APP_BASE_NAME" ${(u)LOCALIZED_NAMES:#$APP_BASE_NAME})
  print -r -- "\"${(j:", ":)terms}\""
}

# --- Access to TextEdit settings ---------------------------------------------
# TextEdit is sandboxed, so its settings live in ~/Library/Containers. When macOS blocks
# "access to other apps' data", even reads look like "not set". To avoid writing a wrong
# backup, check that writes work first.
TARGET_CONTAINER_PREFS="$HOME/Library/Containers/$TARGET_BUNDLE_ID/Data/Library/Preferences"
FULL_DISK_ACCESS_PANE="x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"

can_write_textedit_prefs() {
  local probe="NotepadAppAccessProbe"
  defaults write "$TARGET_BUNDLE_ID" "$probe" -bool true 2>/dev/null || return 1
  defaults delete "$TARGET_BUNDLE_ID" "$probe" 2>/dev/null || true
}

# The app that needs access = the GUI app running this script (Terminal, iTerm, VS Code, ...).
# Walk up the process tree and take the outermost .app bundle.
# Sets: HOST_APP_NAME, HOST_APP_ID (empty if unknown), HOST_APP_LABEL ("name (bundle ID)")
detect_host_app() {
  local pid=$$ comm app=
  while [[ -n $pid ]] && (( pid > 1 )); do
    comm=$(ps -o comm= -p "$pid" 2>/dev/null) || break
    [[ $comm == *.app/* ]] && app="${comm%%.app/*}.app"
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done

  HOST_APP_ID= HOST_APP_NAME=
  if [[ -n $app ]]; then
    HOST_APP_ID=$(bundle_id_of "$app")
    HOST_APP_NAME=$(osascript -l JavaScript -e 'function run(argv) {
      ObjC.import("Foundation")
      return $.NSFileManager.defaultManager.displayNameAtPath(argv[0]).js }' "$app" 2>/dev/null)
    HOST_APP_NAME=${${HOST_APP_NAME:-${app:t}}%.app}
  else
    # If no app is found (tmux, ssh, ...), guess from environment variables
    HOST_APP_ID=${__CFBundleIdentifier:-}
    case ${TERM_PROGRAM:-} in
      Apple_Terminal) HOST_APP_NAME=$(msg term_app_terminal) ;;
      iTerm.app)      HOST_APP_NAME="iTerm" ;;
      vscode)         HOST_APP_NAME="Visual Studio Code" ;;
      "")             HOST_APP_NAME=$(msg term_app_unknown) ;;
      *)              HOST_APP_NAME=$TERM_PROGRAM ;;
    esac
  fi
  HOST_APP_LABEL=$HOST_APP_NAME
  [[ -n $HOST_APP_ID ]] && HOST_APP_LABEL+=" ($HOST_APP_ID)"
  return 0
}

# Access guidance dialog. Run in the background; opens System Settings if the user asks.
show_access_alert() {
  local open_label answer
  open_label=$(msg access_alert_open)
  answer=$(osascript \
    -e 'on run argv' \
    -e 'display alert (item 1 of argv) message (item 2 of argv) as warning buttons {item 3 of argv, item 4 of argv} default button 2' \
    -e 'return button returned of result' \
    -e 'end run' \
    "$(msg access_alert_title)" "$(msg access_alert_body "$HOST_APP_LABEL")" \
    "$(msg access_alert_close)" "$open_label" 2>/dev/null) || true
  [[ $answer == "$open_label" ]] && open "$FULL_DISK_ACCESS_PANE"
  return 0
}

# Obtain access to TextEdit settings.
# Returns: 0 = access granted, 1 = skipped with the s key (or no terminal to read input from)
acquire_textedit_prefs_access() {
  can_write_textedit_prefs && return 0

  # defaults goes through cfprefsd, which just denies without a macOS consent prompt.
  # Touching the container folder directly shows the "would like to access data from
  # other apps" prompt and blocks until the user responds.
  log access_requesting
  ls "$TARGET_CONTAINER_PREFS" >/dev/null 2>&1 || true
  can_write_textedit_prefs && return 0

  detect_host_app
  warn access_needed "$HOST_APP_LABEL"

  # brew does not pass stdin through, so read keys from the terminal (/dev/tty) directly.
  if ! { : < /dev/tty } 2>/dev/null; then
    warn access_no_tty
    return 1
  fi

  log access_waiting "$HOST_APP_NAME"
  show_access_alert &
  local alert_pid=$! key result
  while true; do
    if can_write_textedit_prefs; then
      log access_granted
      result=0
      break
    fi
    if read -s -k 1 -t 1 key < /dev/tty 2>/dev/null && [[ $key == [sS] ]]; then
      result=1
      break
    fi
  done
  pkill -P "$alert_pid" osascript 2>/dev/null || true
  kill "$alert_pid" 2>/dev/null || true
  return $result
}

# Command to reinstall this tool (the brew command if installed via Homebrew)
reinstall_command() {
  if [[ $SCRIPT_DIR == */Caskroom/* ]]; then
    print -r -- "brew reinstall --cask notepad"
  else
    print -r -- "${(q-)SCRIPT_DIR}/install.sh ${(q-)${1:-/Applications}}"
  fi
}

# --- Spotlight ----------------------------------------------------------------

# Index the app in Spotlight and verify it is searchable. On failure, explain why and return 1.
index_in_spotlight() {
  local app=$1 i
  log spotlight_requesting "$app"
  touch "$app"                      # Notify the change via FSEvents
  mdimport "$app" 2>/dev/null || true

  for i in {1..15}; do
    mdfind "kMDItemCFBundleIdentifier == '$APP_BUNDLE_ID'" 2>/dev/null | grep -qxF "$app" && {
      log spotlight_done
      return 0
    }
    sleep 1
  done

  local volume md_status
  volume=$(df "$app" | awk 'END { print $NF }')
  md_status=$(mdutil -s "$volume" 2>&1)
  if [[ $md_status == *disabled* || $md_status == *read-only* || $md_status == *"unknown indexing state"* ]]; then
    warn spotlight_unhealthy "$volume" "${md_status//$'\n'/ }"
  else
    warn spotlight_pending
  fi
  return 1
}

bundle_id_of() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$1/Contents/Info.plist" 2>/dev/null
}
