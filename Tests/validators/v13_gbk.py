# -*- coding: utf-8 -*-
"""V13 gbk_roundtrip - a GBK script file differs from its base only inside the recorded edits
(Docs/05 muc 7, Docs/08 muc 1.2: all.* files are GBK and are edited at byte level only).

Input: base bytes (S1), edited bytes (Canonical) and the edit list written by the builder:
  {'op': 'replace' | 'insert', 'kind': 'obj'|'material'|'effect'|'particle', 'name_hex': hex of the GBK name,
   's1_start': int, 's1_end': int, 'old_sha256': sha256(base[s1_start:s1_end]), 'new_sha256': ..., 'new_len': int}
Checks: the edits do not overlap, the base still has the recorded bytes at every span, every byte outside
the edits is identical and in the same order, each replaced span really is the block of that name in the
base, and every inserted block is valid GBK that survives decode/encode unchanged.
The check is independent of the builder: it only uses offsets, hashes and small regexes.
"""
import hashlib
import re

from .common import ERROR, WARN, INFO, Report, disp

VID = 'V13'


def _sha(b):
    return hashlib.sha256(b).hexdigest()


def _block_named(kind, seg, name):
    if kind == 'obj':
        return seg.startswith(b'<Object name="' + name + b'">') and seg.endswith(b'</Object>')
    head = seg.split(b'\n', 1)[0].strip()
    if kind == 'material':
        m = re.match(rb'material\s+([^\s:]+)', head)
        return bool(m) and m.group(1) == name
    if kind == 'effect':
        m = re.match(rb'effect\s+(\S+)', head)
        return bool(m) and m.group(1) == name
    if kind == 'particle':
        t = head.split()
        return bool(t) and (t[-1] == name) and (len(t) == 1 or t[0] == b'particle_system')
    return True


def gbk_ok(b):
    try:
        return b.decode('gbk').encode('gbk') == b
    except (UnicodeDecodeError, UnicodeEncodeError):
        return False


def check(base, edited, edits, subject='', report=None):
    rep = report if report is not None else Report()
    eds = sorted(edits, key=lambda e: (e['s1_start'], e['s1_end']))
    prev_end = 0
    for e in eds:
        if e['s1_start'] < prev_end:
            rep.add(VID, ERROR, subject, 'overlapping edits at %d' % e['s1_start'])
            return rep
        prev_end = e['s1_end']
    bp = 0        # position in base
    cp = 0        # position in edited
    bad = 0
    for e in eds:
        seg = base[bp:e['s1_start']]
        if edited[cp:cp + len(seg)] != seg:
            i = next((k for k in range(len(seg)) if cp + k >= len(edited) or edited[cp + k] != seg[k]), len(seg))
            rep.add(VID, ERROR, subject, 'bytes outside the edits differ from the base at base offset %d' % (bp + i))
            bad += 1
            break
        cp += len(seg)
        old = base[e['s1_start']:e['s1_end']]
        name = bytes.fromhex(e.get('name_hex', '')) if e.get('name_hex') else b''
        if _sha(old) != e['old_sha256']:
            rep.add(VID, ERROR, subject, 'base bytes at %d..%d changed since the batch was built (%s %s)'
                    % (e['s1_start'], e['s1_end'], e['kind'], disp(name)))
            bad += 1
        if e['op'] == 'replace' and not _block_named(e['kind'], old.rstrip(b'\r\n'), name):
            rep.add(VID, ERROR, subject, 'replaced span %d..%d is not the %s block "%s" in the base'
                    % (e['s1_start'], e['s1_end'], e['kind'], disp(name)))
            bad += 1
        if e['op'] == 'insert' and e['s1_start'] != e['s1_end']:
            rep.add(VID, ERROR, subject, 'insert edit with a non-empty base span')
            bad += 1
        new = edited[cp:cp + e['new_len']]
        if len(new) != e['new_len'] or _sha(new) != e['new_sha256']:
            rep.add(VID, ERROR, subject, 'edited bytes of %s "%s" do not match the recorded hash'
                    % (e['kind'], disp(name)))
            bad += 1
            break
        if not gbk_ok(new):
            rep.add(VID, ERROR, subject, '%s "%s": new block is not clean GBK (decode/encode round trip fails)'
                    % (e['kind'], disp(name)))
            bad += 1
        cp += e['new_len']
        bp = e['s1_end']
    if not bad:
        seg = base[bp:]
        if edited[cp:] != seg:
            rep.add(VID, ERROR, subject, 'bytes after the last edit differ from the base (base offset %d)' % bp)
            bad += 1
    if not bad:
        rep.add(VID, INFO, subject, '%d edit(s); %d of %d base bytes untouched and identical' % (
            len(eds), len(base) - sum(e['s1_end'] - e['s1_start'] for e in eds), len(base)))
    return rep
