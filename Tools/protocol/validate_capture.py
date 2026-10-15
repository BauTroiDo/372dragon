#!/usr/bin/env python3
"""validate_capture.py - decode every frame of a real capture with the spec
(speccodec) and check that (1) the body is consumed exactly and (2) encode(decode(body))
reproduces the body byte for byte.

Default input: C:\\TLBB\\085\\Tools\\stress-test\\_capture\\capture.jsonl (sniffer.py format).
Writes Registry/protocol/capture_validation.tsv (one row per id/direction/size).
"""
import argparse
import collections
import json
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import speccodec  # noqa: E402

DEFAULT_CAP = r'C:\TLBB\085\Tools\stress-test\_capture\capture.jsonl'
OUT = os.path.abspath(os.path.join(HERE, '..', '..', 'Registry', 'protocol', 'capture_validation.tsv'))
C2S = {'CG', 'CL', 'CGW'}


def reassemble(path):
    streams, base = collections.defaultdict(dict), {}
    for line in open(path, encoding='utf-8'):
        line = line.strip()
        if not line:
            continue
        r = json.loads(line)
        pl = bytes.fromhex(r['hex'])
        if not pl:
            continue
        key = (r['src'], r['sport'], r['dst'], r['dport'])
        base.setdefault(key, r['seq'])
        off = (r['seq'] - base[key]) & 0xFFFFFFFF
        if off > 0x7FFFFFFF:
            continue
        streams[key].setdefault(off, pl)
    for key, d in streams.items():
        buf, pos = b'', 0
        while pos in d:
            buf += d[pos]
            pos += len(d[pos])
        yield key, buf


def frames(buf):
    pos = 0
    while pos + 6 <= len(buf):
        xid, sz, idx = struct.unpack_from('<HHH', buf, pos)
        if pos + 6 + sz > len(buf):
            break
        yield xid, idx, buf[pos + 6:pos + 6 + sz]
        pos += 6 + sz


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('capture', nargs='?', default=DEFAULT_CAP)
    ap.add_argument('--spec', default=speccodec.DEFAULT_JSON)
    ap.add_argument('--out', default=OUT)
    args = ap.parse_args(argv)
    spec = speccodec.Spec(args.spec)
    agg = collections.OrderedDict()
    totals = collections.Counter()
    for key, buf in reassemble(args.capture):
        proto = 'login' if 5733 in (key[1], key[3]) else 'game'
        c2s = key[3] in (5733, 5734)
        for xid, idx, body in frames(buf):
            p = spec.packet(xid, proto)
            name = p['name'] if p else '?'
            status, detail = 'OK', ''
            if p is None:
                status = 'NO_SPEC'
            else:
                if (p['dir'] in C2S) != c2s:
                    status, detail = 'DIR_MISMATCH', 'spec says %s' % p['dir']
                else:
                    try:
                        vals, used = spec.decode(p, body)
                        if used != len(body):
                            status, detail = 'TRAILING', '%d of %d bytes decoded' % (used, len(body))
                        else:
                            again = spec.encode(p, vals)
                            if again != body:
                                i = next((k for k in range(min(len(again), len(body))) if again[k] != body[k]),
                                         min(len(again), len(body)))
                                status, detail = 'ROUNDTRIP_DIFF', 'first diff at byte %d (len %d vs %d)' % (
                                    i, len(again), len(body))
                    except speccodec.Unsupported as e:
                        status, detail = 'UNSUPPORTED', str(e)
                    except speccodec.DecodeError as e:
                        status, detail = 'DECODE_ERROR', str(e)
            k = (proto, 'C2S' if c2s else 'S2C', xid, name, len(body), status)
            if k not in agg:
                agg[k] = [0, detail]
            agg[k][0] += 1
            totals[status] += 1
    with open(args.out, 'w', encoding='utf-8', newline='\n') as f:
        f.write('proto\tdirection\tid\tname\tbody_size\tstatus\tframes\tdetail\n')
        for k, (n, detail) in agg.items():
            f.write('\t'.join(str(x) for x in k) + '\t%d\t%s\n' % (n, detail.replace('\t', ' ')))
    ids_ok = {(k[0], k[2]) for k in agg if k[5] == 'OK'}
    ids_all = {(k[0], k[2]) for k in agg}
    print('capture: %d frames, %s; ids fully OK %d/%d -> %s' % (
        sum(totals.values()), dict(totals), len(ids_ok - {(k[0], k[2]) for k in agg if k[5] != 'OK'}),
        len(ids_all), args.out))
    for k, (n, detail) in agg.items():
        if k[5] != 'OK':
            print('  %-5s %s id=%-4d %-28s sz=%-5d %-14s x%-4d %s' % (k[0], k[1], k[2], k[3], k[4], k[5], n, detail))
    return 0


if __name__ == '__main__':
    sys.exit(main())
