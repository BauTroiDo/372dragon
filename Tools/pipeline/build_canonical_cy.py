"""build_canonical_cy.py - data root for CY-Source: CY 3.71 base + GUI layer (cy-switch phase 1, cy-gui 14/09/2026).

    Assets\\CanonicalCY\\Data  =  S4 CY 3.71.9609 (AXP: plain entries + wrapper types 19-25 decrypted)
                              +  S2 DataCY for wrapper types 1-18 (bytes cut to the S4 payload length)
                              +  S4 root files (MaterialTemplates.zip, OgreCore.zip, ndata.dat)
                              +  GUI layer, selected with --gui:
         --gui cy (default)  CY 3.71 InterfaceFolder as is, except (user decisions 12-14/09/2026):
                               * packed Lua (magic D2D1E2E1B2B1C2C1) unpacked (cy_lua_unpack.py) and GBK Lua -> UTF-8
                                 (the UI runs with System_CodePage=65001); free display literals ("...") Vietnamese
                                 by exact match (translation memory + Registry/i18n, cy_lua_i18n.py: sites coupled
                                 to code - comparisons, table keys, name APIs - are never touched; cy-gui-2);
                               * every CY .font gets a CodePage 65001 FreeType variant with NotoSansSC-Regular.ttf
                                 (copied from Assets\\Canonical, the font the user chose) - CY variants kept;
                               * Schema/all.imageset.xml (one file, CY CEGUIBase reads it by name) split into the
                                 <Imageset> files the scheme names (CEGUI 0.4.1 loads one imageset per file);
                               * ConfigFolder StrDictionary.txt = CY keys with Vietnamese text (cy_gui_dict.py),
                                 StrFilter.txt empty (user 13/09), InterfaceEx.txt = CY bytes (10 columns).
         --gui gl            the former layer from Assets\\Canonical (GL): InterfaceFolder, the textures its
                               imagesets and fonts name, ConfigFolder InterfaceEx/StrDictionary/StrFilter (empty).
    Switching layer moves the files of the previous GUI layer that the new plan does not contain to
    Assets\\CanonicalCY\\_backup_gui_<layer>_<stamp>\\ (listed in _manifest/gui_moved.tsv); nothing else is removed.

Folder names follow Canonical: <Archive>.axp -> <Archive>Folder. File names use the engine form (GBK bytes read
as cp1252, Tools/game/stage_game.engine_name), so the ANSI file layer of the engine opens them.

Sources are read only. Assets\\Canonical is read only. Output: Assets\\CanonicalCY\\{Data,_manifest}.

Modes:
  --plan              list every file and its source, collisions, missing; writes _manifest/plan.tsv (no data)
  --apply             write the data root (idempotent: a file whose size and sha256 already match is kept)
  --verify [--deep]   compare the data root with _manifest/files.tsv (size; --deep also sha256), report extras
  --jobs N            worker processes for --apply/--verify (default 6)
  --gui cy|gl         GUI layer (default cy)
"""
import argparse
import map_header_layout
import collections
import concurrent.futures as cf
import csv
import datetime
import hashlib
import json
import os
import re
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
CYS = r'C:\TLBB\085\CY-Source'                      # assets always live in the main tree (git-ignored)
sys.path.insert(0, os.path.join(REPO, 'Docs', 'evidence', 'assetinv'))
import axp_index as AX                                # noqa: E402  (AXP reader, SEPCIAL_FILE_HD decrypt)
sys.path.insert(0, HERE)
import cy_lua_unpack as LUA                           # noqa: E402  (packed CY Lua)
import cy_gui_dict as GDICT                           # noqa: E402  (CY keys + Vietnamese text)
import cy_lua_i18n as LI                              # noqa: E402  (Vietnamese literals in the CY UI scripts)
import cy_item_text as ITX                            # noqa: E402  (item tables: display columns UTF-8 + Vietnamese)
import cy_gui_image_vi as GIV                         # noqa: E402  (labels drawn in GUI textures -> Vietnamese)

TOOL = 'build_canonical_cy.py 1.2 (2026-09-14, --gui cy, Lua/layout/dictionary Vietnamese via Registry/i18n)'
S4 = r'C:\TLBB\085\Tools\DATA NEW\CY Game\Data'
S2 = r'C:\TLBB\085\Tools\DATA NEW\DataCY31-08-26'
GL = os.path.join(CYS, 'Assets', 'Canonical', 'Data')
OUT = os.path.join(CYS, 'Assets', 'CanonicalCY')
DATA = os.path.join(OUT, 'Data')
MAN = os.path.join(OUT, '_manifest')


def set_out(path):
    """ui-image-vi 15/09: --out DIR writes Data, _manifest and _generated below DIR instead of Assets/CanonicalCY
    (a worktree can run --plan / --apply --only without touching the main data root)."""
    global OUT, DATA, MAN, GEN
    OUT = os.path.abspath(path)
    DATA = os.path.join(OUT, 'Data')
    MAN = os.path.join(OUT, '_manifest')
    GEN = os.path.join(OUT, '_generated', 'gui-cy')
ROOT_FILES = ('MaterialTemplates.zip', 'OgreCore.zip', 'ndata.dat')
GUI_CONFIG = ('InterfaceEx.txt', 'StrDictionary.txt', 'StrFilter.txt')
# CY interface files of these kinds are GUI definitions; when GL defines the same base name, GL wins and the CY
# copy is left out (one definition per base name: OGRE resolves recursive locations by base name).
GUI_KINDS = ('.xml', '.lua', '.font', '.ttf', '.ttc', '.otf', '.bin')

_UNDEFINED = (0x81, 0x8D, 0x8F, 0x90, 0x9D)
VIEW = [chr(b) if b in _UNDEFINED else bytes([b]).decode('cp1252') for b in range(256)]
VIEW_SET = frozenset(VIEW)


def view(raw):
    return ''.join(VIEW[b] for b in raw)


def engine_name(name):
    """Same rule as Tools/game/stage_game.engine_name."""
    return name if all(c in VIEW_SET for c in name) else view(name.encode('gbk'))


def lp(path):
    """Long-path form for Windows file APIs."""
    p = os.path.abspath(path)
    return p if p.startswith('\\\\?\\') else '\\\\?\\' + p


def sha256_file(path):
    h = hashlib.sha256()
    with open(lp(path), 'rb') as f:
        for chunk in iter(lambda: f.read(8 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def log(*a):
    msg = ' '.join(str(x) for x in a)
    print(time.strftime('%H:%M:%S'), msg, flush=True)


# ------------------------------------------------------------------------------ CYS-REAPPLY-GUARD (19/09/2026)
# Vi sao khoi nay o day: builder dung lai `Data/ConfigFolder/SceneDefineEx.txt` tu `Config.axp`, nen no
# XOA 121 dong da noi them va TRA 122 dong da sua ve ban CY goc (243 luot ghi cua 6 dot reapply).
# Truoc 19/09 khong co gi bao dieu do: `71-dbc-dupe-check.py` van ra `SO_ID_TRUNG = 0` sau khi mat sach
# 15 dong `client_res` - tuc mat ca pho ban ma phep kiem van xanh. Nen sau moi lan dung lai, builder tu
# goi `Tools/reapply/scenedef/73-scenedef-manifest.py verify` va **tra ma thoat khac 0** neu thieu dong.
# Quyet dinh cua dieu phoi 19/09: phai DO, khong chi canh bao - mot cong thuc phai nho chay tay se khong
# duoc chay dung vao lan nguoi ta quen, tuc dung lan no can thiet.
REAPPLY_VERIFY = os.path.join(CYS, 'Tools', 'reapply', 'scenedef', '73-scenedef-manifest.py')


def reapply_guard(out_json):
    """Chay phep kiem ton tai cua cac dong DBC canh. Tra ve 0 neu du, khac 0 neu thieu/lech/khong chay duoc."""
    import subprocess
    dbc = os.path.join(DATA, 'ConfigFolder', 'SceneDefineEx.txt')
    gach = '=' * 96
    if not os.path.exists(REAPPLY_VERIFY):
        log(gach)
        log('CYS-REAPPLY-GUARD: KHONG THAY', REAPPLY_VERIFY, '- KHONG kiem duoc cac dong DBC canh.')
        log('  Dung ket luan "khong sao": day dung la luc chung de mat nhat. Xem Tools/reapply/README_vi.md.')
        log(gach)
        return 1
    if not os.path.exists(dbc):
        log('CYS-REAPPLY-GUARD: khong co', dbc, '- bo qua (lan dung nay khong ghi bang do).')
        return 0
    cmd = [sys.executable, '-X', 'utf8', REAPPLY_VERIFY, 'verify', '--dbc', dbc, '--out', out_json]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='replace')
    except OSError as e:
        log('CYS-REAPPLY-GUARD: khong chay duoc phep kiem:', e)
        return 1
    try:
        with open(out_json, encoding='utf-8') as f:
            rec = json.load(f)
    except (OSError, ValueError):
        log('CYS-REAPPLY-GUARD: phep kiem khong tra ve JSON doc duoc; stderr:', (p.stderr or '')[:400])
        return 1
    if rec.get('ok'):
        log('CYS-REAPPLY-GUARD: OK - du %d dong DBC canh (client_res: %s), %d dong x %d cot.'
            % (rec['bang_ke']['so_ID'], rec['CLIENT_RES']['canh_bao'], rec['so_dong'], rec['so_cot']))
        return 0
    log(gach)
    log('CYS-REAPPLY-GUARD: DU LIEU DBC CANH DA MAT - PHAI AP LAI TRUOC KHI CHOI/DO.')
    log('  MAT  %d dong (khong con dong nao o ID do):   %s' % (rec['SO_DONG_MAT'], rec['mat_theo_dot']))
    log('  LECH %d dong (co dong nhung o khac bang ke): %s' % (rec['SO_DONG_LECH'], rec['lech_theo_dot']))
    cr = rec['CLIENT_RES']
    if cr['so_MAT']:
        log('  *** client_res: %s' % cr['canh_bao'])
    if rec.get('bat_bien_vi_pham'):
        log('  bat bien vi pham: %s' % rec['bat_bien_vi_pham'])
    log('  Cach chua: chay day du cac buoc trong Tools/reapply/README_vi.md muc `scenedef/`,')
    log('             roi kiem lai bang: python -X utf8 %s verify' % os.path.relpath(REAPPLY_VERIFY, CYS))
    log('  Chi tiet tung dong: %s' % out_json)
    log('  (Chay lai builder voi --skip-reapply-check de bo qua co y - dung lam viec do theo thoi quen.)')
    log(gach)
    return 1


# ----------------------------------------------------------------------------------------------------- S4 plan
def s4_archive_plan(axp_path):
    """[(rel_dest, archive_name, list_size, entry_off, entry_size, wrapper, payload_len)] for one archive."""
    a = AX.Axp(axp_path)
    stem = os.path.splitext(os.path.basename(axp_path))[0]
    folder = stem + 'Folder'
    rows = []
    missing = []
    fl = a.file_list() or []
    for name, rest in fl:
        ent = a.entry(name)
        if ent is None:
            missing.append((stem, name, 'listed but not in hash table'))
            continue
        head = a.read(ent, AX.HDR_SIZE)
        hd = AX.decode_header(head, ent[1])
        if hd is None:
            wrap, plen = 0, ent[1]
        else:
            wrap, plen = hd[0], hd[1]
        rel = folder + '\\' + engine_name(name.replace('/', '\\'))
        rows.append((rel, name, int(rest[0], 16) if rest and rest[0] else -1, ent[0], ent[1], wrap, plen))
    a.f.close()
    return stem, rows, missing


def s2_path(stem, name):
    return os.path.join(S2, stem, name.replace('/', '\\'))


# ----------------------------------------------------------------------------------------------- GUI (GL) plan
_ATTR = re.compile(rb'\b(Imagefile|Filename|Source|File)\s*=\s*"([^"]+)"', re.I)


def gl_index():
    """lower engine-form relpath (from Data) -> real relpath, and lower base name -> [relpath]."""
    by_rel, by_base = {}, collections.defaultdict(list)
    for dirpath, dirs, files in os.walk(GL):
        for fn in files:
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, GL)
            by_rel[rel.lower()] = rel
            by_base[fn.lower()].append(rel)
    return by_rel, by_base


def attr_to_engine(raw):
    try:
        s = raw.decode('utf-8')
        return engine_name(s)
    except UnicodeDecodeError:
        return view(raw)


def gui_plan():
    by_rel, by_base = gl_index()
    files = {}
    unresolved = []
    for rel in by_rel.values():
        top = rel.split('\\', 1)[0]
        if top == 'InterfaceFolder':
            files[rel] = 'gl-interface'
        elif top == 'ConfigFolder' and rel.split('\\')[-1] in GUI_CONFIG:
            files[rel] = 'gl-gui-config'
    # textures / fonts named by imagesets, fonts, schemes and looknfeels
    tops = sorted({r.split('\\', 1)[0] for r in by_rel.values() if '\\' in r})
    for rel in list(files):
        low = rel.lower()
        if not (low.endswith('.xml') or low.endswith('.font')):
            continue
        with open(lp(os.path.join(GL, rel)), 'rb') as f:
            data = f.read()
        for m in _ATTR.finditer(data):
            val = attr_to_engine(m.group(2)).replace('/', '\\')
            base = val.split('\\')[-1].lower()
            if not re.search(r'\.(dds|tga|png|jpg|jpeg|bmp|ttf|ttc|otf|font|xml)$', base):
                continue
            hit = None
            for t in tops:
                cand = (t + '\\' + val).lower()
                if cand in by_rel:
                    hit = by_rel[cand]
                    break
            if hit is None and by_base.get(base):
                hit = by_base[base][0]
            if hit is None:
                unresolved.append((rel, m.group(1).decode(), val))
                continue
            if hit not in files:
                files[hit] = 'gl-gui-texture'
    return files, unresolved


# ----------------------------------------------------------------------------------------------- GUI (CY) plan
GEN = os.path.join(OUT, '_generated', 'gui-cy')
NOTO_REL = 'InterfaceFolder\\Schema\\NotoSansSC-Regular.ttf'
NOTO_SHA256 = 'd45f67f0a7c0ca3f256950777ce6a61cc7ce5f9696d02900cbbaac25f8aa7d16'   # user file 12/09 (fonts_vi.md)
NOTO_ATTR = b'Schema/NotoSansSC-Regular.ttf'
_FONT = re.compile(rb'<Font\b[^>]*/>')
_ATTRV = re.compile(rb'(\w+)\s*=\s*"([^"]*)"')


LUA_VI = {}         # zh -> vi for the free display literals (filled by cy_gui_generate, passed to the workers)
LUA_EXCL = set()    # literals coupled to code somewhere (never translated)


def lua_vi(data, notes):
    """UTF-8 Lua bytes -> (bytes, note) with the free display literals translated (LUA_VI)."""
    if not LUA_VI:
        return data, '+'.join(notes)
    try:
        text = data.decode('utf-8')
    except UnicodeDecodeError:
        return data, '+'.join(notes + ['lua-vi-skipped(undecodable)'])
    try:
        out, n, _stats = LI.translate(text, LUA_VI.get, LUA_EXCL)
    except ValueError as ex:
        return data, '+'.join(notes + ['lua-vi-rejected(%s)' % str(ex)[:60]])
    if not n:
        return data, '+'.join(notes)
    return out.encode('utf-8'), '+'.join(notes + ['lua-vi(%d)' % n])


def xform_lua(data):
    """Packed -> plain; GBK -> UTF-8; free display literals -> Vietnamese. Returns (bytes, note)."""
    notes = []
    plain = LUA.unpack(data)
    if plain is not None:
        data, notes = plain, ['unpacked']
    try:
        data.decode('utf-8')
        return lua_vi(data, notes + ['utf8-kept'])
    except UnicodeDecodeError:
        pass
    for enc in ('gbk', 'gb18030'):
        try:
            return lua_vi(data.decode(enc).encode('utf-8'), notes + [enc + '->utf8'])
        except UnicodeDecodeError:
            continue
    # mixed encodings inside one file (CY DressPaint_sp.lua): decide per line, keep undecodable lines as bytes
    out, kept = [], 0
    for line in data.split(b'\n'):
        if all(b < 128 for b in line):
            out.append(line)
            continue
        for enc in ('utf-8', 'gbk', 'gb18030'):
            try:
                out.append(line.decode(enc).encode('utf-8'))
                break
            except UnicodeDecodeError:
                continue
        else:
            out.append(line)
            kept += 1
    return lua_vi(b'\n'.join(out), notes + ['per-line->utf8(%d raw lines kept)' % kept])


def xform_font(data):
    """Append a CodePage 65001 Noto variant to a CY <Fonts> file (kept unchanged when one exists)."""
    fonts = [dict(_ATTRV.findall(m.group(0))) for m in _FONT.finditer(data)]
    if not fonts or any(f.get(b'CodePage') == b'65001' for f in fonts):
        return data, 'font-kept'
    first = fonts[0]
    attrs = [(b'Name', first.get(b'Name', b'')), (b'Filename', NOTO_ATTR), (b'Size', first.get(b'Size', b'12'))]
    if b'AntiAlias' in first:
        attrs.append((b'AntiAlias', first[b'AntiAlias']))
    attrs += [(b'TextureSize', b'512'), (b'CodePage', b'65001'), (b'Type', b'FreeType')]
    line = b'<Font ' + b' '.join(k + b'="' + v + b'"' for k, v in attrs) + b'/>'
    nl = b'\r\n' if b'\r\n' in data else b'\n'
    end = data.rfind(b'</Fonts>')
    if end < 0:
        return data, 'font-no-Fonts-element-kept'
    head = data[:end]
    if not head.endswith(nl):
        head += nl
    return head + line + nl + data[end:], 'font+noto65001'


_LAYOUT_TEXT = re.compile(rb'(<Property\s+Name="(?:Text|Tooltip|ColumnHeader)"\s+Value=")([^"]*)(")')
LAYOUT_VI = {}      # zh -> vi, filled by cy_gui_generate() and passed to the workers


def decode_xml(data):
    """(text, encoder) for the four encodings CY layouts use (ascii, utf-8, utf-8 BOM, utf-16)."""
    if data[:2] in (b'\xff\xfe', b'\xfe\xff'):
        enc = 'utf-16-le' if data[:2] == b'\xff\xfe' else 'utf-16-be'
        return data[2:].decode(enc), lambda s: data[:2] + s.encode(enc)
    if data[:3] == b'\xef\xbb\xbf':
        return data[3:].decode('utf-8'), lambda s: b'\xef\xbb\xbf' + s.encode('utf-8')
    return data.decode('utf-8'), lambda s: s.encode('utf-8')


def xform_layout(data):
    """Display texts of a CY layout (Text/Tooltip/ColumnHeader) translated by exact match (LAYOUT_VI)."""
    try:
        text, encode = decode_xml(data)
    except UnicodeDecodeError:
        return data, 'layout-undecodable-kept'
    n = [0]

    def sub(m):
        vi = LAYOUT_VI.get(m.group(2))
        if vi is None or '"' in vi:
            return m.group(0)
        n[0] += 1
        return m.group(1) + vi + m.group(3)

    out = re.sub(r'(<Property\s+Name="(?:Text|Tooltip|ColumnHeader)"\s+Value=")([^"]*)(")', sub, text)
    out, header_changed = map_header_layout.transform(out)
    if not n[0] and not header_changed:
        return data, 'layout-kept'
    return encode(out), 'layout-vi(%d)%s' % (n[0], '-minimap-header' if header_changed else '')


XFORMS = {'lua': xform_lua, 'font': xform_font, 'layout': xform_layout}


def write_if_changed(path, data):
    if os.path.exists(lp(path)) and os.path.getsize(lp(path)) == len(data):
        with open(lp(path), 'rb') as f:
            if f.read() == data:
                return False
    os.makedirs(lp(os.path.dirname(path)), exist_ok=True)
    with open(lp(path + '.part'), 'wb') as f:
        f.write(data)
    os.replace(lp(path + '.part'), lp(path))
    return True


def cy_gui_generate():
    """Write derived GUI files into GEN. Returns (files {rel: (src, layer)}, stats, unresolved, dict_rows, untr)."""
    stats = collections.Counter()
    files, unresolved = {}, []
    ia = AX.Axp(os.path.join(S4, 'Interface.axp'))
    names = {n.replace('/', '\\').lower(): n for n, _ in ia.file_list()}
    _, scheme = ia.payload_full('Schema/WoWLookSkin.scheme.xml', 64 << 20)
    _, allset = ia.payload_full('Schema/all.imageset.xml', 256 << 20)
    chunks = {}
    for m in re.finditer(rb'<Imageset\b[^>]*?\bName="([^"]+)"[^>]*>.*?</Imageset>', allset, re.S):
        chunks.setdefault(m.group(1), m.group(0))
    stats['all_imageset_chunks'] = len(chunks)
    used = set()
    for m in re.finditer(rb'<Imageset\b[^>]*/>', scheme):
        at = dict(_ATTRV.findall(m.group(0)))
        name, fn = at.get(b'Name'), at.get(b'Filename')
        if not name or not fn:
            continue
        stats['scheme_imagesets'] += 1
        relf = fn.decode('utf-8').replace('/', '\\')
        if relf.lower() in names:
            stats['scheme_imageset_real_file'] += 1
            continue
        chunk = chunks.get(name)
        if chunk is None:
            unresolved.append(('Schema\\WoWLookSkin.scheme.xml', 'Imageset', name.decode() + ' -> ' + relf))
            stats['scheme_imageset_unresolved'] += 1
            continue
        used.add(name)
        rel = 'InterfaceFolder\\' + engine_name(relf)
        if rel in files:
            stats['scheme_imageset_duplicate_filename'] += 1
            continue
        data = b'<?xml version="1.0" ?>\r\n' + chunk + b'\r\n'
        src = os.path.join(GEN, rel)
        stats['imageset_split_written'] += write_if_changed(src, data)
        files[rel] = (src, 'cy-gui-imageset-split')
    stats['all_imageset_not_in_scheme'] = len(set(chunks) - used)
    # display texts of the layouts (Text/Tooltip/ColumnHeader), translated by exact match like apply_xml.py
    texts = set()
    for low, name in names.items():
        if not low.endswith('.layout.xml'):
            continue
        _, raw = ia.payload_full(name, 32 << 20)
        try:
            text, _enc = decode_xml(raw)
        except UnicodeDecodeError:
            continue
        for m in re.finditer(r'<Property\s+Name="(?:Text|Tooltip|ColumnHeader)"\s+Value="([^"]*)"', text):
            if m.group(1):
                texts.add(m.group(1))
    extra = GDICT.Extra()
    layout_vi, tstats = GDICT.translate_strings(sorted(texts), extra=extra)
    stats['layout_texts'] = len(texts)
    stats['layout_texts_translated'] = len(layout_vi)
    for k, v in tstats.items():
        stats['layout_text_' + k] = v
    files_layout_vi = layout_vi
    layout_untr = sorted(t for t in texts if t not in layout_vi and GDICT.HAN.search(GDICT.TOK.sub('', t)))
    # free display literals of the Lua scripts (cy_lua_i18n): exact match, code-coupled literals excluded everywhere
    lua_texts = []
    for low, name in names.items():
        if low.endswith('.lua'):
            _, raw = ia.payload_full(name, 32 << 20)
            lua_texts.append(LI.decode_lua(raw, LUA.unpack))
    free, coupled = LI.census(lua_texts)
    lua_excl = set(coupled)
    free_lits = sorted(z for z in free if z not in lua_excl and z.strip() not in lua_excl)
    lua_vi_map, lstats = GDICT.translate_strings(free_lits, extra=extra)
    stats['lua_scripts'] = len(lua_texts)
    stats['lua_literals_han'] = len(free) + len(coupled)
    stats['lua_literals_coupled_excluded'] = len(coupled)
    stats['lua_literals_free'] = len(free_lits)
    stats['lua_literals_translated'] = len(lua_vi_map)
    for k, v in lstats.items():
        stats['lua_literal_' + k] = v
    lua_untr = sorted(z for z in free_lits if z not in lua_vi_map)
    files_lua = (lua_vi_map, lua_excl, lua_untr, layout_untr,
                 sorted((z, ','.join('%s:%d' % kv for kv in sorted(c.items()))) for z, c in coupled.items()))
    # dictionary
    ca = AX.Axp(os.path.join(S4, 'Config.axp'))
    _, raw = ca.payload_full('StrDictionary.txt', 256 << 20)
    text, dstats, dict_rows, untr = GDICT.build(raw, os.path.join(GL, 'ConfigFolder', 'StrDictionary.txt'))
    rel = 'ConfigFolder\\StrDictionary.txt'
    src = os.path.join(GEN, rel)
    write_if_changed(src, text)
    files[rel] = (src, 'cy-gui-dict-vi')
    files['ConfigFolder\\StrFilter.txt'] = (os.path.join(GL, 'ConfigFolder', 'StrFilter.txt'), 'gui-strfilter-empty')
    files[NOTO_REL] = (os.path.join(GL, NOTO_REL), 'user-font-noto')
    # CYS-ITEMTEXT 15/09: item tables (EquipBase, CommonItem, GemInfo ...) with their display columns GBK -> UTF-8 +
    # Vietnamese; resource-key columns byte-identical (cy_item_text.verify); manifests _manifest/item_text*.tsv
    item_files, item_stats, _ = ITX.generate(ca, GEN, MAN)
    for rel, src in item_files:
        files[rel] = (src, ITX.LAYER)
    stats['item_text'] = item_stats
    # CYS-UIVI 15/09: labels drawn into GUI textures repainted in Vietnamese (Registry/i18n/cy_gui_image_vi.tsv); the
    # source texture is the CY 3.71 entry (S4, S2 for wrappers 1-18), file name unchanged; manifest gui_image_vi.tsv
    img_files, img_manifest, img_problems, img_stats = GIV.generate(
        GIV.AxpReader(ia, S2 + '\\Interface', AX), GEN, font_path=os.path.join(GL, NOTO_REL))
    for rel, src in img_files:
        files[engine_name(rel.split('\\', 1)[0]) + '\\' + engine_name(rel.split('\\', 1)[1])] = (src, GIV.LAYER)
    GIV.write_tsv(os.path.join(MAN, 'gui_image_vi.tsv'), GIV.MANIFEST_HEADER, img_manifest)
    GIV.write_tsv(os.path.join(MAN, 'gui_image_vi_problems.tsv'), ['registry_line', 'name', 'problem'], img_problems)
    stats['gui_image_vi'] = img_stats
    if img_problems:
        unresolved += [('Registry/i18n/cy_gui_image_vi.tsv:%s' % p[0], 'image-vi', '%s: %s' % (p[1], p[2]))
                       for p in img_problems]
    ia.f.close()
    ca.f.close()
    stats = dict(stats)
    stats['dictionary'] = dstats
    stats['_layout_vi'] = files_layout_vi
    stats['_lua'] = files_lua
    return files, stats, unresolved, dict_rows, untr


# ------------------------------------------------------------------------------------------------------ apply
def extract_archive(task):
    """Worker: write one archive's entries. Returns (stem, rows, errors)."""
    stem, axp_path, rows, force, layout_vi, lua = task
    if layout_vi:
        LAYOUT_VI.update(layout_vi)
    if lua:
        LUA_VI.update(lua[0])
        LUA_EXCL.update(lua[1])
    out, errors = [], []
    with open(axp_path, 'rb') as f:
        for rel, name, list_size, off, size, wrap, plen, skip, xform in sorted(rows, key=lambda r: r[3]):
            dest = os.path.join(DATA, rel)
            try:
                if skip:
                    out.append((rel, -1, '', 'excluded', f'{stem}.axp:{name}', wrap, skip))
                    continue
                if wrap and wrap < 19:
                    src = s2_path(stem, name)
                    with open(lp(src), 'rb') as g:
                        data = g.read(plen + 64)
                    if len(data) < plen:
                        errors.append((rel, f'S2 shorter than S4 payload ({len(data)} < {plen})'))
                        continue
                    data = data[:plen]
                    layer, source = 'cy-s2-w1-18', 'S2:' + os.path.relpath(src, S2)
                else:
                    f.seek(off)
                    raw = f.read(size)
                    if wrap:
                        data = AX.decrypt(raw[AX.HDR_SIZE:], wrap, plen)
                        if data is None:
                            errors.append((rel, f'wrapper {wrap} not decryptable'))
                            continue
                        data = data[:plen]
                        layer = 'cy-s4-w19-25'
                    else:
                        data = raw
                        layer = 'cy-s4-plain'
                    source = f'S4:{stem}.axp:{name}'
                if xform:
                    data, note = XFORMS[xform](data)
                    layer = 'cy-gui-' + xform
                    source += ' [' + note + ']'
                    if 'no-Fonts' in note or ('raw lines kept' in note and '(0 raw' not in note):
                        errors.append((rel, 'transform: ' + note))
                sha = hashlib.sha256(data).hexdigest()
                need = True
                if not force and os.path.exists(lp(dest)) and os.path.getsize(lp(dest)) == len(data):
                    need = sha256_file(dest) != sha
                if need:
                    os.makedirs(lp(os.path.dirname(dest)), exist_ok=True)
                    tmp = dest + '.part'
                    with open(lp(tmp), 'wb') as g:
                        g.write(data)
                    os.replace(lp(tmp), lp(dest))
                out.append((rel, len(data), sha, layer, source, wrap, 'written' if need else 'kept'))
            except OSError as ex:
                errors.append((rel, f'{type(ex).__name__}: {ex}'))
    return stem, out, errors


def copy_file(task):
    rel, src, layer, force = task
    dest = os.path.join(DATA, rel)
    sha = sha256_file(src)
    size = os.path.getsize(lp(src))
    need = force or not (os.path.exists(lp(dest)) and os.path.getsize(lp(dest)) == size and sha256_file(dest) == sha)
    if need:
        os.makedirs(lp(os.path.dirname(dest)), exist_ok=True)
        tmp = dest + '.part'
        with open(lp(src), 'rb') as a, open(lp(tmp), 'wb') as b:
            for chunk in iter(lambda: a.read(8 << 20), b''):
                b.write(chunk)
        os.replace(lp(tmp), lp(dest))
    return rel, size, sha, layer, src, 0, 'written' if need else 'kept'


def verify_one(task):
    rel, size, sha, deep = task
    p = os.path.join(DATA, rel)
    if not os.path.exists(lp(p)):
        return rel, 'missing'
    if os.path.getsize(lp(p)) != size:
        return rel, 'size'
    if deep and sha256_file(p) != sha:
        return rel, 'sha256'
    return rel, 'ok'


# ------------------------------------------------------------------------------------------------------- main
def build_plan(gui_mode='cy'):
    """gui: {rel: layer} (gl) or {rel: (src, layer)} (cy, files copied from disk)."""
    archives = sorted(p for p in os.listdir(S4) if p.lower().endswith('.axp'))
    s4 = {}
    missing = []
    with cf.ProcessPoolExecutor(max_workers=6) as ex:
        for stem, rows, miss in ex.map(s4_archive_plan, [os.path.join(S4, a) for a in archives]):
            s4[stem] = rows
            missing += miss
    gen_stats = {}
    if gui_mode == 'gl':
        gui, unresolved = gui_plan()
        gui_rel_low = {r.lower() for r in gui}
        gui_base = collections.defaultdict(list)
        for r in gui:
            gui_base[r.split('\\')[-1].lower()].append(r)
    else:
        gui, gen_stats, unresolved, dict_rows, untr = cy_gui_generate()
        gen_stats['_dict_rows'], gen_stats['_untranslated'] = dict_rows, untr
        gui_rel_low = {r.lower() for r in gui}          # generated files replace the S4 entry of the same path
        gui_base = {}
    # collisions
    plan = []            # (rel, layer, source, extra)
    excluded = []
    stats = collections.Counter()
    for stem, rows in s4.items():
        for rel, name, list_size, off, size, wrap, plen in rows:
            low = rel.lower()
            base = low.split('\\')[-1]
            skip = ''
            xform = ''
            if low in gui_rel_low:
                skip = ('same relpath in GL GUI layer (GL wins)' if gui_mode == 'gl'
                        else 'replaced by the CY GUI layer (generated: dictionary/strfilter/imageset/font)')
            elif base in gui_base and (stem == 'Interface' or base.endswith(GUI_KINDS)):
                skip = 'same base name in GL GUI layer (GL wins): ' + gui_base[base][0]
            elif base in gui_base:
                stats['cy_basename_shared_with_gui_kept'] += 1
            if gui_mode == 'cy' and stem == 'Interface' and not skip:
                if low.endswith('.lua'):
                    xform = 'lua'
                elif low.endswith('.font'):
                    xform = 'font'
                elif low.endswith('.layout.xml'):
                    xform = 'layout'
            if wrap and wrap < 19 and not os.path.exists(lp(s2_path(stem, name))):
                missing.append((stem, name, 'wrapper 1-18 and no S2 file'))
                skip = skip or 'no source (w1-18 without S2)'
            if skip:
                excluded.append((rel, f'{stem}.axp:{name}', skip))
                stats['excluded'] += 1
            key = 'plain' if not wrap else ('w1-18' if wrap < 19 else 'w19-25')
            stats['s4_' + key] += 1
            plan.append((rel, stem, name, list_size, off, size, wrap, plen, skip, xform))
    # NTFS is case-insensitive: two GBK names can map to engine names that differ only by cp1252 case
    # (e.g. 文 CE C4 -> 'ÎÄ' and 武 CE E4 -> 'Îä'). Keep the smallest original name, exclude the rest.
    groups = collections.defaultdict(list)
    for i, row in enumerate(plan):
        if not row[8]:
            groups[row[0].lower()].append(i)
    for idxs in groups.values():
        if len(idxs) < 2:
            continue
        idxs.sort(key=lambda i: plan[i][2])
        kept = plan[idxs[0]]
        for i in idxs[1:]:
            row = plan[i]
            reason = f'case-insensitive name collision with {kept[1]}.axp:{kept[2]}'
            plan[i] = row[:8] + (reason,) + row[9:]
            excluded.append((row[0], f'{row[1]}.axp:{row[2]}', reason))
            stats['excluded'] += 1
            stats['case_collisions'] += 1
    return archives, s4, plan, gui, unresolved, excluded, missing, stats, gen_stats


def write_tsv(path, header, rows):
    with open(lp(path), 'w', encoding='utf-8', newline='\n') as f:
        f.write('\t'.join(header) + '\n')
        for r in rows:
            f.write('\t'.join('' if x is None else str(x) for x in r) + '\n')


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--plan', action='store_true')
    g.add_argument('--apply', action='store_true')
    g.add_argument('--verify', action='store_true')
    ap.add_argument('--deep', action='store_true')
    ap.add_argument('--force', action='store_true')
    ap.add_argument('--jobs', type=int, default=6)
    ap.add_argument('--only', help='comma list of archive stems for --apply (debug)')
    ap.add_argument('--gui', choices=('cy', 'gl'), default='cy', help='GUI layer (default cy)')
    ap.add_argument('--out', help='data root folder instead of Assets/CanonicalCY (Data, _manifest, _generated)')
    # CYS-REAPPLY-GUARD: mac dinh LUON kiem sau --apply / --verify; co nay chi de bo qua CO Y.
    ap.add_argument('--skip-reapply-check', action='store_true',
                    help='bo qua phep kiem 243 dong DBC canh (Tools/reapply/scenedef/73-scenedef-manifest.py)')
    args = ap.parse_args()
    if args.out:
        set_out(args.out)
    os.makedirs(MAN, exist_ok=True)
    t0 = time.time()

    if args.verify:
        with open(lp(os.path.join(MAN, 'files.tsv')), encoding='utf-8') as f:
            rows = [r for r in csv.DictReader(f, delimiter='\t', quoting=csv.QUOTE_NONE) if r['size'] != '-1']
        want = {r['relpath']: r for r in rows}
        res = collections.Counter()
        bad = []
        with cf.ProcessPoolExecutor(max_workers=args.jobs) as ex:
            for rel, st in ex.map(verify_one, [(r['relpath'], int(r['size']), r['sha256'], args.deep) for r in rows],
                                  chunksize=256):
                res[st] += 1
                if st != 'ok':
                    bad.append((rel, st))
        extras = []
        wl = {k.lower() for k in want}
        for dirpath, dirs, files in os.walk(lp(DATA)):
            for fn in files:
                rel = os.path.relpath(os.path.join(dirpath, fn), lp(DATA))
                if rel.lower() not in wl:
                    extras.append(rel)
        rep = {'tool': TOOL, 'mode': 'verify-deep' if args.deep else 'verify', 'at': datetime.datetime.now().isoformat(
            timespec='seconds'), 'files': len(rows), 'result': dict(res), 'extras': len(extras),
            'bad_examples': bad[:40], 'extra_examples': extras[:40], 'seconds': round(time.time() - t0, 1)}
        with open(lp(os.path.join(MAN, 'verify-deep.json' if args.deep else 'verify.json')), 'w',
                  encoding='utf-8') as f:
            json.dump(rep, f, ensure_ascii=False, indent=1)
        print(json.dumps(rep, ensure_ascii=False, indent=1))
        rc = 0 if res.get('ok', 0) == len(rows) and not extras else 1
        # CYS-REAPPLY-GUARD: `--verify` chi so voi files.tsv, ma files.tsv la ANH CHUP LUC DUNG -> no
        # KHONG biet 243 dong reapply. Khong noi them phep kiem nay thi `--verify` xanh tren mot cay
        # da mat het dong `client_res`.
        if not args.skip_reapply_check:
            rc |= reapply_guard(os.path.join(MAN, 'reapply-guard.json'))
        sys.exit(rc)

    log(f'planning (reading 23 AXP indexes + GUI layer {args.gui})')
    prev_files = []
    if os.path.exists(lp(os.path.join(MAN, 'files.tsv'))):
        with open(lp(os.path.join(MAN, 'files.tsv')), encoding='utf-8') as f:
            prev_files = [(r['relpath'], r['layer']) for r in csv.DictReader(f, delimiter='\t', quoting=csv.QUOTE_NONE)
                          if r['size'] != '-1']
    archives, s4, plan, gui, unresolved, excluded, missing, stats, gen_stats = build_plan(args.gui)
    layout_vi = gen_stats.pop('_layout_vi', None)
    lua_pack = gen_stats.pop('_lua', None)
    if lua_pack:
        write_tsv(os.path.join(MAN, 'gui_lua_untranslated.tsv'), ['zh'], [(z,) for z in lua_pack[2]])
        write_tsv(os.path.join(MAN, 'gui_layout_untranslated.tsv'), ['zh'], [(z,) for z in lua_pack[3]])
        write_tsv(os.path.join(MAN, 'gui_lua_excluded.tsv'), ['zh', 'contexts'], lua_pack[4])
    write_tsv(os.path.join(MAN, 'plan.tsv'), ['relpath', 'archive', 'name', 'list_size', 'offset', 'stored_size',
                                               'wrapper', 'payload_len', 'excluded', 'transform'], plan)
    write_tsv(os.path.join(MAN, 'excluded.tsv'), ['relpath', 'source', 'reason'], excluded)
    write_tsv(os.path.join(MAN, 'missing.tsv'), ['archive', 'name', 'reason'], missing)
    if args.gui == 'gl':
        gui_rows = sorted(gui.items())
        gui_copy = [(rel, os.path.join(GL, rel), layer) for rel, layer in gui_rows]
    else:
        gui_copy = [(rel, src, layer) for rel, (src, layer) in sorted(gui.items())]
        gui_rows = [(rel, layer) for rel, src, layer in gui_copy]
        gui_rows += [(r[0], 'cy-gui-' + r[9] if r[9] else 'cy-s4-interface') for r in plan
                     if not r[8] and r[1] == 'Interface']
        gui_rows += [(r[0], 'cy-s4-gui-table') for r in plan
                     if not r[8] and r[0].lower() == 'configfolder\\interfaceex.txt']
        gui_rows.sort()
        write_tsv(os.path.join(MAN, 'gui_dict.tsv'), ['key', 'source'], gen_stats.pop('_dict_rows'))
        write_tsv(os.path.join(MAN, 'gui_dict_untranslated.tsv'), ['key', 'zh', 'scope'],
                  gen_stats.pop('_untranslated'))
    write_tsv(os.path.join(MAN, 'gui_layer.tsv'), ['relpath', 'layer'], gui_rows)
    write_tsv(os.path.join(MAN, 'gui_unresolved.tsv'), ['referrer', 'attribute', 'value'], unresolved)
    # destination name clashes inside CY itself (two archives mapping to the same relpath cannot happen: one folder
    # per archive) and names that are not representable (non-GBK) are reported by engine_name raising.
    dup_base = collections.Counter(r[0].split('\\')[-1].lower() for r in plan if not r[8])
    stats['cy_duplicate_basenames'] = sum(1 for v in dup_base.values() if v > 1)
    summary = {'tool': TOOL, 'gui': args.gui, 'at': datetime.datetime.now().isoformat(timespec='seconds'),
               'archives': len(archives), 's4_entries': len(plan), 'gui_layer_files': len(gui_rows),
               'gui_by_layer': dict(collections.Counter(layer for _, layer in gui_rows)),
               'gui_unresolved_refs': len(unresolved), 'gui_generate': gen_stats, 'missing': len(missing),
               'excluded': len(excluded), 'stats': dict(stats)}
    log('plan', json.dumps(summary, ensure_ascii=False))
    if args.plan:
        with open(lp(os.path.join(MAN, 'plan-summary.json')), 'w', encoding='utf-8') as f:
            json.dump(summary, f, ensure_ascii=False, indent=1)
        return

    only = set(args.only.split(',')) if args.only else None
    tasks = []
    by = collections.defaultdict(list)
    for row in plan:
        by[row[1]].append((row[0],) + row[2:])
    for stem in sorted(by, key=lambda s: -os.path.getsize(os.path.join(S4, s + '.axp'))):
        if only and stem not in only:
            continue
        tasks.append((stem, os.path.join(S4, stem + '.axp'), by[stem], args.force,
                      layout_vi if stem == 'Interface' else None,
                      (lua_pack[0], lua_pack[1]) if (lua_pack and stem == 'Interface') else None))
    files, errors = [], []
    with cf.ProcessPoolExecutor(max_workers=args.jobs) as ex:
        futs = [ex.submit(extract_archive, t) for t in tasks]
        for fu in cf.as_completed(futs):
            stem, out, err = fu.result()
            files += out
            errors += err
            log(f'{stem}: {len(out)} rows, {sum(1 for r in out if r[6] == "written")} written, {len(err)} errors')
        if not only:
            ctasks = [(r, os.path.join(S4, r), 'cy-s4-root', args.force) for r in ROOT_FILES]
            ctasks += [(rel, src, layer, args.force) for rel, src, layer in gui_copy]
            for res in ex.map(copy_file, ctasks, chunksize=64):
                files.append(res)
            log(f'root + GUI layer: {len(ctasks)} files')
    files.sort()
    moved = []
    if not only:
        # files of the previous GUI layer that the new plan does not write: move them out of Data (never delete)
        new_low = {r[0].lower() for r in files if r[1] != -1}
        other = 'gl-' if args.gui == 'cy' else 'cy-gui-'
        stamp = time.strftime('%Y%m%d-%H%M%S')
        bdir = os.path.join(OUT, f'_backup_gui_{other.rstrip("-")}_{stamp}')
        for rel, layer in prev_files:
            if not (layer.startswith(other) or (other == 'cy-gui-' and layer in ('user-font-noto',
                                                                                  'gui-strfilter-empty'))):
                continue
            if rel.lower() in new_low or not os.path.exists(lp(os.path.join(DATA, rel))):
                continue
            dest = os.path.join(bdir, rel)
            os.makedirs(lp(os.path.dirname(dest)), exist_ok=True)
            os.replace(lp(os.path.join(DATA, rel)), lp(dest))
            moved.append((rel, layer, dest))
        write_tsv(os.path.join(MAN, 'gui_moved.tsv'), ['relpath', 'previous_layer', 'moved_to'], moved)
        # empty folders left by the move
        for dirpath, dirs, fnames in sorted(os.walk(lp(os.path.join(DATA, 'InterfaceFolder'))), key=lambda t: -len(t[0])):
            if not dirs and not fnames and os.path.normcase(dirpath) != os.path.normcase(lp(os.path.join(DATA, 'InterfaceFolder'))):
                try:
                    os.rmdir(dirpath)
                except OSError:
                    pass
        log(f'previous GUI layer: {len(moved)} files moved to {bdir if moved else "(none)"}')
    write_tsv(os.path.join(MAN, 'files.tsv' if not only else 'files-partial.tsv'),
              ['relpath', 'size', 'sha256', 'layer', 'source', 'wrapper', 'action'], files)
    write_tsv(os.path.join(MAN, 'errors.tsv'), ['relpath', 'error'], errors)
    real = [r for r in files if r[1] != -1]
    summary.update({'finished': datetime.datetime.now().isoformat(timespec='seconds'), 'files': len(real),
                    'bytes': sum(r[1] for r in real), 'by_layer': dict(collections.Counter(r[3] for r in real)),
                    'written_now': sum(1 for r in real if r[6] == 'written'), 'errors': len(errors),
                    'gui_moved_out': len(moved), 'seconds': round(time.time() - t0, 1)})
    with open(lp(os.path.join(MAN, 'canonical_cy.json')), 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)
    log(json.dumps(summary, ensure_ascii=False))
    # CYS-REAPPLY-GUARD: lan dung nay vua ghi de SceneDefineEx.txt -> 243 dong reapply gan nhu chac chan
    # da mat. Bao DO ngay tai day, dung de nguoi ta phai nho chay tay.
    if not args.skip_reapply_check:
        sys.exit(reapply_guard(os.path.join(MAN, 'reapply-guard.json')))


if __name__ == '__main__':
    main()
