"""render_evidence.py - before/after renders of 20 main windows for UI skin v2 (read-only on game data).

  render_evidence.py --variant before|after [--only key,key] [--res 1920x1080,1024x768]
      renders each window (no backdrop, RGBA full screen) into <out>/raw/<variant>/<key>_<W>x<H>.png
  render_evidence.py --index
      crops before/after to the same box, composites them over a GL scene backdrop, writes
      <out>/before, <out>/after, <out>/cmp (side by side) and <out>/index.html + evidence.json
BEFORE = client_GL as is; AFTER = Assets\\Staging\\ui\\skin-v2 over client_GL (same files an install writes).
Renderer: falagard_render.py (CEGUI 0.4.1 Falagard semantics + shipped TLBB widget behaviour).
"""
import argparse
import hashlib
import html
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import falagard_render as FR  # noqa: E402

CLIENT = r"C:\TLBB\085\client_GL\Data"
STAGE = r"C:\TLBB\085\CY-Source\Assets\Staging\ui\skin-v2"
OUT = r"C:\TLBB\085\CY-Source\Build\Logs\2026-09-12-ui-skin"
BACKDROP = r"C:\TLBB\085\Tools\DATA NEW\TLGL_extracted\ui_png_dxt\login\loading\loading2\xy_load_bg1.png"
PREVIEW_UI = r"C:\TLBB\085\Tools\gl-skin\relayout"
WINDOWS = [
    ("character", "SelfEquip", "Character / SelfEquip"), ("bag", "Packet", "Bag / Packet"), ("skills", "CommonSkill", "Skills / CommonSkill"),
    ("pet", "Pet", "Pet"), ("shop", "Shop", "NPC shop / Shop"), ("chat", "ChatFrame", "Chat / ChatFrame"), ("minimap", "MiniMap", "Minimap"),
    ("mainbar", "MainMenuBar", "Main action bar / MainMenuBar"), ("target", "TargetFrame", "Target frame / TargetFrame"),
    ("team", "TeamFrame", "Team / TeamFrame"), ("bigmap", "SceneMap", "Big map / SceneMap"), ("questlog", "QuestLog", "Quest log / QuestLog"),
    ("friends", "Friend", "Friends / Friend"), ("mail", "FriendChat", "Mail -> private message / FriendChat (this client has no mail window)"),
    ("settings", "ViewSetup", "Settings / ViewSetup"), ("login", "Logon", "Login / LogOn"), ("selectrole", "SelectRole", "Select role / SelectRole"),
    ("npcdialog", "Quest", "NPC dialog / Quest"), ("tooltip", "SuperToolTip", "Item tooltip / SuperTooltip"),
    ("messagebox", "MessageBoxCommon", "Message box / MessageBoxCommon"),
]
EXTRA_TEXT = {
    "npcdialog": {"Quest_Text": "#cFFF263Tiểu nhị:#r#W Khách quan muốn mua gì? Tiệm nhỏ có đủ đồ dùng hằng ngày, vũ khí và dược liệu."},
    "messagebox": {"MessageBoxCommon_Text": "Bạn có chắc chắn muốn thoát khỏi trò chơi không?"},
}


def default_states():
    try:
        sys.path.insert(0, PREVIEW_UI)
        import preview_ui  # read-only: reuse the Lua-state presets calibrated for client_GL
        return dict(preview_ui.DEFAULT_STATE)
    except Exception:
        return {}


def render_variant(variant, keys, resolutions):
    roots = [CLIENT] if variant == "before" else [STAGE, CLIENT]
    skin = FR.Skin(roots)
    states = default_states()
    rec = {}
    os.makedirs(os.path.join(OUT, "raw", variant), exist_ok=True)
    for key, layout, label in WINDOWS:
        if keys and key not in keys:
            continue
        for W, H in resolutions:
            st = dict(states.get(layout, {}))
            img, r, roots_ = FR.render_layout(skin, layout, (W, H), st, None, EXTRA_TEXT.get(key))
            p = os.path.join(OUT, "raw", variant, "%s_%dx%d.png" % (key, W, H))
            img.save(p)
            rec["%s_%dx%d" % (key, W, H)] = dict(layout=layout, notes=sorted(set(r.notes))[:30])
            print(variant, key, W, H, "notes", len(r.notes), flush=True)
    with open(os.path.join(OUT, "raw", variant, "_notes.json"), "w", encoding="utf-8") as f:
        json.dump(dict(roots=roots, skin_notes=sorted(set(skin.notes))[:200], renders=rec), f, ensure_ascii=False, indent=1)


def backdrop(size):
    bg = Image.open(BACKDROP).convert("RGB")
    s = max(size[0] / bg.width, size[1] / bg.height)
    bg = bg.resize((int(bg.width * s + 1), int(bg.height * s + 1)), Image.LANCZOS)
    bg = bg.crop((0, 0, size[0], size[1])).filter(ImageFilter.GaussianBlur(3))
    return Image.eval(bg, lambda v: int(v * 0.62)).convert("RGBA")


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def build_index(resolutions):
    fnt = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 18)
    rows, ev = [], []
    for sub in ("before", "after", "cmp"):
        os.makedirs(os.path.join(OUT, sub), exist_ok=True)
    notes = {}
    for v in ("before", "after"):
        f = os.path.join(OUT, "raw", v, "_notes.json")
        notes[v] = json.load(open(f, encoding="utf-8"))["renders"] if os.path.isfile(f) else {}
    for key, layout, label in WINDOWS:
        for W, H in resolutions:
            name = "%s_%dx%d" % (key, W, H)
            pb, pa = (os.path.join(OUT, "raw", v, name + ".png") for v in ("before", "after"))
            if not (os.path.isfile(pb) and os.path.isfile(pa)):
                continue
            b, a = Image.open(pb).convert("RGBA"), Image.open(pa).convert("RGBA")
            boxes = [x for x in (b.getchannel("A").getbbox(), a.getchannel("A").getbbox()) if x]
            if not boxes:
                continue
            box = (max(0, min(x[0] for x in boxes) - 16), max(0, min(x[1] for x in boxes) - 16),
                   min(W, max(x[2] for x in boxes) + 16), min(H, max(x[3] for x in boxes) + 16))
            bd = backdrop((W, H))
            outs = {}
            for v, im in (("before", b), ("after", a)):
                c = bd.copy()
                c.alpha_composite(im)
                c = c.crop(box).convert("RGB")
                p = os.path.join(OUT, v, name + ".png")
                c.save(p)
                outs[v] = (p, c)
            cw, ch = outs["before"][1].size
            cmp_ = Image.new("RGB", (cw * 2 + 24, ch + 34), (24, 24, 28))
            cmp_.paste(outs["before"][1], (0, 34))
            cmp_.paste(outs["after"][1], (cw + 24, 34))
            d = ImageDraw.Draw(cmp_)
            d.text((6, 7), "BEFORE (client_GL)", font=fnt, fill=(230, 200, 120))
            d.text((cw + 30, 7), "AFTER (skin v2)", font=fnt, fill=(140, 220, 140))
            pc = os.path.join(OUT, "cmp", name + ".png")
            cmp_.save(pc)
            rows.append((key, label, W, H, name))
            ev.append(dict(key=key, layout=layout, screen="%dx%d" % (W, H), crop=list(box),
                           before=dict(path=os.path.relpath(outs["before"][0], OUT), sha256=sha(outs["before"][0]), notes=notes["before"].get(name, {}).get("notes", [])),
                           after=dict(path=os.path.relpath(outs["after"][0], OUT), sha256=sha(outs["after"][0]), notes=notes["after"].get(name, {}).get("notes", [])),
                           cmp=os.path.relpath(pc, OUT)))
    with open(os.path.join(OUT, "evidence.json"), "w", encoding="utf-8") as f:
        json.dump(dict(renderer="CY-Source/Tools/ui/falagard_render.py", before_roots=[CLIENT], after_roots=[STAGE, CLIENT],
                       backdrop=BACKDROP, renders=ev), f, ensure_ascii=False, indent=1)
    H_ = ['<!doctype html><html><head><meta charset="utf-8"><title>UI skin v2 - before / after</title><style>',
          'body{background:#15161a;color:#ddd;font:14px Segoe UI,Arial,sans-serif;margin:16px}h1{font-size:20px}h2{font-size:16px;margin:28px 0 6px;color:#f0d890}',
          '.pair{display:flex;gap:12px;align-items:flex-start;overflow-x:auto}.pair figure{margin:0}.pair figcaption{color:#aaa;font-size:12px;margin:2px 0 4px}',
          'img{max-width:none;border:1px solid #333}.res{color:#8fa;font-size:12px}</style></head><body>',
          '<h1>UI skin v2 (GL style) - BEFORE = client_GL as is, AFTER = Assets\\Staging\\ui\\skin-v2 over client_GL</h1>',
          '<p>Offline renders by CY-Source\\Tools\\ui\\falagard_render.py (CEGUI 0.4.1 Falagard semantics; no 3D/scene/Lua). Same crop for both columns. Backdrop: blurred GL loading art.</p>']
    last = None
    for key, label, W, H, name in rows:
        if key != last:
            H_.append("<h2>%s</h2>" % html.escape(label))
            last = key
        H_.append('<div class="res">%dx%d</div><div class="pair"><figure><figcaption>before</figcaption><img src="before/%s.png"></figure>'
                  '<figure><figcaption>after</figcaption><img src="after/%s.png"></figure></div>' % (W, H, name, name))
    H_.append("</body></html>")
    with open(os.path.join(OUT, "index.html"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(H_))
    print("index:", os.path.join(OUT, "index.html"), len(rows), "pairs")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--variant", choices=("before", "after"))
    ap.add_argument("--only", default="")
    ap.add_argument("--res", default="1920x1080,1024x768")
    ap.add_argument("--index", action="store_true")
    a = ap.parse_args()
    res = [tuple(int(v) for v in r.split("x")) for r in a.res.split(",")]
    if a.variant:
        render_variant(a.variant, set(k for k in a.only.split(",") if k), res)
    if a.index:
        build_index(res)


if __name__ == "__main__":
    main()
