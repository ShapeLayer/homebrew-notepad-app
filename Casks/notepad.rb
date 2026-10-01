cask "notepad" do
  version :latest
  sha256 :no_check

  url "https://github.com/ShapeLayer/homebrew-notepad-app/archive/refs/heads/main.tar.gz"
  name "Notepad"
  desc "Opens TextEdit as Notepad (메모장) and sets it to plain text by default"
  homepage "https://github.com/ShapeLayer/homebrew-notepad-app"

  depends_on macos: ">= :big_sur"

  installer script: {
    executable: "homebrew-notepad-app-main/scripts/install.sh",
    args:       [appdir.to_s],
  }

  uninstall script: {
    executable: "homebrew-notepad-app-main/scripts/uninstall.sh",
  }

  zap trash: "~/Library/Application Support/notepad-app"
end
