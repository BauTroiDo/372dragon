#!/usr/bin/env python3
"""run_protocol_tests.py - gate G1 for the generated C++ codecs (Src/Shared/ProtocolGen).

1. capture: every frame of the Aug-27 BotDemo capture (Tools/stress-test/_capture/capture.jsonl, TCP
   streams reassembled exactly like Tools/protocol/validate_capture.py) -> PGFRAME1 file.  GATE: every
   frame must decode strictly and re-encode byte-identically.
2. oracle:  for every packet, bodies produced by walking the spec with the reference decoder
   speccodec.py over a biased random byte source; a body is kept only if speccodec then decodes it
   exactly.  Mismatches are allowed only for the packets in KNOWN_ORACLE_DEVIATIONS (hand-checked
   codegen rules, or speccodec bugs where the C++ follows the server's Lua).
3. cys_protocol_tests: round trip of both sets, fuzzers (truncate / extend / mutate / cross-id /
   random: nothing may crash, whatever decodes must re-encode exactly), API unit tests.
4. Every fuzz input the C++ accepted is decoded again by speccodec (bidirectional differential).
5. Optional (--asan): the same run with the AddressSanitizer build (Build/cmake/protocol-x64/asan).

Frame files are written to the build tree (they contain bot-account login data); reports go to
Build/Logs/2026-09-12-protocol (gate_summary.txt, roundtrip_report.tsv, fuzz_oracle_check.tsv ...).

Usage: run_protocol_tests.py [--exe PATH] [--capture PATH] [--samples N] [--fuzz N] [--seed S] [--asan]
"""
import argparse
import collections
import csv
import os
import random
import re
import struct
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
CY = os.path.abspath(os.path.join(HERE, '..', '..'))
PROTO_TOOLS = os.path.join(CY, 'Tools', 'protocol')
sys.path.insert(0, PROTO_TOOLS)
import speccodec  # noqa: E402
import validate_capture  # noqa: E402

BUILD = os.path.join(CY, 'Build', 'cmake', 'protocol-x64')
EXE = os.path.join(BUILD, 'bin', 'cys_protocol_tests.exe')
ASAN_EXE = os.path.join(BUILD, 'asan', 'bin', 'cys_protocol_tests.exe')
ASAN_DLL_DIR = r'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64'
DATA = os.path.join(BUILD, 'test-data')
LOGS = os.path.join(CY, 'Build', 'Logs', '2026-09-12-protocol')
C2S = {'CG', 'CL', 'CGW'}

# Packets whose C++ decoding intentionally differs from speccodec. Evidence: codegen_cpp_rules.py and the
# live Lua (read-only, 2026-09-12).
KNOWN_ORACLE_DEVIATIONS = {
    'GCBankAcquireList': 'rule: every used_space slot is present (the bis reads them all); speccodec: bank_items[i] = nil',
    'GCPetBankListUPData': 'rule (annotations.py): pet i present when bit i-1 of flag is set; speccodec: pet_list[i] = nil',
    'GCDetailEquipList': 'rule: item i present when its m_wPartFlags bit is set (i = 0..83); speccodec: itemList[i] = nil',
    'GCAuctionBoxList': 'rule: pet slots use flag bits 10..14 (for i = 11, 15); speccodec counts i from 1',
    'GCUICommand': 'rule: string block = last m_aStrOffset + 1 bytes; speccodec cannot size $len',
    'GCPlayerShopRecordList': 'rule: entry count = the #entrys byte; speccodec cannot evaluate the loop bounds',
    # GCBBSMessages / GCRelation (wire booleans) and GCScriptCommand (#event[i].str) used to be listed here;
    # speccodec.py was fixed on 2026-09-12 (WireBool, indexed # names), so they must now agree.
}


def frame_record(proto, c2s, expect_ok, xid, idx, body):
    flags = (1 if c2s else 0) | (2 if expect_ok else 0)
    return struct.pack('<BBHHI', 1 if proto == 'login' else 0, flags, xid, idx, len(body)) + body


def write_frames(path, records):
    with open(path, 'wb') as f:
        f.write(b'PGFRAME1')
        for r in records:
            f.write(r)


def read_frames(path):
    out = []
    with open(path, 'rb') as f:
        if f.read(8) != b'PGFRAME1':
            raise ValueError('bad frame file %s' % path)
        while True:
            h = f.read(10)
            if len(h) < 10:
                break
            proto, flags, xid, idx, ln = struct.unpack('<BBHHI', h)
            out.append(('login' if proto else 'game', flags, xid, idx, f.read(ln)))
    return out


# ------------------------------------------------------------------ capture
def export_capture(cap, path):
    recs, ids = [], set()
    for key, buf in validate_capture.reassemble(cap):
        proto = 'login' if 5733 in (key[1], key[3]) else 'game'
        c2s = key[3] in (5733, 5734)
        for xid, idx, body in validate_capture.frames(buf):
            recs.append(frame_record(proto, c2s, True, xid, idx, body))
            ids.add((proto, xid))
    write_frames(path, recs)
    return len(recs), len(ids)


# ------------------------------------------------------------------ oracle corpus
class TooBig(Exception):
    pass


class RandReader(object):
    """Stands in for speccodec._R: every take(n) invents n bytes (small integers, condition constants,
    printable text) so that speccodec's decoder walks the spec and records a consistent body."""

    def __init__(self, rng, consts):
        self.rng, self.consts, self.buf, self.pos = rng, consts, bytearray(), 0

    def take(self, n):
        if n < 0:
            raise speccodec.DecodeError('negative length')
        if self.pos + n > 20000:
            raise TooBig()
        b = self.make(n)
        self.buf += b
        self.pos += n
        return bytes(b)

    def make(self, n):
        rng = self.rng
        r = rng.random()
        if n in (1, 2, 4, 8):
            if r < 0.45:
                v = rng.randint(0, 12)
            elif r < 0.75 and self.consts:
                v = rng.choice(self.consts)
            elif r < 0.9:
                v = rng.randint(0, 255 if n == 1 else 0xFFFF)
            else:
                return bytes(rng.getrandbits(8) for _ in range(n))
            return (v & ((1 << (8 * n)) - 1)).to_bytes(n, 'little')
        if r < 0.6:
            return bytes(rng.randint(0x20, 0x7E) for _ in range(n))
        if r < 0.8:
            return bytes(n)
        return bytes(rng.getrandbits(8) for _ in range(n))


def condition_constants(p):
    out = set()

    def walk(fields):
        for n in fields:
            if n.get('kind') == 'if':
                for b in n['branches']:
                    for m in re.findall(r'0[xX][0-9a-fA-F]+|\b\d+\b', b['when']):
                        out.add(int(m, 0))
                    walk(b['fields'])
            elif 'fields' in n:
                walk(n['fields'])
    walk(p['fields'])
    return sorted(v for v in out if v < 1 << 32)


def oracle_corpus(spec, samples, seed, path):
    rng = random.Random(seed)
    orig_count = spec._count

    def capped(n, env):
        c = orig_count(n, env)
        if c > 3000:
            raise TooBig()
        return c
    spec._count = capped
    recs, stats = [], collections.OrderedDict()
    try:
        for p in spec.doc['packets']:
            consts = condition_constants(p)
            got, tries, seen = 0, 0, set()
            while got < samples and tries < samples * 8:
                tries += 1
                rd = RandReader(rng, consts)
                env = speccodec.Env()
                env.vars['#__body__'] = 1 << 20
                spec._derive = speccodec.DERIVE.get(p.get('derive'))
                try:
                    spec._dec(p['fields'], env, rd)
                except (speccodec.DecodeError, TooBig, RecursionError, TypeError, ValueError, OverflowError,
                        ZeroDivisionError, IndexError, KeyError, AttributeError):
                    continue
                finally:
                    spec._derive = None
                body = bytes(rd.buf)
                if len(body) > 65535 or body in seen:
                    continue
                try:
                    _, used = spec.decode(p, body)
                except Exception:
                    continue
                if used != len(body):
                    continue
                seen.add(body)
                # informational frames: the verdict is computed here against KNOWN_ORACLE_DEVIATIONS
                recs.append(frame_record(p['proto'], p['dir'] in C2S, False, p['id'], 0, body))
                got += 1
            stats[p['name']] = (got, tries)
    finally:
        spec._count = orig_count
    write_frames(path, recs)
    return recs, stats


# ------------------------------------------------------------------ oracle check of fuzz inputs
def oracle_check(spec, path):
    res = collections.defaultdict(collections.Counter)
    for proto, flags, xid, idx, body in read_frames(path):
        p = spec.packet(xid, proto)
        name = p['name'] if p else '?'
        try:
            _, used = spec.decode(p, body)
            st = 'agree' if used == len(body) else 'oracle_trailing'
        except speccodec.Unsupported:
            st = 'oracle_unsupported'
        except Exception:
            st = 'oracle_rejects'
        res[name][st] += 1
    return res


def run_exe(exe, args, log_path, env=None):
    proc = subprocess.run([exe] + args, capture_output=True, text=True, encoding='utf-8', errors='replace', env=env)
    with open(log_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(proc.stdout)
        f.write(proc.stderr)
    return proc


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--exe', default=EXE)
    ap.add_argument('--capture', default=validate_capture.DEFAULT_CAP)
    ap.add_argument('--samples', type=int, default=24)
    ap.add_argument('--fuzz', type=int, default=300000)
    ap.add_argument('--seed', type=int, default=20260912)
    ap.add_argument('--logs', default=LOGS)
    ap.add_argument('--asan', action='store_true', help='also run the AddressSanitizer build')
    a = ap.parse_args(argv)
    os.makedirs(DATA, exist_ok=True)
    os.makedirs(a.logs, exist_ok=True)
    t0 = time.time()
    summary = []

    def say(s):
        print(s)
        summary.append(s)
    spec = speccodec.Spec()
    cap_bin = os.path.join(DATA, 'capture_frames.bin')
    ora_bin = os.path.join(DATA, 'oracle_frames.bin')
    acc_bin = os.path.join(DATA, 'fuzz_accepted.bin')
    ncap, nid = export_capture(a.capture, cap_bin)
    say('capture: %d frames, %d (proto, id) pairs from %s' % (ncap, nid, a.capture))
    recs, stats = oracle_corpus(spec, a.samples, a.seed, ora_bin)
    covered = sum(1 for v in stats.values() if v[0])
    say('oracle corpus: %d bodies for %d/%d packets (seed %d; none for: %s)' % (
        len(recs), covered, len(stats), a.seed, ' '.join(k for k, v in stats.items() if not v[0])))
    with open(os.path.join(a.logs, 'oracle_corpus_stats.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('packet\tsamples\ttries\n')
        for k, (g, t) in stats.items():
            f.write('%s\t%d\t%d\n' % (k, g, t))
    report = os.path.join(a.logs, 'roundtrip_report.tsv')
    args = ['--frames', cap_bin, '--frames', ora_bin, '--report', report, '--fuzz', str(a.fuzz), '--seed',
            str(a.seed), '--dump-accepted', acc_bin, '--unit']
    proc = run_exe(a.exe, args, os.path.join(a.logs, 'cys_protocol_tests.log'))
    print(proc.stdout[-5000:])
    for ln in proc.stdout.splitlines():
        if ln.startswith(('set ', 'fuzz ', 'unit tests', 'result')):
            summary.append('  exe> ' + ln)
    say('cys_protocol_tests exit code %d' % proc.returncode)
    unexpected = []
    capture_ok = capture_all = 0
    oracle_ok = oracle_all = 0
    known_hits = collections.Counter()
    with open(report, encoding='utf-8') as f:
        for row in csv.DictReader(f, delimiter='\t'):
            n = int(row['frames'])
            if row['set'] == 'capture_frames':
                capture_all += n
                capture_ok += n if row['status'] == 'OK' else 0
                if row['status'] != 'OK':
                    unexpected.append('capture %s id %s %s: %s %s' % (row['direction'], row['id'], row['name'],
                                                                   row['status'], row['detail']))
            elif row['set'] == 'oracle_frames':
                oracle_all += n
                if row['status'] == 'OK':
                    oracle_ok += n
                elif row['name'] in KNOWN_ORACLE_DEVIATIONS:
                    known_hits[row['name']] += n
                else:
                    unexpected.append('oracle %s id %s %s sz %s: %s %s' % (row['direction'], row['id'], row['name'],
                                                                         row['body_size'], row['status'], row['detail']))
    say('GATE capture round trip: %d/%d frames byte-identical' % (capture_ok, capture_all))
    say('oracle corpus round trip: %d/%d OK; %d mismatches in documented deviations: %s' % (
        oracle_ok, oracle_all, sum(known_hits.values()), ', '.join('%s x%d' % kv for kv in sorted(known_hits.items()))))
    for name in sorted(known_hits):
        say('    %s: %s' % (name, KNOWN_ORACLE_DEVIATIONS[name]))
    verdict = collections.Counter()
    lines = ['packet\tagree\toracle_rejects\toracle_trailing\toracle_unsupported\tknown_deviation']
    if os.path.exists(acc_bin):
        res = oracle_check(spec, acc_bin)
        for name in sorted(res):
            c = res[name]
            verdict.update(c)
            known = name in KNOWN_ORACLE_DEVIATIONS
            lines.append('%s\t%d\t%d\t%d\t%d\t%s' % (name, c['agree'], c['oracle_rejects'], c['oracle_trailing'],
                                                     c['oracle_unsupported'], 'yes' if known else ''))
            if (c['oracle_rejects'] or c['oracle_trailing']) and not known:
                unexpected.append('fuzz input accepted by C++ but not by speccodec: %s %s' % (name, dict(c)))
        with open(os.path.join(a.logs, 'fuzz_oracle_check.tsv'), 'w', encoding='utf-8', newline='\n') as f:
            f.write('\n'.join(lines) + '\n')
        say('oracle check of %d C++-accepted fuzz inputs: %s' % (sum(verdict.values()), dict(verdict)))
    if a.asan:
        if os.path.exists(ASAN_EXE):
            env = dict(os.environ)
            env['PATH'] = ASAN_DLL_DIR + os.pathsep + env.get('PATH', '')
            aproc = run_exe(ASAN_EXE, ['--frames', cap_bin, '--frames', ora_bin, '--fuzz', str(a.fuzz), '--seed',
                                       str(a.seed + 1), '--unit'], os.path.join(a.logs, 'cys_protocol_tests_asan.log'), env)
            asan_err = 'AddressSanitizer' in (aproc.stdout + aproc.stderr)
            for ln in aproc.stdout.splitlines():
                if ln.startswith(('fuzz ', 'unit tests', 'result')):
                    summary.append('  asan> ' + ln)
            say('ASan run: exit code %d, AddressSanitizer reports: %s' % (aproc.returncode, 'YES' if asan_err else 'none'))
            if aproc.returncode != 0 or asan_err:
                unexpected.append('ASan run failed (exit %d)' % aproc.returncode)
        else:
            say('ASan run skipped: %s not built' % ASAN_EXE)
    ok = proc.returncode == 0 and not unexpected and capture_ok == capture_all == ncap
    for u in unexpected[:60]:
        say('UNEXPECTED: ' + u)
    say('G1 GATE: %s (%.1f s)' % ('PASSED' if ok else 'FAILED', time.time() - t0))
    with open(os.path.join(a.logs, 'gate_summary.txt'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(summary) + '\n')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
