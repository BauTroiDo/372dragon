#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Offline check of the action-set tables against the models' skeletons (CYS actionset 14/09, CY 3.71 since cs2-world).

  $env:PYTHONUTF8="1"
  python Tests\\actionset\\check_actionset.py --data <Data root> --out <dir> [--all] [--model <name.obj> ...]

Reads ConfigFolder/ActionSet/{ActionSet,ActionSetLine,ActionSetKV}.txt, ActionSetFile.txt, CharModelEx.txt and
CharMount.txt with the same rules as Src/Client/WXClient/Action/CysActionSetTable.cpp (binary DBC of CY 3.71 or the
text tables of client_GL, tab cells, GBK names, lines indexed by row), then for every checked model resolves the base
actions of its set in the slots Game.exe would use (CY 16-slot lines: players 0..12 and 15, others 13; GL: 0..14 and 9
- Docs/specs/game/actionset_vi.md muc 4.3; CharModelEx column 20 in CY, 9 in GL) and looks each animation
name up in the model's skeletons (mesh skeletonLink + <Skeleton> declarations of all.obj + DefaultSkeleton), using
Tests/validators (V01/V02/V03 walkers). Nothing is written into the data root.

Default model list: the two player models, their rider sets from CharMount, and a monster / mount sample; --all
checks every CharModelEx row with a set (slow: every mesh and skeleton of the data set is walked once).

Outputs in --out: actionset_check.json (summary), models.tsv (one row per model), missing_names.tsv (name -> sets),
tables.txt (parser statistics). Exit 1 when the tables do not load or have dangling ids, 0 otherwise (missing
animations are reported, not fatal - the game keeps the current animation, like B).
"""
import argparse
import collections
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TESTS = os.path.dirname(HERE)
if TESTS not in sys.path:
    sys.path.insert(0, TESTS)
from validators import v01_mesh, v02_skeleton  # noqa: E402
from validators.common import DataRoot, tags, disp  # noqa: E402

BASE_ACTIONS = [(0, 'idle'), (1, 'idle_ex0'), (2, 'idle_ex1'), (3, 'walk'), (4, 'run'), (5, 'sit_down'),
                (6, 'sit_idle'), (7, 'sit_stand'), (14, 'f_idle'), (15, 'f_walk'), (16, 'f_run'), (23, 'be_hit'),
                (24, 'die'), (25, 'cadaver')]
# Slot layout of ActionSetLine. GL (client_GL, 11 or 15 columns): 0..8 weapons, 9 shared, 10..14 sects.
# CY 3.71 (16 columns, cs1-tables/cs2-world): SlotFromEquipType (CY FUN_1405c6df0) selects 0..12 and 15 for the
# weapon types, the shared slot of monsters/NPCs/pets/riders is 13 and slot 14 is data-only (never selected).
GL_PLAYER_SLOTS = list(range(0, 15))
GL_SHARED_SLOT = 9
CY_PLAYER_SLOTS = list(range(0, 13)) + [15]
CY_SHARED_SLOT = 13
CY_SLOTS = 16


# ---------------------------------------------------------------- tables (same rules as CysActionSetTable.cpp)
def _binary_rows(data):
    """CY 3.71 binary DBC (magic 0xDDBBCC00, TLBB_DBC.h FILE_HEAD), same reader as CysActionSetTable::SplitBinaryRows:
    fields / records / string bytes, one 4-byte type per field (2 = string offset, 1 = float), 4-byte cells, pool.
    Returns the cells as the bytes the text tables would hold, or None when the buffer is not binary."""
    import struct
    if len(data) < 16 or data[:4] != b'\x00\xcc\xbb\xdd':
        return None
    fields, records, strings = struct.unpack_from('<III', data, 4)
    if fields == 0 or fields > 1024 or records > 4000000:
        return []
    types_end = 16 + 4 * fields
    cells = fields * records
    if types_end > len(data) or cells > (len(data) - types_end) // 4:
        return []
    pool = types_end + 4 * cells
    if strings > len(data) - pool:
        return []
    kinds = struct.unpack_from('<%dI' % fields, data, 16)
    values = struct.unpack_from('<%dI' % cells, data, types_end)
    rows = []
    for r in range(records):
        row = []
        base = r * fields
        for c in range(fields):
            v = values[base + c]
            t = kinds[c]
            if t == 2:
                if v < strings:
                    end = data.find(b'\x00', pool + v, pool + strings)
                    row.append(data[pool + v:end if end >= 0 else pool + strings])
                else:
                    row.append(b'')
            elif t == 1:
                f = struct.unpack('<f', struct.pack('<I', v))[0]
                row.append(('%g' % f).encode('ascii'))
            else:
                row.append(b'%d' % struct.unpack('<i', struct.pack('<I', v))[0])
        rows.append(row)
    return rows


def _rows(path):
    rows = []
    with open(path, 'rb') as f:
        blob = f.read()
    binary = _binary_rows(blob)
    if binary is not None:
        return binary
    with open(path, 'rb') as f:
        for raw in f.read().split(b'\n'):
            line = raw.rstrip(b'\r')
            if not line:
                continue
            cells = line.split(b'\t')
            c0 = cells[0]
            if not c0 or not (c0[:1] == b'-' or c0[:1].isdigit()):
                continue
            rows.append(cells)
    return rows


def _int(cells, i, default, stats):
    if i >= len(cells):
        stats['short_cells'] += 1
        return default
    try:
        return int(cells[i])
    except ValueError:
        stats['bad_numbers'] += 1
        return default


class Table(object):
    def __init__(self, cfg):
        st = self.stats = collections.Counter()
        d = os.path.join(cfg, 'ActionSet')
        self.sets = collections.OrderedDict()
        for r in _rows(os.path.join(d, 'ActionSet.txt')):
            s, a, l = _int(r, 1, -1, st), _int(r, 2, -1, st), _int(r, 3, -1, st)
            if s < 0 or a < 0:
                continue
            lst = self.sets.setdefault(s, [])
            if any(x[0] == a for x in lst):
                st['duplicate_actions'] += 1
            lst.append((a, l))
            st['actions'] += 1
        rows = _rows(os.path.join(d, 'ActionSetLine.txt'))
        ncols = max(len(r) for r in rows[:16])
        self.nslots = ncols - 4
        self.lines = []
        for i, r in enumerate(rows):
            if _int(r, 0, i, st) != i:
                st['line_id_mismatch'] += 1
            slots = [_int(r, 1 + s, 0, st) for s in range(self.nslots)]
            extra = [_int(r, 1 + self.nslots, 0, st), _int(r, 2 + self.nslots, -1, st), _int(r, 3 + self.nslots, -1, st)]
            if len(r) > ncols:
                st['extra_cells'] += 1
            self.lines.append((slots, extra))
        self.names = []
        for r in _rows(os.path.join(d, 'ActionSetKV.txt')):
            i = _int(r, 0, -1, st)
            if i < 0:
                continue
            while len(self.names) <= i:
                self.names.append(b'')
            self.names[i] = r[1] if len(r) > 1 else b''
        # CYS-CY (cs2-world): the slot map follows the table itself; 16 slots = CY 3.71 (shared slot 13, sickle 15).
        self.cy = self.nslots >= CY_SLOTS
        self.player_slots = [s for s in (CY_PLAYER_SLOTS if self.cy else GL_PLAYER_SLOTS) if s < self.nslots]
        self.shared_slot = CY_SHARED_SLOT if self.cy else GL_SHARED_SLOT
        st['sets'] = len(self.sets)
        st['lines'] = len(self.lines)
        st['slots'] = self.nslots
        st['names'] = len(self.names)
        st['empty_names'] = sum(1 for n in self.names if n == b'')
        for s, lst in self.sets.items():
            for a, l in lst:
                if l < 0 or l >= len(self.lines):
                    st['dangling_lines'] += 1
        for slots, _e in self.lines:
            for v in slots:
                if v < 0 or v >= len(self.names):
                    st['dangling_names'] += 1
        self.files = {}
        for r in _rows(os.path.join(cfg, 'ActionSetFile.txt')):
            if len(r) >= 2:
                self.files[int(r[0])] = r[1]
        self.models = collections.OrderedDict()   # model id -> (name bytes, action-set file id)
        # CYS-CY: CharModelEx column 20 is m_nActionSetFileID in CY 3.71 (21 columns, Registry/abi/dbc_struct_columns_cy.tsv);
        # client_GL keeps it in column 9.
        model_rows = _rows(os.path.join(cfg, 'CharModelEx.txt'))
        self.model_set_column = 20 if any(len(r) >= 21 for r in model_rows[:16]) else 9
        st['charmodelex_set_column'] = self.model_set_column
        for r in model_rows:
            if len(r) > self.model_set_column:
                self.models[int(r[0])] = (r[1], _int(r, self.model_set_column, -1, st))
        self.mounts = []   # (id, name, model id, riderF, riderM)
        mp = os.path.join(cfg, 'CharMount.txt')
        if os.path.exists(mp):
            for r in _rows(mp):
                if len(r) >= 8:
                    self.mounts.append((int(r[0]), r[1], _int(r, 3, -1, st), _int(r, 6, -1, st), _int(r, 7, -1, st)))

    def find_line(self, set_id, action):
        for a, l in self.sets.get(set_id, ()):
            if a == action:
                return l
        return -1

    def name(self, line, slot):
        if line < 0 or line >= len(self.lines) or slot < 0 or slot >= self.nslots:
            return None
        v = self.lines[line][0][slot]
        return self.names[v] if 0 <= v < len(self.names) else None


# ---------------------------------------------------------------- all.skill
def load_skills(data_root):
    """skill name -> Animation name (GBK bytes). ActionSetKV names may be skills of EffectFolder/all.skill (e.g.
    m01_跑步 -> Animation 跑步 + foot-dust effects); LogicModel::createSkill tries the skill first."""
    import re
    path = os.path.join(data_root, 'EffectFolder', 'all.skill')
    skills = {}
    if not os.path.exists(path):
        return skills
    d = open(path, 'rb').read()
    for m in re.finditer(rb'(?m)^[ \t]*skill[ \t]+(\S+)[ \t]*\r?\n[ \t]*\{(.*?)\r?\n\}', d, re.S):
        name = m.group(1)
        am = re.search(rb'(?m)^[ \t]*Animation[ \t]+(\S+)', m.group(2))
        skills[name] = am.group(1) if am else b''
    return skills


# ---------------------------------------------------------------- model animations
class AnimIndex(object):
    """Animation names available to a model: skeletons linked by its meshes, DefaultSkeleton, <Skeleton> extras."""

    def __init__(self, root):
        self.root = root
        self.skel_cache = {}
        self.mesh_cache = {}

    def skeleton_anims(self, name_bytes):
        k = name_bytes.lower()
        if k in self.skel_cache:
            return self.skel_cache[k]
        rel = self.root.resolve(name_bytes)
        anims = None
        if rel:
            sw = v02_skeleton.walk_skeleton(self.root.read(rel))
            if not sw['err']:
                anims = {a for a, _l in sw['anims']}
        self.skel_cache[k] = anims
        return anims

    def mesh_skeleton(self, name_bytes):
        k = name_bytes.lower()
        if k in self.mesh_cache:
            return self.mesh_cache[k]
        rel = self.root.resolve(name_bytes)
        skel = None
        if rel:
            mw = v01_mesh.walk_mesh(self.root.read(rel))
            if not mw['err']:
                skel = mw['skel'] or None
        self.mesh_cache[k] = skel
        return skel

    def model_anims(self, obj_name):
        """-> (set of animation names or None when the object is missing, notes list)."""
        block = self.root.object_block(obj_name)
        if block is None:
            return None, ['object not in all.obj']
        anims = set()
        notes = []
        for e in tags(block, b'Entity'):
            f = e.get(b'file', b'').strip()
            if not f:
                continue
            skel = self.mesh_skeleton(f)
            if skel:
                a = self.skeleton_anims(skel)
                if a is None:
                    notes.append('skeleton missing: ' + disp(skel))
                else:
                    anims |= a
        for at in tags(block, b'Attribute'):
            if at.get(b'name', b'') == b'DefaultSkeleton' and at.get(b'value', b'').strip():
                a = self.skeleton_anims(at.get(b'value').strip())
                if a is None:
                    notes.append('DefaultSkeleton missing: ' + disp(at.get(b'value')))
                else:
                    anims |= a
        for sk in tags(block, b'Skeleton'):
            s = sk.get(b'skeleton', b'').strip()
            declared = set(sk.get(b'animations', b'').split())
            if not s:
                continue
            a = self.skeleton_anims(s)
            if a is None:
                notes.append('extra skeleton missing: ' + disp(s))
                continue
            anims |= (a & declared) if declared else a
            miss = declared - a
            if miss:
                notes.append('declared but absent in %s: %s' % (disp(s), ','.join(disp(m) for m in sorted(miss)[:4])))
        return anims, notes


def check_model(table, anim_index, model_id, obj_name, set_id, slots, label='', skills=None):
    skills = skills or {}
    anims, notes = anim_index.model_anims(obj_name)
    res = {'model': model_id, 'object': disp(obj_name), 'set': set_id, 'file': disp(table.files.get(set_id, b'')),
           'label': label, 'actions': len(table.sets.get(set_id, ())), 'resolved': 0, 'distinct': 0,
           'empty': 0, 'via_skill': 0, 'missing': 0, 'missing_names': [], 'base': {}, 'notes': notes,
           'object_found': anims is not None}
    if anims is None:
        return res

    def present(n):
        """Name found in the skeletons, or a skill of all.skill whose Animation is (B: createSkill tries it first)."""
        if n in anims:
            return True
        if n in skills:
            return skills[n] in anims
        return False

    distinct = set()
    missing = set()
    for a, l in table.sets.get(set_id, ()):
        for s in slots:
            n = table.name(l, s)
            if n is None:
                continue
            res['resolved'] += 1
            if n == b'':
                res['empty'] += 1
                continue
            if n not in distinct and n in skills:
                res['via_skill'] += 1
            distinct.add(n)
            if not present(n):
                missing.add(n)
    for a, tag in BASE_ACTIONS:
        l = table.find_line(set_id, a)
        n0 = table.name(l, slots[0]) if l >= 0 else None
        n9 = table.name(l, table.shared_slot) if l >= 0 else None
        res['base'][tag] = {'line': l, 'slot': slots[0], 'first': disp(n0) if n0 is not None else None,
                            'shared_slot': table.shared_slot, 'shared': disp(n9) if n9 is not None else None,
                            'skill_anim': disp(skills[n0]) if n0 in skills else None,
                            'ok': present(n0) if n0 else None}
    res['distinct'] = len(distinct)
    res['missing'] = len(missing)
    res['missing_names'] = sorted(disp(m) for m in missing)
    return res


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--data', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--all', action='store_true', help='check every CharModelEx row with a set')
    ap.add_argument('--model', action='append', default=[], help='extra object name(s) to check')
    ap.add_argument('--limit', type=int, default=0, help='with --all: stop after N models (debug)')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    cfg = os.path.join(a.data, 'ConfigFolder')
    table = Table(cfg)
    st = table.stats
    lines = ['data: %s' % a.data]
    lines.append('tables: %d sets, %d actions, %d lines x %d slots, %d names (%d empty)' % (
        st['sets'], st['actions'], st['lines'], st['slots'], st['names'], st['empty_names']))
    lines.append('row-id mismatch %d, short cells %d, extra cells %d, bad numbers %d, dangling lines %d, '
                 'dangling names %d, duplicate actions %d' % (st['line_id_mismatch'], st['short_cells'],
                 st['extra_cells'], st['bad_numbers'], st['dangling_lines'], st['dangling_names'], st['duplicate_actions']))
    files_no_rows = [i for i in table.files if i not in table.sets]
    models_no_set = sum(1 for _n, s in table.models.values() if s < 0)
    models_bad = [(i, disp(n), s) for i, (n, s) in table.models.items() if s >= 0 and s not in table.sets]
    lines.append('ActionSetFile.txt: %d files, %d without rows' % (len(table.files), len(files_no_rows)))
    lines.append('CharModelEx.txt: %d models, %d with set -1, %d whose set has no rows' % (
        len(table.models), models_no_set, len(models_bad)))
    hard = st['dangling_lines'] or st['dangling_names'] or st['bad_numbers'] or not (table.sets and table.lines and table.names)

    root = DataRoot(a.data)
    idx = AnimIndex(root)
    skills = load_skills(a.data)
    lines.append('all.skill: %d skills (%d with an Animation line)' % (len(skills), sum(1 for v in skills.values() if v)))
    todo = []   # (model id, object bytes, set id, slots, label)
    by_name = {n.lower(): (i, s) for i, (n, s) in table.models.items()}
    player_ids = [i for i, (n, s) in table.models.items() if n in (b'\xc4\xd0\xd6\xf7\xbd\xc7.obj', b'\xc5\xae\xd6\xf7\xbd\xc7.obj')]
    if a.all:
        for i, (n, s) in table.models.items():
            if s >= 0 and s in table.sets:
                todo.append((i, n, s, table.player_slots if i in player_ids else [table.shared_slot], 'all'))
            if a.limit and len(todo) >= a.limit:
                break
    else:
        for i in player_ids:
            n, s = table.models[i]
            todo.append((i, n, s, table.player_slots, 'player'))
        for mid, mname, model, rf, rm in table.mounts[:6]:
            if model in table.models:
                n, s = table.models[model]
                todo.append((model, n, s, [table.shared_slot], 'mount ' + disp(mname)))
            for pid in player_ids:
                n, s = table.models[pid]
                seat = rm if n.startswith(b'\xc4\xd0') else rf   # 男 -> male seat
                if seat in table.sets:
                    todo.append((pid, n, seat, table.player_slots, 'rider on ' + disp(mname)))
        for i, (n, s) in table.models.items():
            if s == 501 and disp(n) == '獠牙雪人.obj':
                todo.append((i, n, s, [table.shared_slot], 'monster'))
    for m in a.model:
        k = m.encode('gbk').lower()
        if k in by_name:
            i, s = by_name[k]
            todo.append((i, table.models[i][0], s, table.player_slots if i in player_ids else [table.shared_slot], 'arg'))
        else:
            lines.append('--model %s: not in CharModelEx.txt' % m)

    results = []
    missing_by_name = collections.defaultdict(set)
    for k, (i, n, s, slots, label) in enumerate(todo):
        r = check_model(table, idx, i, n, s, slots, label, skills)
        results.append(r)
        for mn in r['missing_names']:
            missing_by_name[mn].add(s)
        if a.all and (k + 1) % 500 == 0:
            print('  %d / %d models' % (k + 1, len(todo)), flush=True)
    n_ok = sum(1 for r in results if r['object_found'] and r['missing'] == 0)
    n_found = sum(1 for r in results if r['object_found'])
    lines.append('models checked %d (%d objects found, %d with every resolved animation present, %d distinct missing names)' % (
        len(results), n_found, n_ok, len(missing_by_name)))
    for r in results:
        if r['label'] in ('player', 'monster') or (r['label'].startswith('mount') and r['model'] in (1010, 1011)):
            shared_only = r['label'] == 'monster' or r['label'].startswith('mount')
            base = ', '.join('%s=%s%s' % (t, v['shared'] if shared_only else v['first'],
                                          '' if v['ok'] in (True, None) else '(MISSING)')
                             for t, v in r['base'].items() if t in ('idle', 'idle_ex0', 'run', 'sit_idle', 'die', 'be_hit'))
            lines.append('  %s model %d %s set %d (%s): resolved %d, distinct %d (%d via all.skill), missing %d; %s' % (
                r['label'], r['model'], r['object'], r['set'], r['file'], r['resolved'], r['distinct'], r['via_skill'], r['missing'], base))

    with open(os.path.join(a.out, 'tables.txt'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    with open(os.path.join(a.out, 'models.tsv'), 'w', encoding='utf-8') as f:
        f.write('model\tobject\tset\tfile\tlabel\tactions\tresolved\tdistinct\tempty\tvia_skill\tmissing\tobject_found\tidle_s0\trun_s0\tidle_s9\tmissing_names\tnotes\n')
        for r in results:
            f.write('%d\t%s\t%d\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%s\t%s\t%s\t%s\n' % (
                r['model'], r['object'], r['set'], r['file'], r['label'], r['actions'], r['resolved'], r['distinct'],
                r['empty'], r['via_skill'], r['missing'], int(r['object_found']),
                (r['base'].get('idle') or {}).get('first') or (r['base'].get('idle') or {}).get('shared') or '',
                (r['base'].get('run') or {}).get('first') or (r['base'].get('run') or {}).get('shared') or '',
                (r['base'].get('idle') or {}).get('shared') or '',
                '|'.join(r['missing_names'][:20]), ' ; '.join(r['notes'][:4])))
    with open(os.path.join(a.out, 'missing_names.tsv'), 'w', encoding='utf-8') as f:
        f.write('name\tsets\tset_ids\n')
        for mn, sets in sorted(missing_by_name.items(), key=lambda kv: (-len(kv[1]), kv[0])):
            f.write('%s\t%d\t%s\n' % (mn, len(sets), ','.join(str(s) for s in sorted(sets)[:12])))
    summary = {'data': a.data, 'stats': dict(st), 'files': len(table.files), 'files_without_rows': files_no_rows[:20],
               'models': len(table.models), 'models_no_set': models_no_set, 'models_bad_set': models_bad[:20],
               'checked': len(results), 'objects_found': n_found, 'models_all_present': n_ok,
               'distinct_missing_names': len(missing_by_name), 'hard_error': bool(hard),
               'results': results}
    with open(os.path.join(a.out, 'actionset_check.json'), 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)
    print('\n'.join(lines))
    print('result: %s' % ('ERROR' if hard else 'OK'))
    return 1 if hard else 0


if __name__ == '__main__':
    sys.exit(main())
