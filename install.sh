#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--rollback" ]]; then
    sudo rpm -e blossomos-shellconfig 2>/dev/null || true
    echo "Rolled back."
    exit 0
fi

if git -C "$SCRIPT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$SCRIPT_DIR" submodule update --init --recursive
else
    if [[ ! -d "$SCRIPT_DIR/plugins/zsh-autosuggestions/.git" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$SCRIPT_DIR/plugins/zsh-autosuggestions"
    fi
fi

bash "$SCRIPT_DIR/release.sh" --batch

RPM=$(ls -t "$SCRIPT_DIR/release/"blossomos-shellconfig-*.rpm 2>/dev/null | head -1)
[[ -z "$RPM" ]] && { echo "No RPM found in release/"; exit 1; }
sudo rpm -Uvh --force "$RPM"

echo "Done. To undo: bash $SCRIPT_DIR/install.sh --rollback"
