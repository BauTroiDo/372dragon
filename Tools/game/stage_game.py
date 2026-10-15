#!/usr/bin/env python3
"""CY-Source Tools/game/stage_game.py - private Game.exe stage on Canonical (client_GL) data.

Commands
  build --name NAME [--bin DIR] [--no-creation] [--profile-stage DIR] [--play]
      Build/game-data/NAME/
        Bin64/    Game.exe + DLLs of one build output (default: the game-data worktree build), runtime DLLs/media the
                  build does not produce (from the CI stage Build/Client/Bin64, sha256-checked against its
                  cys_stage.json), terrain cfg (client_GL, read-only copy), WXSystem.cfg (offline 127.0.0.1:14400,
                  CodePage 65001), WXResources.cfg (client_GL FairyResources layout + overlay), game_data_stage.json
                  --play: 1280x720, 120 FPS foreground / 30 background, VSync off, sound enabled.
        Data      directory junction -> Assets/Canonical/Data. Nothing is ever written through it.
        Overlay/  real files completing Canonical for this stage:
                    Pre/<Folder>   listed BEFORE Canonical: wins base-name and backslash-path lookups
                    Post/<Folder>  listed AFTER Canonical: wins full relative-path lookups; new files
                    Bootstrap/     extra Bootstrap archive (CY material templates / programs)
        Patch/    LoginServer.txt (offline fixture), WXLoginServer.txt (one dummy server; never contacted)
  check --stage DIR [--out DIR]
      Resource-index simulation (OgreResourceGroupManager::addResourceLocation, including the CYS base-name index)
      and reachability of every file named by the scripts (*.material/.program/.particle/.effect/.skill/.obj/
      .overlay), scene files (*.Scene, *.Terrain), UI files (layouts, imagesets, fonts, schemes, looks) and the CY
      creation tables: resolved / unreachable (only a CJK-named file exists, which the engine's ANSI file layer
      cannot open) / missing. Works on any stage with a Bin64/WXResources.cfg (e.g. an older Reference-layout stage).

File names follow the project convention (Docs/specs/render/07-fx-audit_vi.md, D1): the engine opens names through
the ANSI API (ACP 1252), so a resource named by GBK bytes must exist on disk as those bytes read as cp1252 ("engine
form"). Canonical already uses it; every overlay name is checked and S2 (Unicode) names are converted.
Read-only sources: Canonical, client_GL, S2, Reference and the profile stage (another agent's stage).
"""
import argparse
import ast
import collections
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tools/pipeline'))
import tlbbfmt  # noqa: E402  (read-only format helpers; iter_blocks)


def set_root(root):
    """CYS: every read-only input (Canonical, CI stage, profile stage, backups) is resolved below ROOT. A worktree
    copy of this tool (Build/wt-<agent>) has none of them: `build --root C:/TLBB/085/CY-Source` points it at the
    main tree while the stage itself goes wherever --out says."""
    global ROOT, CANON, STAGES, DEFAULT_BIN, CI_BIN, GL, S2, PROFILE_STAGE, STAGE_CLIENT, LOGIN_FIXTURE
    ROOT = Path(root).resolve()
    CANON = ROOT / 'Assets/Canonical/Data'
    STAGES = ROOT / 'Build/game-data'
    DEFAULT_BIN = ROOT / 'Build/wt-game-data/Build/cmake/game-data-x64/bin'
    CI_BIN = ROOT / 'Build/Client/Bin64'
    GL = ROOT.parent / 'client_GL'
    S2 = ROOT.parent / 'Tools/DATA NEW/DataCY31-08-26'
    PROFILE_STAGE = ROOT / 'Build/gpt-p1-1-20260913/stage-91148e1'
    STAGE_CLIENT = ROOT / 'Build/Logs/2026-09-12-client/stage_client.py'
    LOGIN_FIXTURE = ROOT / 'Tests/ui/fixtures/login-server-utf8.txt'


# CYS: run from a git worktree below Build/wt-*/ the read-only inputs come from the main tree: the first ancestor
# holding Assets/Canonical/Data (world-replay). `--root` still overrides it (world3).
set_root(next((p for p in (ROOT, *ROOT.parents) if (p / 'Assets/Canonical/Data').is_dir()), ROOT))

# client_GL Bin/FairyResources.cfg (group, location relative to Data, archive type); every folder is recursive.
CANON_LAYOUT = [
    ('Bootstrap', 'OgreCore.zip', 'Zip'), ('Bootstrap', 'MaterialTemplates.zip', 'Zip'),
    ('General', 'EffectFolder', 'FileSystem'), ('General', 'ModelFolder', 'FileSystem'),
    ('General', 'Model2Folder', 'FileSystem'), ('General', 'Model3Folder', 'FileSystem'),
    ('General', 'InterfaceFolder', 'FileSystem'), ('General', 'MaterialFolder', 'FileSystem'),
    ('General', 'Material2Folder', 'FileSystem'), ('General', 'Material3Folder', 'FileSystem'),
    ('General', 'Material4Folder', 'FileSystem'), ('General', 'Material5Folder', 'FileSystem'),
    ('General', 'SoundFolder', 'FileSystem'), ('General', 'ConfigFolder', 'FileSystem'),
    ('Brushes', 'BrushesFolder', 'FileSystem'), ('Scene', 'SceneFolder', 'FileSystem'),
]
# CYS-CY 14/09 (cs1-tables): data profiles. CanonicalCY (Docs/specs/cy-switch_vi.md) has the CY folders Model2..8,
# Material2..8 and Scene2Folder; the order follows Tools/pipeline/reach_canonical_cy.py (viewer/game layout extended).
CANON_LAYOUT_GL = list(CANON_LAYOUT)
CANON_LAYOUT_CY = ([('Bootstrap', 'OgreCore.zip', 'Zip'), ('Bootstrap', 'MaterialTemplates.zip', 'Zip'),
                    ('General', 'EffectFolder', 'FileSystem')] +
                   [('General', 'Model%sFolder' % n, 'FileSystem') for n in ('', 2, 3, 4, 5, 6, 7, 8)] +
                   [('General', 'InterfaceFolder', 'FileSystem')] +
                   [('General', 'Material%sFolder' % n, 'FileSystem') for n in ('', 2, 3, 4, 5, 6, 7, 8)] +
                   [('General', 'SoundFolder', 'FileSystem'), ('General', 'ConfigFolder', 'FileSystem'),
                    ('Brushes', 'BrushesFolder', 'FileSystem'), ('Scene', 'SceneFolder', 'FileSystem'),
                    ('Scene', 'Scene2Folder', 'FileSystem')])
DATA_PROFILES = {'Canonical': ('Assets/Canonical/Data', CANON_LAYOUT_GL),
                 'CanonicalCY': ('Assets/CanonicalCY/Data', CANON_LAYOUT_CY),
                 # CYS-CORE (14/09): CanonicalCY with the client_GL InterfaceFolder (junctions built by the core-loop
                 # agent) while the CY GUI is being installed by cy-gui: the main Game.exe has no Falagard/DragCornerButton
                 # factory yet, so the CY ChatFrame layout aborts the main loop. Temporary; drop once cy-gui merges.
                 'CanonicalCY-glui': ('Build/wt-core-loop/Build/data-cy-glui/Data', CANON_LAYOUT_CY)}
# CYS-CY: client_GL tables a CY 3.71 Game.exe (cs1-tables structs) still needs and CY 3.71 does not ship
# (Tests/abi/check_dbc_layout.py KEEP_GL): staged from Assets/Canonical into Post/ConfigFolder. Empty since
# cs2-world 14/09: the last entry (CampAndStand.txt) is gone now that DBC_CAMP_AND_STAND reads the CY camp
# relations from ReputationTable.txt, exactly as CY 3.71 Game.exe does.
CY_KEEP_GL_TABLES = {}
# CYS-CY 14/09 (cs2-world): CY 3.71 windows whose interface Lua makes its checked state unusable on this build (hosts
# agent cy-gui has not provided yet): CysCheckedScriptLua::StateUnavailable ends Game.exe when the world HUD opens
# (replay-run-13-final on 164cc65: Agname_Env code=-1 usable=0 after Player:GetShowUITitleCnt,
# Player:Player_GetTitleType, _G:Lua_InitTitleTable, _G:Lua_GetTitleElementSize were missing). Filtered out of the
# binary InterfaceEx like the unsupported widget types; every entry is reported in game_data_stage.json.
CY_GUI_WINDOW_BLOCKLIST = {
    'Agname': 'Agname_Env unusable on this build: title hosts Player:GetShowUITitleCnt / Player_GetTitleType / '
              '_G:Lua_InitTitleTable / Lua_GetTitleElementSize missing (agent cy-gui)',
}
DATA_PROFILE = 'Canonical'


def set_data_profile(name):
    """Point CANON / CANON_LAYOUT at a data profile below ROOT (call after set_root)."""
    global CANON, CANON_LAYOUT, DATA_PROFILE
    if name not in DATA_PROFILES:
        raise SystemExit('unknown data profile: ' + str(name))
    rel_data, layout = DATA_PROFILES[name]
    CANON = ROOT / rel_data
    CANON_LAYOUT = list(layout)
    DATA_PROFILE = name


def keep_gl_overlay(ov, report):
    """CYS-CY: stage the client_GL tables of CY_KEEP_GL_TABLES (only for the CanonicalCY profile)."""
    kept = []
    if DATA_PROFILE != 'CanonicalCY':
        return kept
    for name, reason in sorted(CY_KEEP_GL_TABLES.items()):
        if (CANON / 'ConfigFolder' / name).exists():
            continue
        src = ROOT / 'Assets/Canonical/Data/ConfigFolder' / name
        if not src.is_file():
            raise SystemExit('client_GL table to keep is missing: ' + str(src))
        ov.add('Post', 'ConfigFolder', name, src=src, origin=rel(src), reason='client_GL table kept: ' + reason)
        kept.append(name)
    report['keep_gl_tables'] = kept
    return kept


OVERLAY_FOLDERS = ['EffectFolder', 'ModelFolder', 'InterfaceFolder', 'MaterialFolder', 'SoundFolder',
                   'ConfigFolder', 'BrushesFolder', 'SceneFolder']
GROUP_OF = {'BrushesFolder': 'Brushes', 'SceneFolder': 'Scene'}
REFERENCE_FOLDERS = {'Interface': 'InterfaceFolder', 'Material': 'MaterialFolder', 'Model': 'ModelFolder',
                     'Config': 'ConfigFolder', 'Scene': 'SceneFolder', 'Brushes': 'BrushesFolder',
                     'Effect': 'EffectFolder', 'Sound': 'SoundFolder'}
SCRIPT_KIND = {'.material': 'material', '.program': 'program', '.particle': 'particle', '.effect': 'effect',
               '.skill': 'skill', '.obj': 'obj', '.overlay': 'overlay', '.fontdef': 'fontdef',
               '.compositor': 'compositor'}
# files that replace their Canonical counterpart: the CY creation/selection controllers (the point of the profile)
FORCED = {'Data/Interface/CreateRole/CreateRole.layout.xml', 'Data/Interface/CreateRole/CreateRole.lua',
          'Data/Interface/SelectRole/SelectRole.layout.xml', 'Data/Interface/SelectRole/SelectRole.lua'}
# CYS-CYGUI2: on CanonicalCY the CY 3.71 SelectRole layout/Lua is the GUI ("Moi thu nhu CY"); the profile's
# placeholder controller answered the enter-game button with "Chuc nang chua san sang" and never sent the character
# login (cs2-world gui-live-4/5). CreateRole stays forced: its controller drives the 3D sect previews (cy-avatar).
FORCED_GL_ONLY = {'Data/Interface/SelectRole/SelectRole.layout.xml', 'Data/Interface/SelectRole/SelectRole.lua'}
SCHEME = 'Data/Interface/Schema/WoWLookSkin.scheme.xml'
RUNTIME_FROM_CI = ('cg.dll', 'Plugin_CgProgramManager.dll', 'd3dx9_43.dll', 'D3DCompiler_43.dll', 'fmod.dll',
                   'fmodL.dll')

# ------------------------------------------------------------------------------------------------ engine names
_UNDEFINED = (0x81, 0x8D, 0x8F, 0x90, 0x9D)   # Windows maps these cp1252 holes to U+0081.. (identity)
VIEW = [chr(b) if b in _UNDEFINED else bytes([b]).decode('cp1252') for b in range(256)]
VIEW_SET = frozenset(VIEW)


def view(raw):
    """GBK (or any) bytes -> the file name the engine's ANSI file layer opens (bytes read as cp1252)."""
    return ''.join(VIEW[b] for b in raw)


def is_engine_form(name):
    return all(c in VIEW_SET for c in name)


def engine_name(name):
    """Unicode disk name (S2 / Reference use real CJK names) -> engine form. Engine-form names are unchanged."""
    return name if is_engine_form(name) else view(name.encode('gbk'))


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def rel(path):
    try:
        return Path(path).resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        return str(path).replace('\\', '/')


# ------------------------------------------------------------------------------------ resource index simulation
class Location:
    def __init__(self, group, kind, path, recursive, spec):
        self.group, self.kind, self.path, self.recursive, self.spec = group, kind, Path(path), recursive, spec
        self._files = None

    def files(self):
        """Names as OGRE indexes them: relative, '/'-separated (FileSystemArchive::find / ZipArchive::find)."""
        if self._files is None:
            out = []
            if self.kind == 'Zip':
                if self.path.is_file():
                    with zipfile.ZipFile(self.path) as z:
                        out = [n for n in z.namelist() if not n.endswith('/') and (self.recursive or '/' not in n)]
            elif self.path.is_dir():
                base = str(self.path)
                for dirpath, dirs, names in os.walk(base):
                    sub = os.path.relpath(dirpath, base)
                    prefix = '' if sub == '.' else sub.replace('\\', '/') + '/'
                    out.extend(prefix + n for n in names)
                    if not self.recursive:
                        break
            self._files = out
            self._lower = {n.lower(): n for n in out}
        return self._files

    def has(self, name):
        self.files()
        return name.lower() in self._lower

    def read(self, name):
        if self.kind == 'Zip':
            with zipfile.ZipFile(self.path) as z:
                return z.read(self._lower[name.lower()])
        return (self.path / self._lower[name.lower()]).read_bytes()


class GroupIndex:
    """ResourceGroupManager index of one group: case-sensitive + lower-case maps (FileSystem archives on Windows are
    case-insensitive), full names last-wins, CYS base names of recursive locations first-wins."""

    def __init__(self, name):
        self.name, self.locations, self.cs, self.ci = name, [], {}, {}

    def add(self, loc):
        self.locations.append(loc)
        for n in loc.files():
            self.cs[n] = loc
            self.ci[n.lower()] = loc
            if loc.recursive and '/' in n:
                base = n.rsplit('/', 1)[1]
                self.cs.setdefault(base, loc)
                self.ci.setdefault(base.lower(), loc)

    def lookup(self, name):
        loc = self.cs.get(name) or self.ci.get(name.lower())
        if loc is not None:
            return loc
        norm = name.replace('\\', '/')
        for loc in self.locations:          # openResource: search the locations in order (archive->exists)
            if loc.has(norm):
                return loc
        return None


def parse_resources_cfg(bin64):
    """Bin64/WXResources.cfg as WX::System::_setupResources reads it (Ogre::ConfigFile, '*' = recursive)."""
    locations = []
    section = None
    for line in (Path(bin64) / 'WXResources.cfg').read_text(encoding='ascii', errors='replace').splitlines():
        s = line.strip()
        if not s or s.startswith('#'):
            continue
        if s.startswith('['):
            section = s[1:s.index(']')]
            continue
        key, _, value = s.partition('=')
        value = value.strip()
        recursive = value.startswith('*')
        value = value.lstrip('*').strip()
        locations.append(Location(section, key.strip(), (Path(bin64) / value).resolve(), recursive, value))
    # Ogre::ConfigFile keeps settings in a multimap per section: within a section, keys iterate sorted
    # ("FileSystem" before "Zip"), equal keys in file order. Sections are independent groups.
    ordered = []
    for group in sorted({l.group for l in locations}):
        members = [l for l in locations if l.group == group]
        for key in sorted({l.kind for l in members}):
            ordered.extend(l for l in members if l.kind == key)
    return ordered


def build_index(locations):
    groups = collections.OrderedDict()
    for loc in locations:
        groups.setdefault(loc.group, GroupIndex(loc.group)).add(loc)
    return groups


# ------------------------------------------------------------------------------------------- script helpers
_OBJ = re.compile(rb'<Object\s+name="([^"]*)"\s*>.*?</Object>', re.S)


def script_blocks(data, kind):
    """[(name, block_bytes)] of a script, first definition of a name wins; bytes are never decoded (GBK rule)."""
    out, seen = [], set()
    if kind == 'obj':
        items = [(m.group(1), m.group(0)) for m in _OBJ.finditer(data)]
    else:
        items = []
        for header, block in tlbbfmt.iter_blocks(data)[0]:
            toks = header.split()
            if kind == 'material' and toks[:1] == [b'material'] and len(toks) > 1:
                name = toks[1].split(b':')[0]
            elif kind == 'program' and toks[:1] in ([b'vertex_program'], [b'fragment_program']) and len(toks) > 1:
                name = toks[1]
            elif kind == 'particle' and toks[:1] == [b'particle_system'] and len(toks) > 1:
                name = toks[1]
            elif kind in ('effect', 'skill') and toks[:1] == [kind.encode()] and len(toks) > 1:
                name = toks[1]
            else:
                name = header.strip()
            items.append((name, block))
    for name, block in items:
        if name in seen:
            continue
        seen.add(name)
        out.append((name, block))
    return out


def definition_kind(kind):
    # materials and programs share one namespace per manager; group them by manager
    return {'program': 'material'}.get(kind, kind)


def canonical_definitions(locations, kinds):
    """{kind: set(names)} over every script of the given kinds in the given locations."""
    defs = collections.defaultdict(set)
    for loc in locations:
        for n in loc.files():
            kind = SCRIPT_KIND.get(os.path.splitext(n)[1].lower())
            if kind not in kinds:
                continue
            for name, _block in script_blocks(loc.read(n), kind):
                defs[definition_kind(kind)].add(name)
    return defs


# ------------------------------------------------------------------------------------------------ reachability
RESOURCE_EXT = (b'mesh', b'skeleton', b'dds', b'tga', b'jpg', b'jpeg', b'png', b'bmp', b'cg', b'hlsl', b'wav',
                b'ogg', b'mp3')
TOKEN = re.compile(rb'(?i)([^\x00-\x20"\'<>=;,(){}\[\]|*?:]+\.(?:' + b'|'.join(RESOURCE_EXT) + rb'))(?![0-9a-z_])')
SKELETON_TOKEN = re.compile(rb'(?i)([\x21-\x7e\x80-\xfe]{1,120}\.skeleton)(?![0-9a-z_])')
XML_UTF8 = re.compile(rb'^(?:\xef\xbb\xbf)?\s*<\?xml[^>]*encoding\s*=\s*["\']utf-8["\']', re.I)  # BOM allowed


def reference_sources(locations, overlay_only=False):
    for loc in locations:
        if overlay_only and '/Overlay/' not in loc.path.as_posix() + '/':
            continue
        for n in loc.files():
            low = n.lower()
            ext = os.path.splitext(low)[1]
            if (ext in SCRIPT_KIND or ext in ('.scene', '.terrain') or
                    low.endswith(('.layout.xml', '.imageset.xml', '.scheme.xml', '.looknfeel.xml', '.font')) or
                    # the CY creation tables are full S2 tables (every S2 model); they are reported by the full
                    # check but never drive the S2 completion (only what scripts/scenes/UI/meshes name)
                    (not overlay_only and low.rsplit('/', 1)[-1].startswith('cyscreate') and ext == '.txt') or
                    (overlay_only and ext == '.mesh')):
                yield loc, n


def tokens_of(data, name):
    if name.lower().endswith('.mesh'):
        return [m.group(1) for m in SKELETON_TOKEN.finditer(data)]
    tokens = [m.group(1) for m in TOKEN.finditer(data)]
    if XML_UTF8.match(data[:200]):
        # WXExpatParser converts every UTF-8 string to CP936 (MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS) then
        # WideCharToMultiByte(936)); a string that is not valid UTF-8 keeps its bytes. Per token, like the engine:
        # one stray byte elsewhere in a scene must not turn every other name into UTF-8 mojibake.
        converted = []
        for token in tokens:
            try:
                converted.append(token.decode('utf-8').encode('gbk'))
            except (UnicodeDecodeError, UnicodeEncodeError):
                converted.append(token)
        tokens = converted
    return tokens


def check_references(locations, overlay_only=False, limit_examples=40):
    groups = build_index(locations)
    order = [g for g in ('General', 'Bootstrap', 'Scene', 'Brushes') if g in groups] + \
            [g for g in groups if g not in ('General', 'Bootstrap', 'Scene', 'Brushes')]
    cjk_alias = {}
    cjk_files = 0
    for loc in locations:
        for n in loc.files():
            base = n.rsplit('/', 1)[-1]
            if not is_engine_form(base):
                cjk_files += 1
                try:
                    cjk_alias.setdefault(view(base.encode('gbk')).lower(), loc.spec + '/' + n)
                except UnicodeEncodeError:
                    pass
    status = {}
    counts = collections.Counter()
    by_ext = collections.defaultdict(collections.Counter)
    sources = collections.Counter()
    for loc, n in reference_sources(locations, overlay_only):
        sources[loc.spec] += 1
        for token in tokens_of(loc.read(n), n):
            name = view(token.replace(b'\\', b'/').lstrip(b'./'))
            key = name.lower()
            if key in status:
                counts[status[key][0] + '_refs'] += 1
                continue
            found = None
            for g in order:
                found = groups[g].lookup(name) or groups[g].lookup(name.rsplit('/', 1)[-1])
                if found is not None:
                    break
            if found is not None:
                st = ('resolved', found.spec)
            elif name.rsplit('/', 1)[-1].lower() in cjk_alias:
                st = ('unreachable', cjk_alias[name.rsplit('/', 1)[-1].lower()])
            else:
                st = ('missing', '')
            status[key] = (st[0], st[1], loc.spec + '/' + n, name)
            counts[st[0]] += 1
            counts[st[0] + '_refs'] += 1
            by_ext[os.path.splitext(key)[1]][st[0]] += 1
    examples = {s: sorted([v[3] + '  <- ' + v[2] for v in status.values() if v[0] == s])[:limit_examples]
                for s in ('unreachable', 'missing')}
    return {'names': dict(counts), 'by_extension': {k: dict(v) for k, v in sorted(by_ext.items())},
            'cjk_files_on_disk': cjk_files, 'source_files': dict(sources), 'examples': examples,
            'status': status}


# ------------------------------------------------------------------------------------------------------ overlay
class Overlay:
    def __init__(self):
        self.files = collections.OrderedDict()   # 'Pre/InterfaceFolder/x' -> record

    def add(self, where, folder, relpath, data=None, src=None, origin='', reason=''):
        relpath = relpath.replace('\\', '/').strip('/')
        for part in relpath.split('/'):
            if not is_engine_form(part):
                raise ValueError('overlay name not in engine form (GBK bytes as cp1252): ' + relpath)
        key = '/'.join(p for p in (where, folder, relpath) if p)
        digest = sha256(data) if data is not None else sha256_file(src)
        if key in self.files and self.files[key]['sha256'] != digest:
            raise ValueError('conflicting overlay content: ' + key)
        self.files[key] = {'path': key, 'data': data, 'src': src, 'sha256': digest, 'origin': origin,
                           'reason': reason}

    def add_winner(self, folder, relpath, **kw):
        """Must win over Canonical for every lookup form: Pre (base name, backslash path) + Post (full path)."""
        self.add('Pre', folder, relpath, **kw)
        self.add('Post', folder, relpath, **kw)

    def folders(self, where):
        return sorted({k.split('/')[1] for k in self.files if k.startswith(where + '/')})


def map_reference_path(path):
    """'Data/Model/x.mesh' (0.85 / Reference stage layout) -> ('ModelFolder', 'x.mesh')."""
    parts = path.split('/')
    if len(parts) >= 3 and parts[0] == 'Data' and parts[1] in REFERENCE_FOLDERS:
        return REFERENCE_FOLDERS[parts[1]], '/'.join(parts[2:])
    return None, path


def canonical_locations():
    return [Location(g, t, CANON / p, t == 'FileSystem', '../Data/' + p) for g, p, t in CANON_LAYOUT]


class CanonicalView:
    def __init__(self):
        self.locations = canonical_locations()
        self.groups = build_index(self.locations)

    def candidates(self, folder, relpath):
        """Canonical files an overlay file at folder/relpath would compete with: same relative path in any location
        of the group, or the base-name winner of the group."""
        group = GROUP_OF.get(folder, 'General')
        out = []
        for loc in self.groups[group].locations:
            if loc.kind == 'FileSystem' and loc.has(relpath):
                out.append((loc, loc._lower[relpath.lower()]))
        base = relpath.rsplit('/', 1)[-1]
        loc = self.groups[group].ci.get(base.lower())
        if loc is not None:
            for n in loc.files():
                if n.lower() == base.lower() or n.lower().endswith('/' + base.lower()):
                    out.append((loc, n))
                    break
        return out


def creation_overlay(ov, profile_stage, canon, report):
    """Rebase the CY creation profile of a Reference-layout stage onto Canonical (see module docstring)."""
    manifest_path = profile_stage / 'Bin64/create_role_profile.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    if manifest.get('applied') is not True:
        raise ValueError('profile stage has no applied creation profile')
    decisions = collections.Counter()
    canonical_wins = []
    scripts = collections.defaultdict(list)          # (folder, out name) -> [block bytes]
    script_stats = collections.Counter()
    script_files = []
    defs = canonical_definitions(canon.locations, {'material', 'program', 'particle', 'effect', 'skill', 'obj'})
    zip_members = collections.OrderedDict()
    for record in manifest['files']:
        path = record['path']
        if not path.startswith('Data/'):
            continue
        src = profile_stage / path
        data = src.read_bytes()
        if sha256(data) != record['sha256']:
            raise ValueError('profile stage file differs from its manifest: ' + path)
        before = (ROOT / record['backup']).read_bytes() if record.get('backup') else b''
        if record.get('backup') and sha256(before) != record.get('sha256_before'):
            raise ValueError('profile backup differs from its manifest: ' + record['backup'])
        origin = rel(src) + ' (manifest origin: ' + str(record.get('origin', '')) + ')'
        if path == SCHEME:
            scheme_overlay(ov, data, before, origin, report)
            decisions['scheme-merged'] += 1
            continue
        if path == 'Data/MaterialTemplates.zip':
            zip_delta(zip_members, data, before, defs, script_stats, canonical_wins)
            decisions['bootstrap-zip-merged'] += 1
            continue
        folder, relpath = map_reference_path(path)
        if folder is None:
            decisions['skipped-unmapped'] += 1
            continue
        kind = SCRIPT_KIND.get(os.path.splitext(relpath)[1].lower())
        if kind in ('material', 'program', 'particle', 'effect', 'skill', 'obj'):
            kept = script_delta(data, before, kind, defs, script_stats, canonical_wins, path)
            if kept:
                name = relpath.rsplit('/', 1)[-1]
                exists = canon.candidates(folder, name) or canon.candidates(folder, relpath)
                out_name = ('CysCreate_' + name) if exists else name
                if kind == 'obj':
                    blocks = [m for m in _OBJ.finditer(data)]
                    prefix = data[:blocks[0].start()] if blocks else b''
                    suffix = data[blocks[-1].end():] if blocks else b''
                    body = prefix + b'\r\n'.join(kept) + suffix
                else:
                    body = b'\r\n'.join(kept) + b'\r\n'
                ov.add('Post', folder, out_name, data=body, origin=origin,
                       reason='%d CY %s block(s) absent from Canonical' % (len(kept), kind))
                script_files.append({'file': 'Post/%s/%s' % (folder, out_name), 'blocks': len(kept), 'from': path})
            decisions['script-delta'] += 1
            continue
        competitors = canon.candidates(folder, relpath)
        group = GROUP_OF.get(folder, 'General')
        exact = any(loc.kind == 'FileSystem' and loc.has(relpath) for loc in canon.groups[group].locations)
        if competitors and not exact:
            # Only a base-name competitor: full relative-path lookups (imageset Imagefile="CysCreateRole/Common/x.tga")
            # would still miss. Post is listed after Canonical, so the base-name winner stays Canonical's file.
            # (world-replay 14/09: 'CysCreateRole/Common/button06.tga' was dropped as same-as-canonical because
            # MaterialFolder/Common/button06.tga has the same bytes; the selection UI then threw RendererException.)
            ov.add('Post', folder, relpath, src=src, origin=origin,
                   reason='full-path lookup; Canonical has this base name only at another path')
            decisions['path-only-added'] += 1
            continue
        if competitors:
            same = any(len(data) == loc_size(loc, n) and loc.read(n) == data for loc, n in competitors)
            if same:
                decisions['same-as-canonical'] += 1
            elif path in FORCED and not (DATA_PROFILE == 'CanonicalCY' and path in FORCED_GL_ONLY):
                ov.add_winner(folder, relpath, src=src, origin=origin, reason='CY creation controller replaces GL')
                decisions['replaces-canonical (forced)'] += 1
            else:
                decisions['canonical-wins'] += 1
                canonical_wins.append({'profile_file': path, 'canonical': competitors[0][0].spec + '/' +
                                       competitors[0][1]})
            continue
        ov.add('Post', folder, relpath, src=src, origin=origin, reason='new CY creation resource')
        decisions['new'] += 1
    if zip_members:
        report['bootstrap_zip_members'] = sorted(zip_members)
    report['decisions'] = dict(decisions)
    report['script_blocks'] = dict(script_stats)
    report['script_files'] = script_files
    report['canonical_wins'] = canonical_wins
    return zip_members


def loc_size(loc, n):
    if loc.kind == 'Zip':
        return -1
    try:
        return (loc.path / n).stat().st_size
    except OSError:
        return -1


def script_delta(after, before, kind, defs, stats, canonical_wins, label):
    """CY blocks of a profile script: new or changed against the profile backup, minus names Canonical defines."""
    old = dict(script_blocks(before, kind)) if before else {}
    kept = []
    for name, block in script_blocks(after, kind):
        if old.get(name) == block:
            continue
        if name in defs.get(definition_kind(kind), ()):
            stats[kind + ':canonical-wins'] += 1
            canonical_wins.append({'profile_file': label, 'definition': kind + ' ' + view(name)})
            continue
        stats[kind + ':kept'] += 1
        kept.append(block)
    return kept


def zip_delta(members, after, before, defs, stats, canonical_wins):
    import io
    canon_zip = zipfile.ZipFile(CANON / 'MaterialTemplates.zip')
    canon_names = {n.lower(): n for n in canon_zip.namelist()}
    za = zipfile.ZipFile(io.BytesIO(after))
    zb = zipfile.ZipFile(io.BytesIO(before)) if before else None
    old = set(zb.namelist()) if zb else set()
    for name in za.namelist():
        if name.endswith('/'):
            continue
        data = za.read(name)
        prior = zb.read(name) if zb and name in old else None
        if prior == data:
            continue
        kind = SCRIPT_KIND.get(os.path.splitext(name)[1].lower())
        if kind in ('material', 'program'):
            kept = script_delta(data, prior or b'', kind, defs, stats, canonical_wins, 'MaterialTemplates.zip:' + name)
            if kept:
                members['CysCreate_' + name.rsplit('/', 1)[-1]] = b'\r\n'.join(kept) + b'\r\n'
            continue
        if name.lower() in canon_names:
            if canon_zip.read(canon_names[name.lower()]) != data:
                canonical_wins.append({'profile_file': 'MaterialTemplates.zip:' + name,
                                       'canonical': 'MaterialTemplates.zip:' + canon_names[name.lower()]})
            continue
        members[name] = data


def scheme_overlay(ov, after, before, origin, report):
    """Canonical GL scheme + the registrations the creation profile added (CysCR_ namespace), byte-preserving."""
    canon_path = CANON / 'InterfaceFolder/Schema/WoWLookSkin.scheme.xml'
    canon_bytes = canon_path.read_bytes()
    key_attr = {'Imageset': 'Name', 'Font': 'Name', 'FalagardMapping': 'WindowType', 'LookNFeel': 'Filename',
                'WindowSet': 'Filename', 'ImagesetFromImage': 'Name'}

    def entries(raw):
        root = ET.fromstring(raw)
        return [(el.tag, el.attrib.get(key_attr.get(el.tag, ''), ''), el) for el in root]

    old = {(t, k) for t, k, _ in entries(before)}
    canon = {(t, k) for t, k, _ in entries(canon_bytes)}
    added, skipped = [], []
    for tag, key, el in entries(after):
        if (tag, key) in old:
            continue
        if (tag, key) in canon:
            skipped.append(tag + ' ' + key)
            continue
        el.tail = None
        added.append(ET.tostring(el, encoding='utf-8'))
    if canon_bytes.count(b'</GUIScheme>') != 1:
        raise ValueError('unexpected Canonical scheme root')
    merged = canon_bytes.replace(b'</GUIScheme>', b'\r\n'.join(added) + b'\r\n</GUIScheme>')
    ET.fromstring(merged)
    ov.add_winner('InterfaceFolder', 'Schema/WoWLookSkin.scheme.xml', data=merged,
                  origin='Assets/Canonical/Data/InterfaceFolder/Schema/WoWLookSkin.scheme.xml + ' + origin,
                  reason='Canonical scheme + %d CY creation registration(s)' % len(added))
    report['scheme'] = {'added': len(added), 'already_in_canonical': skipped}


def login_overlay(ov, canon, report):
    notes = {}
    # StrFilter: the GL login profile empties the rule set (user-approved exception); keep the two header rows.
    hits = canon.candidates('ConfigFolder', 'StrFilter.txt')
    loc, name = hits[0]
    raw = loc.read(name)
    lines = raw.split(b'\n')
    empty = b'\n'.join(lines[:2]) + b'\n'
    ov.add_winner('ConfigFolder', name, data=empty, origin=loc.spec + '/' + name + ' (header rows only)',
                  reason='empty StrFilter rule set (GL login profile)')
    notes['strfilter'] = 'header rows of Canonical %s, 0 rules' % name
    # ChatFrame: the Reference-era layout had three malformed background descriptors; fix only if present.
    chat = CANON / 'InterfaceFolder/ChatFrame/ChatFrame.layout.xml'
    old = b'Value="dir:CommonFrame set:Chat image:CommonEditBoxBK"'
    if chat.is_file() and chat.read_bytes().count(old) == 3:
        data = chat.read_bytes()
        for direction in (b'left', b'middle', b'right'):
            data = data.replace(old, b'Value="dir:' + direction + b' set:CommonFrame image:CommonEditBoxBK"', 1)
        ov.add_winner('InterfaceFolder', 'ChatFrame/ChatFrame.layout.xml', data=data, origin=rel(chat),
                      reason='ChatFrame descriptor fix (GL login profile)')
        notes['chatframe'] = 'fixed'
    else:
        notes['chatframe'] = 'Canonical layout already well-formed (no change)'
    # WX debug overlay shim (stage_client.py): 0.85 Render.dll looks up WX/DebugOverlay elements.
    overlays = [(l, n) for l in canon.locations for n in l.files() if n.lower().endswith('.overlay')]
    defined = any(b'WX/DebugOverlay' in l.read(n) for l, n in overlays)
    tlbb = [(l, n) for l, n in overlays if n.rsplit('/', 1)[-1].lower() == 'tlbb.overlay']
    if not defined and tlbb:
        l, n = tlbb[0]
        data = l.read(n)
        for key in (b'DebugOverlay', b'StatPanel', b'HitObjPanel', b'HitObjText'):
            data = data.replace(b'TLBB/' + key, b'WX/' + key)
        ov.add('Post', 'MaterialFolder', 'CYS_WXDebug.overlay', data=data, origin=l.spec + '/' + n,
               reason='Render.dll debug panel names (stage_client.py shim)')
        notes['debug_overlay'] = 'shim from ' + n
    else:
        notes['debug_overlay'] = 'defined in Canonical' if defined else 'no TLBB.overlay in Canonical (not added)'
    report['login'] = notes
    imageset_aliases(ov, report)


# Canonical data inconsistencies that make CEGUI throw (logged as UISystem "(Error)"); B tolerates them. Each alias is
# a copy of an existing image under the name the referencing file uses; reported for the data owner, never silent.
IMAGESET_ALIASES = [
    # Schema/wowanimate.xml uses Agname18/ysqcdf_L8; Common/Agname18.imageset.xml only defines "ysqcdf_L8_"
    ('Common/Agname18.imageset.xml', 'ysqcdf_L8', 'ysqcdf_L8_'),
]


def imageset_aliases(ov, report):
    done = []
    for relpath, alias, existing in IMAGESET_ALIASES:
        path = CANON / 'InterfaceFolder' / relpath
        if not path.is_file():
            continue
        data = path.read_bytes()
        if re.search(rb'<Image\b[^>]*\bName\s*=\s*"' + re.escape(alias.encode()) + rb'"', data):
            continue
        match = re.search(rb'<Image\b[^>]*\bName\s*=\s*"' + re.escape(existing.encode()) + rb'"[^>]*/>', data)
        if not match:
            continue
        copy = match.group(0).replace(b'"' + existing.encode() + b'"', b'"' + alias.encode() + b'"', 1)
        data = data[:match.end()] + b'\r\n\t' + copy + data[match.end():]
        ET.fromstring(data.lstrip(b'\xef\xbb\xbf'))
        ov.add_winner('InterfaceFolder', relpath, data=data, origin=rel(path),
                      reason='alias image %s = %s (Canonical data inconsistency)' % (alias, existing))
        done.append('%s: %s = %s' % (relpath, alias, existing))
    report['imageset_aliases'] = done


CEGUI_BASE_TYPES = {'DefaultWindow', 'DefaultGUISheet', 'DragContainer', 'ScrolledContainer', 'ClippedContainer',
                    'GUISheet'}
WINDOW_TYPE = re.compile(rb'<Window\b[^>]*?\bType\s*=\s*"([^"]+)"')
LAYOUT_IMPORT = re.compile(rb'<LayoutImport\b[^>]*?\bFilename\s*=\s*"([^"]+)"')


def registered_window_types(bin_dir):
    """Falagard window factories compiled into the staged CEGUI modules (type-name literals of CEGUIFalagard.dll and
    UI_CEGUI.dll, which links CEGUIFalagardEx), plus the CEGUI base types."""
    types = set(CEGUI_BASE_TYPES)
    for dll in ('CEGUIBase.dll', 'CEGUIFalagard.dll', 'UI_CEGUI.dll'):
        path = Path(bin_dir) / dll
        if path.is_file():
            # CYS-HUD: nested type names carry a second slash (Falagard/SuperTooltip/ResizeText, Falagard/ComplexWindow/ParentWindow)
            types |= {m.decode('ascii') for m in re.findall(rb'Falagard/[A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)?', path.read_bytes())}
    return types


def ui_compat_overlay(ov, canon, registered, report):
    """Canonical InterfaceEx.txt minus the windows whose layouts need a Falagard window type this build does not
    register (CEGUI aborts such a layout with an exception that ends Game.exe, e.g. Cloud_SelectServer ->
    TLBB_NotSuperList -> Falagard/NotSuperList). Recomputed from the staged DLLs at every build, so the list shrinks
    as the UI layer gains the GL widgets. Every excluded window is reported as a blocker, not silently dropped."""
    key = 'Post/InterfaceFolder/Schema/WoWLookSkin.scheme.xml'
    scheme = ov.files[key]['data'] if key in ov.files else \
        (CANON / 'InterfaceFolder/Schema/WoWLookSkin.scheme.xml').read_bytes()
    mapping = {el.attrib['WindowType']: el.attrib.get('TargetType', '')
               for el in ET.fromstring(scheme) if el.tag == 'FalagardMapping'}

    def unsupported(window_type):
        target = mapping.get(window_type, window_type if window_type.startswith('Falagard/') else None)
        return bool(target) and target.startswith('Falagard/') and target not in registered

    interface = [l for l in canon.locations if l.path.name == 'InterfaceFolder'][0]
    cache = {}

    def layout_types(relpath, depth=0):
        relpath = relpath.replace('\\', '/')
        if relpath.lower() in cache:
            return cache[relpath.lower()]
        cache[relpath.lower()] = set()
        record = ov.files.get('Post/InterfaceFolder/' + relpath)
        if record is not None:
            data = record['data'] if record['data'] is not None else Path(record['src']).read_bytes()
        elif interface.has(relpath):
            data = interface.read(relpath)
        else:
            return set()
        types = {t.decode('latin-1') for t in WINDOW_TYPE.findall(data)}
        if depth < 4:
            for imported in LAYOUT_IMPORT.findall(data):
                types |= layout_types(imported.decode('latin-1'), depth + 1)
        cache[relpath.lower()] = types
        return types

    loc, name = canon.candidates('ConfigFolder', 'InterfaceEx.txt')[0]
    staged = ov.files.get('Post/ConfigFolder/InterfaceEx.txt')
    if staged is not None:
        # CYS-CY: --gui gl already staged the client_GL table; filter that one, not the CY table of the data set.
        raw = staged['data'] if staged['data'] is not None else Path(staged['src']).read_bytes()
    else:
        raw = loc.read(name)
    if raw[:4] == b'\x00\xcc\xbb\xdd':
        # CYS-CY 14/09 (cs2-world): CY 3.71 ships InterfaceEx.txt as binary DBC (agent cy-gui). The same filter now
        # runs on records: the kept records are re-emitted with the original header, field types and string pool
        # (string offsets stay valid), so a window whose layout needs a Falagard type this build does not register
        # no longer kills Game.exe (CEGUI aborts the layout: ChatFrame -> TLBB_ButtonCorner -> Falagard/DragCornerButton).
        excluded, data = filter_binary_interface_ex(raw, layout_types, unsupported, mapping)
        if excluded:
            ov.add_winner('ConfigFolder', name, data=data, origin=loc.spec + '/' + name,
                          reason='%d window(s) removed from the binary CY table: their layouts need CEGUI types '
                                 'this build does not register' % len(excluded))
        report['ui_compat'] = {'registered_falagard_types': len(registered), 'excluded_windows': excluded,
                               'note': 'binary CY InterfaceEx.txt: records filtered'}
        return
    kept, excluded = [], []
    for index, line in enumerate(raw.split(b'\n')):
        fields = line.rstrip(b'\r').split(b'\t')
        if index < 2 or not line.strip() or line.startswith(b'#') or len(fields) < 3:
            kept.append(line)
            continue
        bad = sorted(t for t in layout_types(fields[2].decode('latin-1')) if unsupported(t))
        if bad:
            excluded.append({'id': fields[0].decode('latin-1'), 'window': view(fields[1]),
                             'layout': fields[2].decode('latin-1'),
                             'types': [t + ' -> ' + mapping.get(t, t) for t in bad]})
        else:
            kept.append(line)
    if excluded:
        ov.add_winner('ConfigFolder', name, data=b'\n'.join(kept), origin=loc.spec + '/' + name,
                      reason='%d window(s) removed: their layouts need CEGUI types this build does not register'
                             % len(excluded))
    report['ui_compat'] = {'registered_falagard_types': len(registered), 'excluded_windows': excluded}


def filter_binary_interface_ex(raw, layout_types, unsupported, mapping):
    """CYS-CY (cs2-world): drop the records of a binary CY InterfaceEx.txt whose layout needs an unregistered
    Falagard type. Returns (excluded records, new binary). Header: magic, fields, records, string bytes; then one
    4-byte type per field, the 4-byte cells and the string pool (kept whole, so string offsets stay valid)."""
    fields, records, strings = struct.unpack_from('<III', raw, 4)
    types_end = 16 + 4 * fields
    pool = types_end + 4 * fields * records
    kinds = struct.unpack_from('<%dI' % fields, raw, 16)

    def cell(row, column):
        value = struct.unpack_from('<I', raw, types_end + 4 * (row * fields + column))[0]
        if kinds[column] != 2:
            return None
        end = raw.find(b'\x00', pool + value, pool + strings)
        return raw[pool + value:end if end >= 0 else pool + strings]

    layout_column = None
    for column in range(fields):
        if kinds[column] == 2 and any((cell(row, column) or b'').lower().endswith(b'.layout.xml')
                                      for row in range(min(records, 16))):
            layout_column = column
            break
    if layout_column is None:
        return [], raw
    name_column = next((c for c in range(layout_column) if kinds[c] == 2), None)
    kept_rows, excluded = [], []
    row_bytes = 4 * fields
    for row in range(records):
        layout = (cell(row, layout_column) or b'').decode('latin-1')
        bad = sorted(t for t in layout_types(layout) if unsupported(t)) if layout else []
        window_name = (cell(row, name_column) or b'').decode('latin-1') if name_column is not None else ''
        if window_name in CY_GUI_WINDOW_BLOCKLIST:
            bad = bad + ['<blocklist> ' + CY_GUI_WINDOW_BLOCKLIST[window_name]]
        if bad:
            excluded.append({'id': str(struct.unpack_from('<i', raw, types_end + 4 * row * fields)[0]),
                             'window': view(cell(row, name_column) or b'') if name_column is not None else '',
                             'layout': layout, 'types': [t + ' -> ' + mapping.get(t, t) for t in bad]})
        else:
            kept_rows.append(raw[types_end + row * row_bytes:types_end + (row + 1) * row_bytes])
    if not excluded:
        return [], raw
    head = raw[:4] + struct.pack('<III', fields, len(kept_rows), strings) + raw[16:types_end]
    return excluded, head + b''.join(kept_rows) + raw[pool:pool + strings]


GUI_IMAGE_REF = re.compile(rb'(?i)(?:Imagefile|Filename)\s*=\s*"([^"]+\.(?:tga|dds|png|jpg|bmp))"')


def gl_gui_textures(ov, gl_interface, report):
    """CYS-CY (cs2-world, --gui gl): the textures the client_GL imagesets/fonts name (e.g. Common/Common_GL.tga) live
    in the Material folders of Assets/Canonical and are no longer part of Assets/CanonicalCY since the CY GUI layer
    replaced the GL one. Stage every such file that the CY data set does not have, from the same Material folder of
    the client_GL data set; a missing texture aborts the imageset with a CEGUI exception and ends Game.exe."""
    wanted = set()
    for path in sorted(gl_interface.rglob('*')):
        if not path.is_file() or path.suffix.lower() not in ('.xml', '.font', '.scheme', '.imageset'):
            continue
        for match in GUI_IMAGE_REF.findall(path.read_bytes()):
            wanted.add(match.decode('latin-1').replace('\\', '/').lstrip('/'))
    folders = [f for f in ('MaterialFolder', 'Material2Folder', 'Material3Folder', 'Material4Folder',
                           'Material5Folder', 'Material6Folder', 'Material7Folder', 'Material8Folder')]
    gl_root = ROOT / 'Assets/Canonical/Data'
    staged, missing = 0, []
    for name in sorted(wanted):
        if any((CANON / folder / name).is_file() for folder in folders):
            continue   # the CY data set has it
        source = next((gl_root / folder / name for folder in folders if (gl_root / folder / name).is_file()), None)
        if source is None:
            missing.append(name)
            continue
        folder = source.parent
        relative = source.relative_to(gl_root).as_posix()
        top, rest = relative.split('/', 1)
        if ('Post/' + top + '/' + rest) in ov.files or ('Pre/' + top + '/' + rest) in ov.files:
            continue
        ov.add_winner(top, rest, src=source, origin='../Data/' + relative,
                      reason='texture of the client_GL GUI layer (--gui gl)')
        staged += 1
    report['gl_gui_textures'] = {'referenced': len(wanted), 'staged': staged, 'not_found': missing[:20],
                                 'not_found_count': len(missing)}
    return staged


def merge_gl_scheme(ov, gl_interface, report):
    """CYS-CY (cs2-world, --gui gl): the scheme files staged earlier (the CY creation profile merges its CysCR_*
    entries into the CY scheme) would hide the client_GL widget mappings, e.g. TLBB_ChatTabGL of ChatFrame. Rebuild
    each staged scheme on the client_GL file and append only what the earlier overlay added on top of the CY file.
    Returns how many scheme files were rebuilt."""

    def element_key(element):
        attributes = element.attrib
        return (element.tag, attributes.get('WindowType') or attributes.get('Name') or
                attributes.get('Filename') or attributes.get('Alias') or '')

    rebuilt = 0
    notes = []
    for key in [k for k in list(ov.files) if k.startswith('Post/InterfaceFolder/') and k.endswith('.scheme.xml')]:
        relpath = key[len('Post/InterfaceFolder/'):]
        gl_path = gl_interface / relpath
        cy_path = CANON / 'InterfaceFolder' / relpath
        record = ov.files[key]
        staged_bytes = record['data'] if record['data'] is not None else Path(record['src']).read_bytes()
        if not gl_path.is_file() or not cy_path.is_file():
            continue
        gl_root = ET.fromstring(gl_path.read_bytes())
        cy_keys = {element_key(e) for e in ET.fromstring(cy_path.read_bytes())}
        gl_keys = {element_key(e) for e in gl_root}
        added = [e for e in ET.fromstring(staged_bytes)
                 if element_key(e) not in cy_keys and element_key(e) not in gl_keys]
        for element in added:
            gl_root.append(element)
        data = b'<?xml version="1.0" ?>\n' + ET.tostring(gl_root, encoding='utf-8')
        del ov.files[key]
        pre = 'Pre/InterfaceFolder/' + relpath
        had_pre = pre in ov.files
        if had_pre:
            del ov.files[pre]
        # The scheme is looked up by base name as well: it must win in Pre and Post (Overlay.add_winner).
        ov.add_winner('InterfaceFolder', relpath, data=data, origin=rel(gl_path),
                      reason='client_GL scheme (--gui gl) + %d entries the CY creation profile added' % len(added))
        rebuilt += 1
        notes.append({'file': relpath, 'entries_from_creation_profile': len(added)})
    report['gl_scheme_merge'] = notes
    return rebuilt


def gl_gui_overlay(ov, report, gui):
    """CYS-CY 14/09 (cs2-world): stage the client_GL GUI layer (InterfaceFolder + the text InterfaceEx.txt) over the
    CY 3.71 one of Assets/CanonicalCY. --gui gl is for a Game.exe whose CEGUI/Falagard layer is still the client_GL
    one: the CY looknfeel/layouts of agent cy-gui need widgets, properties and imagery this build does not have
    (e.g. TLBBLook_CreatureBoard 'salessign' -> Falagard/CheckBox property MinHeight, ChildImage), and CEGUI turns
    that into an exception that ends Game.exe when the first name board is built in the world. Nothing is written
    into Assets; only the stage overlay carries these files."""
    if gui != 'gl':
        report['gui_layer'] = {'gui': gui, 'files': 0}
        return
    if DATA_PROFILE != 'CanonicalCY':
        raise SystemExit('--gui gl applies to the CanonicalCY data profile only')
    source = ROOT / 'Assets/Canonical/Data/InterfaceFolder'
    if not source.is_dir():
        raise SystemExit('client_GL GUI layer not found: ' + str(source))
    count = 0
    for path in sorted(source.rglob('*')):
        if not path.is_file():
            continue
        relpath = path.relative_to(source).as_posix()
        if ('Post/InterfaceFolder/' + relpath in ov.files) or ('Pre/InterfaceFolder/' + relpath in ov.files):
            continue   # an earlier overlay (CY creation profile, login list) wins over the plain GL file
        # Pre + Post: the GL file must win for the base-name lookups of CEGUI as well as for full paths.
        ov.add_winner('InterfaceFolder', relpath, src=path, origin='../Data/InterfaceFolder/' + relpath,
                      reason='client_GL GUI layer (--gui gl)')
        count += 1
    merged = merge_gl_scheme(ov, source, report)
    count += merged
    count += gl_gui_textures(ov, source, report)
    table = ROOT / 'Assets/Canonical/Data/ConfigFolder/InterfaceEx.txt'
    if not table.is_file():
        raise SystemExit('client_GL InterfaceEx.txt not found: ' + str(table))
    ov.add_winner('ConfigFolder', 'InterfaceEx.txt', src=table, origin='../Data/ConfigFolder/InterfaceEx.txt',
                  reason='client_GL window list belongs to the client_GL GUI layer (--gui gl)')
    report['gui_layer'] = {'gui': 'gl', 'files': count + 1,
                           'source': rel(source), 'table': rel(table)}


def cy_minimap_header_overlay(ov, report, gui):
    """Readable map header in a fresh stage; existing data junctions stay unchanged."""
    if gui != 'cy' or DATA_PROFILE != 'CanonicalCY':
        return
    from map_header_layout import generate
    name = 'MiniMap/MiniMap.layout.xml'
    source = CANON / 'InterfaceFolder' / name
    original = source.read_bytes()
    data, changed = generate(original)
    ov.add_winner('InterfaceFolder', name, data=data,
                  origin='../Data/InterfaceFolder/' + name,
                  reason='CY minimap: scene name and coordinates on separate rows, existing events preserved')
    report['cy_minimap_header'] = {'before_sha256': sha256(original), 'after_sha256': sha256(data),
                                 'changed_geometry': changed, 'source_unchanged': True}


def cy_shop_footer_overlay(ov, report, gui):
    """Keep the CY balance and search controls on separate rows in new stages only."""
    if gui != 'cy' or DATA_PROFILE != 'CanonicalCY':
        return
    from patch_nbshop_footer import generate
    name = 'YuanbaoShop/YuanbaoShop.layout.xml'
    source = CANON / 'InterfaceFolder' / name
    original = source.read_bytes()
    data, changed = generate(original)
    ov.add_winner('InterfaceFolder', name, data=data,
                  origin='../Data/InterfaceFolder/' + name,
                  reason='CY shop: two-row footer preserves the full balance and search controls')
    report['cy_shop_footer'] = {'before_sha256': sha256(original), 'after_sha256': sha256(data),
                                'changed_geometry': changed, 'source_unchanged': True}


def cy_progressbar_lifecycle_overlay(ov, report, gui):
    if gui != 'cy' or DATA_PROFILE != 'CanonicalCY':
        return
    name = 'ProgressBar/ProgressBar.layout.xml'
    original = (CANON / 'InterfaceFolder' / name).read_bytes()
    root = ET.fromstring(original)
    window = root.find('Window')
    if window is None or window.get('Name') != 'ProgressBar_Progress' or window.findall('Event'):
        raise ValueError('Unreviewed ProgressBar lifecycle layout')
    if original.count(b'</Window>') != 1:
        raise ValueError('ProgressBar must have exactly one root window')
    data = original.replace(b'</Window>', b'<Event Name="Hidden" Function="Progress_close();" />\r\n\t</Window>')
    ov.add_winner('InterfaceFolder', name, data=data, origin='../Data/InterfaceFolder/' + name,
                  reason='Cast fade completion synchronizes the script window through its existing close callback')
    report['cy_progressbar_lifecycle'] = {'before_sha256': sha256(original), 'after_sha256': sha256(data)}


def cy_creatureboard_readability_overlay(ov, report, gui):
    if gui != 'cy' or DATA_PROFILE != 'CanonicalCY':
        return
    from patch_creatureboard_readability import generate, NAME
    data, details = generate((CANON / 'InterfaceFolder' / NAME).read_bytes())
    ov.add_winner('InterfaceFolder', NAME, data=data, origin='../Data/InterfaceFolder/' + NAME,
                  reason='Name/title labels: wider centred wrapping and fitted text insets')
    report['cy_creatureboard_readability'] = details


def cy_selfequip_readability_overlay(ov, report, gui, enabled):
    """Opt-in proposal: wider CY stat rows and two rows of tabs in a fresh stage."""
    if not enabled:
        return
    if gui != 'cy' or DATA_PROFILE != 'CanonicalCY':
        raise SystemExit('--cy-selfequip-readable requires --data CanonicalCY --gui cy')
    from patch_selfequip_readability import generate
    source = CANON / 'InterfaceFolder/SelfEquip'
    layout, lua, details = generate((source / 'SelfEquip.layout.xml').read_bytes(),
                                   (source / 'SelfEquip.lua').read_bytes())
    for filename, data in (('SelfEquip.layout.xml', layout), ('SelfEquip.lua', lua)):
        ov.add_winner('InterfaceFolder', 'SelfEquip/' + filename, data=data,
                      origin='../Data/InterfaceFolder/SelfEquip/' + filename,
                      reason='Scoped CY SelfEquip readability; existing controls and events preserved')
    report['cy_selfequip_readability'] = details


def cy_tooltip_readability_overlay(ov, report, gui):
    if gui != 'cy' or DATA_PROFILE != 'CanonicalCY':
        return
    from patch_tooltip_readability import generate
    name = 'SuperTooltip/SuperTooltip.layout.xml'
    source = CANON / 'InterfaceFolder' / name
    original = source.read_bytes()
    data, changed = generate(original)
    ov.add_winner('InterfaceFolder', name, data=data,
                  origin='../Data/InterfaceFolder/' + name,
                  reason='CY tooltip: translated level fits while preserving right-anchored upgrade controls')
    report['cy_tooltip_readability'] = {'before_sha256': sha256(original), 'after_sha256': sha256(data),
                                      'changed_geometry': changed, 'source_unchanged': True}
    from patch_inspection_ui import generate as inspect_ui
    from patch_inspection_ui import layout as inspect_layout
    for frame in ('TargetData', 'TargetEquip'):
        name = frame + '/' + frame + '.lua'
        data = inspect_ui((CANON / 'InterfaceFolder' / name).read_bytes(), frame)
        ov.add_winner('InterfaceFolder', name, data=data, origin='../Data/InterfaceFolder/' + name,
                      reason='CY inspection: corrected labels, care lifecycle and absent enhancement values')
    for frame in ('TargetEquip', 'TargetData'):
        name = frame + '/' + frame + '.layout.xml'
        ov.add_winner('InterfaceFolder', name, data=inspect_layout((CANON / 'InterfaceFolder' / name).read_bytes(),frame),
                      origin='../Data/InterfaceFolder/' + name, reason='CY inspection: readable Vietnamese labels and two rows of tabs')


def cy_wardrobe_overlay(ov, report, gui):
    if gui != 'cy' or DATA_PROFILE != 'CanonicalCY':
        return
    from wardrobe_ui import generate
    layout, lua, counts = generate(CANON)
    for suffix, data in (('layout.xml', layout), ('lua', lua)):
        name = 'NewExterior_DressBox/NewExterior_DressBox.' + suffix
        ov.add_winner('InterfaceFolder', name, data=data, origin='../Data/InterfaceFolder/' + name,
                      reason='CY wardrobe: paginated full catalog and server-confirmed ownership')
    report['cy_wardrobe'] = {'version': 1, 'page_size': 16, 'counts': counts}


def s2_index():
    """lower-case engine-form base name -> S2 path (S2 is read-only; first occurrence wins)."""
    index = {}
    for dirpath, _dirs, names in os.walk(S2):
        for n in names:
            try:
                key = engine_name(n).lower()
            except UnicodeEncodeError:
                continue
            index.setdefault(key, Path(dirpath) / n)
    return index


def s2_folder(path):
    top = path.relative_to(S2).parts[0].lower()
    for prefix, folder in (('model', 'ModelFolder'), ('material', 'MaterialFolder'), ('effect', 'EffectFolder'),
                           ('brushes', 'BrushesFolder'), ('scene', 'SceneFolder'), ('sound', 'SoundFolder'),
                           ('interface', 'InterfaceFolder'), ('config', 'ConfigFolder')):
        if top.startswith(prefix):
            return folder
    return None


def complete_from_s2(ov, stage_locations, report, rounds=4):
    """Files named by overlay content but found nowhere: take them from S2 in engine form (D1)."""
    added = []
    index = None
    for _ in range(rounds):
        result = check_references(stage_locations(), overlay_only=True)
        missing = [v for v in result['status'].values() if v[0] == 'missing']
        if not missing:
            break
        if index is None:
            index = s2_index()
        progress = False
        for _st, _where, source, name in missing:
            base = name.rsplit('/', 1)[-1]
            hit = index.get(base.lower())
            if hit is None:
                continue
            folder = s2_folder(hit)
            if folder is None:
                continue
            ov.add('Post', folder, engine_name(hit.name), src=hit,
                   origin='../Tools/DATA NEW/DataCY31-08-26/' + hit.relative_to(S2).as_posix(),
                   reason='named by ' + source + ' but absent from the profile closure')
            added.append({'name': base, 'from': hit.relative_to(S2).as_posix(), 'named_by': source})
            progress = True
        if not progress:
            break
    report['s2_completions'] = added


# ------------------------------------------------------------------------------------------------------- build
def git_head(tree):
    try:
        return subprocess.run(['git', '-C', str(tree), 'rev-parse', 'HEAD'], capture_output=True, text=True,
                              timeout=30).stdout.strip()
    except OSError:
        return ''


def stage_client_values():
    tree = ast.parse(STAGE_CLIENT.read_text(encoding='utf-8-sig'))
    values = {}
    for node in tree.body:
        if isinstance(node, ast.Assign) and isinstance(node.targets[0], ast.Name) and \
                node.targets[0].id in ('WXSYSTEM', 'LOGINSERVER'):
            values[node.targets[0].id] = ast.literal_eval(node.value)
    return values


def resources_cfg(ov, has_bootstrap_zip):
    lines = ['# CY-Source Tools/game/stage_game.py: client_GL Bin/FairyResources.cfg layout on ../Data (junction ->',
             '# %s) + ../Overlay. Pre folders precede Canonical (base-name / backslash lookups),' % DATA_PROFILES[DATA_PROFILE][0],
             '# Post folders follow it (full relative paths, new files). See Docs/specs/game/canonical-data_vi.md.']
    for group in ('Bootstrap', 'General', 'Brushes', 'Scene'):
        lines.append('')
        lines.append('[%s]' % group)
        if group == 'Bootstrap':
            lines += ['Zip=../Data/OgreCore.zip', 'Zip=../Data/MaterialTemplates.zip']
            if has_bootstrap_zip:
                lines.append('Zip=../Overlay/Bootstrap/CysCreateTemplates.zip')
            continue
        for folder in ov.folders('Pre'):
            if GROUP_OF.get(folder, 'General') == group:
                lines.append('FileSystem=*../Overlay/Pre/' + folder)
        for g, p, t in CANON_LAYOUT:
            if g == group:
                lines.append('FileSystem=*../Data/' + p)
        for folder in ov.folders('Post'):
            if GROUP_OF.get(folder, 'General') == group:
                lines.append('FileSystem=*../Overlay/Post/' + folder)
    return ('\r\n'.join(lines) + '\r\n').encode('ascii')


def stage_locations_for(stage, ov, zip_members):
    """Locations the stage WILL have (before anything is written): Canonical + planned overlay files."""
    class Planned(Location):
        def __init__(self, group, spec, files):
            super().__init__(group, 'FileSystem', stage / spec.replace('../', ''), True, spec)
            self._files = files
            self._lower = {n.lower(): n for n in files}

        def read(self, name):
            record = ov.files[self.spec.replace('../Overlay/', '') + '/' + self._lower[name.lower()]]
            return record['data'] if record['data'] is not None else Path(record['src']).read_bytes()

    def build():
        locs = []
        for group in ('Bootstrap', 'Brushes', 'General', 'Scene'):
            if group == 'Bootstrap':
                locs += [l for l in canonical_locations() if l.group == 'Bootstrap']
                continue
            for where in ('Pre', None, 'Post'):
                if where is None:
                    locs += [l for l in canonical_locations() if l.group == group]
                    continue
                for folder in ov.folders(where):
                    if GROUP_OF.get(folder, 'General') != group:
                        continue
                    prefix = where + '/' + folder + '/'
                    files = [k[len(prefix):] for k in ov.files if k.startswith(prefix)]
                    locs.append(Planned(group, '../Overlay/' + where + '/' + folder, files))
        return locs
    return build


def cmd_build(args):
    name = args.name
    if not re.fullmatch(r'[A-Za-z0-9._-]{1,64}', name):
        raise SystemExit('stage name: letters, digits, . _ - only')
    stage = Path(args.out).resolve() if args.out else STAGES / name
    if not str(stage).startswith(str(ROOT / 'Build') + os.sep):
        raise SystemExit('stage must stay below Build: ' + str(stage))
    if stage.exists():
        raise SystemExit('stage exists; keep evidence and choose a new --name/--out: ' + rel(stage))
    bin_src = Path(args.bin).resolve() if args.bin else DEFAULT_BIN
    profile_stage = Path(args.profile_stage).resolve() if args.profile_stage else PROFILE_STAGE
    report = {'tool': 'Tools/game/stage_game.py', 'tool_sha256': sha256_file(__file__),
              'created': datetime.datetime.now().astimezone().isoformat(timespec='seconds'), 'name': name}

    # ---- binaries (plan)
    binaries = []
    for p in sorted(bin_src.iterdir()):
        low = p.name.lower()
        if low == 'game.exe' or low.endswith('.dll') or (args.pdb and low.endswith('.pdb') and
                                                         not low.startswith(('cys_', 'abi_', 'tlbbviewer'))):
            binaries.append({'name': p.name, 'src': p, 'kind': 'build'})
    have = {b['name'].lower() for b in binaries}
    if 'game.exe' not in have:
        raise SystemExit('no Game.exe in ' + str(bin_src))
    ci_manifest = json.loads((CI_BIN / 'cys_stage.json').read_text(encoding='utf-8-sig'))
    ci_files = {f['name'].lower(): f for f in ci_manifest['files']}
    for n in RUNTIME_FROM_CI:
        if n.lower() in have:
            continue
        entry = ci_files.get(n.lower())
        if entry is None:
            raise SystemExit('runtime file missing from the CI stage: ' + n)
        src = CI_BIN / entry['name']
        if sha256_file(src) != entry['sha256']:
            raise SystemExit('CI stage file differs from its manifest: ' + n)
        binaries.append({'name': entry['name'], 'src': src, 'kind': 'runtime (CI stage %s)' % ci_manifest['short']})
    terrain = GL / 'Bin64/TerrainTypeInfo.cfg'
    if not terrain.is_file():
        terrain = GL / 'Bin/TerrainTypeInfo.cfg'
    values = stage_client_values()
    wxsystem = values['WXSYSTEM'].replace('GameServer_Port=1231', 'GameServer_Port=14400') \
        .replace('[Variable]\n', '[Variable]\nSystem_CodePage=65001\n').replace('DisableAllSound=0', 'DisableAllSound=1')
    for needle in ('GameServer_Address=127.0.0.1', 'GameServer_Port=14400', 'GameServer_ConnectDirect=0',
                   'System_CodePage=65001'):
        if wxsystem.count(needle) != 1:
            raise SystemExit('unexpected WXSystem template: ' + needle)
    # camera3d: scene camera keys of CY 3.71 Bin/System.cfg (Docs/specs/render/camera3d_vi.md). View_UseSkyCamera
    # is client_GL's switch; C has no such key and keeps the pitch at Camera_Pitch (scene-change-fix: CY camera read
    # from memory, a vertical right drag does not change the pitch).
    #
    # CO Y KHAC CY (17/09/2026, lenh nguoi dung "doi mac dinh luon"): ban choi ghi View_UseSkyCamera=1 = CAMERA TU DO
    # (pitch -40..60 do, Camera_Pitch_Min/Max). CY khoa pitch 40 do, nhung nguoi dung muon goc nhin tu do khi choi.
    # Day la ngoai le duy nhat cua luat "moi thu nhu CY" o tang camera; muon quay ve dung CY thi doi lai thanh '0'
    # (mot khoa, khong can dung lai gi khac). Xem Docs/specs/render/camera3d_vi.md muc "Co y khac CY".
    wxsystem = apply_cy_camera_keys(wxsystem)
    # Player settings belong in the generator, before the configuration hashes are sealed.
    # Front/Back drive the QPC pacer; System_MaxFPS alone only affects the legacy fallback.
    # Keep the default measurement template unchanged when --play is absent.
    if getattr(args, 'play', False):
        for key, value in (('View_Resoution', '1280,720'), ('System_MaxFPS', '120'),
                           ('System_MaxFPS_Front', '120'), ('System_MaxFPS_Back', '30'),
                           ('View_Aplomb', '0'), ('DisableAllSound', '0')):
            wxsystem, count = re.subn(r'(?m)^' + re.escape(key) + r'=[^\r\n]*$',
                                     key + '=' + value, wxsystem)
            if count != 1:
                raise SystemExit('play preset requires exactly one key: ' + key)
    login = values['LOGINSERVER']
    if 'IP=127.0.0.1\nPORT=14400' not in login:
        raise SystemExit('unexpected WXLoginServer template')

    # ---- overlay (plan)
    canon = CanonicalView()
    ov = Overlay()
    login_overlay(ov, canon, report)
    keep_gl_overlay(ov, report)
    zip_members = {}
    creation = {}
    if not args.no_creation:
        creation['profile_stage'] = rel(profile_stage)
        creation['profile_manifest_sha256'] = sha256_file(profile_stage / 'Bin64/create_role_profile.json')
        zip_members = creation_overlay(ov, profile_stage, canon, creation)
        complete_from_s2(ov, stage_locations_for(stage, ov, zip_members), creation)
    report['creation'] = creation or None
    # CEGUI window types this build lacks would abort a layout and end Game.exe: keep those windows out, report them
    gl_gui_overlay(ov, report, getattr(args, 'gui', 'cy'))
    cy_minimap_header_overlay(ov, report, getattr(args, 'gui', 'cy'))
    cy_shop_footer_overlay(ov, report, getattr(args, 'gui', 'cy'))
    cy_tooltip_readability_overlay(ov, report, getattr(args, 'gui', 'cy'))
    cy_creatureboard_readability_overlay(ov, report, getattr(args, 'gui', 'cy'))
    cy_progressbar_lifecycle_overlay(ov, report, getattr(args, 'gui', 'cy'))
    cy_selfequip_readability_overlay(ov, report, getattr(args, 'gui', 'cy'), getattr(args, 'cy_selfequip_readable', False))
    cy_wardrobe_overlay(ov, report, getattr(args, 'gui', 'cy'))
    ui_compat_overlay(ov, canon, registered_window_types(bin_src), report)

    # ---- write (every destination is below the new stage and never below the junction)
    stage.mkdir(parents=True)
    bin64 = stage / 'Bin64'
    bin64.mkdir()
    for sub in ('tmp', 'ShaderCache'):
        (bin64 / sub).mkdir()
    records = []
    for b in binaries:
        dst = bin64 / b['name']
        shutil.copy2(b['src'], dst)
        records.append({'name': b['name'], 'sha256': sha256_file(dst), 'bytes': dst.stat().st_size,
                        'kind': b['kind'], 'source': rel(b['src'])})
    media = CI_BIN / 'Media'
    if media.is_dir():
        shutil.copytree(media, bin64 / 'Media')
    # fx-render HANDOFF (Build/Logs/2026-09-13-fx-render): post-FX media of the source tree the binaries were built
    # from -> Bin64/Media/CysPostFX. The stage sets no PostFX key: CysPostFx defaults decide (CYS-COLOR: NewHDRBloom
    # off in the world as CY; CYS-AA: PostFX.AAMode=fxaa turns CY's FXAA on over the template's View_Fanhunjiao=0 and
    # View_TextureFiltering=2 is applied at start-up, Docs/specs/render/aa-cy_vi.md).
    if re.search(r'(?mi)^\s*(Gfx_PostFX|PostFX\.)', wxsystem):
        raise SystemExit('WXSystem.cfg must not override the post-FX defaults')
    postfx = next((p / 'Src/Engine/WXCore/CYS/PostFX/media' for p in bin_src.resolve().parents
                   if (p / 'Src/Engine/WXCore/CYS/PostFX/media').is_dir()), None)
    report['postfx_media'] = None
    if postfx is not None:
        target = bin64 / 'Media/CysPostFX'
        target.mkdir(parents=True, exist_ok=True)
        copied = []
        for f in sorted(postfx.iterdir()):
            if f.is_file():
                shutil.copy2(f, target / f.name)
                copied.append({'name': f.name, 'sha256': sha256_file(target / f.name)})
        report['postfx_media'] = {'source': rel(postfx), 'files': copied}
    # CYS-SHADOW: shadow media (debug view, fallback casters) of the same source tree -> Bin64/Media/CysShadow
    shadow_media = next((p / 'Src/Engine/WXCore/CYS/Shadow/media' for p in bin_src.resolve().parents
                         if (p / 'Src/Engine/WXCore/CYS/Shadow/media').is_dir()), None)
    report['shadow_media'] = None
    if shadow_media is not None:
        target = bin64 / 'Media/CysShadow'
        target.mkdir(parents=True, exist_ok=True)
        copied = []
        for f in sorted(shadow_media.iterdir()):
            if f.is_file():
                shutil.copy2(f, target / f.name)
                copied.append({'name': f.name, 'sha256': sha256_file(target / f.name)})
        report['shadow_media'] = {'source': rel(shadow_media), 'files': copied}
    shutil.copy2(terrain, bin64 / 'TerrainTypeInfo.cfg')
    shutil.copy2(terrain, bin64 / 'WXTerrainType.cfg')
    if creation:
        # Game.exe enables the CY creation/selection path only when Bin64/create_role_profile.json exists
        # (CGamePro_CharCreate::HasCyCreationProfile); without it a character list with one role throws
        # "CY creation profile is not installed." (world-replay 14/09: first run on a stage_game stage).
        shutil.copy2(profile_stage / 'Bin64/create_role_profile.json', bin64 / 'create_role_profile.json')
        creation['profile_json_staged_sha256'] = sha256_file(bin64 / 'create_role_profile.json')
    (bin64 / 'WXSystem.cfg').write_bytes(wxsystem.replace('\n', '\r\n').encode('ascii'))
    (stage / 'Patch').mkdir()
    (stage / 'Patch/WXLoginServer.txt').write_bytes(login.replace('\n', '\r\n').encode('ascii'))
    shutil.copy2(LOGIN_FIXTURE, stage / 'Patch/LoginServer.txt')
    (stage / 'ScreenShots').mkdir()
    rc = subprocess.run(['cmd', '/c', 'mklink', '/J', str(stage / 'Data'), str(CANON)], capture_output=True,
                        text=True)
    if rc.returncode != 0:
        raise SystemExit('mklink /J failed: ' + rc.stdout + rc.stderr)
    if os.path.realpath(stage / 'Data') != os.path.realpath(CANON):
        raise SystemExit('Data junction does not resolve to the %s data set' % DATA_PROFILE)
    overlay_records = []
    real_canon = os.path.realpath(CANON)
    for key, record in ov.files.items():
        dst = stage / 'Overlay' / key
        if os.path.realpath(dst).startswith(real_canon):
            raise SystemExit('refusing to write below Canonical: ' + key)
        dst.parent.mkdir(parents=True, exist_ok=True)
        if record['data'] is not None:
            dst.write_bytes(record['data'])
        else:
            shutil.copyfile(record['src'], dst)
        if sha256_file(dst) != record['sha256']:
            raise SystemExit('overlay write verification failed: ' + key)
        overlay_records.append({'path': 'Overlay/' + key, 'sha256': record['sha256'], 'bytes': dst.stat().st_size,
                                'origin': record['origin'], 'reason': record['reason']})
    if zip_members:
        target = stage / 'Overlay/Bootstrap/CysCreateTemplates.zip'
        target.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as z:
            for member, data in zip_members.items():
                z.writestr(member, data)
        overlay_records.append({'path': 'Overlay/Bootstrap/CysCreateTemplates.zip', 'sha256': sha256_file(target),
                                'bytes': target.stat().st_size, 'origin': 'MaterialTemplates.zip delta of the profile',
                                'reason': '%d member(s)' % len(zip_members)})
    (bin64 / 'WXResources.cfg').write_bytes(resources_cfg(ov, bool(zip_members)))
    report.update({
        'stage': rel(stage), 'bin_source': rel(bin_src), 'bin_source_git_head': git_head(bin_src),
        'binaries': records,
        'configs': {n: sha256_file(bin64 / n) for n in ('WXSystem.cfg', 'WXResources.cfg', 'TerrainTypeInfo.cfg',
                                                         'WXTerrainType.cfg')},
        'terrain_source': rel(terrain),
        'patch': {n: sha256_file(stage / 'Patch' / n) for n in ('LoginServer.txt', 'WXLoginServer.txt')},
        'data': {'junction': 'Data', 'target': rel(CANON), 'profile': DATA_PROFILE},
        'overlay': overlay_records, 'endpoint': '127.0.0.1:14400 (offline; never contacted)', 'game_args': ['-fl']})
    text = json.dumps(report, ensure_ascii=False, indent=1) + '\n'
    (bin64 / 'game_data_stage.json').write_text(text, encoding='utf-8')
    print('STAGED %s: %d binaries, %d overlay files, creation=%s' % (
        rel(stage), len(records), len(overlay_records), 'no' if args.no_creation else json.dumps(
            creation.get('decisions'), ensure_ascii=False)))
    if creation:
        print('  S2 completions:', len(creation.get('s2_completions', [])), 'canonical wins:',
              len(creation.get('canonical_wins', [])))
    return 0


# ------------------------------------------------------------------------------------------------------- check
def cmd_check(args):
    stage = Path(args.stage).resolve()
    locations = parse_resources_cfg(stage / 'Bin64')
    result = check_references(locations)
    names = result['names']
    summary = {'stage': rel(stage), 'resources_cfg_sha256': sha256_file(stage / 'Bin64/WXResources.cfg'),
               'locations': [l.group + ' ' + l.kind + ' ' + ('*' if l.recursive else '') + l.spec for l in locations],
               'unique_names': {k: v for k, v in names.items() if not k.endswith('_refs')},
               'references': {k[:-5]: v for k, v in names.items() if k.endswith('_refs')},
               'by_extension': result['by_extension'], 'cjk_files_on_disk': result['cjk_files_on_disk'],
               'source_files': result['source_files'], 'examples': result['examples']}
    out = Path(args.out).resolve() if args.out else None
    if out:
        out.mkdir(parents=True, exist_ok=True)
        (out / 'reachability.json').write_text(json.dumps(summary, ensure_ascii=False, indent=1) + '\n',
                                               encoding='utf-8')
        rows = ['status\tname\twhere\tfirst_named_by']
        for key in sorted(result['status']):
            st, where, source, name = result['status'][key]
            rows.append('\t'.join([st, name, where, source]))
        (out / 'reachability.tsv').write_text('\n'.join(rows) + '\n', encoding='utf-8')
    print(json.dumps({'stage': summary['stage'], 'unique_names': summary['unique_names'],
                      'references': summary['references'], 'cjk_files_on_disk': summary['cjk_files_on_disk']},
                     ensure_ascii=False))
    for st in ('unreachable', 'missing'):
        for line in summary['examples'][st][:10]:
            print('  %s: %s' % (st, line))
    return 1 if args.gate and summary['unique_names'].get('unreachable', 0) else 0


CY_CAMERA_KEYS = (
    ('Camera_MinDistance', '6.0'), ('Camera_MaxDistance', '27.5'), ('Camera_Zoom', '1.0'), ('Camera_Pitch', '40.0'),
    ('Camera_FOV', '35.0'), ('Camera_Smooth', '1'), ('Camera_RestoreView', '0'), ('Camera_Pitch_Min', '-40.0'),
    ('Camera_Pitch_Max', '60.0'), ('Camera_Pitch_Moving', '40.0'), ('Camera_MoveSpeed_Auto', '30.0'),
    ('View_DefaultCamera', '1'), ('View_UseSkyCamera', '1'),   # 1 = camera tu do (CO Y KHAC CY, xem ghi chu tren)
)


def apply_cy_camera_keys(text):
    """Set every CY 3.71 camera key once (replacing the template value, appending the missing ones)."""
    lines = text.split('\n')
    for key, value in CY_CAMERA_KEYS:
        hits = [i for i, line in enumerate(lines) if line.split('=', 1)[0].strip() == key]
        if len(hits) > 1:
            raise SystemExit('WXSystem template repeats ' + key)
        if hits:
            lines[hits[0]] = key + '=' + value
        else:
            end = len(lines)
            while end and not lines[end - 1].strip():
                end -= 1
            lines.insert(end, key + '=' + value)
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='cmd', required=True)
    b = sub.add_parser('build')
    b.add_argument('--name', required=True)
    b.add_argument('--bin', help='build output with Game.exe (default: the game-data worktree build)')
    b.add_argument('--profile-stage', help='stage whose applied CY creation profile is rebased (read-only)')
    b.add_argument('--no-creation', action='store_true')
    b.add_argument('--pdb', action='store_true', help='also stage the .pdb files of Game.exe and the DLLs')
    b.add_argument('--cy-selfequip-readable', action='store_true',
                   help='stage the reviewed SelfEquip readability proposal in this new CY stage')
    b.add_argument('--out', help='stage directory (default Build/game-data/NAME); must stay below Build')
    b.add_argument('--root', help='CY-Source tree holding Canonical, the CI stage and the profile stage '
                                  '(default: the tree this script lives in)')
    b.add_argument('--gui', choices=('cy', 'gl'), default='cy',
                   help='GUI layer of a CanonicalCY stage: cy (the CY 3.71 layer in the data set) or gl '
                        '(stage the client_GL layer, for a build without the CY widgets)')
    b.add_argument('--play', action='store_true',
                   help='player preset: 1280x720, 120/30 FPS foreground/background, VSync off, sound on')
    b.add_argument('--data', choices=sorted(DATA_PROFILES), default='Canonical',
                   help='data profile behind the Data junction: Canonical (client_GL structs) or CanonicalCY '
                        '(CY 3.71 structs, cs1-tables and later)')
    c = sub.add_parser('check')
    c.add_argument('--stage', required=True)
    c.add_argument('--out')
    c.add_argument('--gate', action='store_true', help='exit 1 when any referenced name is unreachable')
    c.add_argument('--root', help='CY-Source tree holding Canonical (default: the tree this script lives in)')
    c.add_argument('--data', choices=sorted(DATA_PROFILES), default='Canonical', help='data profile (see build)')
    args = parser.parse_args()
    if getattr(args, 'root', None):
        set_root(args.root)
    set_data_profile(getattr(args, 'data', 'Canonical'))
    return cmd_build(args) if args.cmd == 'build' else cmd_check(args)


if __name__ == '__main__':
    sys.exit(main())
