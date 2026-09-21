#!/bin/bash
# Apply interactive optimization package after uploading lagernvs_interactive_opt.tgz
# into ~/lagernvs/ (or ~/). Usage: bash apply_interactive_opt.sh
set -euo pipefail
ROOT="${LAGERNVS_ROOT:-$HOME/lagernvs}"
cd "$ROOT"
TGZ=""
for c in \
  "$ROOT/lagernvs_interactive_opt.tgz" \
  "$HOME/lagernvs_interactive_opt.tgz" \
  "$ROOT/06_交互功能优化/lagernvs_interactive_opt.tgz"
do
  if [ -f "$c" ]; then TGZ="$c"; break; fi
done
if [ -z "$TGZ" ]; then
  echo "ERROR: lagernvs_interactive_opt.tgz not found under ~/ or ~/lagernvs/"
  echo "Upload from local: d:\\新建文件夹\\LagerNVS\\lagernvs_interactive_opt.tgz"
  exit 1
fi
mkdir -p "$ROOT/_interactive_backup"
for f in interactive_viewer.html run_interactive_server.py; do
  if [ -f "$ROOT/$f" ]; then cp -a "$ROOT/$f" "$ROOT/_interactive_backup/$f"; fi
done
tar -xzf "$TGZ" -C "$ROOT"
chmod +x "$ROOT/06_run_interactive.sh"
echo "Applied from $TGZ"
grep -n "location.host" "$ROOT/interactive_viewer.html" | head -2
grep -n "settings" "$ROOT/run_interactive_server.py" | head -3
wc -c "$ROOT/interactive_viewer.html" "$ROOT/run_interactive_server.py" "$ROOT/06_run_interactive.sh"
echo APPLY_OK
