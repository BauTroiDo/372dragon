# -*- coding: utf-8 -*-
"""CYS-UIEDIT 19/09/2026 — giu ket qua keo khung tay khoi bi mat, va kiem no doc duoc.

VI SAO CAN FILE NAY
-------------------
Ket qua nguoi dung keo khung phai o cho client doc duoc luc chay, tuc duoi `Assets/CanonicalCY/Data`.
Nhung `.gitignore` loai `/Assets/*` ⇒ git khong giu. Cung lop mat du lieu da phai tra gia bang 242
dong `SceneDefineEx` (xem `Tools/reapply/README_vi.md`).

Cach xu ly o day KHAC voi cac cong thuc khac trong `Tools/reapply`: khong "dung lai" gi ca, ma dat
ban THAT vao thu muc duoc git theo doi (`Tools/reapply/ui-editor/data`) roi noi mot DIRECTORY
JUNCTION tu trong `Data` sang do. Nho vay:

  * client ghi thang vao thu muc duoc git theo doi (nguoi dung bam "luu" trong game la xong),
  * `build_canonical_cy.py` khong dung toi (no chi `os.replace` nhung tep co trong manifest cua lop
    GUI TRUOC; tep la khong bao gio bi don — da kiem: script KHONG co `rmtree`/`os.remove` nao),
  * xoa `Build/` hay dung lai `Assets` khong lam mat gi.

Neu junction khong tao duoc (quyen, hoac o dia khac) thi van chay duoc o che do CHEP: `apply` chep
master -> runtime, `save` chep runtime -> master. Luc do phai nho chay `save` sau khi keo.

TAI SAO KHONG SUA THANG `*.layout.xml`
--------------------------------------
`Tools/pipeline/build_canonical_cy.py` dung lai CA CAY `InterfaceFolder` tu `.axp` cua CY (ham
`xform_layout`, nhanh `low.endswith('.layout.xml')`), nen moi chu sua trong layout se bien mat o lan
dung lai sau — khong co canh bao nao.

LENH
----
  python -X utf8 Tools/reapply/ui-editor/85-ui-overrides.py link      # tao junction (chay MOT lan)
  python -X utf8 Tools/reapply/ui-editor/85-ui-overrides.py status    # dang o che do nao, bao nhieu dong
  python -X utf8 Tools/reapply/ui-editor/85-ui-overrides.py apply     # master -> runtime (che do CHEP)
  python -X utf8 Tools/reapply/ui-editor/85-ui-overrides.py save      # runtime -> master (che do CHEP)
  python -X utf8 Tools/reapply/ui-editor/85-ui-overrides.py verify    # kiem dinh dang + doi chieu hai ben
"""
import argparse
import hashlib
import io
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
MASTER_DIR = os.path.join(HERE, "data")
RUNTIME_DIR = os.path.join(REPO, "Assets", "CanonicalCY", "Data", "InterfaceFolder", "CysUiEdit")
FILES = ("ui_layout_overrides.tsv", "ui_edit_targets.tsv")
PROP = "UnifiedAreaRect"


def sha256(path):
    if not os.path.exists(path):
        return None
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()


def is_junction(path):
    if not os.path.isdir(path):
        return False
    try:
        return bool(os.readlink(path))
    except OSError:
        return False


def junction_target(path):
    try:
        return os.path.realpath(path)
    except OSError:
        return ""


def parse(path):
    """Tra ve (rows, loi). Moi row = (layout, window, prop, value, origin)."""
    rows, errors = [], []
    if not os.path.exists(path):
        return rows, ["khong co file: %s" % path]
    with io.open(path, encoding="utf-8", errors="replace") as fh:
        for n, line in enumerate(fh, 1):
            line = line.rstrip("\r\n")
            if not line or line.startswith("#"):
                continue
            f = line.split("\t")
            if len(f) < 4:
                errors.append("dong %d: chi co %d cot (can >= 4)" % (n, len(f)))
                continue
            if f[2] != PROP:
                errors.append("dong %d: prop la %r, ban v1 chi hieu %r" % (n, f[2], PROP))
                continue
            if not f[1]:
                errors.append("dong %d: thieu ten window" % n)
                continue
            value = f[3]
            if value.count("{") != 5 or value.count("}") != 5 or value.count(",") != 7:
                errors.append("dong %d: %s khong dung dang {{s,o},{s,o},{s,o},{s,o}}: %r" % (n, PROP, value))
                continue
            rows.append((f[0], f[1], f[2], value, f[4] if len(f) > 4 else ""))
    seen, dup = set(), []
    for r in rows:
        if r[1] in seen:
            dup.append(r[1])
        seen.add(r[1])
    for w in sorted(set(dup)):
        errors.append("window %r co nhieu dong; ban doc cua client giu dong CUOI" % w)
    return rows, errors


def cmd_link():
    os.makedirs(MASTER_DIR, exist_ok=True)
    for name in FILES:
        p = os.path.join(MASTER_DIR, name)
        if not os.path.exists(p):
            with io.open(p, "w", encoding="utf-8", newline="\n") as fh:
                fh.write("# CYS-UIEDIT v1\n")
    if is_junction(RUNTIME_DIR):
        print("da co junction: %s -> %s" % (RUNTIME_DIR, junction_target(RUNTIME_DIR)))
        return 0
    if os.path.isdir(RUNTIME_DIR):
        print("DA CO thu muc THAT o %s — khong dam dat junction de len." % RUNTIME_DIR)
        print("Chuyen sang che do CHEP: dung `apply` / `save`.")
        return 1
    os.makedirs(os.path.dirname(RUNTIME_DIR), exist_ok=True)
    rc = subprocess.call(["cmd", "/c", "mklink", "/J", RUNTIME_DIR, MASTER_DIR],
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if rc != 0 or not is_junction(RUNTIME_DIR):
        print("mklink /J that bai (rc=%s). Dung che do CHEP: `apply` / `save`." % rc)
        return 1
    print("junction: %s -> %s" % (RUNTIME_DIR, junction_target(RUNTIME_DIR)))
    return 0


def cmd_copy(src_dir, dst_dir, label):
    os.makedirs(dst_dir, exist_ok=True)
    if is_junction(RUNTIME_DIR):
        print("dang o che do JUNCTION: hai ben la MOT thu muc, khong can %s." % label)
        return 0
    n = 0
    for name in FILES:
        src = os.path.join(src_dir, name)
        if not os.path.exists(src):
            continue
        shutil.copy2(src, os.path.join(dst_dir, name))
        n += 1
    print("%s: %d tep" % (label, n))
    return 0


def cmd_status():
    mode = "JUNCTION" if is_junction(RUNTIME_DIR) else ("CHEP" if os.path.isdir(RUNTIME_DIR) else "CHUA CO")
    out = {"che_do": mode, "master": MASTER_DIR, "runtime": RUNTIME_DIR}
    if mode == "JUNCTION":
        out["junction_tro_toi"] = junction_target(RUNTIME_DIR)
    for tag, d in (("master", MASTER_DIR), ("runtime", RUNTIME_DIR)):
        path = os.path.join(d, FILES[0])
        rows, errors = parse(path)
        out[tag + "_dong"] = len(rows)
        out[tag + "_loi"] = len(errors)
        out[tag + "_sha256"] = (sha256(path) or "")[:8]
        tpath = os.path.join(d, FILES[1])
        out[tag + "_khung_hong"] = sum(
            1 for l in io.open(tpath, encoding="utf-8", errors="replace").read().splitlines()
            if l and not l.startswith("#")) if os.path.exists(tpath) else 0
    print(json.dumps(out, ensure_ascii=False, indent=1))
    return 0


def cmd_verify(out_json):
    result = {"ok": True, "loi": [], "che_do": "JUNCTION" if is_junction(RUNTIME_DIR) else "CHEP"}
    runtime = os.path.join(RUNTIME_DIR, FILES[0])
    master = os.path.join(MASTER_DIR, FILES[0])
    rows, errors = parse(runtime)
    result["runtime_dong"] = len(rows)
    result["loi"].extend(errors)
    # Phep kiem PHAI biet truot: mot file rong va mot file hong phai ra hai ket qua khac nhau.
    if not os.path.exists(runtime):
        result["loi"].append("khong co file runtime: %s" % runtime)
    if result["che_do"] == "CHEP":
        a, b = sha256(runtime), sha256(master)
        result["runtime_sha256"] = (a or "")[:8]
        result["master_sha256"] = (b or "")[:8]
        if a != b:
            result["loi"].append("runtime va master LECH — chay `save` (neu vua keo trong game) "
                                 "hoac `apply` (neu master moi hon)")
    # Moi dong phai co gia tri KHAC gia tri goc, neu khong no khong sua gi ma van lam file phinh.
    noop = [r[1] for r in rows if r[4] and r[3] == r[4]]
    if noop:
        result["loi"].append("%d dong co value == goc (khong sua gi): %s" % (len(noop), ", ".join(noop[:5])))
    result["ok"] = not result["loi"]
    print(json.dumps(result, ensure_ascii=False, indent=1))
    if out_json:
        with io.open(out_json, "w", encoding="utf-8") as fh:
            json.dump(result, fh, ensure_ascii=False, indent=1)
    return 0 if result["ok"] else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("action", choices=["link", "apply", "save", "status", "verify"])
    ap.add_argument("--out", default="", help="verify: ghi ket qua ra file JSON")
    args = ap.parse_args()
    if args.action == "link":
        return cmd_link()
    if args.action == "apply":
        return cmd_copy(MASTER_DIR, RUNTIME_DIR, "apply master -> runtime")
    if args.action == "save":
        return cmd_copy(RUNTIME_DIR, MASTER_DIR, "save runtime -> master")
    if args.action == "status":
        return cmd_status()
    return cmd_verify(args.out)


if __name__ == "__main__":
    sys.exit(main())
