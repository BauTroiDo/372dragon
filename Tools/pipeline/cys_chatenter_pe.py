# -*- coding: utf-8 -*-
"""CYS-CHATENTER: doc ma cua cay SONG bang KY HIEU / CHUOI (luat 22.8), khong bang dia chi chep tay.

Khong can Ghidra. Dung `llvm-objdump` de dich nguoc, tu phan tich PE de:
  * doi ten export  -> RVA (dinh vi bang KY HIEU)
  * doi chuoi       -> moi `lea reg,[rip+disp]` tro toi no (dinh vi bang CHUOI)
  * doi RVA         -> ham chua no (bang .pdata, x64)
  * chu thich moi `call [rip+X]` bang ten import, moi `call rel32` bang ten export neu co

    python cys_chatenter_pe.py info   <pe>
    python cys_chatenter_pe.py exp    <pe> <regex>                 # liet ke export khop
    python cys_chatenter_pe.py dis    <pe> --sym <ten export>      # dich nguoc ca ham
    python cys_chatenter_pe.py dis    <pe> --rva 0x27130
    python cys_chatenter_pe.py xref   <pe> --str ClearOffset       # ham nao tham chieu chuoi
    python cys_chatenter_pe.py vtab   <pe> --sym <ten export ??_7...>  --count 80

Moi lenh in dong dau: duong dan + sha256 + kich thuoc (luat 22.8: dia chi phai kem ban dung).
"""
import argparse
import bisect
import hashlib
import os
import re
import struct
import subprocess
import sys

OBJDUMP = r"C:\Program Files\LLVM\bin\llvm-objdump.exe"
UNDNAME = r"C:\Program Files\LLVM\bin\llvm-undname.exe"


def sha256(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


class PE(object):
    def __init__(self, path):
        self.path = path
        self.data = open(path, 'rb').read()
        d = self.data
        e = struct.unpack_from('<I', d, 0x3C)[0]
        assert d[e:e + 4] == b'PE\0\0', 'khong phai PE'
        coff = e + 4
        self.machine = struct.unpack_from('<H', d, coff)[0]
        nsec = struct.unpack_from('<H', d, coff + 2)[0]
        optsz = struct.unpack_from('<H', d, coff + 16)[0]
        opt = coff + 20
        magic = struct.unpack_from('<H', d, opt)[0]
        self.is64 = magic == 0x20b
        self.base = struct.unpack_from('<Q', d, opt + 24)[0] if self.is64 else struct.unpack_from('<I', d, opt + 28)[0]
        ddir = opt + (112 if self.is64 else 96)
        self.dirs = [struct.unpack_from('<II', d, ddir + i * 8) for i in range(16)]
        so = opt + optsz
        self.secs = []
        for i in range(nsec):
            o = so + i * 40
            name = d[o:o + 8].rstrip(b'\0').decode('latin-1')
            vsize, vaddr, rsize, raddr = struct.unpack_from('<IIII', d, o + 8)
            self.secs.append((name, vaddr, vsize, raddr, rsize))
        self._exports = None
        self._imports = None
        self._pdata = None

    def rva2off(self, rva):
        for name, va, vs, ra, rs in self.secs:
            if va <= rva < va + max(vs, rs):
                if rva - va < rs:
                    return ra + (rva - va)
        return None

    def cstr(self, rva, limit=4096):
        o = self.rva2off(rva)
        if o is None:
            return None
        end = self.data.find(b'\0', o, o + limit)
        return self.data[o:end].decode('latin-1')

    def exports(self):
        if self._exports is not None:
            return self._exports
        out = {}
        rva, size = self.dirs[0]
        if rva:
            o = self.rva2off(rva)
            nfun, nname = struct.unpack_from('<II', self.data, o + 20)
            afun, aname, aord = struct.unpack_from('<III', self.data, o + 28)
            ofun, oname, oord = self.rva2off(afun), self.rva2off(aname), self.rva2off(aord)
            for i in range(nname):
                nrva = struct.unpack_from('<I', self.data, oname + i * 4)[0]
                ordi = struct.unpack_from('<H', self.data, oord + i * 2)[0]
                frva = struct.unpack_from('<I', self.data, ofun + ordi * 4)[0]
                out[self.cstr(nrva)] = frva
        self._exports = out
        return out

    def imports(self):
        """IAT slot RVA -> 'dll!name'"""
        if self._imports is not None:
            return self._imports
        out = {}
        rva, size = self.dirs[1]
        if rva:
            o = self.rva2off(rva)
            while True:
                oft, _, _, nrva, ft = struct.unpack_from('<IIIII', self.data, o)
                if not nrva and not ft:
                    break
                dll = self.cstr(nrva)
                thunk = oft or ft
                to = self.rva2off(thunk)
                step = 8 if self.is64 else 4
                i = 0
                while True:
                    v = struct.unpack_from('<Q' if self.is64 else '<I', self.data, to + i * step)[0]
                    if not v:
                        break
                    if v >> (63 if self.is64 else 31):
                        nm = 'ord#%d' % (v & 0xffff)
                    else:
                        nm = self.cstr((v & 0x7fffffff) + 2)
                    out[ft + i * step] = '%s!%s' % (dll, nm)
                    i += 1
                o += 20
        self._imports = out
        return out

    def pdata(self):
        if self._pdata is not None:
            return self._pdata
        out = []
        rva, size = self.dirs[3]
        if rva and self.is64:
            o = self.rva2off(rva)
            for i in range(size // 12):
                b, e, u = struct.unpack_from('<III', self.data, o + i * 12)
                if b:
                    out.append((b, e))
        out.sort()
        self._pdata = out
        return out

    def func_of(self, rva):
        pd = self.pdata()
        i = bisect.bisect_right(pd, (rva, 0xffffffff)) - 1
        if i >= 0 and pd[i][0] <= rva < pd[i][1]:
            return pd[i]
        return None

    def func_range(self, rva):
        """ham x64 co the gom nhieu khuc .pdata lien nhau (chained); o day lay khuc chua rva va
        noi cac khuc KE TIEP lien sat cho toi khi gap mot RVA la dau export/ham khac."""
        f = self.func_of(rva)
        if not f:
            return (rva, rva + 0x200)
        return f


def undname(names):
    if not names or not os.path.exists(UNDNAME):
        return {}
    try:
        p = subprocess.run([UNDNAME] + list(names), capture_output=True, text=True, timeout=60)
    except Exception:
        return {}
    out = {}
    cur = None
    for line in p.stdout.splitlines():
        line = line.rstrip()
        if line in names:
            cur = line
        elif cur and line:
            out[cur] = line
            cur = None
    return out


def header(pe):
    print('# %s' % pe.path)
    print('# sha256=%s size=%d image_base=0x%x %s' % (sha256(pe.path), len(pe.data), pe.base, 'x64' if pe.is64 else 'x86'))


def disassemble(pe, start_rva, stop_rva):
    rev_exp = {}
    for n, r in pe.exports().items():
        rev_exp.setdefault(r, n)
    imps = pe.imports()
    cmd = [OBJDUMP, '-d', '--no-show-raw-insn', '-M', 'intel',
           '--start-address=0x%x' % (pe.base + start_rva), '--stop-address=0x%x' % (pe.base + stop_rva), pe.path]
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    lines = []
    want = set()
    for line in p.stdout.splitlines():
        m = re.match(r'\s*([0-9a-f]+):\s+(.*)$', line)
        if not m:
            continue
        va = int(m.group(1), 16)
        ins = m.group(2).strip()
        note = ''
        mm = re.search(r'\[rip \+ 0x([0-9a-f]+)\]\s*(?:#\s*0x([0-9a-f]+))?', ins)
        tgt = None
        m2 = re.search(r'#\s*0x([0-9a-f]+)', ins)
        if m2:
            tgt = int(m2.group(1), 16) - pe.base
        if tgt is not None:
            if tgt in imps:
                note = '  ; IAT ' + imps[tgt]
                want.add(imps[tgt].split('!', 1)[1])
            elif ins.startswith('lea'):
                s = pe.cstr(tgt, 200)
                if s and len(s) >= 3 and all(32 <= ord(c) < 127 for c in s):
                    note = '  ; "%s"' % s
                elif tgt in rev_exp:
                    note = '  ; &' + rev_exp[tgt]
                    want.add(rev_exp[tgt])
        m3 = re.match(r'(call|jmp)\s+0x([0-9a-f]+)', ins)
        if m3:
            t = int(m3.group(2), 16) - pe.base
            if t in rev_exp:
                note = '  ; -> ' + rev_exp[t]
                want.add(rev_exp[t])
        lines.append((va, ins, note))
    und = undname(sorted(want))
    for va, ins, note in lines:
        if note:
            key = note.split(' ', 4)[-1].split('!')[-1].lstrip('&').strip()
            if key in und:
                note += '   {' + und[key] + '}'
        print('%x: %s%s' % (va, ins, note))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=['info', 'exp', 'dis', 'xref', 'vtab'])
    ap.add_argument('pe')
    ap.add_argument('pattern', nargs='?')
    ap.add_argument('--sym')
    ap.add_argument('--rva')
    ap.add_argument('--str', dest='text')
    ap.add_argument('--count', type=int, default=64)
    ap.add_argument('--len', dest='length')
    a = ap.parse_args()
    pe = PE(a.pe)
    header(pe)
    if a.cmd == 'info':
        for s in pe.secs:
            print('  %-8s rva=0x%x vsize=0x%x raw=0x%x rsize=0x%x' % s)
        print('  exports=%d imports=%d pdata=%d' % (len(pe.exports()), len(pe.imports()), len(pe.pdata())))
    elif a.cmd == 'exp':
        rx = re.compile(a.pattern or '.')
        names = sorted(n for n in pe.exports() if rx.search(n))
        und = undname(names)
        for n in names:
            print('0x%08x  %s   {%s}' % (pe.exports()[n], n, und.get(n, '')))
        print('# %d export khop' % len(names))
    elif a.cmd == 'dis':
        if a.sym:
            matches = [n for n in pe.exports() if n == a.sym] or [n for n in pe.exports() if a.sym in n]
            if len(matches) != 1:
                print('# --sym khop %d export: %s' % (len(matches), matches[:8]))
                return 2
            rva = pe.exports()[matches[0]]
            print('# sym %s -> rva 0x%x' % (matches[0], rva))
        else:
            rva = int(a.rva, 16)
        b, e = pe.func_range(rva)
        if a.length:
            e = b + int(a.length, 16)
        print('# ham [0x%x, 0x%x) (%d byte) theo .pdata' % (b, e, e - b))
        disassemble(pe, b, e)
    elif a.cmd == 'xref':
        needle = a.text.encode('latin-1') + b'\0'
        hits = []
        i = 0
        while True:
            i = pe.data.find(needle, i)
            if i < 0:
                break
            if i == 0 or pe.data[i - 1:i] == b'\0':
                hits.append(i)
            i += 1
        print('# chuoi "%s": %d vi tri (khop tron chuoi, co NUL hai dau)' % (a.text, len(hits)))
        text = [s for s in pe.secs if s[0] == '.text'][0]
        buf = pe.data[text[3]:text[3] + text[4]]
        for off in hits:
            rva = None
            for name, va, vs, ra, rs in pe.secs:
                if ra <= off < ra + rs:
                    rva = va + off - ra
            if rva is None:
                continue
            print('  chuoi @ rva 0x%x' % rva)
            for m in re.finditer(rb'[\x48\x4c]\x8d[\x05\x0d\x15\x1d\x25\x2d\x35\x3d]', buf):
                j = m.start()
                if j + 7 > len(buf):
                    continue
                disp = struct.unpack_from('<i', buf, j + 3)[0]
                if text[1] + j + 7 + disp == rva:
                    ins = text[1] + j
                    f = pe.func_of(ins)
                    print('    lea @ rva 0x%x  trong ham %s' % (ins, ('[0x%x,0x%x)' % f) if f else '?'))
    elif a.cmd == 'vtab':
        matches = [n for n in pe.exports() if n == a.sym] or [n for n in pe.exports() if a.sym in n]
        if len(matches) != 1:
            print('# --sym khop %d export: %s' % (len(matches), matches[:8]))
            return 2
        rva = pe.exports()[matches[0]]
        rev = {}
        for n, r in pe.exports().items():
            rev.setdefault(r, []).append(n)
        imps = pe.imports()
        o = pe.rva2off(rva)
        names = []
        rows = []
        for i in range(a.count):
            v = struct.unpack_from('<Q', pe.data, o + i * 8)[0]
            t = v - pe.base
            if not (0 < t < 0x10000000):
                break
            ns = rev.get(t, [])
            # thunk `jmp [rip+X]` toi import?
            if not ns:
                fo = pe.rva2off(t)
                if fo is not None and pe.data[fo:fo + 2] == b'\xff\x25':
                    disp = struct.unpack_from('<i', pe.data, fo + 2)[0]
                    slot = t + 6 + disp
                    if slot in imps:
                        ns = ['IAT ' + imps[slot]]
            rows.append((i, t, ns))
            names.extend(n.split('!')[-1].replace('IAT ', '') for n in ns)
        und = undname(sorted(set(names)))
        for i, t, ns in rows:
            label = ' | '.join(und.get(n.split('!')[-1], n) for n in ns) if ns else ''
            print('  [%3d] +0x%03x rva 0x%x  %s' % (i, i * 8, t, label))
    return 0


if __name__ == '__main__':
    sys.exit(main())
