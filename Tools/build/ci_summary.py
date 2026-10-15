#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CY-Source CI summary: turns one ci.ps1 run into Build/Logs/ci/<short>/summary.json (+ summary.txt).

Inputs (paths come from meta.json written by ci.ps1):
  * build.log   - configure + ninja output ("==== CONFIGURE" / "==== BUILD" sections)
  * the CMake File API codemodel reply of the tree (targets, artifacts, dependencies, defining .cmake file)
  * <tree>/.ninja_log compared with ninja_log.before (edges run in this build, seconds per target)
  * "ninja -n <target>" after the build: a target is OK when nothing is left to do for it

Target status: OK, FAIL (an edge of the target failed), BLOCKED (a dependency failed), NOT_BUILT (configure
failed). Each target carries its component (the cmake/components/<name>.cmake that defines it) and the likely
owner. Also updates Build/Logs/ci/latest.json and appends Build/Logs/ci/history.tsv.

Usage: python ci_summary.py --meta Build/Logs/ci/<short>/meta.json
Exit:  0 all targets OK, 1 failures, 2 configure failed.
"""
import argparse
import datetime
import glob
import json
import os
import re
import shutil
import subprocess
import sys

# CYS-WARNSWEEP 19/09: cac ma canh bao "nhom A" - gan nhu chac chan la loi that, khong phai nhieu.
# Ly do co bang nay: C4477 (sai kieu doi so cho chuoi dinh dang) da nam trong summary.json cua CI
# TU 12/09 (Build/Logs/ci/f32d71b/summary.json: "C4477": 6) va khong ai doc, vi con so duy nhat duoc
# in ra la TONG canh bao - ma tong do bi D9025 (682/798) nhan chim. Loi do ton 3 ngay dieu tra
# (Timeline/handoff/crash-report.md). Bang nay tach rieng phan tin duoc.
WARN_GROUP_A = {
    'C4473': 'thieu doi so cho chuoi dinh dang',
    'C4474': 'thua doi so cho chuoi dinh dang',
    'C4475': 'chuoi dinh dang khong hop le',
    'C4476': 'chuoi dinh dang khong hop le',
    'C4477': 'kieu doi so KHAC kieu chuoi dinh dang',
    'C4478': 'chuoi dinh dang khong hop le',
    'C4313': "'%X'/'%s' xung dot kich thuoc doi so (64-bit)",
    'C4774': 'chuoi dinh dang khong phai hang so',
    'C4302': 'ep kieu lam CAT CUT gia tri',
    'C4306': 'ep kieu mo rong sang con tro lon hon',
    'C4311': 'ep kieu CAT CUT con tro',
    'C4312': 'ep kieu so nho -> con tro lon hon',
    'C4826': 'mo rong CO DAU sang 64-bit',
    'C4309': 'cat cut gia tri hang',
    'C4018': 'so sanh co dau vs khong dau',
    'C4389': "'==' giua co dau va khong dau",
    'C4552': 'toan tu khong co tac dung',
    'C4553': "'==' khong co tac dung - co the dinh viet '='",
    'C4390': "cau lenh dieu khien rong (';' thua)",
    'C4172': 'TRA VE dia chi cua bien cuc bo',
    'C4715': 'khong phai moi nhanh deu tra ve gia tri',
    'C4716': 'phai tra ve mot gia tri',
    'C4717': 'de quy tren moi nhanh',
    'C4700': 'dung bien CHUA khoi tao',
    # C4701/C4703 la muc 4 => chi thay duoc nho /w34701 /w34703 trong CYSCommon.cmake. DUNG BO:
    # 15 trong 16 loi that cua dot 19/09 thuoc dung hai ma nay (2 cho giai tham chieu con tro rac).
    'C4701': 'bien co the chua khoi tao',
    'C4703': 'bien con tro co the chua khoi tao',
    'C4533': "khoi tao bi 'goto' nhay qua",
    'C4265': 'lop co ham ao ma destructor KHONG ao',
    'C4291': 'khong co delete tuong ung cho placement new',
    'C4047': 'khac muc do gian tiep (con tro)',
    'C4024': 'khac kieu o doi so',
    'C4020': 'qua nhieu doi so thuc te',
    'C4022': 'con tro khong tuong thich o doi so',
    'C4028': 'khai bao tham so khac nhau',
    'C4113': 'danh sach tham so cua con tro ham KHAC nhau',
    'C4133': 'kieu khong tuong thich',
    'C4090': "mat 'const' khi gan",
    'C4805': 'tron bool voi int khong an toan',
    'C4806': 'phep so sanh khong an toan voi bool',
    'C4804': 'phep toan khong an toan voi bool',
}

def warn_is_ours(line):
    """CYS-WARNSWEEP 19/09: canh bao nay thuoc MA CUA DU AN hay thu vien ngoai?

    Src/ThirdParty/** la thu vien ngoai; Src/Engine/OGRE/** la OGRE duoc nhung thang vao cay Src.
    Phan con lai cua Src/** la ma minh viet/sua - do la phan duy nhat mot nhanh co the lam xau di.
    """
    p = line.lower().replace('/', '\\')
    i = p.find('\\src\\')
    if i < 0:
        return False
    tail = p[i:]
    if tail.startswith('\\src\\thirdparty\\') or tail.startswith('\\src\\engine\\ogre\\'):
        return False
    return True


OWNERS = [
    (('zlib', 'zziplib', 'freetype', 'devil', 'ogremain', 'ogre_d3d9', 'ogre_plugins', 'ogre_platform',
      'ogre_smoke'), 'OGRE/materials agent'),
    (('opcode', 'tinyxml', 'expat', 'scorpio', 'particlefx2', 'wxengine', 'wxcore', 'wxrender'),
     'WX/materials/effects/scene/postfx/shadow agents'),
    (('cegui', 'falagardex', 'luaplus', 'uisystem'), 'UI agent'),
    (('wxnetpackets', 'wxclient'), 'game-layer agent'),
    (('viewer',), 'canonical agent'),
    (('postfx_test',), 'postfx agent'),
    (('shadow_test',), 'shadow agent'),
    (('common', 'root'), 'build/integration (Src/CMakeLists.txt, Src/cmake/CYSCommon.cmake)'),
]

RE_EDGE = re.compile(r'^\[(\d+)/(\d+)\]\s+(.*)$')
RE_ERR = re.compile(r'\b(?:fatal\s+)?error\s+[A-Za-z]{1,4}\d{1,5}\s*:|^ninja: error:|^CMake Error|\bLINK\s*:\s*fatal error')
RE_WARN = re.compile(r'\bwarning\s+([A-Za-z]{1,4}\d{1,5})\s*:')
RE_OBJDIR = re.compile(r'(?:^|/)cmakefiles/([^/]+)\.dir/')
RE_COMPONENTS = re.compile(r'set\(\s*CYS_ALL_COMPONENTS\s+([^)]*)\)', re.S)
RE_COMP_FILE = re.compile(r'(?:^|/)cmake/components/([A-Za-z0-9_]+)\.cmake$')
STATUS_RANK = {'OK': 0, 'NO_TARGETS': 0, 'NOT_BUILT': 1, 'MISSING': 1, 'BLOCKED': 2, 'FAIL': 3}


def owner_of(component):
    for names, who in OWNERS:
        if component in names:
            return who
    return 'unknown'


def read_lines(path):
    """Build logs mix UTF-8 (CMake) and the console code page (cl.exe): decode line by line."""
    try:
        with open(path, 'rb') as f:
            data = f.read()
    except OSError:
        return []
    if data.startswith(b'\xef\xbb\xbf'):
        data = data[3:]
    out = []
    for raw in data.split(b'\n'):
        raw = raw.rstrip(b'\r')
        try:
            out.append(raw.decode('utf-8'))
        except UnicodeDecodeError:
            out.append(raw.decode('cp1252', errors='replace'))
    return out


def split_sections(lines):
    cfg, bld, mode = [], [], None
    for line in lines:
        if line.startswith('==== CONFIGURE END') or line.startswith('==== BUILD END'):
            mode = None
            continue
        if line.startswith('==== CONFIGURE'):
            mode = 'cfg'
            continue
        if line.startswith('==== BUILD'):
            mode = 'bld'
            continue
        if mode == 'cfg':
            cfg.append(line)
        elif mode == 'bld':
            bld.append(line)
    return cfg, bld


def parse_configure(lines):
    errors, warnings, i = [], 0, 0
    while i < len(lines):
        line = lines[i]
        if line.startswith('CMake Error'):
            block, j = [line.strip()], i + 1
            while j < len(lines) and len(block) < 12 and (lines[j].startswith(' ') or not lines[j].strip()):
                if lines[j].strip():
                    block.append(lines[j].strip())
                j += 1
            errors.append(' | '.join(block)[:900])
            i = j
            continue
        if line.startswith('CMake Warning'):
            warnings += 1
        i += 1
    return errors, warnings


def declared_components(worktree):
    try:
        with open(os.path.join(worktree, 'Src', 'CMakeLists.txt'), encoding='utf-8-sig') as f:
            text = f.read()
    except OSError:
        return []
    m = RE_COMPONENTS.search(text)
    if not m:
        return []
    body = re.sub(r'#[^\n]*', ' ', m.group(1))
    return [w for w in body.split() if w]


def git_info(root, sha):
    try:
        r = subprocess.run(['git', '-C', root, 'log', '-1', '--format=%s%x00%cI%x00%an', sha],
                           capture_output=True, timeout=60)
        parts = r.stdout.decode('utf-8', 'replace').strip().split('\x00')
        if len(parts) >= 3:
            return {'subject': parts[0], 'commit_date': parts[1], 'author': parts[2]}
    except Exception:
        pass
    return {}


def load_codemodel(tree):
    reply = os.path.join(tree, '.cmake', 'api', 'v1', 'reply')
    idx = sorted(glob.glob(os.path.join(reply, 'index-*.json')))
    if not idx:
        return None
    with open(idx[-1], encoding='utf-8') as f:
        index = json.load(f)
    cm_file = None
    for obj in index.get('objects', []):
        if obj.get('kind') == 'codemodel':
            cm_file = obj.get('jsonFile')
    if not cm_file:
        return None
    with open(os.path.join(reply, cm_file), encoding='utf-8') as f:
        cm = json.load(f)
    targets = {}
    for t in cm['configurations'][0].get('targets', []):
        with open(os.path.join(reply, t['jsonFile']), encoding='utf-8') as f:
            targets[t['id']] = json.load(f)
    return targets


def component_of(tj):
    graph = tj.get('backtraceGraph') or {}
    files, nodes = graph.get('files', []), graph.get('nodes', [])
    i, hops, fallback = tj.get('backtrace'), 0, None
    while i is not None and 0 <= i < len(nodes) and hops < 64:
        node = nodes[i]
        fidx = node.get('file')
        path = files[fidx].replace('\\', '/') if fidx is not None and fidx < len(files) else ''
        m = RE_COMP_FILE.search(path)
        if m:
            return m.group(1)
        if fallback is None and path.endswith('CYSCommon.cmake'):
            fallback = 'common'
        i = node.get('parent')
        hops += 1
    return fallback or 'root'


def norm_path(p, tree):
    p = p.strip().strip('"').replace('\\', '/')
    t = tree.replace('\\', '/').rstrip('/') + '/'
    if p.lower().startswith(t.lower()):
        p = p[len(t):]
    if p.startswith('./'):
        p = p[2:]
    return p.lower()


def read_ninja_log(path):
    entries = {}
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            for line in f:
                if line.startswith('#'):
                    continue
                parts = line.rstrip('\n').split('\t')
                if len(parts) < 4:
                    continue
                try:
                    start, end = int(parts[0]), int(parts[1])
                except ValueError:
                    continue
                entries[parts[3]] = (start, end, parts[2], parts[4] if len(parts) > 4 else '')
    except OSError:
        pass
    return entries


class DryRun:
    """"ninja -n <target>" on a COPY of build.ninja. With file(GLOB ... CONFIGURE_DEPENDS) the real manifest is
    always out of date (VerifyGlobs), and in dry-run mode ninja then stops right after the (dry) manifest rebuild
    without looking at the target. A manifest under another name is no edge's output, so nothing short-circuits."""

    def __init__(self, ninja, tree):
        self.ninja, self.tree = ninja, tree
        self.name = 'build.ci-dryrun.ninja'
        self.path = os.path.join(tree, self.name)
        shutil.copyfile(os.path.join(tree, 'build.ninja'), self.path)

    def up_to_date(self, target):
        try:
            r = subprocess.run([self.ninja, '-C', self.tree, '-f', self.name, '-n', target],
                               capture_output=True, timeout=180)
        except Exception as e:  # noqa: BLE001
            return None, 'ninja -n failed: %s' % e
        out = (r.stdout + r.stderr).decode('utf-8', 'replace')
        if r.returncode != 0:
            last = out.strip().splitlines()[-1] if out.strip() else 'ninja -n rc=%d' % r.returncode
            return None, last
        if 'no work to do' in out:
            return True, ''
        pending = [ln for ln in out.splitlines() if RE_EDGE.match(ln)]
        return False, '%d edge(s) still to run, first: %s' % (len(pending), pending[0][:200] if pending else '?')

    def close(self):
        try:
            os.remove(self.path)
        except OSError:
            pass


def main():
    ap = argparse.ArgumentParser(description='CY-Source CI summary')
    ap.add_argument('--meta', required=True)
    # CYS-WARNSWEEP 19/09: cong kiem dem. Mac dinh TAT (chi bao cao) de khong lam do CI cua nhanh khac;
    # dat --warn-a-max N thi exit code = 1 khi so khoan nhom A vuot N.
    ap.add_argument('--warn-a-max', type=int, default=None,
                    help='so khoan canh bao nhom A toi da truoc khi coi la that bai')
    args = ap.parse_args()
    with open(args.meta, encoding='utf-8-sig') as f:
        meta = json.load(f)
    log_dir = os.path.dirname(os.path.abspath(args.meta))
    root, tree, wt = meta['root'], meta['tree'], meta['worktree']
    ninja = meta.get('ninja')
    cfg_rc = meta['configure'].get('rc')
    bld_rc = meta['build'].get('rc')
    build_ran = bld_rc is not None

    cfg_lines, bld_lines = split_sections(read_lines(meta['log']))
    cfg_errors, cfg_warnings = parse_configure(cfg_lines)
    declared = declared_components(wt)

    # ---- targets from the File API
    cm = load_codemodel(tree) if cfg_rc == 0 else None
    by_id = {}
    for tid, tj in (cm or {}).items():
        by_id[tid] = {
            'id': tid, 'name': tj['name'], 'type': tj['type'], 'component': component_of(tj),
            'artifacts': [a['path'].replace('\\', '/') for a in tj.get('artifacts', [])],
            'deps': [d['id'] for d in tj.get('dependencies', [])],
            'sources': len(tj.get('sources', [])),
        }
    name_by_lower = {t['name'].lower(): t['name'] for t in by_id.values()}
    target_by_output = {}
    for t in by_id.values():
        for a in t['artifacts']:
            target_by_output[norm_path(a, tree)] = t['name']

    def target_for(path):
        p = norm_path(path, tree)
        m = RE_OBJDIR.search(p)
        if m:
            return name_by_lower.get(m.group(1), m.group(1))
        return target_by_output.get(p)

    # ---- build log: errors / warnings attributed to the edge (target) that printed them
    per = {}

    def rec(name):
        return per.setdefault(name or '(unattributed)', {'warnings': 0, 'errors': [], 'failed_edges': 0})

    first_errors, failed_edges, warn_texts, warn_codes = [], [], set(), {}
    warn_a, warn_a_ours = set(), set()          # CYS-WARNSWEEP 19/09: chi cac khoan nhom A
    warnings_total, error_lines = 0, 0
    cur_target, cur_failed = None, None
    for line in bld_lines:
        m = RE_EDGE.match(line)
        if m:
            words = m.group(3).split()
            cur_target = target_for(words[-1]) if words else None
            cur_failed = None
            continue
        if line.startswith('FAILED: '):
            outs = re.sub(r'^\[code=-?\d+\]\s*', '', line[8:]).split()
            tgt = None
            for o in outs:
                tgt = target_for(o)
                if tgt:
                    break
            cur_target = tgt or cur_target
            cur_failed = {'target': cur_target or '(unattributed)', 'outputs': outs[:3], 'errors': []}
            failed_edges.append(cur_failed)
            rec(cur_target)['failed_edges'] += 1
            continue
        if RE_ERR.search(line):
            text = line.strip()[:500]
            error_lines += 1
            r = rec(cur_target)
            if len(r['errors']) < 12:
                r['errors'].append(text)
            if cur_failed is not None and len(cur_failed['errors']) < 8:
                cur_failed['errors'].append(text)
            if len(first_errors) < 25:
                first_errors.append(text)
            continue
        w = RE_WARN.search(line)
        if w:
            warnings_total += 1
            warn_texts.add(line.strip())
            code = w.group(1).upper()
            warn_codes[code] = warn_codes.get(code, 0) + 1
            rec(cur_target)['warnings'] += 1
            if code in WARN_GROUP_A:            # CYS-WARNSWEEP 19/09
                warn_a.add(line.strip()[:400])
                if warn_is_ours(line):
                    warn_a_ours.add(line.strip()[:400])

    # ---- seconds / edges per target from the ninja log entries that changed in this build
    before = read_ninja_log(os.path.join(log_dir, 'ninja_log.before'))
    after = read_ninja_log(os.path.join(tree, '.ninja_log')) if build_ran else {}
    changed = {o: v for o, v in after.items() if before.get(o) != v}
    tsec, tedges, seen = {}, {}, set()
    for o, (s, e, _mt, _h) in changed.items():
        tg = target_for(o) or '(other)'
        if (tg, s, e) in seen:
            continue
        seen.add((tg, s, e))
        tsec[tg] = tsec.get(tg, 0.0) + (e - s) / 1000.0
        tedges[tg] = tedges.get(tg, 0) + 1
    edges_run = len({(s, e, h) for (s, e, _mt, h) in changed.values()})

    # ---- status per target
    status = {}
    dry = DryRun(ninja, tree) if (build_ran and by_id) else None
    try:
        for tid, t in by_id.items():
            if t['type'] == 'INTERFACE_LIBRARY':
                continue
            if not build_ran:
                status[tid] = ('NOT_BUILT', 'configure failed')
            elif per.get(t['name'], {}).get('failed_edges'):
                status[tid] = ('FAIL', '')
            elif t['type'] == 'UTILITY':
                status[tid] = ('UTILITY', '')
            else:
                ok, note = dry.up_to_date(t['name'])
                status[tid] = ('OK', '') if ok else ('PENDING', note)
    finally:
        if dry:
            dry.close()

    def closure(tid, acc):
        for d in by_id[tid]['deps']:
            if d in by_id and d not in acc:
                acc.add(d)
                closure(d, acc)
        return acc

    for tid, (st, note) in list(status.items()):
        if st not in ('PENDING', 'UTILITY'):
            continue
        bad = sorted(by_id[d]['name'] for d in closure(tid, set()) if status.get(d, ('OK', ''))[0] == 'FAIL')
        if bad:
            status[tid] = ('BLOCKED', 'dependency failed: ' + ', '.join(bad))
        elif st == 'UTILITY':
            status[tid] = ('OK', '')
        else:
            status[tid] = ('FAIL', note or 'not up to date after the build (no error line attributed)')

    rows = []
    for tid, t in by_id.items():
        if tid not in status:
            continue
        st, note = status[tid]
        r = per.get(t['name'], {})
        rows.append({
            'name': t['name'], 'type': t['type'], 'component': t['component'], 'owner': owner_of(t['component']),
            'status': st, 'note': note, 'artifacts': t['artifacts'],
            'warnings': r.get('warnings', 0), 'errors': r.get('errors', [])[:8],
            'seconds': round(tsec.get(t['name'], 0.0), 1), 'edges_run': tedges.get(t['name'], 0),
            'sources': t['sources'],
            'depends_on': sorted(by_id[d]['name'] for d in t['deps'] if d in by_id),
        })
    order = {c: i for i, c in enumerate(declared)}
    rows.sort(key=lambda x: (order.get(x['component'], 999), x['name'].lower()))

    comps = []
    for c in declared:
        present = os.path.exists(os.path.join(wt, 'Src', 'cmake', 'components', c + '.cmake'))
        ts = [x for x in rows if x['component'] == c]
        if not present:
            st = 'MISSING'
        elif not ts:
            st = 'NO_TARGETS' if cm is not None else 'NOT_BUILT'
        else:
            st = max((x['status'] for x in ts), key=lambda s: STATUS_RANK.get(s, 0))
        comps.append({'name': c, 'present': present, 'status': st, 'owner': owner_of(c),
                      'targets': [x['name'] for x in ts]})

    if cfg_rc != 0:
        result = 'CONFIGURE_FAIL'
    elif bld_rc != 0 or any(x['status'] != 'OK' for x in rows):
        result = 'FAIL'
    else:
        result = 'OK'
    failures = [{'target': x['name'], 'component': x['component'], 'owner': x['owner'], 'status': x['status'],
                 'first_error': x['errors'][0] if x['errors'] else x['note']}
                for x in rows if x['status'] in ('FAIL', 'BLOCKED')]
    if cfg_rc != 0:
        failures.append({'target': '(configure)', 'component': 'root', 'owner': owner_of('root'),
                         'status': 'CONFIGURE_FAIL', 'first_error': cfg_errors[0] if cfg_errors else 'see build.log'})
    counts = {k: sum(1 for x in rows if x['status'] == k) for k in ('OK', 'FAIL', 'BLOCKED', 'NOT_BUILT')}
    counts['targets'] = len(rows)

    now = datetime.datetime.now().replace(microsecond=0).isoformat()
    out_path = os.path.join(log_dir, 'summary.json')
    summary = {
        'schema': 1, 'sha': meta['sha'], 'short': meta['short'], **git_info(root, meta['sha']),
        'result': result, 'started': meta.get('started'), 'finished': now,
        'root': root, 'worktree': wt, 'tree': tree, 'config': meta.get('config'), 'jobs': meta.get('jobs'),
        'sdk': meta.get('sdk'), 'fmod_visible': meta.get('fmod_visible'), 'cg_dll': meta.get('cg_dll'),
        'worktree_dirty': meta.get('worktree_dirty') or [],
        'configure': {'rc': cfg_rc, 'seconds': meta['configure'].get('seconds'), 'errors': cfg_errors[:10],
                      'warnings': cfg_warnings},
        'build': {'rc': bld_rc, 'seconds': meta['build'].get('seconds'), 'edges_run': edges_run,
                  'warnings': warnings_total, 'warnings_unique': len(warn_texts),
                  'warning_codes': dict(sorted(warn_codes.items(), key=lambda kv: -kv[1])[:20]),
                  # CYS-WARNSWEEP 19/09: dem rieng nhom A de no khong bi tong so nhan chim.
                  'warnings_group_a': len(warn_a), 'warnings_group_a_ours': len(warn_a_ours),
                  'warnings_group_a_items': sorted(warn_a)[:80],
                  'error_lines': error_lines, 'first_errors': first_errors, 'failed_edges': failed_edges[:30]},
        'counts': counts, 'components': comps, 'targets': rows, 'failures': failures,
        'files': {'build_log': meta['log'], 'meta': os.path.abspath(args.meta), 'summary': out_path},
    }
    with open(out_path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)

    # ---- text report
    lines = ['CI %s  %s  [%s]' % (meta['short'], result, summary.get('subject', '')),
             'targets OK %d/%d (FAIL %d, BLOCKED %d, NOT_BUILT %d); configure rc=%s %.1fs; build rc=%s %.1fs, '
             '%d edges run, %d warnings (%d unique)' % (
                 counts['OK'], counts['targets'], counts['FAIL'], counts['BLOCKED'], counts['NOT_BUILT'],
                 cfg_rc, meta['configure'].get('seconds') or 0, bld_rc, meta['build'].get('seconds') or 0,
                 edges_run, warnings_total, len(warn_texts)),
             'components: ' + ', '.join('%s=%s' % (c['name'], c['status']) for c in comps)]
    # CYS-WARNSWEEP 19/09: nhom A luon duoc in rieng, ngay ca khi = 0, de con so nay duoc NHIN THAY.
    # MA CUA TA duoc in truoc vi do la phan duy nhat mot nhanh co the lam xau di.
    lines.append('CANH BAO NHOM A (gan nhu chac chan la loi that): %d khoan MA CUA TA / %d tong'
                 % (len(warn_a_ours), len(warn_a)))
    shown = sorted(warn_a_ours) + [t for t in sorted(warn_a) if t not in warn_a_ours]
    for t in shown[:20]:
        lines.append('  A! ' + t[:240])
    if len(shown) > 20:
        lines.append('  A! ... con %d khoan nua, xem summary.json: build.warnings_group_a_items' % (len(shown) - 20))
    if args.warn_a_max is not None and len(warn_a) > args.warn_a_max:
        lines.append('  *** DO: nhom A = %d > nguong %d (--warn-a-max). Xem khoi A! o tren: khoan nao'
                     ' co duong dan Src\\ ma KHONG phai Src\\ThirdParty hay Src\\Engine\\OGRE thi do la'
                     ' cua chung ta va phai sua, dung noi nguong. ***' % (len(warn_a), args.warn_a_max))
    for x in rows:
        lines.append('  %-9s %-26s %-14s %6.1fs %4d edges %4d warn  %s' % (
            x['status'], x['name'], x['component'], x['seconds'], x['edges_run'], x['warnings'],
            (x['errors'][0] if x['errors'] else x['note'])[:160]))
    for e in cfg_errors[:5]:
        lines.append('  CONFIGURE ERROR: ' + e[:300])
    for fl in failures:
        lines.append('  -> %s %s [%s] owner: %s: %s' % (fl['status'], fl['target'], fl['component'], fl['owner'],
                                                       (fl['first_error'] or '')[:300]))
    text = '\n'.join(lines)
    with open(os.path.join(log_dir, 'summary.txt'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(text + '\n')
    print(text)

    # ---- latest.json + history.tsv
    ci_dir = os.path.dirname(log_dir)
    latest = {'sha': meta['sha'], 'short': meta['short'], 'result': result, 'finished': now,
              'targets_ok': counts['OK'], 'targets_total': counts['targets'], 'summary': out_path,
              # CYS-WARNSWEEP 19/09: co day de ai doc latest.json cung thay ngay, va de phan biet
              # "exit code 1 vi target hong" voi "exit code 1 vi cong nhom A" (result van la OK).
              'warnings_group_a': len(warn_a), 'warnings_group_a_ours': len(warn_a_ours),
              'subject': summary.get('subject', '')}
    with open(os.path.join(ci_dir, 'latest.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(latest, f, ensure_ascii=False, indent=1)
    hist = os.path.join(ci_dir, 'history.tsv')
    new = not os.path.exists(hist)
    # CYS-WARNSWEEP 19/09: hai cot warn_a them o CUOI dong de khong pha cac cot cu; dong tieu de cua
    # file cu duoc nang cap tai cho, de khong de lai canh "11 o du lieu / 9 ten cot" - dung cai bay
    # ma chinh nhanh nay sinh ra de dep. Dong cu giu nguyen (it o hon) chu khong bi bia them so.
    hdr = ('finished\tshort\tresult\tok\ttotal\tbuild_s\tedges\twarnings\tsubject'
           '\twarn_a\twarn_a_ours')
    if not new:
        try:
            with open(hist, encoding='utf-8') as f:
                old = f.read().split('\n')
            if old and old[0].rstrip('\r') != hdr:
                old[0] = hdr
                with open(hist, 'w', encoding='utf-8', newline='\n') as f:
                    f.write('\n'.join(old))
        except OSError:
            pass
    with open(hist, 'a', encoding='utf-8', newline='\n') as f:
        if new:
            f.write(hdr + '\n')
        f.write('%s\t%s\t%s\t%d\t%d\t%s\t%d\t%d\t%s\t%d\t%d\n' % (
            now, meta['short'], result, counts['OK'], counts['targets'], meta['build'].get('seconds'),
            edges_run, warnings_total, summary.get('subject', '').replace('\t', ' '),
            len(warn_a), len(warn_a_ours)))
    if args.warn_a_max is not None and len(warn_a) > args.warn_a_max:
        return 1                                # CYS-WARNSWEEP 19/09: cong kiem dem nhom A
    return 0 if result == 'OK' else (2 if result == 'CONFIGURE_FAIL' else 1)


if __name__ == '__main__':
    sys.exit(main())
