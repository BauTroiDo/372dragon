"""cy_quest_text.py - Vietnamese mission / NPC / place names of the CY quest frames (agent npc-quest, 15/09/2026).

The CY client describes a mission by a GBK Lua block in ConfigFolder (Script.dat id -> event/<scene>/*.lua,
`--MisDescBegin ... --MisDescEnd`, fields x<script>_g_MissionName / g_Name / g_AccomplishNPC_Name / g_SceneID /
g_Position_X / g_Position_Z / g_Custom / g_MissionKind). Game.exe 0.85 parses that block for the mission log and the
tracking frame (GMGameInterface_Script_DataPool.cpp GetPlayerMission_Description); the strings are GBK Chinese, the CY
UI is UTF-8 Vietnamese. This tool writes Src/Client/LuaApiGen/CysHost_QuestText_vi.inc: one row per mission script of
the four maps (Dai Ly, Lac Duong, To Chau, Vo Luong Son) plus the mission kinds, used by CysHost_Quest at run time.

Names, first hit wins (user 15/09: "ghep am Han-Viet, thay vi de nguyen chu Trung"):
  mission name  1. g_MissionName of the running private server script (Vietnamese, what the NPC dialogue shows)
  NPC name      1. wire_names_vi.lua of the private server (what the name board above the NPC shows)
  every name    2. cy_item_text.Lookup (override, translation memory, API dictionaries, cy_items_vi_hanviet.tsv)
                3. Han-Viet reading (cy_item_text.hanviet_name); new readings are appended to
                   Registry/i18n/cy_items_vi_hanviet.tsv with src `hanviet-quest` (kept by `cy_item_text.py hanviet`)
                4. the Chinese text as UTF-8
Long texts (dialogue, descriptions) are not handled here: they stay what the server sends / the StrDictionary key.

usage: python -B cy_quest_text.py [--server \\\\wsl.localhost\\TLBB\\home\\ubuntu\\cys-test-20260913] [--check]
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cy_item_text as IT      # noqa: E402

REPO = IT.REPO
CONFIG = os.path.join(IT.REPO_MAIN, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder')
OUT = os.path.join(REPO, 'Src', 'Client', 'LuaApiGen', 'CysHost_QuestText_vi.inc')
SERVER = r'\\wsl.localhost\TLBB\home\ubuntu\cys-test-20260913'
SCENE_DIRS = ('dali', 'luoyang', 'suzhou', 'wuliang')
SCENES = {2: '大理', 0: '洛阳', 1: '苏州', 73: '无量山'}
HAN = IT.HAN


def gbk(b):
    return IT.decode(b) if isinstance(b, bytes) else b


def c_str(s):
    out = []
    for ch in s.encode('utf-8'):
        if ch in (0x22, 0x5c):
            out.append('\\' + chr(ch))
        elif 0x20 <= ch < 0x7f:
            out.append(chr(ch))
        else:
            out.append('\\x%02x' % ch)
    # split after hex escapes so a following hex digit is not swallowed
    return '"' + '""'.join(re.split(r'(?<=\\x[0-9a-f]{2})(?=[0-9a-fA-F])', ''.join(out))) + '"'


def parse_descriptor(text, sid):
    m = re.search(r'--MisDescBegin(.*?)--MisDescEnd', text, re.S)
    if not m:
        return None
    body = m.group(1)
    d = {}
    for key in ('MissionName', 'Name', 'AccomplishNPC_Name'):
        mm = re.search(r'x%d_g_%s\s*=\s*"([^"]*)"' % (sid, key), body)
        if mm:
            d[key] = mm.group(1)
    for key in ('SceneID', 'MissionKind', 'MissionId'):
        mm = re.search(r'x%d_g_%s\s*=\s*(-?\d+)' % (sid, key), body)
        if mm:
            d[key] = int(mm.group(1))
    for key in ('Position_X', 'Position_Z'):
        mm = re.search(r'x%d_g_%s\s*=\s*(-?[\d.]+)' % (sid, key), body)
        if mm:
            d[key] = float(mm.group(1))
    mm = re.search(r'x%d_g_Custom\s*=\s*(\{.*)' % sid, body)
    if mm:
        d['Custom'] = re.findall(r'id\s*"?\]?\s*=\s*"([^"]*)"', mm.group(1))
    return d


def server_names(server):
    """{script id: Vietnamese g_MissionName} of the running server scripts, {zh: vi} of wire_names_vi.lua."""
    base = os.path.join(server, 'Game_2', 'Script', 'scripts')
    dat = open(os.path.join(base, 'scripts.lua'), encoding='utf-8', errors='replace').read()
    paths = {int(a): b for a, b in re.findall(r'\[(\d+)\]\s*=\s*"([^"]+)"', dat)}
    names = {}
    for sid, mod in paths.items():
        if not any('.event.%s.' % s in mod for s in SCENE_DIRS):
            continue
        p = os.path.join(server, 'Game_2', 'Script', *mod.split('.')) + '.lua'
        try:
            t = open(p, encoding='utf-8', errors='replace').read()
        except OSError:
            continue
        mm = re.search(r'\.g_MissionName\s*=\s*"([^"]*)"', t)
        if mm and not HAN.search(mm.group(1)):
            names[sid] = mm.group(1)
    wire = {}
    wp = os.path.join(server, 'GameServer', 'lualib', 'wire_names_vi.lua')
    if os.path.exists(wp):
        for zh, vi in re.findall(r'\["([^"]+)"\]\s*=\s*"([^"]*)"', open(wp, encoding='utf-8', errors='replace').read()):
            wire.setdefault(zh, vi)
    return names, wire


class Namer:
    def __init__(self, wire):
        self.look = IT.Lookup()
        self.read, self.phrases = IT.hanviet_model()
        self.wire = wire
        self.new_hanviet = {}
        self.src = {}

    def name(self, zh, npc=False):
        if not zh or not HAN.search(zh):
            return zh
        if npc and zh in self.wire:
            self.src[zh] = 'wire'
            return self.wire[zh]
        vi, src = self.look.get(zh)
        if vi is not None and not HAN.search(vi):
            self.src[zh] = src
            return vi
        hv = IT.hanviet_name(zh, self.read, self.phrases)
        if hv and not HAN.search(hv):
            self.new_hanviet[zh] = hv
            self.src[zh] = 'hanviet-quest'
            return hv
        self.src[zh] = 'untranslated'
        return zh


def mission_kinds():
    path = os.path.join(CONFIG, 'MissionKind.txt')
    raw = open(path, 'rb').read()
    nf, nr, kinds, cells, strings = IT.parse(raw)
    out = {}
    for r in range(nr):
        kid = cells[r * nf + 0] if kinds[0] != 2 else None
        name = None
        for c in range(nf):
            if kinds[c] == 2:
                name = gbk(strings[(r, c)])
                break
        if kid is not None and name:
            out[kid] = name
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--server', default=SERVER)
    ap.add_argument('--check', action='store_true', help='compare with the checked-in .inc, write nothing')
    args = ap.parse_args()
    dat = gbk(open(os.path.join(CONFIG, 'Script.dat'), 'rb').read())
    scripts = []
    for line in dat.splitlines():
        mm = re.match(r'\s*(\d+)\s*=\s*\\event\\(%s)\\(\S+\.lua)' % '|'.join(SCENE_DIRS), line)
        if mm:
            scripts.append((int(mm.group(1)), os.path.join(CONFIG, 'event', mm.group(2), mm.group(3))))
    names, wire = server_names(args.server)
    namer = Namer(wire)
    rows = []
    seen = set()
    for sid, path in sorted(scripts):
        if sid in seen or not os.path.exists(path):
            continue
        seen.add(sid)
        d = parse_descriptor(gbk(open(path, 'rb').read()), sid)
        if not d or 'MissionName' not in d:
            continue
        npc_zh = d.get('AccomplishNPC_Name') or d.get('Name') or ''
        scene = d.get('SceneID', -1)
        rows.append(dict(
            sid=sid, mission=d.get('MissionId', -1), kind=d.get('MissionKind', -1),
            name_zh=d['MissionName'], name=names.get(sid) or namer.name(d['MissionName']),
            npc=namer.name(npc_zh, npc=True), scene=scene,
            scene_name=namer.name(SCENES.get(scene, '')), x=int(d.get('Position_X', 0)), z=int(d.get('Position_Z', 0)),
            custom=[(c, namer.name(c)) for c in d.get('Custom', [])]))
    kinds = {k: namer.name(v) for k, v in mission_kinds().items()}
    lines = ['// CysHost_QuestText_vi.inc - GENERATED by Tools/pipeline/cy_quest_text.py (agent npc-quest). Do not edit.',
             '// Mission scripts of Dai Ly / Lac Duong / To Chau / Vo Luong Son: Vietnamese name, finish NPC and place,',
             '// custom goals (zh GBK text of the CY descriptor -> vi). Sources per name: server script, wire names,',
             '// translation memory / dictionaries, Han-Viet reading (cy_items_vi_hanviet.tsv src hanviet-quest).',
             '// { script, mission, kind, name, finish npc, scene, scene name, x, z }']
    lines.append('static const CysQuestText kQuestText[] = {')
    for r in rows:
        lines.append('    {%d, %d, %d, %s, %s, %d, %s, %d, %d},' % (
            r['sid'], r['mission'], r['kind'], c_str(r['name']), c_str(r['npc']), r['scene'], c_str(r['scene_name']),
            r['x'], r['z']))
    lines.append('};')
    customs = {}
    for r in rows:
        for zh, vi in r['custom']:
            customs.setdefault(zh, vi)
    lines.append('// custom goal strings (g_Custom id, UTF-8 zh -> vi)')
    lines.append('static const CysQuestPair kQuestCustom[] = {')
    for zh, vi in sorted(customs.items()):
        lines.append('    {%s, %s},' % (c_str(zh), c_str(vi)))
    lines.append('};')
    lines.append('// mission kinds (MissionKind.txt id -> vi)')
    lines.append('static const CysQuestKind kQuestKind[] = {')
    for k in sorted(kinds):
        lines.append('    {%d, %s},' % (k, c_str(kinds[k])))
    lines.append('};')
    text = '\n'.join(lines) + '\n'
    if args.check:
        old = open(OUT, encoding='utf-8').read() if os.path.exists(OUT) else ''
        print('up to date' if old == text else 'DIFFERS')
        return 0 if old == text else 1
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    # extend the Han-Viet table of cy_item_text (same file, own src tag)
    if namer.new_hanviet:
        have = IT.GDICT.load_tsv_dict(IT.HANVIET_TSV)
        add = [(z, v) for z, v in sorted(namer.new_hanviet.items()) if z not in have]
        if add:
            with open(IT.HANVIET_TSV, 'a', encoding='utf-8', newline='\n') as f:
                for z, v in add:
                    f.write('%s\t%s\thanviet-quest\n' % (z, IT.clean(v)))
    from collections import Counter
    print('missions %d (server names %d), customs %d, kinds %d, name sources %s -> %s' % (
        len(rows), sum(1 for r in rows if r['sid'] in names), len(customs), len(kinds),
        dict(Counter(namer.src.values())), os.path.relpath(OUT, REPO)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
