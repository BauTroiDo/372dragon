"""TLBB CEGUI skin inventory (read-only).

For every *.layout.xml under an InterfaceFolder: count each Window Type, resolve it through
Schema/WoWLookSkin.scheme.xml (FalagardMapping; the last definition wins, like CEGUI) to its
WidgetLook (the last loaded looknfeel wins), follow <Section look=".."> and auto-created
<Child type="..">, and classify the art the look draws:

  gl     every image reference comes from a GL-skin imageset (name ends with _GL, _GL2, GL ...)
  mixed  GL and old 085 imagesets
  old    old 085 imagesets only
  none   the look draws no image itself (text only / transparent / image given by the layout)

Layout-level image properties (Image, NormalImage, ... = "set:X image:Y") are counted too,
because many old 085 frames are drawn by StaticImage windows rather than by a WidgetLook.

usage: ui_inventory.py [--if InterfaceFolder] [--overlay SkinInterfaceFolder] [--out DIR] [--tag NAME]
  --overlay  files of the overlay (same relative path) replace those of --if; this evaluates a
             staged skin before it is applied.
Outputs in DIR: <tag>_widgetlooks.tsv, <tag>_layout_images.tsv, <tag>_inventory.json,
<tag>_INVENTORY.md
"""
import argparse
import collections
import json
import os
import re
import sys

DEF_IF = r"C:\TLBB\085\client_GL\Data\InterfaceFolder"
DEF_OUT = r"C:\TLBB\085\CY-Source\Build\Logs\2026-09-12-ui-skin\inventory"
COMMENT = re.compile(r"<!--.*?-->", re.S)
ATTR = re.compile(r'([A-Za-z_][\w:.-]*)\s*=\s*"([^"]*)"')
IMGREF = re.compile(r'imageset\s*=\s*"([^"]+)"\s+image\s*=\s*"([^"]+)"')
SETREF = re.compile(r'set:\s*([^\s"]+)\s+image:\s*([^\s"]+)')
WLOOK = re.compile(r'<WidgetLook\s+name\s*=\s*"([^"]+)"[^>]*>(.*?)</WidgetLook\s*>', re.S)
SECTION_DEF = re.compile(r'<ImagerySection\s+name\s*=\s*"([^"]+)"\s*(?:/>|>(.*?)</ImagerySection\s*>)', re.S)
SECTION_REF = re.compile(r"<Section\b([^>]*?)/?>")
CHILD = re.compile(r"<Child\b([^>]*?)/?>")
LOOK_PROP = re.compile(r'<Property\s+name\s*=\s*"([^"]+)"\s+value\s*=\s*"([^"]*)"')
LAYOUT_TOKEN = re.compile(r'<Window\b([^>]*?)/?>|<Property\s+Name\s*=\s*"([^"]+)"\s+Value\s*=\s*"([^"]*)"')
IMAGE_TAG = re.compile(r'<Image\s+Name\s*=\s*"([^"]+)"\s+XPos\s*=\s*"(-?\d+)"\s+YPos\s*=\s*"(-?\d+)"\s+Width\s*=\s*"(\d+)"\s+Height\s*=\s*"(\d+)"')
GL_SET = re.compile(r"(?:_GL\d*|GL\d*)$")
CATEGORIES = [
    ("close", r"ButtonClose|CloseButton"),
    ("slot", r"ActionButton|ItemBox|Slot"),
    ("tab", r"FenYe|PageUp|PageDown|CheckFor|Tab"),
    ("scrollbar", r"Scroll"),
    ("bar", r"Progress|Slider"),
    ("list", r"List|Combo|Tree|Menu"),
    ("edit", r"Edit|IME"),
    ("tooltip", r"Tooltip|Tip|PaoPao|Popup"),
    ("title", r"Title"),
    ("window frame", r"MainFrame"),
    ("border/panel", r"Frame|Lace|Border|Bk|BK|Back"),
    ("button", r"Button|Btn|Check|Radio"),
    ("text", r"Text|Label|Info"),
    ("image", r"Image|Icon|Picture|Anim"),
]


def read_text(path):
    with open(path, "rb") as f:
        b = f.read()
    if b[:3] == b"\xef\xbb\xbf":
        b = b[3:]
    try:
        return b.decode("utf-8")
    except UnicodeDecodeError:
        return b.decode("gb18030", errors="replace")


def category(t):
    for c, rx in CATEGORIES:
        if re.search(rx, t or ""):
            return c
    return "other"


class Tree:
    """InterfaceFolder with an optional overlay (a staged skin) on top of it."""

    def __init__(self, base, overlay=None):
        self.base, self.overlay = base, overlay

    def path(self, rel):
        rel = rel.replace("/", os.sep).replace("\\", os.sep)
        if self.overlay:
            p = os.path.join(self.overlay, rel)
            if os.path.isfile(p):
                return p
        return os.path.join(self.base, rel)


def parse_scheme(text):
    text = COMMENT.sub("", text)
    imagesets, lnfs, mapping, alias = collections.OrderedDict(), [], collections.OrderedDict(), {}
    for m in re.finditer(r"<(Imageset|LookNFeel|FalagardMapping|WindowAlias)\b([^>]*)>", text):
        a = dict(ATTR.findall(m.group(2)))
        kind = m.group(1)
        if kind == "Imageset" and "Name" in a:
            imagesets[a["Name"]] = a.get("Filename", "")
        elif kind == "LookNFeel" and "Filename" in a:
            lnfs.append(a["Filename"])
        elif kind == "FalagardMapping" and "WindowType" in a:
            mapping.pop(a["WindowType"], None)          # CEGUI replaces an existing mapping
            mapping[a["WindowType"]] = (a.get("TargetType", ""), a.get("LookNFeel", ""))
        elif kind == "WindowAlias" and "Alias" in a:
            alias[a["Alias"]] = a.get("Target", "")
    return imagesets, lnfs, mapping, alias


def parse_imagesets(tree, imagesets):
    """{set: (Imagefile, {image: (x, y, w, h)})}; None for a listed imageset whose file is missing."""
    out = {}
    for name, rel in imagesets.items():
        p = tree.path(rel)
        if not os.path.isfile(p):
            out[name] = None
            continue
        t = read_text(p)
        mf = re.search(r'Imagefile\s*=\s*"([^"]+)"', t)
        out[name] = (mf.group(1) if mf else "", {m.group(1): tuple(int(v) for v in m.groups()[1:]) for m in IMAGE_TAG.finditer(t)})
    return out


class Look:
    __slots__ = ("name", "src", "body", "sections", "secrefs", "children", "imageprops")

    def __init__(self, name, body, src):
        self.name, self.body, self.src = name, body, src
        self.sections = {m.group(1): (m.group(2) or "") for m in SECTION_DEF.finditer(body)}
        self.secrefs, self.children = [], []
        for m in SECTION_REF.finditer(body):
            a = dict(ATTR.findall(m.group(1)))
            if "section" in a:
                self.secrefs.append((a.get("look") or name, a["section"]))
        for m in CHILD.finditer(body):
            a = dict(ATTR.findall(m.group(1)))
            if "type" in a:
                self.children.append(a["type"])
        self.imageprops = len(re.findall(r"<ImageProperty\b", body))


def load_looks(tree, lnfs):
    looks, order = {}, []
    for rel in lnfs:
        p = tree.path(rel)
        if not os.path.isfile(p):
            order.append((rel, "MISSING"))
            continue
        t = COMMENT.sub("", read_text(p))
        n = 0
        for m in WLOOK.finditer(t):
            looks[m.group(1)] = Look(m.group(1), m.group(2), rel)   # a later file replaces, like CEGUI
            n += 1
        order.append((rel, n))
    return looks, order


def look_images(looks, name):
    """Counter{(imageset, image)} drawn by a look: its own sections used by a StateImagery, the
    sections it borrows from other looks, and set:/image: values of its own properties."""
    L = looks.get(name)
    if L is None:
        return None
    c = collections.Counter()
    for lk, s in L.secrefs:
        X = looks.get(lk)
        if X is None or s not in X.sections:
            continue
        text = X.sections[s]
        for k in IMGREF.findall(text):
            c[k] += 1
        for k in SETREF.findall(text):
            c[k] += 1
    for _, v in LOOK_PROP.findall(L.body):
        for k in SETREF.findall(v):
            c[k] += 1
    return c


def classify(c, gl_sets):
    if not c:
        return "none"
    g = sum(v for (s, _), v in c.items() if s in gl_sets)
    o = sum(c.values()) - g
    return "gl" if o == 0 else ("old" if g == 0 else "mixed")


def scan_layouts(if_dir):
    files = []
    for dp, dn, fn in os.walk(if_dir):
        for f in fn:
            if f.lower().endswith(".layout.xml"):
                files.append(os.path.join(dp, f))
    files.sort()
    types = collections.Counter()
    type_layouts = collections.defaultdict(set)
    img_refs = collections.Counter()
    img_layouts = collections.defaultdict(set)
    img_users = collections.defaultdict(collections.Counter)
    for p in files:
        t = COMMENT.sub("", read_text(p))
        rel = os.path.relpath(p, if_dir)
        cur = ""
        for m in LAYOUT_TOKEN.finditer(t):
            if m.group(1) is not None:
                cur = dict(ATTR.findall(m.group(1))).get("Type", "")
                types[cur] += 1
                type_layouts[cur].add(rel)
            else:
                for k in SETREF.findall(m.group(3)):
                    img_refs[k] += 1
                    img_layouts[k].add(rel)
                    img_users[k][(cur, m.group(2))] += 1
    return files, types, type_layouts, img_refs, img_layouts, img_users


def auto_children(looks, mapping, alias, types):
    auto = collections.Counter()

    def walk(t, n, depth, stack):
        lk = mapping.get(alias.get(t, t), ("", ""))[1]
        L = looks.get(lk)
        if L is None or depth > 5:
            return
        for ct in L.children:
            if ct in stack:
                continue
            auto[ct] += n
            walk(ct, n, depth + 1, stack | {ct})

    for t, n in types.items():
        walk(t, n, 0, {t})
    return auto


def build(ifolder, overlay=None):
    tree = Tree(ifolder, overlay)
    imagesets, lnfs, mapping, alias = parse_scheme(read_text(tree.path("Schema/WoWLookSkin.scheme.xml")))
    gl_sets = {s for s in imagesets if GL_SET.search(s)}
    sets = parse_imagesets(tree, imagesets)
    looks, order = load_looks(tree, lnfs)
    files, types, type_layouts, img_refs, img_layouts, img_users = scan_layouts(ifolder)
    auto = auto_children(looks, mapping, alias, types)
    rows = []
    for t in sorted(set(types) | set(auto)):
        target, lk = mapping.get(alias.get(t, t), ("", ""))
        c = look_images(looks, lk) if lk else None
        missing = sorted({"%s:%s" % k for k in (c or {}) if sets.get(k[0]) is None or k[1] not in sets[k[0]][1]})
        old_sets = collections.Counter()
        gl_refs = old_refs = 0
        for (s, _), v in (c or {}).items():
            if s in gl_sets:
                gl_refs += v
            else:
                old_refs += v
                old_sets[s] += v
        L = looks.get(lk)
        rows.append(dict(type=t, category=category(t), target=target, look=lk,
                         look_file=L.src if L else ("" if not lk else "MISSING"),
                         cls=("unmapped" if not lk else ("missing-look" if L is None else classify(c, gl_sets))),
                         instances=types.get(t, 0), auto=auto.get(t, 0), layouts=len(type_layouts.get(t, ())),
                         gl_refs=gl_refs, old_refs=old_refs, old_sets=[s for s, _ in old_sets.most_common(6)],
                         children=list(dict.fromkeys(L.children)) if L else [], imageprops=L.imageprops if L else 0,
                         missing_images=missing))
    rows.sort(key=lambda r: (-(r["instances"] + r["auto"]), r["type"]))
    limg = []
    for k, n in img_refs.most_common():
        s, i = k
        rect = sets.get(s)[1].get(i) if sets.get(s) else None
        limg.append(dict(ref="%s:%s" % k, imageset=s, image=i, uses=n, layouts=len(img_layouts[k]),
                         gl=s in gl_sets, size=("%dx%d" % rect[2:]) if rect else "?",
                         users=["%s.%s x%d" % (a, b, m) for (a, b), m in img_users[k].most_common(3)]))
    meta = dict(interface_folder=ifolder, overlay=overlay, layouts=len(files), windows=sum(types.values()),
                window_types=len(types), gl_imagesets=sorted(gl_sets), looknfeel_load_order=order,
                imagesets_listed=len(imagesets), imagesets_missing=sorted(k for k, v in sets.items() if v is None))
    # sections borrowed from another look (<Section look="X" section="Y">): who draws them, how often
    sec_uses, sec_types = collections.Counter(), collections.defaultdict(set)
    for r in rows:
        L = looks.get(r["look"])
        if L is None:
            continue
        for lk, s in set(L.secrefs):
            if lk != L.name:
                sec_uses[(lk, s)] += r["instances"] + r["auto"]
                sec_types[(lk, s)].add(r["type"])
    shared = []
    for (lk, s), n in sec_uses.most_common():
        X = looks.get(lk)
        text = X.sections.get(s, "") if X else ""
        c = collections.Counter(IMGREF.findall(text) + SETREF.findall(text))
        shared.append(dict(look=lk, section=s, uses=n, types=len(sec_types[(lk, s)]), cls=classify(c, gl_sets),
                           imagesets=sorted({k[0] for k in c}), sample_types=sorted(sec_types[(lk, s)])[:6]))
    meta["shared_sections"] = shared
    return meta, rows, limg


def pct(a, b):
    return "%.1f%%" % (100.0 * a / b) if b else "-"


def write_reports(meta, rows, limg, out, tag, top):
    os.makedirs(out, exist_ok=True)
    cols = ["type", "category", "target", "look", "look_file", "cls", "instances", "auto", "layouts", "gl_refs", "old_refs", "old_sets", "children", "imageprops", "missing_images"]
    with open(os.path.join(out, tag + "_widgetlooks.tsv"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\t".join(cols) + "\n")
        for r in rows:
            f.write("\t".join(",".join(r[c]) if isinstance(r[c], list) else str(r[c]) for c in cols) + "\n")
    with open(os.path.join(out, tag + "_layout_images.tsv"), "w", encoding="utf-8", newline="\n") as f:
        f.write("ref\tuses\tlayouts\tgl\tsize\tusers\n")
        for r in limg:
            f.write("%s\t%d\t%d\t%s\t%s\t%s\n" % (r["ref"], r["uses"], r["layouts"], r["gl"], r["size"], "; ".join(r["users"])))
    with open(os.path.join(out, tag + "_inventory.json"), "w", encoding="utf-8") as f:
        json.dump(dict(meta=meta, widgetlooks=rows, layout_images=limg[:3000]), f, ensure_ascii=False, indent=1)
    used = [r for r in rows if r["instances"] + r["auto"] > 0]
    tot_i = sum(r["instances"] + r["auto"] for r in used)
    by_cls = collections.OrderedDict((k, [0, 0]) for k in ("gl", "mixed", "old", "none", "unmapped", "missing-look"))
    for r in used:
        by_cls.setdefault(r["cls"], [0, 0])
        by_cls[r["cls"]][0] += 1
        by_cls[r["cls"]][1] += r["instances"] + r["auto"]
    L = []
    L.append("# UI skin inventory — %s\n" % tag)
    L.append("- InterfaceFolder: `%s`%s" % (meta["interface_folder"], ("  \n- Overlay: `%s`" % meta["overlay"]) if meta["overlay"] else ""))
    L.append("- Layouts scanned: **%d**, windows: **%d**, distinct window types: **%d**" % (meta["layouts"], meta["windows"], meta["window_types"]))
    L.append("- Imagesets listed in scheme: %d (missing files: %s)" % (meta["imagesets_listed"], ", ".join(meta["imagesets_missing"]) or "none"))
    L.append("- GL-skin imagesets: %s" % ", ".join(meta["gl_imagesets"]))
    L.append("- Instances = windows declared in layouts; auto = children created by a look (`<Child>`), e.g. list scrollbars.\n")
    L.append("## Coverage by class\n")
    L.append("| class | window types | instances (+auto) | share |")
    L.append("|---|---:|---:|---:|")
    for k, (n, i) in by_cls.items():
        L.append("| %s | %d | %d | %s |" % (k, n, i, pct(i, tot_i)))
    cats = collections.defaultdict(lambda: collections.Counter())
    for r in used:
        cats[r["category"]][r["cls"]] += r["instances"] + r["auto"]
    L.append("\n## Instances by category and class\n")
    L.append("| category | gl | mixed | old | none | unmapped |")
    L.append("|---|---:|---:|---:|---:|---:|")
    for c in sorted(cats, key=lambda c: -sum(cats[c].values())):
        v = cats[c]
        L.append("| %s | %d | %d | %d | %d | %d |" % (c, v["gl"], v["mixed"], v["old"], v["none"], v["unmapped"]))

    def table(title, sel, n):
        L.append("\n## %s\n" % title)
        L.append("| # | window type | look | category | instances | auto | layouts | old imagesets |")
        L.append("|---:|---|---|---|---:|---:|---:|---|")
        for k, r in enumerate([r for r in used if sel(r)][:n], 1):
            L.append("| %d | `%s` | `%s` | %s | %d | %d | %d | %s |" % (k, r["type"], r["look"], r["category"], r["instances"], r["auto"], r["layouts"], ", ".join(r["old_sets"][:4])))
    table("Old 085 art still drawn by a WidgetLook — by usage (ugliest first)", lambda r: r["cls"] == "old", top)
    table("Mixed GL + old art", lambda r: r["cls"] == "mixed", top)
    table("GL-skinned looks", lambda r: r["cls"] == "gl", top)
    table("Looks without own images (text / transparent / image from layout)", lambda r: r["cls"] == "none", 40)
    table("Types without a Falagard mapping (base/native factories)", lambda r: r["cls"] == "unmapped", 30)
    broken = [r for r in used if r["missing_images"]]
    if broken:
        L.append("\n## Looks referencing images that do not exist\n")
        for r in broken[:60]:
            L.append("- `%s` (%s): %s" % (r["look"], r["type"], ", ".join(r["missing_images"][:6])))
    L.append("\n## Shared sections borrowed from another look — by usage\n")
    L.append("| # | look / section | class | uses | borrowing types | imagesets | sample types |")
    L.append("|---:|---|---|---:|---:|---|---|")
    for k, r in enumerate(meta.get("shared_sections", [])[:top], 1):
        L.append("| %d | `%s` / `%s` | %s | %d | %d | %s | %s |" % (k, r["look"], r["section"], r["cls"], r["uses"], r["types"], ", ".join(r["imagesets"][:4]), ", ".join(r["sample_types"][:3])))
    L.append("\n## Layout-level images from old imagesets (Image/NormalImage/... properties) — top %d\n" % top)
    L.append("| # | imageset:image | size | uses | layouts | typical users |")
    L.append("|---:|---|---|---:|---:|---|")
    for k, r in enumerate([r for r in limg if not r["gl"]][:top], 1):
        L.append("| %d | `%s` | %s | %d | %d | %s |" % (k, r["ref"], r["size"], r["uses"], r["layouts"], "; ".join(r["users"])))
    per_set = collections.Counter()
    for r in limg:
        if not r["gl"]:
            per_set[r["imageset"]] += r["uses"]
    L.append("\n## Layout-level uses per old imageset — top 40\n")
    L.append("| imageset | uses |")
    L.append("|---|---:|")
    for s, n in per_set.most_common(40):
        L.append("| %s | %d |" % (s, n))
    L.append("\n## Looknfeel load order\n")
    for rel, n in meta["looknfeel_load_order"]:
        L.append("- `%s`: %s" % (rel, n))
    with open(os.path.join(out, tag + "_INVENTORY.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L) + "\n")
    return by_cls, tot_i


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--if", dest="ifolder", default=DEF_IF)
    ap.add_argument("--overlay")
    ap.add_argument("--out", default=DEF_OUT)
    ap.add_argument("--tag")
    ap.add_argument("--top", type=int, default=60)
    a = ap.parse_args()
    tag = a.tag or ("after" if a.overlay else "before")
    meta, rows, limg = build(a.ifolder, a.overlay)
    by_cls, tot = write_reports(meta, rows, limg, a.out, tag, a.top)
    print("layouts %d, windows %d, types %d" % (meta["layouts"], meta["windows"], meta["window_types"]))
    for k, (n, i) in by_cls.items():
        print("  %-12s types %4d  instances %6d  %s" % (k, n, i, pct(i, tot)))
    print("reports:", os.path.join(a.out, tag + "_INVENTORY.md"))


if __name__ == "__main__":
    sys.exit(main())
