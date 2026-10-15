"""build_skin_v2.py - TLBB UI "skin v2" (GL / Thien Long Quy Lai style) - reproducible build + installer.

Modes (CY-Source Tools rule: check / apply / verify / revert, back up before writing):
  build_skin_v2.py [--base IF] [--out DIR]         build the staged skin (default: base = client_GL
                                                   InterfaceFolder, out = Assets\\Staging\\ui\\skin-v2)
  build_skin_v2.py --check  IF                     dry run against a target InterfaceFolder
  build_skin_v2.py --apply  IF [--material DIR]    install into IF (+ MaterialFolder next to it)
  build_skin_v2.py --verify IF                     validate an installed skin
  build_skin_v2.py --revert IF                     restore the scheme, move v2 files to a quarantine folder
What is written: Schema/TLBBLook_GLv2.looknfeel.xml (look overrides, loaded last), Common/Common_GL2.imageset.xml,
MaterialFolder/Common/Common_GL2.tga, and two lines in Schema/WoWLookSkin.scheme.xml. Layouts, Lua, fonts,
window types and sizes are never touched. Looks are regenerated from the TARGET's own definitions, so the
same command adapts to client_GL (v1 GL skin present) or to a pristine 085 InterfaceFolder.
"""
import argparse
import datetime
import hashlib
import json
import os
import re
import shutil
import sys
import xml.dom.minidom

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import skin_v2_art as ART    # noqa: E402
import skin_v2_looks as LK   # noqa: E402

DEF_BASE = r"C:\TLBB\085\client_GL\Data\InterfaceFolder"
DEF_OUT = r"C:\TLBB\085\CY-Source\Assets\Staging\ui\skin-v2"
LNF_REL = "Schema/TLBBLook_GLv2.looknfeel.xml"
SET_REL = "Common/Common_GL2.imageset.xml"
TEX_REL = "Common/Common_GL2.tga"
SCHEME_REL = "Schema/WoWLookSkin.scheme.xml"
APPLIED_REL = "Schema/skin-v2.applied.json"
BAK_SUFFIX = ".pre-skin-v2.bak"
IMGREF = re.compile(r'imageset\s*=\s*"([^"]+)"\s+image\s*=\s*"([^"]+)"')
SETREF = re.compile(r'set:\s*([^\s"]+)\s+image:\s*([^\s"]+)')
VERSION = "2.0"


def sha256_bytes(b):
    return hashlib.sha256(b).hexdigest()


def sha256_file(p):
    with open(p, "rb") as f:
        return sha256_bytes(f.read())


def p_(root, rel):
    return os.path.join(root, rel.replace("/", os.sep))


# ---------------------------------------------------------------------- progress bar colours
def progress_colours(if_dir, mat_dir, looks):
    """Tag -> rgb of the 085 fill image of TLBB_Look_ProgressProperty<Tag>; key map for the transformer."""
    sets_cache, bars, keys = {}, {}, {}
    scheme = LK.read_text(p_(if_dir, SCHEME_REL))
    setfiles = {a: b for a, b in re.findall(r'<Imageset\s+Name="([^"]+)"\s+Filename="([^"]+)"', scheme)}
    for name, (el, rel) in sorted(looks.items()):
        m = re.match(r"^TLBB_Look_ProgressProperty(\w+)$", name)
        if not m:
            continue
        tag = m.group(1)
        text = LK.ET.tostring(el, encoding="unicode")
        refs = [(a, b) for a, b in IMGREF.findall(text) if b != "ProgressLight" and a not in ("Buttons",)]
        mids = [r for r in refs if r[1].endswith("M") or r[1].endswith("_M")] or refs
        if not mids:
            continue
        s, i = mids[0]
        f = setfiles.get(s)
        if s not in sets_cache:
            sets_cache[s] = None
            if f and os.path.isfile(p_(if_dir, f)):
                t = LK.read_text(p_(if_dir, f))
                mf = re.search(r'Imagefile="([^"]+)"', t)
                imgs = {n: tuple(int(v) for v in g) for n, *g in re.findall(r'<Image\s+Name="([^"]+)"\s+XPos="(\d+)"\s+YPos="(\d+)"\s+Width="(\d+)"\s+Height="(\d+)"', t)}
                sets_cache[s] = (mf.group(1) if mf else "", imgs)
        info = sets_cache[s]
        if not info or i not in info[1]:
            continue
        tp = p_(mat_dir, info[0])
        if not os.path.isfile(tp):
            continue
        try:
            tex = Image.open(tp).convert("RGBA")
        except Exception:
            continue
        x, y, w, h = info[1][i]
        a = np.asarray(tex.crop((x, y, x + w, y + h))).reshape(-1, 4)
        a = a[a[:, 3] > 100] if (a[:, 3] > 100).any() else a
        bars[tag] = tuple(int(v) for v in a[:, :3].mean(axis=0))
        for r in set(refs):
            keys["%s:%s" % r] = tag
    return bars, keys


# ---------------------------------------------------------------------- generation
def generate(if_dir, mat_dir):
    looks, errors = LK.load_effective_looks(if_dir)
    bars, bar_keys = progress_colours(if_dir, mat_dir, looks)
    art = ART.Art().build(bars)
    atlas, pos = art.atlas()
    band_top, band_bot = art.band_rows
    geo = {"W_inset": (8, 30, 8, 13), "D_inset": (22, band_bot + 4, 22, 13)}
    tr = LK.Transformer(geo, pos.keys())
    tr.bar_keys = bar_keys
    out, rows = [], []
    for name in sorted(looks):
        el, rel = looks[name]
        new, changes = tr.transform(name, el)
        if new is not None:
            out.append(new)
            rows.append((name, rel, len(changes), "; ".join(sorted(set(changes)))[:300]))
    header = "UI skin v2 (GL style) generated by CY-Source\\Tools\\ui\\build_skin_v2.py %s from %s - do not edit" % (VERSION, if_dir)
    lnf = LK.serialize(out, header)
    xs = ['<?xml version="1.0" ?>', '<Imageset Name="%s" Imagefile="%s" NativeHorzRes="1024" NativeVertRes="768" AutoScaled="false">' % (LK.SET, TEX_REL)]
    for n, (x, y, w, h) in sorted(pos.items()):
        xs.append('  <Image Name="%s" XPos="%d" YPos="%d" Width="%d" Height="%d" />' % (n, x, y, w, h))
    xs.append("</Imageset>")
    imageset = b"\xef\xbb\xbf" + ("\r\n".join(xs) + "\r\n").encode("utf-8")
    return dict(looks=looks, errors=errors, art=art, atlas=atlas, pos=pos, lnf=lnf, imageset=imageset,
                overrides=rows, stats=tr.stats, geo=geo, bars=bars)


def patch_scheme(text):
    """insert the Common_GL2 imageset and put the v2 looknfeel LAST; idempotent. text = decoded (no BOM)."""
    nl = "\r\n" if "\r\n" in text else "\n"
    lines = text.split(nl)
    lines = [l for l in lines if LNF_REL not in l and 'Name="%s"' % LK.SET not in l]
    set_line = '  <Imageset Name="%s" Filename="%s" />' % (LK.SET, SET_REL)
    lnf_line = '  <LookNFeel Filename="%s" />' % LNF_REL
    first_set = next((i for i, l in enumerate(lines) if re.match(r"\s*<Imageset\b", l)), None)
    if first_set is None:
        first_set = next(i for i, l in enumerate(lines) if "<GUIScheme" in l) + 1
    lines.insert(first_set, set_line)
    last_lnf = max(i for i, l in enumerate(lines) if re.match(r"\s*<LookNFeel\b", l))
    lines.insert(last_lnf + 1, lnf_line)
    return nl.join(lines)


def read_scheme(if_dir):
    with open(p_(if_dir, SCHEME_REL), "rb") as f:
        raw = f.read()
    return raw, raw[3:].decode("utf-8") if raw[:3] == b"\xef\xbb\xbf" else raw.decode("utf-8", errors="surrogateescape")


def encode_scheme(text):
    t = text.replace("\r\n", "\n").replace("\n", "\r\n")
    return b"\xef\xbb\xbf" + t.encode("utf-8", errors="surrogateescape")


def validate_xml(blobs):
    for name, b in blobs.items():
        xml.dom.minidom.parseString(b[3:] if b[:3] == b"\xef\xbb\xbf" else b)


def write_manifest(path, g, outputs, base, mode):
    m = dict(tool="CY-Source/Tools/ui/build_skin_v2.py", version=VERSION, mode=mode, base=base,
             created=datetime.datetime.now().isoformat(timespec="seconds"),
             gl_sources=g["art"].sources, geometry=g["geo"], progress_bar_colours=g["bars"],
             atlas=dict(size="%dx%d" % g["atlas"].size, pieces=len(g["pos"])),
             pieces={n: dict(rect=list(g["pos"][n]), **g["art"].prov[n]) for n in sorted(g["pos"])},
             overrides=[dict(look=a, source=b, changes=c, detail=d) for a, b, c, d in g["overrides"]],
             transform_stats=g["stats"], outputs=outputs, looknfeel_errors=g["errors"])
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(m, f, ensure_ascii=False, indent=1)


# ---------------------------------------------------------------------- modes
def do_build(base, out):
    mat = os.path.join(os.path.dirname(base), "MaterialFolder")
    g = generate(base, mat)
    raw, text = read_scheme(base)
    scheme = encode_scheme(patch_scheme(text))
    blobs = {"lnf": g["lnf"], "imageset": g["imageset"], "scheme": scheme}
    validate_xml(blobs)
    files = {p_(out, "InterfaceFolder/" + LNF_REL): g["lnf"], p_(out, "InterfaceFolder/" + SET_REL): g["imageset"],
             p_(out, "InterfaceFolder/" + SCHEME_REL): scheme}
    for p, b in files.items():
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as f:
            f.write(b)
    tex = p_(out, "MaterialFolder/" + TEX_REL)
    os.makedirs(os.path.dirname(tex), exist_ok=True)
    g["atlas"].save(tex)
    os.makedirs(p_(out, "preview"), exist_ok=True)
    g["atlas"].save(p_(out, "preview/Common_GL2-atlas.png"))
    outputs = [dict(path=os.path.relpath(p, out), bytes=os.path.getsize(p), sha256=sha256_file(p)) for p in list(files) + [tex]]
    write_manifest(p_(out, "manifest.json"), g, outputs, base, "build")
    with open(p_(out, "overrides.tsv"), "w", encoding="utf-8", newline="\n") as f:
        f.write("look\tsource\tchanges\tdetail\n")
        for r in g["overrides"]:
            f.write("%s\t%s\t%d\t%s\n" % r)
    print("staged skin v2 -> %s" % out)
    print("  pieces %d, atlas %s, look overrides %d, stats %s" % (len(g["pos"]), g["atlas"].size, len(g["overrides"]), dict(sorted(g["stats"].items()))))
    if g["errors"]:
        print("  looknfeel warnings:", g["errors"][:5])
    return 0


def do_check(if_dir):
    mat = os.path.join(os.path.dirname(if_dir), "MaterialFolder")
    g = generate(if_dir, mat)
    raw, text = read_scheme(if_dir)
    applied = os.path.isfile(p_(if_dir, APPLIED_REL))
    print("check %s" % if_dir)
    print("  already applied: %s; scheme has v2 looknfeel: %s; material dir: %s (%s)" % (applied, LNF_REL in text, mat, os.path.isdir(mat)))
    print("  would write %d look overrides, %d atlas pieces; stats %s" % (len(g["overrides"]), len(g["pos"]), dict(sorted(g["stats"].items()))))
    validate_xml({"lnf": g["lnf"], "imageset": g["imageset"], "scheme": encode_scheme(patch_scheme(text))})
    print("  generated XML parses: OK")
    return 0


def do_apply(if_dir, mat):
    mat = mat or os.path.join(os.path.dirname(if_dir), "MaterialFolder")
    if not os.path.isdir(if_dir) or not os.path.isfile(p_(if_dir, SCHEME_REL)):
        print("not an InterfaceFolder:", if_dir)
        return 2
    g = generate(if_dir, mat)
    raw, text = read_scheme(if_dir)
    scheme = encode_scheme(patch_scheme(text))
    validate_xml({"lnf": g["lnf"], "imageset": g["imageset"], "scheme": scheme})
    bak = p_(if_dir, SCHEME_REL) + BAK_SUFFIX
    if not os.path.exists(bak):
        shutil.copy2(p_(if_dir, SCHEME_REL), bak)
    written = []
    for rel, b in ((LNF_REL, g["lnf"]), (SET_REL, g["imageset"]), (SCHEME_REL, scheme)):
        p = p_(if_dir, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as f:
            f.write(b)
        written.append(p)
    tex = p_(mat, TEX_REL)
    os.makedirs(os.path.dirname(tex), exist_ok=True)
    g["atlas"].save(tex)
    written.append(tex)
    outputs = [dict(path=p, bytes=os.path.getsize(p), sha256=sha256_file(p)) for p in written]
    rec = dict(version=VERSION, applied=datetime.datetime.now().isoformat(timespec="seconds"), interface_folder=if_dir,
               material_folder=mat, scheme_backup=bak, files=outputs, overrides=len(g["overrides"]))
    with open(p_(if_dir, APPLIED_REL), "w", encoding="utf-8", newline="\n") as f:
        json.dump(rec, f, ensure_ascii=False, indent=1)
    print("applied skin v2 to %s (%d look overrides); backup %s" % (if_dir, len(g["overrides"]), bak))
    return do_verify(if_dir)


def do_verify(if_dir):
    ok = True
    ap = p_(if_dir, APPLIED_REL)
    if not os.path.isfile(ap):
        print("FAIL: %s missing (skin v2 not applied)" % APPLIED_REL)
        return 1
    rec = json.load(open(ap, encoding="utf-8"))
    for f in rec["files"]:
        if not os.path.isfile(f["path"]):
            print("FAIL: missing", f["path"])
            ok = False
        elif os.path.basename(f["path"]) != os.path.basename(SCHEME_REL) and sha256_file(f["path"]) != f["sha256"]:
            print("FAIL: changed since apply", f["path"])
            ok = False
    raw, text = read_scheme(if_dir)
    lnfs = LK.scheme_lnfs(if_dir)
    if not lnfs or lnfs[-1] != LNF_REL:
        print("FAIL: v2 looknfeel is not the last LookNFeel in the scheme")
        ok = False
    if text.count('Name="%s"' % LK.SET) != 1:
        print("FAIL: Common_GL2 imageset must be listed exactly once")
        ok = False
    iset = LK.read_text(p_(if_dir, SET_REL))
    names = set(re.findall(r'<Image\s+Name="([^"]+)"', iset))
    m = re.findall(r'Width="(\d+)"', iset)
    lnf = LK.read_text(p_(if_dir, LNF_REL))
    xml.dom.minidom.parseString(lnf.encode("utf-8"))
    used = {i for s, i in IMGREF.findall(lnf) if s == LK.SET} | {i for s, i in SETREF.findall(lnf) if s == LK.SET}
    missing = sorted(used - names)
    if missing:
        print("FAIL: v2 looks reference %d images missing from Common_GL2: %s" % (len(missing), missing[:8]))
        ok = False
    looks, _ = LK.load_effective_looks(if_dir)
    over = {el.get("name"): el for el in LK.ET.fromstring(re.sub(r"^\s*<\?xml[^>]*\?>", "", lnf)).findall("WidgetLook")}
    allsec = {n: {s.get("name") for s in el.findall("ImagerySection")} for n, (el, r) in looks.items()}
    allsec.update({n: {s.get("name") for s in el.findall("ImagerySection")} for n, el in over.items()})
    bad = []
    for n, el in over.items():
        for s in el.iter("Section"):
            lk = s.get("look") or n
            if s.get("section") and s.get("section") not in allsec.get(lk, set()):
                bad.append("%s -> %s/%s" % (n, lk, s.get("section")))
    if bad:
        print("FAIL: unresolved section references: %s" % bad[:8])
        ok = False
    tex = p_(rec["material_folder"], TEX_REL)
    if not os.path.isfile(tex):
        print("FAIL: atlas missing", tex)
        ok = False
    print("verify %s: %s (%d v2 images referenced, %d overrides)" % (if_dir, "OK" if ok else "FAILED", len(used), len(over)))
    return 0 if ok else 1


def do_revert(if_dir):
    ap = p_(if_dir, APPLIED_REL)
    bak = p_(if_dir, SCHEME_REL) + BAK_SUFFIX
    if not os.path.isfile(bak):
        print("nothing to revert (no %s)" % bak)
        return 1
    rec = json.load(open(ap, encoding="utf-8")) if os.path.isfile(ap) else {"files": [], "material_folder": os.path.join(os.path.dirname(if_dir), "MaterialFolder")}
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    q = os.path.join(os.path.dirname(if_dir), "_skin-v2-reverted-" + stamp)
    for p in [f["path"] for f in rec["files"] if os.path.basename(f["path"]) != os.path.basename(SCHEME_REL)] + [ap]:
        if os.path.isfile(p):
            dst = os.path.join(q, os.path.relpath(p, os.path.dirname(if_dir)).replace("..", "_"))
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.move(p, dst)
    shutil.copy2(bak, p_(if_dir, SCHEME_REL))
    print("reverted %s: scheme restored from %s; v2 files moved to %s" % (if_dir, bak, q))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--base", default=DEF_BASE)
    ap.add_argument("--out", default=DEF_OUT)
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--check", metavar="IF")
    g.add_argument("--apply", metavar="IF")
    g.add_argument("--verify", metavar="IF")
    g.add_argument("--revert", metavar="IF")
    ap.add_argument("--material", help="MaterialFolder for --apply (default: sibling of IF)")
    a = ap.parse_args()
    if a.check:
        return do_check(os.path.abspath(a.check))
    if a.apply:
        return do_apply(os.path.abspath(a.apply), a.material)
    if a.verify:
        return do_verify(os.path.abspath(a.verify))
    if a.revert:
        return do_revert(os.path.abspath(a.revert))
    return do_build(os.path.abspath(a.base), os.path.abspath(a.out))


if __name__ == "__main__":
    sys.exit(main())
