#!/usr/bin/env python3
"""CY-Source Tools/perf/sample_profile.py - flat profile of the presenting thread from the present probe sampler
(CYS_PROBE_SAMPLE=1, perf-cy 15/09/2026).

Input: a directory with probe_<pid>.samples / .modules / .csv. Window: from the end of the last load frame (> --gap ms)
plus --skip seconds to the end (or --from/--to seconds since probe load).

Output:
  - modules: self (leaf) share and inclusive share (sample has an address in the module anywhere on its stack)
  - functions: self and inclusive share, symbolized with llvm-symbolizer against --bin (directory with the same DLL/EXE
    and their PDB: the CY-Source build) or reported as module+rva for binaries without symbols (CY, drivers, system)
  - --ms-per-frame: shares converted to milliseconds of main-thread CPU per frame with the probe's median main_cyc
    (cycles / --cycles-per-ms) so CY and CY-Source can be compared in ms.
Stacks come from RtlVirtualUnwind on a copy of the thread stack (CYS_PROBE_UNWIND=0: a return-address scan, where
inclusive numbers may over-count stale return addresses); self numbers are exact samples.
--focus SUBSTR (repeatable): for the samples whose stack holds a function matching SUBSTR, its direct callees and callers.
Symbols need the same build (PE TimeDateStamp of --bin must match the loaded module); otherwise nearest export (~).
"""
import argparse
import bisect
import collections
import csv
import glob
import os
import statistics
import struct
import subprocess
import sys

LLVM = 'C:\\Program Files\\LLVM\\bin\\'
SYMBOLIZER = LLVM + 'llvm-symbolizer.exe'


_EXPORTS = {}


def exports_of(path):
    if path in _EXPORTS:
        return _EXPORTS[path]
    out = []
    if os.path.exists(path) and 'Windows' not in path:
        try:
            txt = subprocess.run([LLVM + 'llvm-readobj.exe', '--coff-exports', path], capture_output=True,
                                 text=True, timeout=120).stdout
            name = None
            for line in txt.splitlines():
                line = line.strip()
                if line.startswith('Name:'):
                    name = line[5:].strip()
                elif line.startswith('RVA:') and name:
                    out.append((int(line[4:].strip(), 16), name))
                    name = None
            if out:
                NL = chr(10)
                dem = subprocess.run([LLVM + 'llvm-cxxfilt.exe'], input=NL.join(n for _, n in out) + NL,
                                     capture_output=True, text=True, timeout=120).stdout.splitlines()
                if len(dem) == len(out):
                    out = [(r, d) for (r, _), d in zip(out, dem)]
        except Exception:  # noqa
            out = []
    out.sort()
    _EXPORTS[path] = out
    return out



def pe_stamp(path):
    try:
        with open(path, 'rb') as f:
            head = f.read(4096)
        off = struct.unpack_from('<I', head, 0x3c)[0]
        return struct.unpack_from('<I', head, off + 8)[0]
    except Exception:  # noqa
        return None


def load_modules(path):
    mods = []
    for line in open(path, encoding='utf-8', errors='replace'):
        p = line.rstrip('\n').split(' ', 2)
        if len(p) == 3:
            mods.append((int(p[0], 16), int(p[1], 16), p[2]))
    mods.sort()
    return mods


def window(d, gap, skip, t_from, t_to):
    rows = list(csv.DictReader(open(glob.glob(os.path.join(d, 'probe_*.csv'))[0])))
    t = [float(r['t_ms']) for r in rows]
    start = t[0]
    for a, b in zip(t, t[1:]):
        if b - a > gap:
            start = b
    a0 = t_from * 1000.0 if t_from is not None else start + skip * 1000.0
    a1 = t_to * 1000.0 if t_to is not None else t[-1]
    sel = [r for r in rows if a0 <= float(r['t_ms']) < a1]
    return a0, a1, sel


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('dir')
    ap.add_argument('--bin', default=r'C:\TLBB\085\CY-Source\Build\wt-perf-cy\Build\cmake\perfcy-x64\bin')
    ap.add_argument('--gap', type=float, default=1000.0)
    ap.add_argument('--skip', type=float, default=10.0)
    ap.add_argument('--from', dest='t_from', type=float)
    ap.add_argument('--to', dest='t_to', type=float)
    ap.add_argument('--top', type=int, default=40)
    ap.add_argument('--cycles-per-ms', type=float, default=2.27e6)
    ap.add_argument('--out')
    ap.add_argument('--focus', action='append', default=[], help='substring of a function: print its callees and callers')
    args = ap.parse_args()
    d = args.dir
    mods = load_modules(glob.glob(os.path.join(d, 'probe_*.modules'))[0])
    bases = [m[0] for m in mods]
    a0, a1, frames = window(d, args.gap, args.skip, args.t_from, args.t_to)
    main_ms = statistics.median(int(r['main_cyc']) / args.cycles_per_ms for r in frames) if frames else 0
    frame_ms = (a1 - a0) / len(frames) if frames else 0  # samples are wall-clock (a waiting thread is sampled too)
    fps = 1000.0 * len(frames) / (a1 - a0) if a1 > a0 else 0

    def locate(addr):
        i = bisect.bisect_right(bases, addr) - 1
        if i >= 0 and addr < mods[i][0] + mods[i][1]:
            return i, addr - mods[i][0]
        return -1, addr

    raw = open(glob.glob(os.path.join(d, 'probe_*.samples'))[0], 'rb').read()
    pos = 0
    samples = []
    while pos + 12 <= len(raw):
        tm, count = struct.unpack_from('<dI', raw, pos)
        pos += 12
        if count > 32 or pos + 8 * count > len(raw):
            break
        addrs = struct.unpack_from('<%dQ' % count, raw, pos)
        pos += 8 * count
        if a0 <= tm < a1:
            samples.append(addrs)
    n = len(samples)
    if not n:
        print('no samples in window')
        return 1
    # symbolize unique addresses of modules that exist in --bin
    uniq = collections.defaultdict(set)
    for s in samples:
        for a in s:
            mi, rva = locate(a)
            if mi >= 0:
                uniq[mi].add(rva)
    names = {}
    for mi, rvas in uniq.items():
        base_name = os.path.basename(mods[mi][2])
        obj = os.path.join(args.bin, base_name)
        rv = sorted(rvas)
        if (os.path.exists(obj) and os.path.exists(os.path.splitext(obj)[0] + '.pdb') and
                pe_stamp(obj) is not None and pe_stamp(obj) == pe_stamp(mods[mi][2])):  # the same build only
            img_base = 0x140000000 if base_name.lower().endswith('.exe') else 0x180000000
            inp = '\n'.join('0x%x' % (img_base + r) for r in rv) + '\n'
            try:
                res = subprocess.run([SYMBOLIZER, '--obj=' + obj, '--functions=short', '--no-inlines', '--demangle'],
                                     input=inp, capture_output=True, text=True, timeout=600).stdout
                blocks = res.strip('\n').split('\n\n')
                for r, blk in zip(rv, blocks):
                    fn = blk.split('\n')[0].strip()
                    names[(mi, r)] = base_name + '!' + (fn if fn and fn != '??' else '0x%x' % r)
            except Exception as e:  # noqa
                print('symbolizer failed for', base_name, e, file=sys.stderr)
        else:
            # CY / binaries without PDB: nearest exported symbol at or below the address (approximate, marked ~)
            exps = exports_of(mods[mi][2])
            if exps:
                eb = [e[0] for e in exps]
                for r in rv:
                    k = bisect.bisect_right(eb, r) - 1
                    if k >= 0 and r - exps[k][0] < 0x4000:
                        names[(mi, r)] = '%s!~%s' % (base_name, exps[k][1])
        for r in rv:
            names.setdefault((mi, r), None)

    def fname(mi, r):
        if mi < 0:
            return '?unknown'
        nm = names.get((mi, r))
        if nm:
            return nm
        base_name = os.path.basename(mods[mi][2])
        return '%s+0x%x' % (base_name, r & ~0xfff)  # page bucket for unsymbolized code

    mod_self = collections.Counter()
    mod_incl = collections.Counter()
    fn_self = collections.Counter()
    fn_incl = collections.Counter()
    for s in samples:
        mi, r = locate(s[0])
        mod_self[os.path.basename(mods[mi][2]) if mi >= 0 else '?'] += 1
        fn_self[fname(mi, r)] += 1
        seen_m, seen_f = set(), set()
        for a in s:
            mi, r = locate(a)
            m = os.path.basename(mods[mi][2]) if mi >= 0 else '?'
            f = fname(mi, r)
            if m not in seen_m:
                seen_m.add(m)
                mod_incl[m] += 1
            if f not in seen_f:
                seen_f.add(f)
                fn_incl[f] += 1
    lines = []
    lines.append('%s: window %.1f-%.1f s, %d samples, %d frames (%.1f fps), median main-thread CPU %.2f ms/frame' % (
        d, a0 / 1000, a1 / 1000, n, len(frames), fps, main_ms))
    lines.append('ms/frame = share x mean frame time %.2f ms (wall clock: waits in win32u/ntdll/driver included)' % frame_ms)
    lines.append('-- modules (self %% / incl %% / self ms / incl ms)')
    for m, c in mod_incl.most_common(25):
        lines.append('  %-34s %5.1f %5.1f %6.2f %6.2f' % (m, 100.0 * mod_self[m] / n, 100.0 * c / n, frame_ms * mod_self[m] / n,
                                                          frame_ms * c / n))
    lines.append('-- functions by self')
    for f, c in fn_self.most_common(args.top):
        lines.append('  %5.1f%% %6.2f ms  %s' % (100.0 * c / n, frame_ms * c / n, f))
    lines.append('-- functions by inclusive')
    for f, c in fn_incl.most_common(args.top * 2):
        lines.append('  %5.1f%% %6.2f ms  %s' % (100.0 * c / n, frame_ms * c / n, f))
    for foc in args.focus:
        callees = collections.Counter()
        callers = collections.Counter()
        hits = 0
        for smp in samples:
            nms = [fname(*locate(a)) for a in smp]
            idx = next((i for i, nm in enumerate(nms) if foc in nm), None)
            if idx is None:
                continue
            hits += 1
            callees[nms[idx - 1] if idx > 0 else '(self)'] += 1
            callers[nms[idx + 1] if idx + 1 < len(nms) else '(top)'] += 1
        lines.append('-- focus %s: %.1f%% %.2f ms' % (foc, 100.0 * hits / n, frame_ms * hits / n))
        for nm, c in callees.most_common(25):
            lines.append('   callee %5.1f%% %6.2f ms  %s' % (100.0 * c / n, frame_ms * c / n, nm))
        for nm, c in callers.most_common(12):
            lines.append('   caller %5.1f%% %6.2f ms  %s' % (100.0 * c / n, frame_ms * c / n, nm))
    txt = '\n'.join(lines)
    print(txt)
    if args.out:
        open(args.out, 'w', encoding='utf-8').write(txt + '\n')
    return 0


if __name__ == '__main__':
    sys.exit(main())
