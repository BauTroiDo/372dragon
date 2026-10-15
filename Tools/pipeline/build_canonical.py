# -*- coding: utf-8 -*-
"""build_canonical.py - CY-Source data track D1: the Canonical data root Assets\\Canonical\\Data.

Canonical = S1 (C:\\TLBB\\085\\client_GL\\Data, read-only) mirrored with its exact on-disk names (GBK shown as cp1252)
and folder layout, backup files skipped, + ordered overlays. Overlay of this tool: the automatic variant selection
Registry\\selections\\<selection>.yaml - every object picked from S2 (DataCY) or S3 (CYHJ) gets that source's full
closure (Tools\\pipeline\\canon_lib.py: closure, same/new/replace/rename decisions, byte-level all.* edits).

Modes (one of):
  --check    plan only: what the mirror would copy, the overlay plan, renames; nothing written into Canonical
             (plan.json / plan.txt go to Build\\Logs\\<log>)
  --apply    mirror (changed files only, threads) -> overlay files -> all.* byte edits -> manifests -> batch record
             Registry\\batches\\<batch>.yaml -> validators V01-V06/V13 on everything touched
  --verify   Canonical == S1 mirror + overlay (size+mtime, --deep: sha256 of every file), all.* == S1 + edits,
             no unexpected files, validators; exit code 1 on any difference or validator error
  --revert   undo the overlay of --batch: overwritten files restored from S1, added files moved to
             Assets\\Canonical\\_quarantine\\<batch>, all.* restored from S1 (Canonical is a copy: nothing is lost)
  --render   TlbbViewer evidence: every switched object from Canonical and from client_GL (--ff), side by side
Options: --selection FILE  --batch NAME  --log-dir DIR  --jobs N  --deep  --prune  --no-validate  --render-jobs N

Run (PowerShell):
  $env:PYTHONUTF8="1"; & "C:\\Program Files\\Python313\\python.exe" C:\\TLBB\\085\\CY-Source\\Tools\\pipeline\\build_canonical.py --apply
Writes only: Assets\\Canonical\\**, Registry\\batches\\<batch>.yaml, Build\\Logs\\<log>\\**.
"""
import argparse
import collections
import concurrent.futures as cf
import datetime
import hashlib
import html
import json
import os
import re
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import canon_lib as CL  # noqa: E402
from validators import common as VC  # noqa: E402
from validators import run as VR  # noqa: E402

VERSION = '1.0 (2026-09-12)'
CYS = CL.CYS
S1_ROOT = r'C:\TLBB\085\client_GL\Data'
CANON = os.path.join(CYS, 'Assets', 'Canonical')
DATA = os.path.join(CANON, 'Data')
MAN_DIR = os.path.join(CANON, '_manifest')
QUAR_DIR = os.path.join(CANON, '_quarantine')
SEL_DEFAULT = os.path.join(CYS, 'Registry', 'selections', '2026-09-12-variants.yaml')
BATCH_DEFAULT = '2026-09-12-variants-canonical'
BATCH_DIR = os.path.join(CYS, 'Registry', 'batches')
LOG_DEFAULT = os.path.join(CYS, 'Build', 'Logs', '2026-09-12-canonical')
VIEWER = os.path.join(CYS, 'Build', 'cmake', 'viewer-x64', 'bin', 'TlbbViewer.exe')
TMP_SUFFIX = '.cys-tmp'
LOGF = None


def log(*a):
    s = time.strftime('%H:%M:%S ') + ' '.join(str(x) for x in a)
    print(s, flush=True)
    if LOGF:
        LOGF.write(s + '\n')
        LOGF.flush()


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        while True:
            b = f.read(8 << 20)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def rel_cys(p):
    return os.path.relpath(p, CYS).replace('\\', '/')


def below_normal_priority():
    if os.name == 'nt':
        try:
            import ctypes
            k = ctypes.windll.kernel32
            k.SetPriorityClass(k.GetCurrentProcess(), 0x00004000)
        except Exception:
            pass


# ------------------------------------------------------------------ inputs
_SEL = re.compile(r'^("(?:[^"\\]|\\.)*")\s*:\s*(S\d)\s*(?:#\s*(.*))?$')


def load_selection(path):
    picks = []
    with open(path, encoding='utf-8') as f:
        for ln in f:
            m = _SEL.match(ln.strip())
            if m:
                picks.append((json.loads(m.group(1)), m.group(2), (m.group(3) or '').strip()))
    return picks


def walk_s1(root):
    files, skipped = [], []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames.sort()
        rd = os.path.relpath(dirpath, root)
        for fn in sorted(filenames):
            rel = fn if rd == '.' else os.path.join(rd, fn)
            st = os.stat(os.path.join(dirpath, fn))
            (skipped if CL.is_backup(fn) else files).append((rel, st.st_size, st.st_mtime_ns))
    return files, skipped


def load_manifest(path):
    out = {}
    try:
        with open(path, encoding='utf-8-sig') as f:
            next(f)
            for ln in f:
                p = ln.rstrip('\n').split('\t')
                if len(p) >= 4:
                    out[p[0]] = (int(p[1]), int(p[2]), p[3])
    except (OSError, StopIteration, ValueError):
        pass
    return out


def write_tsv(path, header, rows):
    tmp = path + TMP_SUFFIX
    with open(tmp, 'w', encoding='utf-8-sig', newline='\n', errors='surrogateescape') as f:
        f.write('\t'.join(header) + '\n')
        for r in rows:
            f.write('\t'.join(str(x) for x in r) + '\n')
    os.replace(tmp, path)


# ------------------------------------------------------------------ plan
class Build:
    def __init__(self, args):
        self.args = args
        self.t = {}

    def plan(self):
        a = self.args
        t0 = time.time()
        self.picks = load_selection(a.selection)
        self.switch = [(n, S, r) for n, S, r in self.picks if S in ('S2', 'S3')]
        log('selection %s: %d objects, %d switched to S2/S3' % (rel_cys(a.selection), len(self.picks), len(self.switch)))
        self.s1_files, self.skipped = walk_s1(S1_ROOT)
        log('S1 walk: %d files kept (%.2f GB), %d backup files skipped (%.3f GB)' % (
            len(self.s1_files), sum(x[1] for x in self.s1_files) / 1e9, len(self.skipped),
            sum(x[1] for x in self.skipped) / 1e9))
        self.t['walk'] = round(time.time() - t0, 1)
        t = time.time()
        os.makedirs(MAN_DIR, exist_ok=True)
        binrefs = CL.scan_binrefs(S1_ROOT, self.s1_files, os.path.join(MAN_DIR, 'binrefs_S1.pkl'), a.scan_jobs, log)
        self.base = VC.DataRoot(S1_ROOT)
        self.refdb = CL.RefDB(self.base, self.s1_files, binrefs, log)
        self.t['refdb'] = round(time.time() - t, 1)
        t = time.time()
        needed = sorted({S for _n, S, _r in self.switch})
        self.sources = {S: CL.SourceView(S) for S in needed}
        log('sources loaded: %s (%.1fs)' % (', '.join(needed), time.time() - t))
        t = time.time()
        pl = CL.Planner(self.base, self.refdb, self.sources, log)
        for name, S, reason in self.switch:
            pl.add_switched(name.encode('gbk'), S, reason)
        pl.decide()
        self.s1_scripts = {k: self.base.script(k) for k in CL.SCRIPT_KINDS}
        self.out = pl.emit(self.s1_scripts)
        self.pl = pl
        self.t['plan'] = round(time.time() - t, 1)
        st = collections.Counter('%s:%s' % (it.kind, it.status) for it in pl.order if not it.switched)
        log('plan: %d switched objects (%s), %d closure items %s, %d rounds, %d problems (%.1fs)' % (
            len(pl.switched), dict(collections.Counter(it.status for it in pl.switched)), len(pl.order) - len(pl.switched),
            dict(sorted(st.items())), pl.rounds, len(pl.problems), time.time() - t))
        self.owned = {w['rel'].lower() for w in self.out['files'] if w['item'].status == 'replace'}
        self.added = {w['rel'].lower() for w in self.out['files'] if w['item'].status in ('new', 'rename')}
        self.scripts = {k: CL.SCRIPT_REL[k] for k, eds in self.out['edits'].items() if eds}
        self.owned |= {v.lower() for v in self.scripts.values()}
        s1_lower = {rel.lower() for rel, _s, _m in self.s1_files}
        clash = sorted(r for r in self.added if r in s1_lower)
        if clash:
            raise CL.PlanError('added files collide with S1 paths: %s' % clash[:5])

    # -------------------------------------------------------------- mirror
    def mirror_todo(self):
        todo, keep = [], {}
        prev = load_manifest(os.path.join(MAN_DIR, 'mirror.tsv'))
        for rel, size, mt in self.s1_files:
            if rel.lower() in self.owned:
                continue
            dst = os.path.join(DATA, rel)
            try:
                st = os.stat(dst)
            except FileNotFoundError:
                st = None
            if st is not None and st.st_size == size and st.st_mtime_ns == mt:
                p = prev.get(rel)
                keep[rel] = (size, mt, p[2] if p and p[0] == size and p[1] == mt else '')
            else:
                todo.append((rel, size, mt))
        return todo, keep

    def mirror(self):
        t = time.time()
        todo, keep = self.mirror_todo()
        nbytes = sum(x[1] for x in todo)
        log('mirror: %d files to copy (%.2f GB), %d up to date' % (len(todo), nbytes / 1e9, len(keep)))

        def copy_one(item):
            rel, size, mt = item
            src = os.path.join(S1_ROOT, rel)
            dst = os.path.join(DATA, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            tmp = dst + TMP_SUFFIX
            h = hashlib.sha256()
            with open(src, 'rb') as fi, open(tmp, 'wb') as fo:
                while True:
                    b = fi.read(8 << 20)
                    if not b:
                        break
                    h.update(b)
                    fo.write(b)
            os.utime(tmp, ns=(mt, mt))
            os.replace(tmp, dst)
            return rel, size, mt, h.hexdigest()

        def hash_one(rel):
            return rel, sha256_file(os.path.join(DATA, rel))
        done = 0
        last = time.time()
        with cf.ThreadPoolExecutor(max_workers=self.args.jobs) as ex:
            for rel, size, mt, sha in ex.map(copy_one, todo):
                keep[rel] = (size, mt, sha)
                done += 1
                if time.time() - last > 15:
                    last = time.time()
                    log('  mirror %d/%d files' % (done, len(todo)))
            missing = [rel for rel, v in keep.items() if not v[2]]
            if missing:
                log('mirror: hashing %d files without a manifest hash' % len(missing))
                for rel, sha in ex.map(hash_one, missing):
                    size, mt, _ = keep[rel]
                    keep[rel] = (size, mt, sha)
        rows = sorted((rel, v[0], v[1], v[2]) for rel, v in keep.items())
        write_tsv(os.path.join(MAN_DIR, 'mirror.tsv'), ['relpath', 'size', 'mtime_ns', 'sha256'], rows)
        write_tsv(os.path.join(MAN_DIR, 'skipped_backups.tsv'), ['relpath', 'size', 'mtime_ns'],
                  sorted(self.skipped))
        self.mirror_rows = rows
        self.t['mirror'] = round(time.time() - t, 1)
        self.mirror_copied = (len(todo), nbytes)
        log('mirror done: %d copied (%.2f GB) in %.1fs' % (len(todo), nbytes / 1e9, time.time() - t))

    # -------------------------------------------------------------- overlay
    def write_file(self, rel, data):
        dst = os.path.join(DATA, rel)
        if os.path.exists(dst):
            with open(dst, 'rb') as f:
                if f.read() == data:
                    return False
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        tmp = dst + TMP_SUFFIX
        with open(tmp, 'wb') as f:
            f.write(data)
        os.replace(tmp, dst)
        return True

    def overlay(self):
        t = time.time()
        n = 0
        for w in self.out['files']:
            n += self.write_file(w['rel'], w['data'])
        self.script_bytes = {}
        for kind, eds in self.out['edits'].items():
            if not eds:
                continue
            new = CL.apply_edits(self.s1_scripts[kind], eds)
            self.script_bytes[kind] = new
            n += self.write_file(CL.SCRIPT_REL[kind], new)
        self.t['overlay'] = round(time.time() - t, 1)
        log('overlay: %d files, %d script files; %d written now (%.1fs)' % (
            len(self.out['files']), len(self.script_bytes), n, time.time() - t))

    def extras(self):
        """Canonical files that are neither S1 mirror nor overlay output."""
        s1 = {rel.lower() for rel, _s, _m in self.s1_files}
        out = []
        for dirpath, _dn, filenames in os.walk(DATA):
            rd = os.path.relpath(dirpath, DATA)
            for fn in filenames:
                rel = fn if rd == '.' else os.path.join(rd, fn)
                low = rel.lower()
                if low not in s1 and low not in self.added:
                    out.append(rel)
        return sorted(out)

    # -------------------------------------------------------------- records
    def touched(self):
        pl = self.pl
        objs = [it for it in pl.order if it.kind == 'obj']
        tj = {'files': [w['rel'] for w in self.out['files']],
              'objects': [{'hex': it.final_name.hex(), 'name': CL.disp(it.final_name)} for it in objs],
              'scripts': []}
        for kind in CL.DEF_KINDS:
            key = {'material': 'materials', 'effect': 'effects', 'particle': 'particles'}[kind]
            tj[key] = [{'hex': it.final_name.hex(), 'name': CL.disp(it.final_name)} for it in pl.order
                       if it.kind == kind and it.status in ('new', 'rename', 'replace')]
        for kind, eds in self.out['edits'].items():
            if eds:
                tj['scripts'].append({'file': CL.SCRIPT_REL[kind], 'edits': [self.edit_json(e) for e in eds]})
        return tj

    @staticmethod
    def edit_json(e):
        return {k: v for k, v in e.items() if k not in ('bytes', 'item')}

    def plan_json(self):
        pl = self.pl
        items = []
        for it in pl.order:
            items.append({'kind': it.kind, 'name': CL.disp(it.name), 'final_name': CL.disp(it.final_name),
                          'src': it.src, 'src_rel': it.src_rel, 'status': it.status, 'switched': it.switched,
                          'target': it.target_rel, 'rename_reason': it.rename_reason, 'notes': it.notes,
                          'trimmed': it.trimmed, 'sha256': CL.sha256(it.data),
                          'deps': ['%s:%s' % (r, CL.disp(d.final_name)) for r, _x, d in it.deps if d is not None]})
        return {'tool': 'build_canonical.py ' + VERSION, 'selection': rel_cys(self.args.selection),
                'switched': len(pl.switched), 'problems': pl.problems, 'rounds': pl.rounds, 'items': items,
                'edits': {k: [self.edit_json(e) for e in v] for k, v in self.out['edits'].items()},
                'mirror_owned': sorted(self.owned), 'added': sorted(self.added)}

    def plan_text(self):
        pl = self.pl
        L = ['build_canonical.py %s - plan for %s' % (VERSION, rel_cys(self.args.selection)), '']
        for it in sorted(pl.switched, key=lambda i: i.name):
            L.append('%s  <- %s  [%s]  %s' % (CL.disp(it.name), it.src, it.status, it.reason))
            for d in pl.closure_of(it):
                L.append('    %-9s %-40s %-8s %s%s' % (d.kind, CL.disp(d.name), d.status,
                                                     ('-> ' + CL.disp(d.final_name) + ' ') if d.final_name != d.name else '',
                                                     d.target_rel or ''))
        L.append('')
        L.append('renames:')
        for it in pl.order:
            if it.status == 'rename':
                L.append('  %s %s -> %s: %s' % (it.kind, CL.disp(it.name), CL.disp(it.final_name), it.rename_reason))
        L.append('')
        L.append('script edits:')
        for kind, eds in self.out['edits'].items():
            for e in eds:
                L.append('  %-8s %-7s %s @%d..%d (%d bytes)' % (kind, e['op'], e['name'], e['s1_start'], e['s1_end'],
                                                             e['new_len']))
        L.append('')
        L.append('problems: %d' % len(pl.problems))
        for o, m in pl.problems:
            L.append('  %s: %s' % (o, m))
        return '\n'.join(L) + '\n'

    def reverse_deps(self):
        rev = collections.defaultdict(list)
        for it in self.pl.order:
            for role, _x, d in it.deps:
                if d is not None:
                    rev[id(d)].append((role, it))
        return rev

    def batch_record(self, status, vsum=None):
        pl = self.pl
        base = self.base
        rev = self.reverse_deps()
        sel_sha = sha256_file(self.args.selection)
        objects = []
        for it in sorted(pl.switched, key=lambda i: i.name):
            info = pl.base_info(it)
            clos = []
            for d in pl.closure_of(it):
                rec = {'kind': d.kind, 'name': CL.disp(d.name), 'status': d.status}
                if d.final_name != d.name:
                    rec['final_name'] = CL.disp(d.final_name)
                if d.target_rel:
                    rec['target'] = d.target_rel.replace('\\', '/')
                if d.src_rel:
                    rec['source'] = '%s:%s' % (d.src, d.src_rel.replace('\\', '/'))
                clos.append(rec)
            objects.append({'name': CL.disp(it.name), 'source': it.src, 'reason': it.reason,
                            'all_obj': {'same': 'unchanged (identical block)', 'replace': 'block replaced',
                                        'new': 'block inserted'}[it.status],
                            'base_occurrences': info['count'], 'closure': clos})
        files = []
        for w in self.out['files']:
            it = w['item']
            before = None
            bbytes = None
            if it.status == 'replace':
                p = os.path.join(S1_ROOT, w['rel'])
                before = sha256_file(p)
                bbytes = os.path.getsize(p)
            files.append({'path': w['rel'].replace('\\', '/'), 'path_gbk': CL.disp(VC.gbk_name(w['rel'].split('\\')[-1])),
                          'kind': it.kind, 'action': {'replace': 'overwrite', 'new': 'add', 'rename': 'add-renamed'}[
                              it.status], 'source': '%s:%s' % (it.src, it.src_rel.replace('\\', '/')),
                          'sha256_before': before, 'bytes_before': bbytes, 'sha256_after': CL.sha256(w['data']),
                          'bytes_after': len(w['data']), 'padding_trimmed': it.trimmed})
        defs = []
        for kind, eds in self.out['edits'].items():
            for e in eds:
                it = e['item']
                if kind == 'obj':
                    continue
                defs.append({'file': CL.SCRIPT_REL[kind].replace('\\', '/'), 'kind': kind, 'name': e['name'],
                             'action': {'replace': 'replace', 'new': 'add', 'rename': 'add-renamed'}[it.status],
                             'source': it.src, 's1_span': [e['s1_start'], e['s1_end']],
                             'sha256_before': e['old_sha256'] if e['op'] == 'replace' else None,
                             'sha256_after': e['new_sha256'], 'bytes_after': e['new_len']})
        scripts = []
        for kind, eds in self.out['edits'].items():
            if not eds:
                continue
            new = self.script_bytes.get(kind) if hasattr(self, 'script_bytes') else CL.apply_edits(
                self.s1_scripts[kind], eds)
            scripts.append({'path': CL.SCRIPT_REL[kind].replace('\\', '/'), 'edits': len(eds),
                            'replaced_blocks': sum(1 for e in eds if e['op'] == 'replace'),
                            'inserted_blocks': sum(1 for e in eds if e['op'] == 'insert'),
                            'sha256_s1': CL.sha256(self.s1_scripts[kind]), 'bytes_s1': len(self.s1_scripts[kind]),
                            'sha256_canonical': CL.sha256(new), 'bytes_canonical': len(new),
                            'edit_list': [{'op': e['op'], 'name': e['name'], 's1_span': [e['s1_start'], e['s1_end']],
                                           'old_sha256': e['old_sha256'], 'new_sha256': e['new_sha256'],
                                           'new_len': e['new_len']} for e in eds]})
        renames = []
        for it in pl.order:
            if it.status != 'rename':
                continue
            rw = []
            for role, parent in rev.get(id(it), []):
                rw.append('%s %s (%s)' % (parent.kind, CL.disp(parent.final_name), role))
            renames.append({'kind': it.kind, 'from': CL.disp(it.name), 'to': CL.disp(it.final_name), 'source': it.src,
                            'reason': it.rename_reason, 'references_rewritten_in': sorted(set(rw))})
        summ = collections.Counter('%s %s' % (it.kind, it.status) for it in pl.order if not it.switched)
        rec = collections.OrderedDict()
        rec['schema'] = 1
        rec['batch'] = self.args.batch
        rec['status'] = status
        rec['created'] = datetime.datetime.now().isoformat(timespec='seconds')
        rec['tool'] = 'Tools/pipeline/build_canonical.py %s (+ canon_lib.py)' % VERSION
        rec['selection'] = {'file': rel_cys(self.args.selection), 'sha256': sel_sha, 'objects': len(self.picks),
                            'switched': len(self.switch),
                            'rule': 'Tools/pipeline/auto_select.py (consensus >= 2 sources, then quality score)'}
        rec['canonical_root'] = DATA.replace('\\', '/')
        rec['base'] = {'source': 'S1', 'root': S1_ROOT.replace('\\', '/'),
                       'mirror': 'every file except %d backup files (Assets/Canonical/_manifest/skipped_backups.tsv)'
                                 % len(self.skipped)}
        rec['sources'] = {S: v.root.replace('\\', '/') for S, v in self.sources.items()}
        rec['policy'] = [
            'files and definitions compared by content (files: sha256 of the format-length content; blocks: '
            'whitespace-normalised hash)',
            'overwrite / replace in place only when the base has one copy and every reference to the name in the whole '
            'base data lies in definitions this batch replaces; otherwise a new name <name>_hj (S3) / _cy (S2) and '
            'the references inside the closure are rewritten at byte level',
            'all.obj: first occurrence of a duplicated object name replaced (WXLogicModelManager keeps the first); '
            'new objects inserted before </AllObjects>; new definitions appended; files never re-encoded',
            'source files copied at their format length (Assets/Staging/index fmt_len / sha256_content)',
            'ModelFolder/filedep.xml (preload index generated from the scripts) is not a use: it is ignored by the '
            'exclusivity scan and not edited, so new / renamed names are simply not preloaded',
            'a base mesh / skeleton that nothing outside the batch uses any more (orphaned, e.g. the S1 placeholder '
            'sword of boss_2026武神坛耶律浚) does not block an in-place overwrite through its binary links']
        rec['summary'] = dict(sorted(summ.items()))
        rec['objects'] = objects
        rec['files'] = files
        rec['definitions'] = defs
        rec['scripts'] = scripts
        rec['renames'] = renames
        rec['problems'] = ['%s: %s' % p for p in pl.problems]
        if vsum is not None:
            cat = os.path.join(self.args.log_dir, 'objects_all.json')
            if os.path.exists(cat):
                with open(cat, encoding='utf-8') as f:
                    cj = json.load(f)
                vsum = dict(vsum)
                vsum['catalogue_regression'] = {
                    'check': 'Tests/validators run.py --all-objects: V03 on every all.obj object, Canonical vs S1',
                    'objects': cj.get('objects_checked'), 'objects_in_s1': cj.get('objects_in_base'),
                    'with_errors': cj.get('objects_with_errors'), 'with_errors_in_s1': cj.get('objects_with_errors_in_base'),
                    'regressions': len(cj.get('regressions', {})), 'report': rel_cys(cat)}
            rec['validators'] = vsum
        rec['revert'] = {
            'command': 'python Tools/pipeline/build_canonical.py --revert --batch %s' % self.args.batch,
            'manual': ['copy every files[action=overwrite] path back from the S1 root (sha256_before)',
                       'move every files[action=add|add-renamed] path out of Canonical (the tool moves them to '
                       'Assets/Canonical/_quarantine/%s)' % self.args.batch,
                       'copy ModelFolder/all.obj, MaterialFolder/all.material, EffectFolder/all.effect, '
                       'EffectFolder/all.particle back from S1 (their bytes outside scripts[].edit_list are S1 bytes)'],
            'state_file': rel_cys(os.path.join(MAN_DIR, 'overlay-%s.json' % self.args.batch))}
        return rec

    def overlay_state(self):
        return {'batch': self.args.batch, 'written': datetime.datetime.now().isoformat(timespec='seconds'),
                'owned': sorted(w['rel'] for w in self.out['files'] if w['item'].status == 'replace'),
                'added': sorted(w['rel'] for w in self.out['files'] if w['item'].status in ('new', 'rename')),
                'scripts': sorted(self.scripts.values()),
                'files_sha256': {w['rel']: CL.sha256(w['data']) for w in self.out['files']},
                'scripts_sha256': {CL.SCRIPT_REL[k]: CL.sha256(v) for k, v in getattr(self, 'script_bytes', {}).items()}}

    # -------------------------------------------------------------- validators
    def validate(self):
        t = time.time()
        tj = self.touched()
        os.makedirs(self.args.log_dir, exist_ok=True)
        with open(os.path.join(self.args.log_dir, 'touched.json'), 'w', encoding='utf-8') as f:
            json.dump(tj, f, ensure_ascii=False, indent=1)
        rep, stats = VR.run_all(DATA, tj, base_root=S1_ROOT)
        hdr = 'validators on the batch %s (data root %s, base %s)' % (self.args.batch, DATA, S1_ROOT)
        VR.write_outputs(rep, stats, self.args.log_dir, header=hdr)
        self.t['validate'] = round(time.time() - t, 1)
        vs = {'errors': rep.count(VC.ERROR), 'warnings': rep.count(VC.WARN), 'checked': stats,
              'by_validator': {k: dict(v) for k, v in rep.summary().items()},
              'report': rel_cys(os.path.join(self.args.log_dir, 'validate.txt'))}
        log('validators: %d errors, %d warnings, checked %s (%.1fs)' % (vs['errors'], vs['warnings'], stats,
                                                                      time.time() - t))
        for r in rep.items:
            if r['level'] == VC.ERROR:
                log('  ERROR [%s] %s: %s' % (r['vid'], r['subject'], r['message']))
        return vs, rep


# ------------------------------------------------------------------ YAML (JSON-style scalars are valid YAML 1.2)
def _scalar(v):
    if v is None:
        return 'null'
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, dict):
        return '{}'
    if isinstance(v, (list, tuple)):
        return '[' + ', '.join(_scalar(x) for x in v) + ']' if all(not isinstance(x, (dict, list)) for x in v) else '[]'
    return json.dumps(str(v), ensure_ascii=False)


def yaml_lines(obj, indent=0):
    sp = '  ' * indent
    out = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(v, dict) and v:
                out.append('%s%s:' % (sp, k))
                out.extend(yaml_lines(v, indent + 1))
            elif isinstance(v, list) and v and any(isinstance(x, (dict, list)) for x in v):
                out.append('%s%s:' % (sp, k))
                out.extend(yaml_lines(v, indent + 1))
            elif isinstance(v, list) and (len(v) > 6 or any(isinstance(x, str) and len(x) > 40 for x in v)):
                out.append('%s%s:' % (sp, k))
                out.extend('%s  - %s' % (sp, _scalar(x)) for x in v)
            else:
                out.append('%s%s: %s' % (sp, k, _scalar(v)))
    elif isinstance(obj, list):
        for v in obj:
            if isinstance(v, (dict, list)) and v:
                sub = yaml_lines(v, indent + 1)
                out.append('%s- %s' % (sp, sub[0].lstrip()))
                out.extend(sub[1:])
            else:
                out.append('%s- %s' % (sp, _scalar(v)))
    return out


def write_yaml(path, rec, header):
    tmp = path + TMP_SUFFIX
    with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
        for h in header:
            f.write('# ' + h + '\n')
        f.write('\n'.join(yaml_lines(rec)) + '\n')
    os.replace(tmp, path)


# ------------------------------------------------------------------ modes
def do_check(b):
    todo, keep = b.mirror_todo()
    os.makedirs(b.args.log_dir, exist_ok=True)
    with open(os.path.join(b.args.log_dir, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(b.plan_json(), f, ensure_ascii=False, indent=1)
    with open(os.path.join(b.args.log_dir, 'plan.txt'), 'w', encoding='utf-8-sig', newline='\r\n') as f:
        f.write(b.plan_text())
    log('check: mirror would copy %d files (%.2f GB), %d up to date; overlay writes %d files + %d script files; '
        'plan in %s' % (len(todo), sum(x[1] for x in todo) / 1e9, len(keep), len(b.out['files']),
                        sum(1 for v in b.out['edits'].values() if v), b.args.log_dir))
    return 0


def do_apply(b):
    b.mirror()
    b.overlay()
    extra = b.extras()
    if extra:
        log('WARNING: %d unexpected file(s) in Canonical (not in S1 nor in the overlay), e.g. %s' % (len(extra), extra[:5]))
        if b.args.prune:
            dst_root = os.path.join(QUAR_DIR, 'extras-' + time.strftime('%Y%m%d-%H%M%S'))
            for rel in extra:
                dst = os.path.join(dst_root, rel)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.move(os.path.join(DATA, rel), dst)
            log('  moved to ' + dst_root)
    with open(os.path.join(MAN_DIR, 'overlay-%s.json' % b.args.batch), 'w', encoding='utf-8') as f:
        json.dump(b.overlay_state(), f, ensure_ascii=False, indent=1)
    os.makedirs(b.args.log_dir, exist_ok=True)
    with open(os.path.join(b.args.log_dir, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(b.plan_json(), f, ensure_ascii=False, indent=1)
    with open(os.path.join(b.args.log_dir, 'plan.txt'), 'w', encoding='utf-8-sig', newline='\r\n') as f:
        f.write(b.plan_text())
    vsum, rep = (None, None) if b.args.no_validate else b.validate()
    status = 'applied' if (vsum is None or vsum['errors'] == 0) else 'applied-with-validator-errors'
    rec = b.batch_record(status, vsum)
    os.makedirs(BATCH_DIR, exist_ok=True)
    write_yaml(os.path.join(BATCH_DIR, b.args.batch + '.yaml'), rec,
               ['Batch record written by Tools/pipeline/build_canonical.py - do not edit by hand (re-run the tool).',
                'Canonical overlay of the automatic variant selection; revert: see "revert" at the end.'])
    total = sum(r[1] for r in b.mirror_rows) + sum(len(w['data']) for w in b.out['files'] if w['item'].status != 'replace')
    nfiles = len(b.mirror_rows) + len(b.owned) + len(b.added)
    summary = {'tool': 'build_canonical.py ' + VERSION, 'finished': datetime.datetime.now().isoformat(timespec='seconds'),
               'data_root': DATA, 'base': S1_ROOT, 'files': nfiles, 'bytes_approx': total,
               'mirror_files': len(b.mirror_rows), 'mirror_copied_now': b.mirror_copied[0],
               'skipped_backups': len(b.skipped), 'skipped_backup_bytes': sum(x[1] for x in b.skipped),
               'overlays': [b.args.batch], 'overlay_owned': len(b.owned), 'overlay_added': len(b.added),
               'unexpected_files': len(extra), 'validators': vsum, 'status': status, 'timings_s': b.t}
    with open(os.path.join(MAN_DIR, 'canonical.json'), 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)
    log('apply: %s; Canonical %d files (~%.2f GB); batch record %s' % (
        status, nfiles, total / 1e9, rel_cys(os.path.join(BATCH_DIR, b.args.batch + '.yaml'))))
    return 0 if status == 'applied' else 1


def do_verify(b):
    bad = 0
    todo, keep = b.mirror_todo()
    if todo:
        bad += len(todo)
        log('verify: %d S1 files missing or stale in Canonical, e.g. %s' % (len(todo), [x[0] for x in todo[:5]]))
    if b.args.deep:
        prev = load_manifest(os.path.join(MAN_DIR, 'mirror.tsv'))

        def cmp(item):
            rel = item[0]
            a = sha256_file(os.path.join(S1_ROOT, rel))
            c = sha256_file(os.path.join(DATA, rel))
            return rel, a, c, prev.get(rel, (0, 0, ''))[2]
        with cf.ThreadPoolExecutor(max_workers=b.args.jobs) as ex:
            for rel, a, c, m in ex.map(cmp, [(rel,) for rel in keep]):
                if a != c or (m and m != c):
                    bad += 1
                    log('verify: content differs: ' + rel)
    for w in b.out['files']:
        p = os.path.join(DATA, w['rel'])
        if not os.path.exists(p) or sha256_file(p) != CL.sha256(w['data']):
            bad += 1
            log('verify: overlay file differs: ' + w['rel'])
    for kind, eds in b.out['edits'].items():
        if eds:
            exp = CL.apply_edits(b.s1_scripts[kind], eds)
            with open(os.path.join(DATA, CL.SCRIPT_REL[kind]), 'rb') as f:
                if f.read() != exp:
                    bad += 1
                    log('verify: %s differs from S1 + edits' % CL.SCRIPT_REL[kind])
    extra = b.extras()
    if extra:
        bad += len(extra)
        log('verify: %d unexpected files, e.g. %s' % (len(extra), extra[:5]))
    vsum = None
    if not b.args.no_validate:
        vsum, _rep = b.validate()
        bad += vsum['errors']
    log('verify: %s (%d problem(s))' % ('OK' if not bad else 'FAILED', bad))
    return 0 if not bad else 1


def do_revert(b):
    sp = os.path.join(MAN_DIR, 'overlay-%s.json' % b.args.batch)
    with open(sp, encoding='utf-8') as f:
        st = json.load(f)
    qroot = os.path.join(QUAR_DIR, b.args.batch + '-' + time.strftime('%Y%m%d-%H%M%S'))
    for rel in st['owned'] + st['scripts']:
        src = os.path.join(S1_ROOT, rel)
        dst = os.path.join(DATA, rel)
        shutil.copy2(src, dst + TMP_SUFFIX)
        os.replace(dst + TMP_SUFFIX, dst)
        log('revert: restored from S1 ' + rel)
    for rel in st['added']:
        p = os.path.join(DATA, rel)
        if os.path.exists(p):
            q = os.path.join(qroot, rel)
            os.makedirs(os.path.dirname(q), exist_ok=True)
            shutil.move(p, q)
            log('revert: moved to quarantine ' + rel)
    os.replace(sp, sp[:-5] + '.reverted-%s.json' % time.strftime('%Y%m%d-%H%M%S'))
    log('revert: done; batch record %s kept (status stays as written); re-run --apply to re-apply' % b.args.batch)
    return 0


RENDER_MODES = {'mat': ([], 'real materials (WXRender runtime material system)'),
                'ff': (['--ff'], '--ff fixed-function diagnostic')}


def do_render(b):
    """TlbbViewer evidence: every switched object from client_GL (left) and Canonical (right), once with the real
    material path and once with --ff. Objects that client_GL does not have are rendered from Canonical only."""
    out = os.path.join(b.args.log_dir, 'viewer')
    os.makedirs(out, exist_ok=True)
    modes = [m.strip() for m in b.args.render_modes.split(',') if m.strip() in RENDER_MODES]
    tasks = []
    objs = sorted(b.pl.switched, key=lambda i: i.name)
    for i, it in enumerate(objs, 1):
        name = CL.disp(it.name)
        for mode in modes:
            for tag, root in (('client_GL', S1_ROOT), ('canonical', DATA)):
                if tag == 'client_GL' and it.status == 'new':
                    continue
                png = os.path.join(out, 'obj%02d_%s_%s.png' % (i, mode, tag))
                cmd = ([VIEWER, '--data', root, '--model', name] + RENDER_MODES[mode][0] +
                       ['--shot', png, '--frames', '30', '--dt', '0.033', '--size', '1280x720'])
                tasks.append((i, name, mode, tag, cmd, png))

    def run(t):
        i, name, mode, tag, cmd, png = t
        t0 = time.time()
        flags = getattr(subprocess, 'BELOW_NORMAL_PRIORITY_CLASS', 0)
        try:
            p = subprocess.run(cmd, capture_output=True, timeout=1200, creationflags=flags,
                               cwd=os.path.dirname(VIEWER))
            code, so, se = p.returncode, p.stdout, p.stderr
        except subprocess.TimeoutExpired:
            code, so, se = -9, b'', b'timeout'
        with open(png[:-4] + '.stdout.txt', 'wb') as f:
            f.write(b' '.join(x.encode('utf-8') for x in cmd) + b'\n\n' + so + b'\n--- stderr ---\n' + se)
        return i, name, mode, tag, code, round(time.time() - t0, 1), os.path.exists(png)
    res = []
    t0 = time.time()
    with cf.ThreadPoolExecutor(max_workers=b.args.render_jobs) as ex:
        for r in ex.map(run, tasks):
            res.append(r)
            log('render obj%02d %-3s %-9s exit %s %5.1fs %s %s' % (r[0], r[2], r[3], r[4], r[5],
                                                                  'png' if r[6] else 'NO PNG', r[1]))
    by = collections.defaultdict(dict)
    for i, name, mode, tag, code, secs, ok in res:
        by[(i, mode)][tag] = (code, ok)
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        Image = None
    rows = []
    for i, it in enumerate(objs, 1):
        for mode in modes:
            d = by.get((i, mode), {})
            pair = ''
            if Image is not None:
                ims = []
                for tag in ('client_GL', 'canonical'):
                    p = os.path.join(out, 'obj%02d_%s_%s.png' % (i, mode, tag))
                    if os.path.exists(p):
                        im = Image.open(p).convert('RGB')
                    else:
                        im = Image.new('RGB', (1280, 720), (60, 60, 60))
                        why = ('object not in client_GL' if tag == 'client_GL' and it.status == 'new' else
                               'no image (exit %s)' % (d.get(tag, ('?',))[0],))
                        ImageDraw.Draw(im).text((40, 340), '%s: %s' % (tag, why), fill=(255, 255, 255))
                    ImageDraw.Draw(im).text((12, 10), '%s  %s  obj%02d' % (tag, mode, i), fill=(255, 255, 0))
                    ims.append(im)
                sheet = Image.new('RGB', (2560 + 8, 720), (255, 255, 255))
                sheet.paste(ims[0], (0, 0))
                sheet.paste(ims[1], (1288, 0))
                pair = 'obj%02d_%s_pair.jpg' % (i, mode)
                sheet.save(os.path.join(out, pair), 'JPEG', quality=88)
            rows.append((i, CL.disp(it.name), it.src, it.status, mode,
                         d.get('client_GL', ('absent' if it.status == 'new' else '', False))[0],
                         d.get('canonical', ('', False))[0], pair))
    write_tsv(os.path.join(out, 'pairs.tsv'), ['idx', 'object', 'source', 'all_obj', 'mode', 'exit_client_GL',
                                               'exit_canonical', 'pair_image'], rows)
    h = ['<!doctype html><meta charset="utf-8"><title>Canonical vs client_GL</title>',
         '<style>body{font:13px Segoe UI,sans-serif;margin:16px}img{width:100%;max-width:1400px;display:block}'
         'h3{margin:18px 0 4px}</style>',
         '<h1>Canonical vs client_GL - TlbbViewer (left client_GL, right Canonical)</h1>',
         '<p>' + '; '.join('<b>%s</b> = %s' % (m, html.escape(RENDER_MODES[m][1])) for m in modes) + '</p>']
    for i, name, S, stt, mode, e1, e2, pair in rows:
        h.append('<h3>obj%02d %s &larr; %s (%s) &middot; %s &middot; exit client_GL %s / Canonical %s</h3>' % (
            i, html.escape(name), S, stt, mode, e1, e2))
        if pair:
            h.append('<img src="%s" alt="%s %s">' % (pair, html.escape(name), mode))
    with open(os.path.join(out, 'index.html'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(h))
    n_ok = sum(1 for r in res if r[6])
    log('render: %d/%d images in %.0fs, index %s' % (n_ok, len(res), time.time() - t0,
                                                     os.path.join(out, 'index.html')))
    return 0 if n_ok == len(res) else 1


def main():
    global LOGF
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group(required=True)
    for m in ('check', 'apply', 'verify', 'revert', 'render'):
        g.add_argument('--' + m, action='store_true')
    ap.add_argument('--selection', default=SEL_DEFAULT)
    ap.add_argument('--batch', default=BATCH_DEFAULT)
    ap.add_argument('--log-dir', default=LOG_DEFAULT)
    ap.add_argument('--jobs', type=int, default=8, help='copy / hash threads')
    ap.add_argument('--scan-jobs', type=int, default=6, help='processes for the S1 mesh/skeleton reference scan')
    ap.add_argument('--render-jobs', type=int, default=3)
    ap.add_argument('--render-modes', default='mat,ff',
                    help='--render: mat (real materials, runtime material system) and/or ff (--ff diagnostic)')
    ap.add_argument('--deep', action='store_true', help='--verify: compare sha256 of every mirrored file with S1')
    ap.add_argument('--prune', action='store_true', help='--apply: move unexpected Canonical files to _quarantine')
    ap.add_argument('--no-validate', action='store_true')
    args = ap.parse_args()
    args.selection = os.path.abspath(args.selection)
    args.log_dir = os.path.abspath(args.log_dir)
    os.makedirs(args.log_dir, exist_ok=True)
    LOGF = open(os.path.join(args.log_dir, 'build_canonical.log'), 'a', encoding='utf-8')
    below_normal_priority()
    mode = next(m for m in ('check', 'apply', 'verify', 'revert', 'render') if getattr(args, m))
    log('=== build_canonical %s --%s selection=%s batch=%s' % (VERSION, mode, rel_cys(args.selection), args.batch))
    b = Build(args)
    if mode == 'revert':
        return do_revert(b)
    b.plan()
    return {'check': do_check, 'apply': do_apply, 'verify': do_verify, 'render': do_render}[mode](b)


if __name__ == '__main__':
    sys.exit(main())
