#!/usr/bin/env bash
set -euo pipefail

APP="com.usebottles.bottles"

DEST_DIR="$HOME/.var/app/$APP/data/patches"
STATE="$DEST_DIR/.installed-paths"

OVERRIDE_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/overrides/$APP"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

[[ -f "$STATE" ]] || die "Installation state not found: $STATE"

# Read only the existing user-level override.
OVERRIDES="$(flatpak override --user --show "$APP")"

CURRENT="$(
    printf '%s\n' "$OVERRIDES" |
    awk '
        /^\[Environment\]$/ { section=1; next }
        /^\[/ { section=0 }
        section && /^PYTHONPATH=/ {
            sub(/^PYTHONPATH=/, "")
            print
            exit
        }
    '
)"

# Remove only components recorded as installed by us.
NEW_PATH="$(
    python3 - "$CURRENT" "$STATE" <<'PY'
import sys
from pathlib import Path

current, state_file = sys.argv[1:]

lines = Path(state_file).read_text().splitlines()
owned = set(lines[1:])

paths = [
    p for p in current.split(":")
    if p and p not in owned
]

print(":".join(paths))
PY
)" || die "Could not calculate remaining PYTHONPATH"

CREATED="$(head -n 1 "$STATE")"

if [[ -n "$NEW_PATH" ]]; then

    # Other paths remain: preserve them.
    flatpak override --user \
        --env="PYTHONPATH=$NEW_PATH" \
        "$APP"

elif [[ "$CREATED" == "created=0" ]]; then

    # The override existed before installation.
    # Restore its original empty value.
    flatpak override --user \
        --env="PYTHONPATH=" \
        "$APP"

else

    # We created the override and nothing remains.
    # Delete only the PYTHONPATH key, not other settings.
    if [[ -f "$OVERRIDE_FILE" ]]; then
        python3 - "$OVERRIDE_FILE" <<'PY'
import os
import sys
import tempfile
from pathlib import Path

path = Path(sys.argv[1])

lines = path.read_text().splitlines(keepends=True)

result = []
section = None

for line in lines:
    stripped = line.strip()

    if stripped.startswith("[") and stripped.endswith("]"):
        section = stripped

    if section == "[Environment]" and line.startswith("PYTHONPATH="):
        continue

    result.append(line)

# Preserve unrelated Flatpak settings and file permissions.
fd, tmp = tempfile.mkstemp(
    prefix=".override-",
    dir=path.parent,
)

try:
    os.fchmod(fd, path.stat().st_mode & 0o777)

    with os.fdopen(fd, "w") as f:
        f.writelines(result)

    os.replace(tmp, path)
except BaseException:
    if os.path.exists(tmp):
        os.unlink(tmp)
    raise
PY
    fi
fi

# Remove installed files.
rm -f "$DEST_DIR/sitecustomize.py"
rm -f "$STATE"
rm -rf -- "$DEST_DIR/__pycache__"

# Only remove the directory if empty.
rmdir "$DEST_DIR" 2>/dev/null || true

echo "Bottles runtime patch uninstalled."
echo "Remaining PYTHONPATH: ${NEW_PATH:-<default>}"
