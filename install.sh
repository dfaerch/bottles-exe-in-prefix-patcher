#!/usr/bin/env bash
set -euo pipefail

APP="com.usebottles.bottles"
PATCH_PATH="/var/data/patches"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/patch/sitecustomize.py"

DEST_DIR="$HOME/.var/app/$APP/data/patches"
STATE="$DEST_DIR/.installed-paths"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

[[ -f "$SOURCE" ]] || die "Missing $SOURCE"
flatpak info "$APP" >/dev/null || die "Bottles is not installed"

# Read the current user-level override, if any.
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

# Distinguish an absent override from an empty one.
if printf '%s\n' "$OVERRIDES" |
    awk '
        /^\[Environment\]$/ { section=1; next }
        /^\[/ { section=0 }
        section && /^PYTHONPATH=/ { found=1 }
        END { exit !found }
    '
then
    HAS_OVERRIDE=1
else
    HAS_OVERRIDE=0
fi

# Discover application paths with our override disabled.
APP_PATHS="$(
    flatpak run \
        --unset-env=PYTHONPATH \
        --command=python3 \
        "$APP" \
        -c '
import sys

print(":".join(
    p for p in sys.path
    if p.startswith("/app/")
))
'
)" || die "Could not discover Python paths"

[[ -n "$APP_PATHS" ]] || die "No application Python paths found"

mkdir -p "$DEST_DIR"

TMP_STATE="$(mktemp "$DEST_DIR/.state.XXXXXX")"
trap 'rm -f "$TMP_STATE"' EXIT

# Merge paths, preserving existing user entries.
NEW_PATH="$(
    python3 - "$CURRENT" "$APP_PATHS" "$PATCH_PATH" \
        "$STATE" "$TMP_STATE" "$HAS_OVERRIDE" <<'PY'
import sys
from pathlib import Path

current, app_paths, patch, state_file, output, has_override = sys.argv[1:]

def split(value):
    return [p for p in value.split(":") if p]

existing = split(current)
required = [patch] + split(app_paths)

state_path = Path(state_file)

if state_path.exists():
    lines = state_path.read_text().splitlines()
    created = lines[0] == "created=1"
    owned = set(lines[1:])
else:
    created = has_override == "0"
    owned = set()

# Remove components we previously installed, allowing updates
# to replace obsolete application-specific Python paths.
base = [p for p in existing if p not in owned]

result = list(base)
new_owned = set()

for path in required:
    if path not in result:
        result.append(path)
        new_owned.add(path)
    elif path in owned:
        new_owned.add(path)

# Our patch directory always belongs to this installation.
new_owned.add(patch)

Path(output).write_text(
    f"created={int(created)}\n" +
    "".join(f"{p}\n" for p in sorted(new_owned))
)

print(":".join(result))
PY
)" || die "Could not construct PYTHONPATH"

# Install the Python hook.
install -m 644 "$SOURCE" "$DEST_DIR/sitecustomize.py"

# Update only Bottles' PYTHONPATH override.
flatpak override --user \
    --env="PYTHONPATH=$NEW_PATH" \
    "$APP"

# Record which path components we own.
mv -f "$TMP_STATE" "$STATE"

echo "Installed: $DEST_DIR/sitecustomize.py"
echo "PYTHONPATH=$NEW_PATH"
echo "Restart Bottles to activate."
