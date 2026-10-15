# CYS: pick OgreSmoke test models per material-template family (2026-09-12).
# Reads (read-only): client_GL\Data\MaterialFolder\all.material (GBK), the extracted B template
# scripts (Assets\Staging\materialtemplates\B\*.material) and Assets\Staging\index\models_S1.tsv
# (S1 = client_GL). Writes a TSV of candidates per template family to stdout or --out.
#   python pick_models.py [--out FILE] [--per 6]
import argparse
import csv
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
ALLMAT = r"C:\TLBB\085\client_GL\Data\MaterialFolder\all.material"
TPL_DIR = os.path.join(ROOT, "Assets", "Staging", "materialtemplates", "B")
INDEX = os.path.join(ROOT, "Assets", "Staging", "index", "models_S1.tsv")

MAT_RE = re.compile(rb"^\s*material\s+(.+?)\s*$")


def parse_materials(path):
    """name -> parent (None for root materials). Names decoded from GBK."""
    out = {}
    with open(path, "rb") as f:
        for raw in f:
            m = MAT_RE.match(raw.rstrip(b"\r\n"))
            if not m:
                continue
            decl = m.group(1).decode("gbk", "replace")
            if ":" in decl:
                name, parent = decl.split(":", 1)
                out[name.strip()] = parent.strip()
            else:
                out[decl.strip()] = None
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out")
    ap.add_argument("--per", type=int, default=6)
    args = ap.parse_args()

    templates = set()
    for fn in os.listdir(TPL_DIR):
        if fn.endswith(".material"):
            templates.update(parse_materials(os.path.join(TPL_DIR, fn)).keys())
    allmat = parse_materials(ALLMAT)

    def family(name):
        seen = set()
        while name and name not in seen:
            seen.add(name)
            if name in templates:
                return name
            name = allmat.get(name)
        return None

    fams = {}
    with open(INDEX, encoding="utf-8-sig") as f:
        rd = csv.reader(f, delimiter="\t")
        hdr = next(rd)
        for row in rd:
            d = dict(zip(hdr, row))
            if d.get("complete") != "ok" or d.get("tex_missing"):
                continue
            try:
                verts = int(d.get("verts") or 0)
            except ValueError:
                verts = 0
            if verts < 800:
                continue
            mats = [m for m in re.split(r"[;|]", d.get("materials", "")) if m]
            if not mats:
                continue
            fs = sorted({family(m) or "-" for m in mats})
            key = fs[0] if len(fs) == 1 else "+".join(fs)
            fams.setdefault(key, []).append((verts, d))

    lines = ["family\tobj\tmeshes\tmaterials\tverts\tmax_sub_bones\tskel_bones\tanims\tmesh_relpath"]
    for key in sorted(fams, key=lambda k: -len(fams[k])):
        cands = sorted(fams[key], key=lambda t: -t[0])[: args.per]
        for verts, d in cands:
            lines.append("\t".join([key, d["obj"], d["meshes"], d["materials"], str(verts),
                                    d.get("max_sub_bones", ""), d.get("skel_bones", ""),
                                    d.get("anims", ""), d.get("mesh_relpath", "")]))
    text = "\n".join(lines) + "\n"
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(text)
    else:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stdout.write(text)
    sys.stderr.write("families: %d\n" % len(fams))


if __name__ == "__main__":
    main()
