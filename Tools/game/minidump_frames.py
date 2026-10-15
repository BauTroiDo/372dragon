#!/usr/bin/env python3
"""CY-Source Tools/game/minidump_frames.py - read a Game.exe minidump (WXEngine TDCrashReport writes
%TEMP%\\dmpNNNN.tmp with MiniDumpNormal) without a debugger: exception record, faulting thread context,
module list and a return-address scan of the faulting thread's stack, each address printed as
module+RVA. Optionally symbolizes the addresses with llvm-symbolizer (PDBs next to the DLLs or at the
path the DLL's debug directory names).

  python -B Tools/game/minidump_frames.py DUMP [--symbolize] [--frames 40]

Pure stdlib; read-only. Only the addresses and module names are printed, never memory contents.
"""
import argparse
import os
import struct
import subprocess
import sys

STREAMS = {3: 'ThreadList', 4: 'ModuleList', 5: 'MemoryList', 6: 'Exception', 7: 'SystemInfo'}


def read_dump(path):
    data = open(path, 'rb').read()
    sig, ver, count, rva = struct.unpack_from('<4sIII', data, 0)
    if sig != b'MDMP':
        raise SystemExit('not a minidump')
    streams = {}
    for i in range(count):
        kind, size, off = struct.unpack_from('<III', data, rva + 12 * i)
        streams.setdefault(kind, []).append((off, size))
    return data, streams


def mem_ranges(data, streams):
    ranges = []
    for off, _ in streams.get(5, []):
        n = struct.unpack_from('<I', data, off)[0]
        for i in range(n):
            start, size, drva = struct.unpack_from('<QII', data, off + 4 + 16 * i)  # MINIDUMP_MEMORY_DESCRIPTOR
            ranges.append((start, size, drva))
    return ranges


def read_mem(data, ranges, addr, size):
    for start, n, drva in ranges:
        if start <= addr and addr + size <= start + n:
            return data[drva + (addr - start): drva + (addr - start) + size]
    return None


def modules(data, streams):
    out = []
    for off, _ in streams.get(4, []):
        n = struct.unpack_from('<I', data, off)[0]
        for i in range(n):
            base, size, cksum, ts, name_rva = struct.unpack_from('<QIIII', data, off + 4 + 108 * i)
            length = struct.unpack_from('<I', data, name_rva)[0]
            name = data[name_rva + 4:name_rva + 4 + length].decode('utf-16-le', 'replace')
            out.append((base, size, name))
    return out


def which(mods, addr):
    for base, size, name in mods:
        if base <= addr < base + size:
            return os.path.basename(name), addr - base, name
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('dump')
    parser.add_argument('--symbolize', action='store_true')
    parser.add_argument('--frames', type=int, default=40)
    parser.add_argument('--symbolizer', default=r'C:\Program Files\LLVM\bin\llvm-symbolizer.exe')
    args = parser.parse_args()
    data, streams = read_dump(args.dump)
    mods = modules(data, streams)
    ranges = mem_ranges(data, streams)
    print('streams:', {STREAMS.get(k, k): len(v) for k, v in streams.items()})
    print('modules:', len(mods))
    exc = streams.get(6)
    if not exc:
        raise SystemExit('no exception stream')
    off = exc[0][0]
    tid, _, code, flags, record, addr = struct.unpack_from('<IIIIQQ', data, off)
    nparams = struct.unpack_from('<I', data, off + 32)[0]
    params = struct.unpack_from('<15Q', data, off + 40)
    ctx_size, ctx_rva = struct.unpack_from('<II', data, off + 8 + 152)
    print('exception: thread=%u code=0x%08X address=0x%016X params=%s' % (tid, code, addr, [hex(p) for p in params[:nparams]]))
    hit = which(mods, addr)
    print('  at', '%s+0x%X' % (hit[0], hit[1]) if hit else 'unknown module')
    # x64 CONTEXT: Rip at 0xF8, Rsp at 0x98, Rbp at 0xA0
    ctx = data[ctx_rva:ctx_rva + ctx_size]
    rip = struct.unpack_from('<Q', ctx, 0xF8)[0]
    rsp = struct.unpack_from('<Q', ctx, 0x98)[0]
    rbp = struct.unpack_from('<Q', ctx, 0xA0)[0]
    rcx, rdx, rax, rbx = (struct.unpack_from('<Q', ctx, o)[0] for o in (0x80, 0x88, 0x78, 0x90))
    print('context: rip=0x%X rsp=0x%X rbp=0x%X rax=0x%X rbx=0x%X rcx=0x%X rdx=0x%X' % (rip, rsp, rbp, rax, rbx, rcx, rdx))
    frames = []
    hit = which(mods, rip)
    if hit:
        frames.append((rip, hit))
    # Scan the stack for return addresses inside known modules (no unwind info: candidates, in stack order).
    for i in range(0, 64 * 1024, 8):
        chunk = read_mem(data, ranges, rsp + i, 8)
        if chunk is None or len(chunk) < 8:
            break
        value = struct.unpack('<Q', chunk)[0]
        hit = which(mods, value)
        if hit and hit[1] > 0x1000:
            frames.append((value, hit))
            if len(frames) >= args.frames:
                break
    print('candidate frames (rip first, then return-address scan of the stack):')
    for value, (name, rva, full) in frames:
        print('  %s+0x%X' % (name, rva))
    if args.symbolize and os.path.isfile(args.symbolizer):
        by_module = {}
        for value, (name, rva, full) in frames:
            by_module.setdefault(full, []).append(rva)
        print('symbolized:')
        for full, rvas in by_module.items():
            if not os.path.isfile(full):
                print('  (module file missing)', full)
                continue
            proc = subprocess.run([args.symbolizer, '--obj=' + full, '--relative-address', '--functions=short',
                                   '--inlines=0'] + ['0x%X' % r for r in rvas], capture_output=True, text=True)
            lines = [l for l in proc.stdout.splitlines()]
            print('  ' + os.path.basename(full) + ':')
            for line in lines:
                if line.strip():
                    print('    ' + line)
    return 0


if __name__ == '__main__':
    sys.exit(main())
