#!/bin/bash
# CY-Source Tools/server/cys_server.sh - operate the PRIVATE CY-Source server only (run as root inside WSL TLBB).
#
#   cys_server.sh status                         read-only: services (verified by exe/config/cwd), ports, client
#                                                 connections, git state; lists original-server processes as "not ours"
#   cys_server.sh backup [label]                  mongodump of the private Mongo (127.0.0.1:27018) + git HEAD +
#                                                 sha256 manifest into <root>/backups/<UTC>-<label>/ (git-ignored)
#   cys_server.sh restore <backup-dir> --confirm-root <root>   mongorestore --drop; refuses while any skynet
#                                                 service of the private server runs or a client is connected
#   cys_server.sh stop|start|restart --confirm-root <root>     delegate to Tools/server/provision_test_wsl.py
#                                                 (pidfd, identity-checked SIGTERM, no SIGKILL); refuse while a
#                                                 client is connected to the login/game ports
#
# The root is fixed: /home/ubuntu/cys-test-20260913. Nothing here signals, reads or writes the original server
# (/home/ubuntu/GameServer, Mongo 27017). Credentials are read in-process from the private server_conf.lua and
# handed to mongodump/mongorestore through a 0600 --config file that is removed on exit; they are never printed.
# Docs: Docs/specs/net/cys-server_vi.md
set -euo pipefail
ROOT=/home/ubuntu/cys-test-20260913
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVISION="$HERE/provision_test_wsl.py"
LOGIN_PORT=15733
GAME_PORT=15734
MONGO_PORT=27018

die() { echo "cys_server: $*" >&2; exit 2; }
[ "$(id -u)" = 0 ] || die "run as root inside WSL (wsl -d TLBB -u root -- bash ...)"
[ "$(realpath -e "$ROOT")" = "$ROOT" ] || die "private root missing or behind a symlink: $ROOT"

hexport() { printf '%04X' "$1"; }

# ESTABLISHED (state 01) TCP connections whose local port is the login or game port.
client_connections() {
    local lp gp
    lp=$(hexport "$LOGIN_PORT"); gp=$(hexport "$GAME_PORT")
    awk -v lp="$lp" -v gp="$gp" 'NR>1 { split($2, a, ":"); if ((a[2]==lp || a[2]==gp) && $4=="01") n++ } END { print n+0 }' \
        /proc/net/tcp /proc/net/tcp6
}

skynet_running() {
    python3 -B "$PROVISION" status | python3 -c '
import json, sys
state = json.load(sys.stdin)
print(sum(1 for s in state["services"] if s["name"] in ("Manager", "DataCenter", "Tool", "Game") and s["running"]))'
}

mongo_config_file() {
    # Writes a 0600 mongo tools --config YAML with the private password; prints its path.
    local file
    file=$(mktemp /run/cys-mongo-XXXXXX.yaml)
    chmod 600 "$file"
    python3 - "$ROOT/confs/publish_yu/server_conf.lua" "$file" <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
match = re.search(r'username="cys_test",password="([0-9a-f]{64})"', text)
if not match:
    sys.exit('private database credential not found in server_conf.lua')
with open(sys.argv[2], 'w', encoding='ascii') as out:
    out.write('password: "%s"\n' % match.group(1))
PY
    echo "$file"
}

cmd_status() {
    echo "== private server $ROOT"
    python3 -B "$PROVISION" status | python3 -c '
import json, sys
state = json.load(sys.stdin)
for s in state["services"]:
    print("  %-10s running=%-5s pids=%s pidfile_ok=%s" % (s["name"], s["running"], s["owned_pids"], s["pid_file_matches"]))
closed = [p for p, open_ in state["ports"].items() if not open_]
print("  ports listening: %d/%d%s" % (len(state["ports"]) - len(closed), len(state["ports"]),
      (" (closed: " + ",".join(closed) + ")") if closed else ""))'
    echo "  client connections on $LOGIN_PORT/$GAME_PORT: $(client_connections)"
    if [ -d "$ROOT/.git" ]; then
        echo "  git: $(git -C "$ROOT" log --oneline -1) ; modified/untracked: $(git -C "$ROOT" status --porcelain | wc -l)"
    else
        echo "  git: (no repository)"
    fi
    local last
    last=$(ls -1d "$ROOT"/backups/*/ 2>/dev/null | tail -1 || true)
    echo "  last backup: ${last:-none}"
    echo "== original server (read-only listing, never touched by this tool)"
    local found=0
    for p in /proc/[0-9]*; do
        exe=$(readlink "$p/exe" 2>/dev/null || true)
        case "$exe" in
            /home/ubuntu/GameServer/framework/*) echo "  pid ${p#/proc/} $exe"; found=1 ;;
        esac
    done
    [ "$found" = 1 ] || echo "  (no original skynet process)"
}

cmd_backup() {
    local label="${1:-manual}"
    [[ "$label" =~ ^[A-Za-z0-9._-]{1,40}$ ]] || die "label: 1..40 of [A-Za-z0-9._-]"
    python3 -B "$PROVISION" status | python3 -c '
import json, sys
state = json.load(sys.stdin)
mongo = [s for s in state["services"] if s["name"] == "Mongo"][0]
sys.exit(0 if mongo["running"] and state["ports"]["27018"] else "private Mongo is not running; nothing to back up")'
    local stamp dir cfg
    stamp=$(date -u +%Y%m%dT%H%M%SZ)
    dir="$ROOT/backups/$stamp-$label"
    umask 077
    mkdir -p "$dir"
    cfg=$(mongo_config_file)
    trap 'rm -f "$cfg"' EXIT
    mongodump --quiet --config="$cfg" --uri="mongodb://cys_test@127.0.0.1:$MONGO_PORT/?authSource=admin" \
        --gzip --out="$dir/mongo"
    rm -f "$cfg"; trap - EXIT
    cp -p "$ROOT/confs/publish_yu/server_conf.lua" "$dir/server_conf.lua"   # credential copy, 0600, never printed
    chmod 600 "$dir/server_conf.lua"
    python3 - "$ROOT" "$dir" "$label" <<'PY'
import datetime, hashlib, json, os, subprocess, sys
root, out, label = sys.argv[1:4]
files = []
for base, _, names in os.walk(out):
    for name in sorted(names):
        path = os.path.join(base, name)
        data = open(path, 'rb').read()
        files.append({'path': os.path.relpath(path, out), 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
def git(*args):
    try:
        return subprocess.run(['git', '-C', root, *args], capture_output=True, text=True, check=True).stdout.strip()
    except Exception:
        return ''
record = {'root': root, 'label': label, 'created_utc': datetime.datetime.utcnow().isoformat(timespec='seconds') + 'Z',
          'git_head': git('rev-parse', 'HEAD'), 'git_dirty_entries': len([l for l in git('status', '--porcelain').splitlines() if l]),
          'mongo': {'port': 27018, 'tool': subprocess.run(['mongodump', '--version'], capture_output=True, text=True).stdout.splitlines()[0],
                    'format': 'mongodump --gzip', 'databases': sorted(d for d in os.listdir(os.path.join(out, 'mongo')))},
          'credential_files': ['server_conf.lua (0600, not printed)'],
          'files': [f for f in files if f['path'] != 'backup.json']}
open(os.path.join(out, 'backup.json'), 'w', encoding='utf-8').write(json.dumps(record, indent=1) + '\n')
print(json.dumps({'backup': out, 'databases': record['mongo']['databases'], 'files': len(record['files']),
                  'bytes': sum(f['bytes'] for f in record['files']), 'git_head': record['git_head']}, indent=1))
PY
}

require_confirm() {
    [ "${1:-}" = "--confirm-root" ] && [ "${2:-}" = "$ROOT" ] || die "requires --confirm-root $ROOT"
}

require_no_clients() {
    local n
    n=$(client_connections)
    [ "$n" = 0 ] || die "$n client connection(s) on $LOGIN_PORT/$GAME_PORT; close every Game.exe/bot first"
}

cmd_restore() {
    local src="${1:-}"; shift || true
    require_confirm "$@"
    [ -n "$src" ] || die "restore <backup-dir> --confirm-root $ROOT"
    src=$(realpath -e "$src")
    case "$src" in "$ROOT"/backups/*) ;; *) die "backup must be under $ROOT/backups" ;; esac
    [ -f "$src/backup.json" ] && [ -d "$src/mongo" ] || die "not a cys_server.sh backup: $src"
    require_no_clients
    [ "$(skynet_running)" = 0 ] || die "stop the private skynet services first (cys_server.sh stop --confirm-root $ROOT), Mongo stays up"
    python3 - "$src" <<'PY'
import hashlib, json, os, sys
src = sys.argv[1]
record = json.load(open(os.path.join(src, 'backup.json'), encoding='utf-8'))
bad = [f['path'] for f in record['files'] if hashlib.sha256(open(os.path.join(src, f['path']), 'rb').read()).hexdigest() != f['sha256']]
sys.exit('backup files changed: ' + ', '.join(bad) if bad else 0)
PY
    local cfg
    cfg=$(mongo_config_file)
    trap 'rm -f "$cfg"' EXIT
    mongorestore --quiet --config="$cfg" --uri="mongodb://cys_test@127.0.0.1:$MONGO_PORT/?authSource=admin" \
        --gzip --drop --nsExclude='admin.*' --dir="$src/mongo"
    rm -f "$cfg"; trap - EXIT
    echo "restored $src (admin database untouched); start with: cys_server.sh start --confirm-root $ROOT"
}

cmd="${1:-status}"; shift || true
case "$cmd" in
    status)  cmd_status ;;
    backup)  cmd_backup "${1:-manual}" ;;
    restore) cmd_restore "$@" ;;
    stop)    require_confirm "$@"; require_no_clients; python3 -B "$PROVISION" stop --confirm-root "$ROOT" ;;
    start)   require_confirm "$@"; python3 -B "$PROVISION" start ;;
    restart) require_confirm "$@"; require_no_clients
             python3 -B "$PROVISION" stop --confirm-root "$ROOT"
             python3 -B "$PROVISION" start ;;
    *) die "usage: cys_server.sh status | backup [label] | restore <dir> --confirm-root $ROOT | stop|start|restart --confirm-root $ROOT" ;;
esac
