#!/bin/bash
# plugins/sinners.notifications is Omarchy's own notifications plugin, copied and patched. This tells you whether the
# copy has fallen behind: whether the stock plugin has changed since it was copied (UPSTREAM records the version and
# the hash of every file as copied), and whether the fork changes only the files it means to.
#
#   tools/check-notifications-upstream.sh          report; exits 1 if stock has changed or the fork has strayed
#   tools/check-notifications-upstream.sh --diff   also show what the fork changes against the stock files
#
# When stock has changed, copy the new stock files over the fork's, then carry the burn patch across: it is small
# and every part of it is marked "Sinners" in Service.qml and Toast.qml (--diff shows it against the old stock
# while that is still installed; keep a copy of the old plugin if you want to diff the two stocks). Then update
# UPSTREAM with the new version and hashes.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
FORK=$ROOT/plugins/sinners.notifications
STOCK=${SINNERS_STOCK_NOTIFICATIONS:-/usr/share/omarchy/shell/plugins/notifications}
EDITED="Service.qml Toast.qml manifest.json"      # the files the fork is meant to change

[[ -f $FORK/UPSTREAM ]] || { echo "no $FORK/UPSTREAM" >&2; exit 2; }
[[ -d $STOCK ]] || { echo "no stock plugin at $STOCK; is Omarchy installed?" >&2; exit 2; }

python3 -I - "$FORK" "$STOCK" "$EDITED" "${1:-}" <<'PY'
import hashlib, json, os, subprocess, sys
fork, stock, edited, flag = sys.argv[1], sys.argv[2], sys.argv[3].split(), sys.argv[4]
up = json.load(open(os.path.join(fork, 'UPSTREAM')))
sha = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()

now = subprocess.run(['pacman', '-Q', 'omarchy'], capture_output=True, text=True).stdout.split()
print(f"fork copied from Omarchy {up['omarchyVersion']} (plugin {up['pluginVersion']}); installed: "
      f"{now[1] if len(now) > 1 else 'unknown'}")

bad = 0
# 1. has stock moved?
stock_files = sorted(f for f in os.listdir(stock) if f.endswith(('.qml', '.js', '.json')))
for f in stock_files:
    if f not in up['files']:
        print(f"  NEW in stock: {f}"); bad = 1
    elif sha(os.path.join(stock, f)) != up['files'][f]:
        print(f"  CHANGED in stock: {f}"); bad = 1
for f in up['files']:
    if f not in stock_files:
        print(f"  GONE from stock: {f}"); bad = 1
if not bad:
    print("  stock is unchanged since the copy")

# 2. does the fork change only what it means to?
for f, h in up['files'].items():
    p = os.path.join(fork, f)
    if not os.path.exists(p):
        print(f"  MISSING from the fork: {f}"); bad = 1
    elif f in edited:
        if sha(p) == h: print(f"  note: {f} is meant to be patched but matches stock")
    elif sha(p) != h:
        print(f"  STRAYED: {f} differs from stock and should not"); bad = 1
if not bad: print("  the fork differs from stock only in: " + ", ".join(edited))

if flag == '--diff':
    for f in edited:
        print(f"\n===== {f}: stock -> fork")
        subprocess.run(['diff', '-u', '--label', f'stock/{f}', '--label', f'fork/{f}', os.path.join(stock, f), os.path.join(fork, f)])
sys.exit(bad)
PY
