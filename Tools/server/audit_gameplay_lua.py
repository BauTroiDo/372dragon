"""Read-only inventory of gameplay Lua and its UI event bridge; no script execution.

Regex findings are candidates, not proof a gameplay branch works or is broken.
Run on Windows (WSL UNC paths supported) or Linux. Syntax is checked separately
with the server's Lua compiler; this tool never imports game modules.
"""
import argparse
import collections
import hashlib
import json
import re
from pathlib import Path


def read(path):
    data = path.read_bytes()
    for encoding in ("utf-8-sig", "gb18030"):
        try:
            return data.decode(encoding)
        except UnicodeDecodeError:
            pass
    return data.decode("latin1")


def strip_comments(text):
    # Preserve quoted literals (event names) and line numbers. Long Lua strings
    # are opaque too: comments inside translated dialogue are not Lua comments.
    pattern = r"\[(=*)\[.*?\]\1\]|\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*'|--\[(=*)\[.*?\]\2\]|--[^\r\n]*"
    return re.sub(pattern, lambda m: re.sub(r"[^\r\n]", " ", m[0]) if m[0].startswith("--") else m[0], text, flags=re.S)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--server", type=Path, required=True)
    ap.add_argument("--reference", type=Path, required=True)
    ap.add_argument("--repo", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    root = args.server / "Game_2/Script"
    files = sorted(root.rglob("*.lua"))
    texts = {p.relative_to(root).as_posix(): strip_comments(read(p)) for p in files}
    registry = collections.defaultdict(list)
    for sid, module in re.findall(r'\[\s*(\d+)\s*\]\s*=\s*"([^"]+)"', texts["scripts/scripts.lua"]):
        registry[int(sid)].append(module)
    missing_modules = []
    paths_by_case = {p.relative_to(root).as_posix().lower(): p.relative_to(root).as_posix() for p in files}
    for sid, modules in registry.items():
        module = modules[-1]
        if not (root / (module.replace(".", "/") + ".lua")).is_file():
            rel = module.replace(".", "/") + ".lua"
            missing_modules.append({"id": sid, "module": module,
                                    "reference_exists": (args.reference / "Game_2/Script" / rel).is_file(),
                                    "case_variant": paths_by_case.get(rel.lower())})
    base = strip_comments(read(args.server / "GameServer/lualib/script_base.lua"))
    inherited = set(re.findall(r'function\s+script_base[:.]([\w]+)\s*\(', base))
    if 'require("script_legacy_compat").install(script_base)' in base:
        adapter = strip_comments(read(args.server / 'GameServer/lualib/script_legacy_compat.lua'))
        inherited.update(re.findall(r'function\s+base[:.]([\w]+)\s*\(', adapter))
    npc_refs = collections.defaultdict(list)
    for p in sorted((args.server / 'Game_2/Scene').glob('*monster*.ini')):
        text = read(p)
        for m in re.finditer(r'^\s*script_id\s*=\s*(\d+)', text, flags=re.M):
            npc_refs[int(m[1])].append({'file': p.name, 'line': text.count('\n', 0, m.start()) + 1})
    missing_ids = {x['id'] for x in missing_modules}
    absent = collections.defaultdict(set)
    commands = collections.defaultdict(list)
    unchanged = changed = reference_missing = 0
    for rel, text in texts.items():
        own = set(re.findall(r'function\s+[\w]+[:.]([\w]+)\s*\(', text))
        for call in set(re.findall(r'\bself\s*:\s*(\w+)\s*\(', text)) - own - inherited:
            absent[call].add(rel)
        for match in re.finditer(r'\bself\s*:\s*DispatchUICommand\s*\([^,\n]+,\s*(\d+)\s*\)', text):
            commands[match[1]].append({"file": rel, "line": text.count("\n", 0, match.start()) + 1})
        ref = args.reference / "Game_2/Script" / rel
        if not ref.is_file():
            reference_missing += 1
        elif sha(root / rel) == sha(ref):
            unchanged += 1
        else:
            changed += 1
    ui_root = args.repo / "Assets/CanonicalCY/Data/InterfaceFolder"
    registrations = collections.defaultdict(set)
    producers = collections.defaultdict(set)
    ui_command_files = []
    ui_files = sorted(ui_root.rglob("*.lua"))
    for p in ui_files:
        text = strip_comments(read(p))
        rel = p.relative_to(ui_root).as_posix()
        for ev in re.findall(r'\bRegisterEvent\s*\(\s*["\']([\w]+)["\']', text):
            registrations[ev].add(rel)
        for ev in re.findall(r'\bPushEvent\s*\(\s*["\']([\w]+)["\']', text):
            producers[ev].add(rel)
        if '"UI_COMMAND"' in text or "'UI_COMMAND'" in text:
            ui_command_files.append(rel)
    native_events = set(re.findall(r'\{\s*GE_\w+\s*,\s*"(\w+)"', read(args.repo / "Src/Client/WXClient/Event/GMEventSystem.cpp")))
    report = {
        "scope": "read-only static inventory; no claim of gameplay completion",
        "server": str(args.server), "reference": str(args.reference),
        "server_lua_files": len(files), "registry_ids": len(registry),
        "duplicate_ids": {str(k): v for k, v in registry.items() if len(v) > 1},
        "missing_registered_modules": missing_modules,
        "npc_referenced_script_ids": len(npc_refs),
        "npc_refs_without_module": {str(k): v for k, v in sorted(npc_refs.items()) if k not in registry or k in missing_ids},
        "reference_comparison": {"same": unchanged, "different": changed, "no_reference": reference_missing},
        "self_method_candidates": [{"method": k, "files": sorted(v)} for k, v in sorted(absent.items(), key=lambda kv: (-len(kv[1]), kv[0]))],
        "server_ui_commands": dict(sorted(commands.items(), key=lambda kv: int(kv[0]))),
        "server_ui_command_files": len({x["file"] for v in commands.values() for x in v}),
        "client_lua_files": len(ui_files), "native_events": len(native_events),
        "registered_event_names": len(registrations), "ui_command_listener_files": ui_command_files,
        "unregistered_event_names": [{"event": k, "listeners": sorted(v), "lua_producers": sorted(producers.get(k, []))} for k, v in sorted(registrations.items()) if k not in native_events],
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: report[k] for k in ("server_lua_files", "registry_ids", "reference_comparison", "server_ui_command_files", "client_lua_files", "native_events", "registered_event_names")}, ensure_ascii=False))
    print("missing modules:", len(missing_modules), "UI listeners:", len(ui_command_files), "missing events:", len(report["unregistered_event_names"]))
    print("self method candidates:", [(x["method"], len(x["files"])) for x in report["self_method_candidates"][:20]])


if __name__ == "__main__":
    main()
