# -*- coding: utf-8 -*-
"""index_sources.py - CY-Source phase D0: read-only index of the asset sources S1-S4.

Outputs (Assets/Staging/index/, UTF-8 with BOM, TAB separated, header row):
  sha256_S1.tsv, sha256_S2.tsv, sha256_S3.tsv
        every file: size, sha256, format-derived length (mesh/skeleton/dds/png/jpg),
        trailing padding kind, sha256 of the content without padding, short info
  models_S1.tsv, models_S2.tsv, models_S3.tsv
        one row per <Object> of all.obj: meshes (+size/vertices/submeshes), skeletons,
        animations, materials, texture closure (+max resolution), locators, effects,
        attributes, completeness, definition/content hashes
  models_S4.tsv   names only: all.obj of CY Game 3.71.9609 resolved against the AXP (list)
  models_cross.tsv   obj -> sources, identity by SHA-256, quality metrics side by side, hint
  effects_cross.tsv  effect / particle / skill names per source, identical or not
  s2_vs_s4_lengths.tsv + s2_vs_s4_summary.txt   S2 size vs S4 (list) size, padding, trim plan
  index_summary.json run parameters, timings and counts
  _cache/            incremental scan cache (safe to delete; --rescan ignores it)

Every source is opened read-only. Nothing is written outside the output folder.
Run (PowerShell):
  $env:PYTHONUTF8="1"; & "C:\\Program Files\\Python313\\python.exe" C:\\TLBB\\085\\CY-Source\\Tools\\pipeline\\index_sources.py
Options: --jobs N  --rescan  --skip-s4-verify  --out DIR
"""
import argparse
import collections
import concurrent.futures as cf
import datetime
import hashlib
import json
import os
import pickle
import re
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import tlbbfmt as F  # noqa: E402

TOOL_VERSION = '1.0 (2026-09-12)'
CACHE_V = 3
CYS = r'C:\TLBB\085\CY-Source'
OUT_DEFAULT = os.path.join(CYS, 'Assets', 'Staging', 'index')
DN = r'C:\TLBB\085\Tools\DATA NEW'
S4_DIR = os.path.join(DN, 'CY Game', 'Data')
_LOOSE = {'obj': r'Model\all.obj', 'material': r'Material\all.material', 'effect': r'Effect\all.effect',
          'particle': r'Effect\all.particle', 'skill': r'Effect\all.skill'}
# Mirrors Assets/Sources/sources.yaml (S1-S4). Paths are read-only.
SOURCES = {
    'S1': dict(root=r'C:\TLBB\085\client_GL\Data', mojibake=True, exclude=(),
               obj=r'ModelFolder\all.obj', material=r'MaterialFolder\all.material',
               effect=r'EffectFolder\all.effect', particle=r'EffectFolder\all.particle',
               skill=r'EffectFolder\all.skill'),
    'S2': dict(root=os.path.join(DN, 'DataCY31-08-26'), mojibake=False,
               exclude=('tlbb15', 'tlbb15.zip'), **_LOOSE),       # tlbb15 = S2b (server), never read
    'S3': dict(root=os.path.join(DN, 'CYHJ091026'), mojibake=False, exclude=(), **_LOOSE),
}
LOOSE = ('S1', 'S2', 'S3')
ALL = ('S1', 'S2', 'S3', 'S4')
TIE_ORDER = ('S1', 'S3', 'S2')      # on equal metrics prefer the installed client, then HJ, then CY
FOLDER_RE = re.compile(r'^(model|material)(\d*)(folder)?$', re.I)
MODEL_EXT = ('.mesh', '.skeleton')
BUILTIN_MATS = {b'BaseWhite', b'BaseWhiteNoLighting'}     # created by Ogre itself, never in all.material

LOGF = None


def log(*a):
    s = time.strftime('%H:%M:%S ') + ' '.join(str(x) for x in a)
    print(s, flush=True)
    if LOGF:
        LOGF.write(s + '\n')
        LOGF.flush()


# ------------------------------------------------------------------ small helpers
def ext_of(rel):
    return os.path.splitext(rel)[1].lower()


def folder_rank(top):
    m = FOLDER_RE.match(top)
    if not m:
        return (2, 0, top.lower())
    return (0 if m.group(1).lower() == 'model' else 1, int(m.group(2) or 1), '')


def disp_rel(rel, moj):
    if not moj:
        return rel
    return '\\'.join(F.disp(F.disk_name_bytes(p, True)) for p in rel.split('\\'))


def cell(x):
    if x is None:
        return ''
    if isinstance(x, bytes):
        x = F.disp(x)
    s = str(x)
    if '\t' in s or '\n' in s or '\r' in s:
        s = s.replace('\t', ' ').replace('\r', ' ').replace('\n', ' ')
    return s


def write_tsv(path, header, rows):
    tmp = path + '.tmp'
    n = 0
    with open(tmp, 'w', encoding='utf-8-sig', newline='\n', errors='backslashreplace') as f:
        f.write('\t'.join(header) + '\n')
        for r in rows:
            f.write('\t'.join(cell(x) for x in r) + '\n')
            n += 1
    os.replace(tmp, path)
    log('  wrote', os.path.basename(path), n, 'rows')
    return n


def joinb(items, sep=';'):
    return sep.join(F.disp(x) if isinstance(x, bytes) else str(x) for x in items)


def sha16(parts):
    h = hashlib.sha256()
    for p in parts:
        h.update(p if isinstance(p, bytes) else str(p).encode('utf-8', 'surrogatepass'))
        h.update(b'\x00')
    return h.hexdigest()[:16]


def cache_file(out, name):
    return os.path.join(out, '_cache', name + '.pkl')


def load_cache(out, name):
    try:
        with open(cache_file(out, name), 'rb') as f:
            c = pickle.load(f)
        return c if isinstance(c, dict) and c.get('_v') == CACHE_V else None
    except (OSError, pickle.PickleError, EOFError, AttributeError, ValueError):
        return None


def save_cache(out, name, obj):
    p = cache_file(out, name)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    obj['_v'] = CACHE_V
    with open(p + '.tmp', 'wb') as f:
        pickle.dump(obj, f, protocol=pickle.HIGHEST_PROTOCOL)
    os.replace(p + '.tmp', p)


# ------------------------------------------------------------------ stage 1: walk
def walk(root, exclude):
    files = []
    stack = [root]
    while stack:
        d = stack.pop()
        try:
            with os.scandir(d) as it:
                for e in it:
                    if d == root and e.name in exclude:
                        continue
                    if e.is_dir(follow_symlinks=False):
                        stack.append(e.path)
                    elif e.is_file(follow_symlinks=False):
                        st = e.stat(follow_symlinks=False)
                        files.append((os.path.relpath(e.path, root), st.st_size, st.st_mtime_ns))
        except OSError as ex:
            log('WALK-ERR', d, ex)
    files.sort()
    return files


# ------------------------------------------------------------------ stage 2: S4 index
def s4_index(out, rescan):
    cache = (None if rescan else load_cache(out, 's4index')) or {}
    res = {}
    for fn in sorted(os.listdir(S4_DIR)):
        if not fn.lower().endswith('.axp'):
            continue
        p = os.path.join(S4_DIR, fn)
        st = os.stat(p)
        key = (st.st_size, st.st_mtime_ns)
        c = cache.get(fn)
        if c and c['key'] == key:
            res[fn] = c
            continue
        ax = F.Axp(p)
        try:
            rows = []
            for nm, rest in ax.file_list() or []:
                lsz = int(rest[0], 16) if rest and rest[0].strip() else -1
                chk = rest[1].strip() if len(rest) > 1 else ''
                ent = ax.entry(nm)
                if ent is None:
                    rows.append((nm, lsz, chk, -1, -1, 0, -1, -1))
                    continue
                off, size, flags = ent
                ax.f.seek(off)
                hd = F.decode_header(ax.f.read(min(size, F.HDR_SIZE)), size)
                rows.append((nm, lsz, chk, off, size, flags, 0 if hd is None else hd[0],
                             size if hd is None else hd[1]))
            used = sum(1 for e in ax.entries if e[2] & 0x80000000)
            res[fn] = {'key': key, 'count': ax.count, 'used': used, 'rows': rows, 'unlisted': []}
        finally:
            ax.f.close()
    save_cache(out, 's4index', dict(res))
    return res


def s4_unlisted(s4, s2files):
    """S2 files whose path is not in an archive's (list): look the name up in the AXP hash
    table directly (the archives carry a few unlisted entries)."""
    arch_by_top = {fn[:-4].lower(): fn for fn in s4}
    listed = set()
    for fn, a in s4.items():
        top = fn[:-4].lower()
        for r in a['rows']:
            listed.add((top, r[0].lower().replace('\\', '/')))
    cand = collections.defaultdict(list)
    for rel, size, mt in s2files:
        parts = rel.split('\\', 1)
        if len(parts) < 2 or parts[0].lower() not in arch_by_top:
            continue
        inner = parts[1].replace('\\', '/')
        if (parts[0].lower(), inner.lower()) not in listed:
            cand[parts[0].lower()].append(inner)
    found = 0
    for top, names in cand.items():
        fn = arch_by_top[top]
        a = s4[fn]
        if a.get('unlisted_checked') == len(names):
            found += len(a['unlisted'])
            continue
        ax = F.Axp(os.path.join(S4_DIR, fn))
        try:
            rows = []
            for nm in names:
                try:
                    ent = ax.entry(nm)
                except UnicodeEncodeError:
                    ent = None
                if ent is None:
                    continue
                off, size, flags = ent
                ax.f.seek(off)
                hd = F.decode_header(ax.f.read(min(size, F.HDR_SIZE)), size)
                rows.append((nm, -1, '', off, size, flags, 0 if hd is None else hd[0],
                             size if hd is None else hd[1]))
            a['unlisted'] = rows
            a['unlisted_checked'] = len(names)
            found += len(rows)
        finally:
            ax.f.close()
    return sum(len(v) for v in cand.values()), found


def s4_canon_map(s4):
    """(top_lower, inner_lower) -> (archive, row, listed)"""
    m = {}
    for fn, a in s4.items():
        top = fn[:-4].lower()
        for r in a['rows']:
            if r[3] >= 0:
                m.setdefault((top, r[0].lower().replace('\\', '/')), (fn, r, True))
        for r in a.get('unlisted', []):
            m.setdefault((top, r[0].lower().replace('\\', '/')), (fn, r, False))
    return m


def s2_key(rel):
    parts = rel.split('\\', 1)
    if len(parts) < 2:
        return None
    return (parts[0].lower(), parts[1].replace('\\', '/').lower())


# ------------------------------------------------------------------ stage 3: scan S1-S3
def scan_sources(out, walked, canon, jobs, rescan):
    results = {}
    caches = {}
    todo = []
    total_bytes = 0
    for S in walked:
        root = SOURCES[S]['root']
        c = (None if rescan else load_cache(out, 'scan_' + S)) or {}
        caches[S] = c
        res = {}
        for rel, size, mt in walked[S]:
            cn = -1
            if S == 'S2':
                k = s2_key(rel)
                if k in canon:
                    cn = canon[k][1][7]
            hit = c.get(rel)
            if hit and hit[1] == cn and hit[0][1] == size and hit[0][2] == mt:
                res[rel] = hit[0]
                continue
            todo.append((S, rel, os.path.join(root, rel), ext_of(rel), cn, size))
            total_bytes += size
        results[S] = res
    log('scan: %d files to read (%.2f GB), %d from cache' % (len(todo), total_bytes / 1e9,
                                                             sum(len(r) for r in results.values())))
    if todo:
        batches = []
        cur = []
        cur_b = 0
        cur_s = None
        for S, rel, path, ext, cn, size in todo:
            if cur and (S != cur_s or cur_b >= (48 << 20) or len(cur) >= 300):
                batches.append((cur_s, cur))
                cur, cur_b = [], 0
            cur_s = S
            cur.append((rel, path, ext, cn))
            cur_b += size
        if cur:
            batches.append((cur_s, cur))
        t0 = time.time()
        done_b = 0
        size_of = {(S, rel): size for S, rel, path, ext, cn, size in todo}
        cn_of = {(S, rel): cn for S, rel, path, ext, cn, size in todo}
        last = t0
        with cf.ProcessPoolExecutor(max_workers=jobs) as ex:
            futs = {ex.submit(F.scan_batch, b): S for S, b in batches}
            for i, fu in enumerate(cf.as_completed(futs), 1):
                S = futs[fu]
                for r in fu.result():
                    results[S][r[0]] = r
                    caches[S][r[0]] = (r, cn_of[(S, r[0])])
                    done_b += max(0, size_of[(S, r[0])])
                now = time.time()
                if now - last > 15 or i == len(batches):
                    last = now
                    log('  scan %d/%d batches, %.1f/%.1f GB, %.0f MB/s' % (
                        i, len(batches), done_b / 1e9, total_bytes / 1e9, done_b / 1e6 / max(0.1, now - t0)))
        for S in walked:
            keep = {rel for rel, size, mt in walked[S]}
            c = {k: v for k, v in caches[S].items() if k in keep}
            save_cache(out, 'scan_' + S, c)
    return results


# ------------------------------------------------------------------ stage 4: S4 payload hashes
def s4_hashes(out, s4, jobs, rescan):
    cache = (None if rescan else load_cache(out, 's4hash')) or {}
    res = {}
    tasks = []
    total = 0
    for fn, a in s4.items():
        c = cache.get(fn)
        nrows = len(a['rows']) + len(a.get('unlisted', []))
        if c and c['key'] == a['key'] and c['n'] == nrows:
            res[fn] = c['h']
            continue
        res[fn] = {}
        rows = sorted((r for r in a['rows'] + a.get('unlisted', []) if r[3] >= 0), key=lambda r: r[3])
        path = os.path.join(S4_DIR, fn)
        chunk = []
        acc = 0
        for r in rows:
            chunk.append((r[0], r[3], r[4], r[6], r[7]))
            acc += r[4]
            total += r[4]
            if acc >= (96 << 20) or len(chunk) >= 400:
                tasks.append((path, chunk))
                chunk, acc = [], 0
        if chunk:
            tasks.append((path, chunk))
    log('s4 verify: %d tasks, %.2f GB to read' % (len(tasks), total / 1e9))
    if tasks:
        t0 = time.time()
        last = t0
        done = 0
        with cf.ProcessPoolExecutor(max_workers=jobs) as ex:
            futs = [ex.submit(F.s4_hash_batch, t) for t in tasks]
            sizes = {id(t): sum(x[2] for x in t[1]) for t in tasks}
            fsize = {f: sizes[id(t)] for f, t in zip(futs, tasks)}
            for i, fu in enumerate(cf.as_completed(futs), 1):
                path, items = fu.result()
                fn = os.path.basename(path)
                for nm, sha, magic in items:
                    res[fn][nm] = (sha, magic)
                done += fsize[fu]
                now = time.time()
                if now - last > 15 or i == len(futs):
                    last = now
                    log('  s4 %d/%d tasks, %.1f/%.1f GB, %.0f MB/s' % (i, len(futs), done / 1e9, total / 1e9,
                                                                        done / 1e6 / max(0.1, now - t0)))
        for fn, a in s4.items():
            cache[fn] = {'key': a['key'], 'n': len(a['rows']) + len(a.get('unlisted', [])), 'h': res[fn]}
        save_cache(out, 's4hash', cache)
    return res


# ------------------------------------------------------------------ outputs: sha256 manifests
def write_sha(out, S, files, scan):
    moj = SOURCES[S]['mojibake']
    rows = []
    stats = collections.Counter()
    tails = collections.Counter()
    for rel, size, mt in files:
        r = scan.get(rel)
        if r is None:
            continue
        ext = ext_of(rel)
        name = disp_rel(rel, moj)
        rows.append((rel, name if name != rel else '', r[1], r[3], r[4] if r[9] is not None else '',
                     r[5], r[6] if r[6] != r[3] else '', F.info_text(ext, r[9])))
        stats['files'] += 1
        stats['bytes'] += max(0, r[1])
        if r[5]:
            tails[(ext, r[5])] += 1
        if r[5].startswith('ERR'):
            stats['read_errors'] += 1
        if r[9] and r[9].get('err'):
            stats['parse_errors_' + ext] += 1
    write_tsv(os.path.join(out, 'sha256_%s.tsv' % S),
              ['relpath', 'name_gbk', 'size', 'sha256', 'fmt_len', 'tail', 'sha256_content', 'info'], rows)
    return dict(stats), {'%s %s' % k: v for k, v in sorted(tails.items())}


# ------------------------------------------------------------------ models
def name_index(S, files):
    moj = SOURCES[S]['mojibake']
    ent = []
    for rel, size, mt in files:
        parts = rel.split('\\')
        top = parts[0] if len(parts) > 1 else ''
        ent.append((folder_rank(top), rel, F.key_of(F.disk_name_bytes(parts[-1], moj))))
    ent.sort()
    idx = {}
    dup = 0
    for rk, rel, k in ent:
        if k in idx:
            dup += 1
            continue
        idx[k] = rel
    return idx, dup


def read_src(S, what):
    with open(os.path.join(SOURCES[S]['root'], SOURCES[S][what]), 'rb') as f:
        return f.read()


def read_s4(fn, suffix):
    ax = F.Axp(os.path.join(S4_DIR, fn))
    try:
        names = [nm for nm, rest in ax.file_list() or [] if nm.lower() == suffix or
                 (nm.lower().endswith(suffix) and '/' not in nm)]
        if not names:
            return b''
        alg, data = ax.payload_full(names[0], maxlen=1 << 30)
        return data or b''
    finally:
        ax.f.close()


def fmt_attrs(atts):
    out = []
    for n, v, h in atts:
        if h == b'SlotCreate':
            continue
        s = F.disp(n) + '=' + F.disp(v)
        if h:
            s += '|' + F.disp(h)
        out.append(s)
    return ' ; '.join(out)


def build_models(S, objs, mats, fxdefs, idx, scan):
    tcache = {}
    rows = []
    recs = {}
    stats = collections.Counter()
    for o in objs:
        name = F.disp(o['name'])
        ents = o['entities']
        dmesh = list(dict.fromkeys(F.base_of(e.get(b'file', b'')) for e in ents if e.get(b'file', b'').strip()))
        minfo = []
        for mb in dmesh:
            rel = idx.get(F.key_of(mb))
            minfo.append((mb, rel, scan.get(rel) if rel else None))
        mby = {F.key_of(mb): r for mb, rel, r in minfo}
        mused = []
        for e in ents:
            m = e.get(b'material', b'')
            if m.strip():
                mused.extend(x.strip() for x in m.split(b';') if x.strip())
            elif e.get(b'file', b'').strip():
                r = mby.get(F.key_of(F.base_of(e[b'file'])))
                if r and r[9]:
                    mused.extend(x for x in r[9].get('mats', ()) if x)
        for ml in o['matlist']:
            if ml.get(b'material', b'').strip():
                mused.append(ml[b'material'].strip())
        mused = list(dict.fromkeys(mused))
        mat_undef = [m for m in mused if m not in mats and m not in BUILTIN_MATS]
        texs = []
        for m in mused:
            texs.extend(F.material_textures(m, mats, tcache))
        texs = list(dict.fromkeys(texs))
        tinfo = []
        for t in texs:
            rel = idx.get(F.key_of(F.base_of(t)))
            tinfo.append((t, rel, scan.get(rel) if rel else None))
        skl = list(dict.fromkeys(r[9]['skel'] for mb, rel, r in minfo if r and r[9] and r[9].get('skel')))
        sinfo = []
        for s in skl:
            rel = idx.get(F.key_of(F.base_of(s)))
            sinfo.append((s, rel, scan.get(rel) if rel else None))
        xs = o['skeletons']
        xs_found = 0
        anims_extra = 0
        for s, an in xs:
            if idx.get(F.key_of(F.base_of(s))):
                xs_found += 1
            anims_extra += len(an.split())
        effects = list(dict.fromkeys(o['effects']))
        fx_undef = [e for e in effects if e not in fxdefs]
        found_m = [(mb, rel, r) for mb, rel, r in minfo if r and r[9] is not None]
        verts = sum(r[9]['verts'] for mb, rel, r in found_m)
        tris = sum(r[9]['tris'] for mb, rel, r in found_m)
        subs = sum(r[9]['subs'] for mb, rel, r in found_m)
        mbones = max([r[9]['bones'] for mb, rel, r in found_m] or [0])
        idx32 = any(r[9]['idx32'] for mb, rel, r in found_m)
        found_s = [r for s, rel, r in sinfo if r and r[9] is not None]
        sk_bones = max([r[9]['bones'] for r in found_s] or [0])
        anims_base = sum(r[9]['anims'] for r in found_s)
        found_t = [(t, rel, r) for t, rel, r in tinfo if r]
        tex_bytes = sum(max(0, r[4]) for t, rel, r in found_t)     # content length (padding excluded)
        maxpx = 0
        fmts = set()
        for t, rel, r in found_t:
            if r[9]:
                maxpx = max(maxpx, r[9].get('w', 0) or 0, r[9].get('h', 0) or 0)
                if r[9].get('fmt'):
                    fmts.add(r[9]['fmt'])
        miss = []
        nm_miss = len(minfo) - sum(1 for x in minfo if x[2])
        if nm_miss:
            miss.append('mesh-%d' % nm_miss)
        ns_miss = len(sinfo) - sum(1 for x in sinfo if x[2])
        if ns_miss:
            miss.append('skel-%d' % ns_miss)
        if mat_undef:
            miss.append('mat-%d' % len(mat_undef))
        nt_miss = len(tinfo) - len(found_t)
        if nt_miss:
            miss.append('tex-%d' % nt_miss)
        complete = 'ok' if not miss else ','.join(miss)
        stats['objects'] += 1
        stats['complete' if complete == 'ok' else 'incomplete'] += 1
        stats['missing_meshes'] += nm_miss
        stats['missing_textures'] += nt_miss
        stats['undefined_materials'] += len(mat_undef)
        stats['undefined_effects'] += len(fx_undef)
        mesh_sig = None if nm_miss or not minfo else tuple(sorted((F.key_of(mb), r[6]) for mb, rel, r in minfo))
        tex_sig = None if nt_miss else tuple(sorted((F.key_of(F.base_of(t)), r[6]) for t, rel, r in tinfo))
        texdim_sig = None if nt_miss else tuple(sorted(
            (F.key_of(F.base_of(t)), (r[9] or {}).get('w', 0), (r[9] or {}).get('h', 0), (r[9] or {}).get('fmt', ''))
            for t, rel, r in tinfo))
        matdef = sha16(sorted(m + b'\x01' + (mats[m]['sha'].encode() if m in mats else b'?') for m in mused))
        fxdef = sha16(sorted(e + b'\x01' + (fxdefs[e][0].encode() if e in fxdefs else b'?') for e in effects))
        recs[name] = {'objdef': o['sha'][:16], 'mesh_sig': mesh_sig, 'tex_sig': tex_sig, 'matdef': matdef,
                      'texdim_sig': texdim_sig,
                      'fxdef': fxdef, 'verts': verts, 'tris': tris, 'maxtex': maxpx, 'texbytes': tex_bytes,
                      'anims': anims_base + anims_extra, 'complete': complete, 'n_mesh': len(minfo)}
        rows.append((
            name, len(ents), joinb(dmesh), '%d/%d' % (len(minfo) - nm_miss, len(minfo)),
            ';'.join(str(r[1]) if r else '-' for mb, rel, r in minfo),
            ';'.join(str(r[9]['verts']) if r and r[9] else '-' for mb, rel, r in minfo),
            ';'.join(str(r[9]['subs']) if r and r[9] else '-' for mb, rel, r in minfo),
            verts, tris, subs, mbones, 'y' if idx32 else '',
            joinb(skl), '%d/%d' % (len(sinfo) - ns_miss, len(sinfo)), sk_bones, anims_base,
            len(xs), '%d/%d' % (xs_found, len(xs)), anims_extra, anims_base + anims_extra,
            joinb(mused), joinb(mat_undef), joinb(texs), '%d/%d' % (len(found_t), len(tinfo)),
            joinb([t for t, rel, r in tinfo if not r]), tex_bytes, maxpx, ','.join(sorted(fmts)),
            o['locators'], joinb(list(dict.fromkeys(o['slots']))), joinb(effects), joinb(fx_undef),
            fmt_attrs(o['attributes']), complete, o['sha'][:16], matdef, fxdef,
            ';'.join(r[6][:16] if r else '-' for mb, rel, r in minfo),
            ';'.join(rel or '-' for mb, rel, r in minfo)))
    return rows, recs, dict(stats)


MODELS_HDR = ['obj', 'entities', 'meshes', 'mesh_found', 'mesh_bytes', 'mesh_verts', 'mesh_subs',
              'verts', 'tris', 'submeshes', 'max_sub_bones', 'idx32',
              'skeletons', 'skel_found', 'skel_bones', 'anims_base', 'xskel', 'xskel_found', 'anims_extra', 'anims',
              'materials', 'mat_undef', 'textures', 'tex_found', 'tex_missing', 'tex_bytes', 'max_tex_px',
              'tex_formats', 'locators', 'slot_objs', 'effects', 'fx_undef', 'attrs', 'complete',
              'objdef_sha', 'matdef_sha', 'fxdef_sha', 'mesh_sha_content', 'mesh_relpath']


def build_models_s4(objs, mats, fxdefs, s4, s4h, scan2):
    """S4 = names only: meshes/skeletons resolved against the (list) of Model*.axp."""
    bidx = {}
    for fn in sorted((f for f in s4 if f.lower().startswith('model')), key=lambda f: folder_rank(f[:-4])):
        for r in s4[fn]['rows'] + s4[fn].get('unlisted', []):
            if r[3] < 0:
                continue
            b = r[0].replace('\\', '/').rsplit('/', 1)[-1].lower()
            bidx.setdefault(b, (fn, r))
    scan2_l = {rel.lower(): r for rel, r in scan2.items()}
    rows = []
    recs = {}
    stats = collections.Counter()
    for o in objs:
        name = F.disp(o['name'])
        ents = o['entities']
        dmesh = list(dict.fromkeys(F.base_of(e.get(b'file', b'')) for e in ents if e.get(b'file', b'').strip()))
        spec = []
        need = need_ok = found = 0
        sig = []
        for mb in dmesh:
            hit = bidx.get(F.key_of(mb))
            if not hit:
                spec.append('-')
                sig.append(None)
                continue
            fn, r = hit
            found += 1
            wrap = r[6]
            spec.append('%s:%d:%s' % (fn, r[7], 'plain' if not wrap else 'w%d' % wrap))
            sha = s4h.get(fn, {}).get(r[0], ('', ''))[0]
            sig.append((F.key_of(mb), sha) if sha else None)
            if 1 <= wrap <= 18:
                need += 1
                s2 = scan2_l.get((fn[:-4] + '\\' + r[0].replace('/', '\\')).lower())
                if s2 and s2[1] >= r[7]:
                    need_ok += 1
        xs = o['skeletons']
        xs_found = sum(1 for s, an in xs if F.base_of(s).decode('gbk', 'surrogateescape').lower() in bidx)
        anims_extra = sum(len(an.split()) for s, an in xs)
        mused = []
        for e in ents:
            m = e.get(b'material', b'')
            if m.strip():
                mused.extend(x.strip() for x in m.split(b';') if x.strip())
        for ml in o['matlist']:
            if ml.get(b'material', b'').strip():
                mused.append(ml[b'material'].strip())
        mused = list(dict.fromkeys(mused))
        effects = list(dict.fromkeys(o['effects']))
        fx_undef = [e for e in effects if e not in fxdefs]
        mesh_sig = None if (not sig or any(x is None for x in sig)) else tuple(sorted(sig))
        stats['objects'] += 1
        stats['mesh_missing_in_list'] += len(dmesh) - found
        stats['meshes_need_S2(w1-18)'] += need
        recs[name] = {'objdef': o['sha'][:16], 'mesh_sig': mesh_sig, 'need_s2': need, 'found': found,
                      'n_mesh': len(dmesh)}
        rows.append((name, len(ents), joinb(dmesh), '%d/%d' % (found, len(dmesh)), ';'.join(spec), need,
                     '%d/%d' % (need_ok, need), len(xs), '%d/%d' % (xs_found, len(xs)), anims_extra,
                     joinb(mused), joinb([m for m in mused if m not in mats and m not in BUILTIN_MATS]), o['locators'],
                     joinb(list(dict.fromkeys(o['slots']))), joinb(effects), joinb(fx_undef),
                     fmt_attrs(o['attributes']), o['sha'][:16],
                     ';'.join(x[1][:16] if x else '-' for x in sig)))
    return rows, recs, dict(stats)


MODELS4_HDR = ['obj', 'entities', 'meshes', 'mesh_found_s4', 'mesh_s4(archive:payload_len:wrapper)',
               'need_s2(w1-18)', 'need_s2_present_in_S2', 'xskel', 'xskel_found_s4', 'anims_extra',
               'materials(obj-level)', 'mat_undef', 'locators', 'slot_objs', 'effects', 'fx_undef', 'attrs',
               'objdef_sha', 'mesh_sha_payload']


# ------------------------------------------------------------------ cross tables
def grouping(present, sig):
    g = collections.OrderedDict()
    unk = []
    for S in present:
        v = sig(S)
        if v is None:
            unk.append(S)
        else:
            g.setdefault(v, []).append(S)
    txt = '|'.join('='.join(v) for v in g.values())
    if unk:
        txt += (' ' if txt else '') + ' '.join(u + '?' for u in unk)
    if len(present) <= 1:
        st = 'single'
    elif len(g) == 1 and not unk:
        st = 'same'
    elif len(g) > 1:
        st = 'diff'
    elif len(g) == 1:
        st = 'partial'
    else:
        st = 'unknown'
    return st, txt


def hint_for(name, present, recs):
    if not present:
        return 'S4 only'
    if len(present) == 1:
        return 'only ' + present[0]
    R = {S: recs[S][name] for S in present}

    def content(S):
        return (R[S]['mesh_sig'], R[S]['tex_sig'])
    if len({content(S) for S in present}) == 1 and None not in content(present[0]):
        return 'identical content'
    labels = ('complete', 'max_tex_px', 'tex_bytes', 'verts', 'anims')

    def k(S):
        return (R[S]['complete'] == 'ok', R[S]['maxtex'], R[S]['texbytes'], R[S]['verts'], R[S]['anims'])
    best = max(present, key=lambda S: (k(S), -TIE_ORDER.index(S)))
    same = [S for S in present if S != best and None not in content(S) and content(S) == content(best)]
    others = [S for S in present if S != best and S not in same]
    head = best + ''.join('=' + S for S in same)
    if not others:
        return head + ' (identical)'
    second = max(others, key=lambda S: (k(S), -TIE_ORDER.index(S)))
    kb, ks = k(best), k(second)
    for i, lab in enumerate(labels):
        if kb[i] != ks[i]:
            return '%s (%s %s>%s %s)' % (head, lab, kb[i], ks[i], second)
    if (R[best]['mesh_sig'] is not None and R[best]['mesh_sig'] == R[second]['mesh_sig']
            and R[best]['texdim_sig'] is not None and R[best]['texdim_sig'] == R[second]['texdim_sig']):
        return '%s (same mesh and texture sizes; %s textures re-encoded)' % (head, second)
    return '%s (metrics tie with %s)' % (head, second)


def build_cross(recs):
    names = set()
    for S in recs:
        names.update(recs[S].keys())
    rows = []
    st = collections.Counter()
    for name in sorted(names):
        present = [S for S in ALL if S in recs and name in recs[S]]
        p3 = [S for S in present if S != 'S4']
        o_st, o_g = grouping(present, lambda S: recs[S][name]['objdef'])
        m_st, m_g = grouping(present, lambda S: recs[S][name]['mesh_sig'])
        t_st, t_g = grouping(p3, lambda S: recs[S][name]['tex_sig'])
        d_st, d_g = grouping(p3, lambda S: recs[S][name]['texdim_sig'])
        a_st, a_g = grouping(p3, lambda S: recs[S][name]['matdef'])
        vals = []
        for key in ('verts', 'maxtex', 'texbytes', 'anims', 'complete'):
            for S in LOOSE:
                vals.append(recs[S][name][key] if S in recs and name in recs[S] else '')
        s4 = recs.get('S4', {}).get(name)
        tag = ''.join(S[1] for S in present)
        st['in:' + tag] += 1
        if len(p3) >= 2:
            st['S1-S3 multi-source'] += 1
            st['mesh ' + m_st] += 1
            st['tex ' + t_st] += 1
            st['tex_dims ' + d_st] += 1
            if t_st == 'diff' and d_st == 'same':
                st['tex bytes differ but same WxH/format (re-encoded)'] += 1
        rows.append([name, ','.join(present), len(present), o_st, o_g, m_st, m_g, t_st, t_g, d_st, d_g, a_st, a_g] +
                    vals + ['y' if s4 else '', s4['need_s2'] if s4 else '', hint_for(name, p3, recs)])
    hdr = ['obj', 'sources', 'n_src', 'objdef', 'objdef_groups', 'mesh', 'mesh_groups', 'tex', 'tex_groups',
           'tex_dims', 'tex_dims_groups', 'matdef', 'matdef_groups']
    for key in ('verts', 'max_tex_px', 'tex_bytes', 'anims', 'complete'):
        hdr += ['%s_%s' % (key, S) for S in LOOSE]
    hdr += ['in_S4', 'S4_need_s2(w1-18)', 'hint']
    return hdr, rows, st


def build_effects_cross(defs):
    srcs = [S for S in ALL if S in defs]
    rows = []
    st = collections.Counter()
    for kind in ('effect', 'particle', 'skill'):
        names = set()
        for S in srcs:
            names.update(defs[S][kind].keys())
        for nm in sorted(names, key=F.disp):
            present = [S for S in srcs if nm in defs[S][kind]]
            status, grp = grouping(present, lambda S: defs[S][kind][nm][0])
            tag = ''.join(S[1] for S in present)
            st['%s %s' % (kind, status)] += 1
            if status == 'single':
                st['%s only-%s' % (kind, present[0])] += 1
            rows.append([kind, F.disp(nm), tag, len(present), status, grp] +
                        [defs[S][kind][nm][0][:12] if nm in defs[S][kind] else '' for S in srcs])
    return ['kind', 'name', 'in', 'n_src', 'status', 'groups'] + ['sha_%s' % S for S in srcs], rows, st


# ------------------------------------------------------------------ S2 vs S4
def build_s2_vs_s4(s4, s4h, files2, scan2):
    by_lower = {rel.lower(): rel for rel, size, mt in files2}
    rows = []
    st = collections.Counter()
    ext_st = collections.Counter()
    delta_hist = collections.Counter()
    missing_in_s2 = []
    matched = set()
    for fn in sorted(s4):
        top = fn[:-4]
        for listed, rr in ((True, s4[fn]['rows']), (False, s4[fn].get('unlisted', []))):
            for r in rr:
                nm, lsz, chk, off, size, flags, wrap, plen = r
                if off < 0:
                    st['s4 listed but not in hash table'] += 1
                    continue
                rel_l = (top + '\\' + nm.replace('/', '\\')).lower()
                rel = by_lower.get(rel_l)
                if rel is None:
                    missing_in_s2.append('%s:%s' % (fn, nm))
                    st['S4 entry missing in S2'] += 1
                    continue
                matched.add(rel)
                s2 = scan2.get(rel)
                if s2 is None:
                    continue
                ext = ext_of(rel)
                s2size = s2[1]
                delta = s2size - plen
                sha4, magic4 = s4h.get(fn, {}).get(nm, ('', ''))
                if wrap and wrap < 19:
                    verify = 'n/a(w1-18)'
                elif not sha4:
                    verify = 'n/a'
                elif delta < 0:
                    verify = 'DIFF'
                else:
                    verify = 'same' if s2[7] == sha4 else 'DIFF'
                ctail = s2[8] if delta > 0 else ''
                fmt_known = s2[9] is not None and ext in ('.mesh', '.skeleton', '.dds', '.png', '.jpg')
                fmt_eq = ('y' if s2[4] == plen else 'n') if fmt_known else ''
                if magic4 == 'DBC' and ext in ('.txt', '.tab'):
                    action = 'format-differs(S4 DBC, S2 text)'
                elif verify == 'DIFF':
                    action = 'content-differs' + ('(S2 shorter)' if delta < 0 else '')
                elif delta == 0:
                    action = 'ok' if verify == 'same' else 'ok(size)'
                elif delta > 0:
                    action = ('trim' if verify == 'same' else 'trim-unverified') + '-' + (ctail or '?') + '-tail'
                else:
                    action = 'S2-shorter-unverified'
                st[action] += 1
                if delta > 0 and action.startswith('trim'):
                    delta_hist[delta if delta <= 16 else '>16'] += 1
                    ext_st['%s %s' % (ext, ctail)] += 1
                    if fmt_known:
                        st['check: padded file, format-derived length == S4 payload length' if fmt_eq == 'y'
                           else 'check: padded file, format-derived length != S4 payload length'] += 1
                rows.append((fn, nm, 'listed' if listed else 'unlisted', lsz, 'plain' if not wrap else 'w%d' % wrap,
                             plen, rel, s2size, delta, ctail, s2[4] if fmt_known else '', fmt_eq, verify, action,
                             magic4, s2[7][:16] if s2[7] else ''))
    s2_only = [rel for rel, size, mt in files2 if rel not in matched]
    hdr = ['archive', 'name', 'in_list', 's4_list_size', 's4_wrapper', 's4_payload_len', 's2_relpath', 's2_size',
           'delta', 's2_tail', 's2_fmt_len', 'fmt_len_eq_payload', 'verify', 'action', 's4_magic',
           'sha256_s2_trimmed']
    return hdr, rows, st, delta_hist, ext_st, missing_in_s2, s2_only


def write_s2s4_summary(path, st, delta_hist, ext_st, missing, s2_only, nrows, s4, s4h, unl):
    L = []
    w = L.append
    w('S2 (DataCY31-08-26) vs S4 (CY Game 3.71.9609 AXP) - generated %s by index_sources.py %s' % (
        datetime.datetime.now().strftime('%Y-%m-%d %H:%M'), TOOL_VERSION))
    w('')
    w('Rule: S4 payload length = (list) size - 96 for wrapped entries (header), = (list) size for plain ones.')
    w('verify = sha256(S2[:payload_len]) == sha256(decrypted S4 payload); wrapper types 1-18 cannot be')
    w('decrypted (only S2 has those files) -> size check only. No source file was modified.')
    w('')
    w('pairs present in both: %d' % nrows)
    for k, v in sorted(st.items(), key=lambda x: (-x[1], x[0])):
        w('  %-58s %d' % (k, v))
    w('')
    w('padding (S2 size - payload length) histogram: %s' % dict(sorted(delta_hist.items(), key=lambda x: str(x[0]))))
    w('padded files by extension and tail kind:')
    for k, v in sorted(ext_st.items(), key=lambda x: -x[1]):
        w('  %-30s %d' % (k, v))
    w('')
    w('S2 names not in any (list) but found in the AXP hash table (unlisted entries): %d' % unl)
    w('S4 entries missing in S2: %d' % len(missing))
    for x in missing[:200]:
        w('  ' + x)
    w('S2 files without S4 entry: %d' % len(s2_only))
    top = collections.Counter(r.split('\\', 1)[0] for r in s2_only)
    w('  by top folder: %s' % dict(top.most_common()))
    for x in s2_only[:100]:
        w('  ' + x)
    with open(path, 'w', encoding='utf-8-sig', newline='\n') as f:
        f.write('\n'.join(L) + '\n')
    log('  wrote', os.path.basename(path))


# ------------------------------------------------------------------ main
def main():
    global LOGF
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--out', default=OUT_DEFAULT)
    ap.add_argument('--jobs', type=int, default=min(24, os.cpu_count() or 4))
    ap.add_argument('--rescan', action='store_true', help='ignore the scan caches')
    ap.add_argument('--skip-s4-verify', action='store_true', help='do not read S4 payloads (no content verify)')
    args = ap.parse_args()
    out = os.path.abspath(args.out)
    if not out.lower().startswith(os.path.join(CYS, 'Assets', 'Staging').lower()):
        sys.exit('refusing to write outside CY-Source\\Assets\\Staging: ' + out)
    os.makedirs(out, exist_ok=True)
    LOGF = open(os.path.join(out, 'index_sources.log'), 'a', encoding='utf-8')
    T = {}
    t_all = time.time()
    summary = {'tool': 'index_sources.py ' + TOOL_VERSION, 'started': datetime.datetime.now().isoformat(timespec='seconds'),
               'jobs': args.jobs, 'python': sys.version.split()[0],
               'sources': {S: SOURCES[S]['root'] for S in LOOSE}, 's4_dir': S4_DIR}
    log('=== index_sources %s  out=%s jobs=%d' % (TOOL_VERSION, out, args.jobs))

    t = time.time()
    walked = {S: walk(SOURCES[S]['root'], SOURCES[S]['exclude']) for S in LOOSE}
    for S in LOOSE:
        log('walk %s: %d files, %.2f GB' % (S, len(walked[S]), sum(x[1] for x in walked[S]) / 1e9))
    T['walk'] = round(time.time() - t, 1)

    t = time.time()
    s4 = s4_index(out, args.rescan)
    cand, unl = s4_unlisted(s4, walked['S2'])
    save_cache(out, 's4index', dict(s4))
    canon = s4_canon_map(s4)
    log('s4 index: %d archives, %d listed rows, %d S2-only names checked, %d unlisted entries found' % (
        len(s4), sum(len(a['rows']) for a in s4.values()), cand, unl))
    T['s4_index'] = round(time.time() - t, 1)

    t = time.time()
    scan = scan_sources(out, walked, canon, args.jobs, args.rescan)
    T['scan'] = round(time.time() - t, 1)

    t = time.time()
    s4h = {} if args.skip_s4_verify else s4_hashes(out, s4, args.jobs, args.rescan)
    T['s4_verify'] = round(time.time() - t, 1)

    t = time.time()
    summary['files'] = {}
    for S in LOOSE:
        stats, tails = write_sha(out, S, walked[S], scan[S])
        summary['files'][S] = {'stats': stats, 'trailing_tails(ext kind: files)': tails}

    # scripts
    defs = {}
    parse_stats = {}
    mats = {}
    objs = {}
    for S in LOOSE:
        defs[S] = {}
        parse_stats[S] = {}
        for kind in ('effect', 'particle', 'skill'):
            defs[S][kind], parse_stats[S][kind] = F.script_defs(read_src(S, kind), kind)
        mats[S], parse_stats[S]['material'] = F.material_defs(read_src(S, 'material'))
        objs[S], parse_stats[S]['obj'] = F.parse_all_obj(read_src(S, 'obj'))
    defs['S4'] = {}
    parse_stats['S4'] = {}
    for kind in ('effect', 'particle', 'skill'):
        defs['S4'][kind], parse_stats['S4'][kind] = F.script_defs(read_s4('Effect.axp', '.' + kind), kind)
    mats['S4'], parse_stats['S4']['material'] = F.material_defs(read_s4('Material.axp', '.material'))
    objs['S4'], parse_stats['S4']['obj'] = F.parse_all_obj(read_s4('Model.axp', 'all.obj'))
    summary['script_parse'] = parse_stats
    for S in ALL:
        log('parse %s: %s' % (S, {k: (v.get('defs') or v.get('materials') or v.get('objects'), v.get('stray'), v.get('dup'))
                                   for k, v in parse_stats[S].items()}))

    recs = {}
    summary['models'] = {}
    for S in LOOSE:
        idx, dup = name_index(S, walked[S])
        rows, recs[S], mst = build_models(S, objs[S], mats[S], defs[S]['effect'], idx, scan[S])
        mst['duplicate_basenames_in_source'] = dup
        summary['models'][S] = mst
        write_tsv(os.path.join(out, 'models_%s.tsv' % S), MODELS_HDR, rows)
    rows, recs['S4'], mst = build_models_s4(objs['S4'], mats['S4'], defs['S4']['effect'], s4, s4h, scan['S2'])
    summary['models']['S4'] = mst
    write_tsv(os.path.join(out, 'models_S4.tsv'), MODELS4_HDR, rows)

    hdr, rows, cst = build_cross(recs)
    write_tsv(os.path.join(out, 'models_cross.tsv'), hdr, rows)
    summary['models_cross'] = dict(sorted(cst.items()))

    hdr, rows, est = build_effects_cross(defs)
    write_tsv(os.path.join(out, 'effects_cross.tsv'), hdr, rows)
    summary['effects_cross'] = dict(sorted(est.items()))

    if s4h:
        hdr, rows, st, dh, ext_st, missing, s2_only = build_s2_vs_s4(s4, s4h, walked['S2'], scan['S2'])
        n = write_tsv(os.path.join(out, 's2_vs_s4_lengths.tsv'), hdr, rows)
        write_s2s4_summary(os.path.join(out, 's2_vs_s4_summary.txt'), st, dh, ext_st, missing, s2_only, n, s4, s4h, unl)
        summary['s2_vs_s4'] = {'pairs': n, 'actions': dict(st), 'delta_hist': {str(k): v for k, v in dh.items()},
                               'padded_by_ext_tail': dict(ext_st), 'S4_missing_in_S2': len(missing),
                               'S2_without_S4_entry': len(s2_only), 'unlisted_S4_entries_matched': unl}
    summary['s4_archives'] = {fn: {'entries': a['count'], 'used': a['used'], 'listed': len(a['rows']),
                                   'unlisted_found': len(a.get('unlisted', [])),
                                   'wrappers': dict(collections.Counter('plain' if not r[6] else ('w1-18' if r[6] <= 18 else 'w19-25')
                                                                        for r in a['rows'] if r[3] >= 0))}
                              for fn, a in s4.items()}
    T['outputs'] = round(time.time() - t, 1)
    T['total'] = round(time.time() - t_all, 1)
    summary['timings_s'] = T
    summary['finished'] = datetime.datetime.now().isoformat(timespec='seconds')
    with open(os.path.join(out, 'index_summary.json'), 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=1, default=str)
    log('done in %.1fs  timings=%s' % (T['total'], T))
    LOGF.close()


if __name__ == '__main__':
    main()
