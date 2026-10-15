#!/usr/bin/env python3
"""Extract the first world session of the Aug-27 capture into a PGWORLD1 fixture.

Input: the ignored PGFRAME1 file written by Tests/protocol/run_protocol_tests.py
(Build/cmake/protocol-x64/test-data/capture_frames.bin). Only the game socket of
session 1 is kept (client and server directions); every login frame, including
the bot credential and the charlogin key, is dropped. The fixture stays in the
ignored Build/cmake tree. Printed metadata never contains packet bodies.

Record: u8 c2s, u16 id, u16 idx, u32 size, body.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import struct

CY = Path(__file__).resolve().parents[2]
DEFAULT_IN = 'Build/cmake/protocol-x64/test-data/capture_frames.bin'
DEFAULT_OUT = 'Build/cmake/world-x64/test-data/world_session_1.bin'


def read_pgframe(path):
    records = []
    with open(path, 'rb') as handle:
        if handle.read(8) != b'PGFRAME1':
            raise SystemExit('input is not a PGFRAME1 capture')
        while True:
            head = handle.read(10)
            if not head:
                break
            if len(head) != 10:
                raise SystemExit('partial capture record')
            proto, flags, xid, idx, size = struct.unpack('<BBHHI', head)
            body = handle.read(size)
            if len(body) != size:
                raise SystemExit('partial capture body')
            records.append(('login' if proto else 'game', bool(flags & 1), xid, idx, body))
    return records


def first_session(records):
    """Streams are stored one after another; take the first game C2S and S2C runs."""
    runs, current = [], None
    for record in records:
        key = (record[0], record[1])
        if current is None or current[0] != key:
            current = [key, []]
            runs.append(current)
        current[1].append(record)
    c2s = next(run[1] for run in runs if run[0] == ('game', True))
    s2c = next(run[1] for run in runs if run[0] == ('game', False))
    if c2s[0][2] != 49 or s2c[0][2] != 67 or s2c[1][2] != 456 or s2c[2][2] != 1764:
        raise SystemExit('unexpected first world session shape')
    return c2s, s2c


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', default=DEFAULT_IN)
    parser.add_argument('--out', default=DEFAULT_OUT)
    args = parser.parse_args()
    source = (CY / args.input).resolve()
    target = Path(os.path.abspath(CY / args.out))
    if not source.is_relative_to(CY / 'Build') or not target.is_relative_to(CY / 'Build' / 'cmake'):
        raise SystemExit('fixture paths must stay in the ignored Build tree')
    for path in [target, *target.parents]:
        if path.exists() and (path.is_symlink() or path.is_junction()):
            raise SystemExit('fixture path must not traverse a junction')
    c2s, s2c = first_session(read_pgframe(source))
    target.parent.mkdir(parents=True, exist_ok=True)
    blob = bytearray(b'PGWORLD1')
    for direction, run in ((1, c2s), (0, s2c)):
        for _, _, xid, idx, body in run:
            blob += struct.pack('<BHHI', direction, xid, idx, len(body)) + body
    target.write_bytes(bytes(blob))
    meta = {'fixture': str(target.relative_to(CY)).replace('\\', '/'), 'sha256': hashlib.sha256(blob).hexdigest(),
            'bytes': len(blob), 'c2s_frames': len(c2s), 's2c_frames': len(s2c),
            'first_c2s_ids': [r[2] for r in c2s[:8]], 'first_s2c_ids': [r[2] for r in s2c[:4]], 'bodies_in_report': False}
    print(json.dumps(meta))


if __name__ == '__main__':
    main()
