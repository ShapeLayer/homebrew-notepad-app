# homebrew-notepad-app

**English** | [한국어](README-ko.md)

![](./.static/spotlight.png)  

A Homebrew tap that lets you launch macOS TextEdit from Spotlight as **notepad** / **메모장**.

On install, it:

- Creates a `Notepad.app` wrapper app that opens TextEdit.
  - The file name is `Notepad.app` and the Korean localized display name is `메모장` (the same way TextEdit is `TextEdit.app` / `텍스트 편집기`).
  - The icon is copied from TextEdit on your Mac.
- Backs up your current TextEdit settings and changes them as follows:
  - New document format: plain text (`RichText = false`)
  - Smart quotes off (`SmartQuotes = false`)

On uninstall, it removes the wrapper app and restores TextEdit settings from the backup.

## Install / Uninstall

```sh
brew tap shapelayer/notepad-app
brew install --cask notepad
```

```sh
brew uninstall --cask notepad
```

You can change the install location with `--appdir=~/Applications` (default: `/Applications`).

To use it without Homebrew, run `scripts/install.sh [app folder]` and `scripts/uninstall.sh` directly.

## Notes

- **Your terminal needs access to other apps' data.** TextEdit is sandboxed, so its settings live in
  `~/Library/Containers/com.apple.TextEdit`. If access is blocked, the script tells you which app (name and bundle ID)
  needs it and waits until it is granted. Turn that app on in System Settings > Privacy & Security > Full Disk Access and it continues automatically.
  - Press **s** to skip only the TextEdit settings and still install the wrapper app. The script shows how to change the settings yourself and the command to reinstall.
    If you installed this way, uninstall has no settings to restore and does not ask for access.
  - If you press s to skip the restore during uninstall, the backup is kept and the script prints the `defaults` commands to restore it yourself.
    The remaining backup is reused as the original values on reinstall, and `brew uninstall --zap --cask notepad` removes it.
  - When key input is not available (run without a terminal), it skips right away instead of waiting.
- The settings backup is stored in `~/Library/Application Support/notepad-app/`. Reinstalling keeps the first backup,
  so uninstalling returns to the values from before this tool was first installed.
- If TextEdit was running, restart it for the changed settings to take effect.
