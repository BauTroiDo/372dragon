# -*- coding: utf-8 -*-
"""V02 skeleton_parse - [Serializer_v1.10] + Fairy chunk 0x4120 (Docs/05 muc 7, Docs/08 muc 2.1-2.4).

Checks: header/version, sequential walk to the end (padding warn, unparsed data error), >= 1 bone, unique
bone handles, parents and animation tracks point to existing bones, chunk 0x4120 flags only use bits 0-2
(rotation / translation / scale), animation links listed (resolved by V03).
check_mesh_bones(): bones used by each submesh exist in the skeleton (error) and number <= 74
(MAX_SKIN_BONE_NUM of ShaderLib\\ParamNamedAuto.inc; warn, the total bone count is not limited).
"""
import struct

from .common import ERROR, WARN, INFO, PAD_MAX, Report, disp

VID = 'V02'
VERSION = b'[Serializer_v1.10]'
MAX_SKIN_BONES = 74
MAX_HANDLE = 256          # OGRE_MAX_NUM_BONES of the Ogre 1.x line


def walk_skeleton(data):
    """-> dict ver, bones {handle: name}, parents [(child, parent)], anims [(name, length)], tracks set,
    fairy (count of 0x4120 chunks), fairy_bad_flags, links [(name, (q, k))], end, err."""
    n = len(data)
    r = {'ver': b'', 'bones': {}, 'dup_handles': 0, 'parents': [], 'anims': [], 'tracks': set(), 'fairy': 0,
         'fairy_bad_flags': 0, 'keyframes': 0, 'links': [], 'end': 0, 'err': ''}
    if n < 8 or data[:2] != b'\x00\x10':
        r['err'] = 'not an Ogre skeleton (header chunk 0x1000 missing)'
        return r
    e = data.find(b'\n', 2, 80)
    if e < 0:
        r['err'] = 'no version string'
        return r
    r['ver'] = data[2:e]
    p = e + 1
    last = p
    try:
        while p + 6 <= n:
            cid, sz = struct.unpack_from('<HI', data, p)
            q = p + 6
            if cid == 0x1010:                                   # blend mode
                p = q + 2
            elif cid == 0x2000:                                 # BONE: name, u16 handle, pos, rot, [scale]
                k = data.index(b'\n', q, min(n, q + 1024))
                h = struct.unpack_from('<H', data, k + 1)[0]
                if h in r['bones']:
                    r['dup_handles'] += 1
                r['bones'][h] = data[q:k]
                p = k + 1 + 2 + 28 + (12 if sz > 36 else 0)
            elif cid == 0x3000:                                 # BONE_PARENT: child, parent
                r['parents'].append(struct.unpack_from('<HH', data, q))
                p = q + 4
            elif cid == 0x4000:                                 # ANIMATION: name, f32 length
                k = data.index(b'\n', q, min(n, q + 1024))
                r['anims'].append((data[q:k], struct.unpack_from('<f', data, k + 1)[0]))
                p = k + 1 + 4
            elif cid == 0x4010:                                 # animation base info: name, f32
                k = data.index(b'\n', q, min(n, q + 1024))
                p = k + 1 + 4
            elif cid == 0x4100:                                 # ANIMATION_TRACK: u16 bone
                r['tracks'].add(struct.unpack_from('<H', data, q)[0])
                p = q + 2
            elif cid == 0x4110:                                 # KEYFRAME: time, rot, trans, [scale]
                r['keyframes'] += 1
                p = q + 32 + (12 if sz > 38 else 0)
            elif cid == 0x4120:                                 # Fairy compact keyframes
                cnt, fl = struct.unpack_from('<HH', data, q)
                r['fairy'] += 1
                if fl & ~7 or not fl:
                    r['fairy_bad_flags'] += 1
                r['keyframes'] += cnt
                p = q + 4 + cnt * (4 + (16 if fl & 1 else 0) + (12 if fl & 2 else 0) + (12 if fl & 4 else 0))
            elif cid == 0x5000:                                 # ANIMATION_LINK: skeleton name, f32 scale
                k = data.index(b'\n', q, min(n, q + 1024))
                r['links'].append((data[q:k], (q, k)))
                p = k + 1 + 4
            else:
                break
            if p > n:
                r['err'] = 'chunk 0x%04X overruns the file' % cid
                break
            last = p
    except (ValueError, IndexError, struct.error) as ex:
        r['err'] = '%s at offset %d' % (type(ex).__name__, p)
    r['end'] = last
    return r


def check(data, subject='', report=None):
    rep = report if report is not None else Report()
    s = walk_skeleton(data)
    if s['err'] and not s['ver']:
        rep.add(VID, ERROR, subject, s['err'])
        return rep, s
    if s['ver'] != VERSION:
        rep.add(VID, ERROR, subject, 'version %s (expected %s)' % (disp(s['ver']), VERSION.decode()))
    if s['err']:
        rep.add(VID, ERROR, subject, 'parse error: ' + s['err'])
    tail = len(data) - s['end']
    if tail > 0:
        t = data[s['end']:]
        if not t.strip(b'\x00') or tail <= PAD_MAX:
            rep.add(VID, WARN, subject, '%d trailing padding byte(s)' % tail)
        else:
            rep.add(VID, ERROR, subject, '%d unparsed byte(s) after offset %d' % (tail, s['end']))
    if not s['bones']:
        rep.add(VID, ERROR, subject, 'no bone')
    if s['dup_handles']:
        rep.add(VID, ERROR, subject, '%d duplicated bone handle(s)' % s['dup_handles'])
    big = [h for h in s['bones'] if h >= MAX_HANDLE]
    if big:
        rep.add(VID, WARN, subject, 'bone handle(s) >= %d: %s' % (MAX_HANDLE, sorted(big)[:5]))
    bad_par = [(c, p) for c, p in s['parents'] if c not in s['bones'] or p not in s['bones']]
    if bad_par:
        rep.add(VID, ERROR, subject, '%d parent link(s) to missing bones, e.g. %s' % (len(bad_par), bad_par[:3]))
    bad_tr = sorted(t for t in s['tracks'] if t not in s['bones'])
    if bad_tr:
        rep.add(VID, ERROR, subject, 'animation track(s) for missing bone handle(s) %s' % bad_tr[:8])
    if s['fairy_bad_flags']:
        rep.add(VID, ERROR, subject, '%d chunk(s) 0x4120 with flags outside bits 0-2 (or 0)' % s['fairy_bad_flags'])
    rep.add(VID, INFO, subject, '%d bones, %d animations, %d chunk(s) 0x4120%s' % (
        len(s['bones']), len(s['anims']), s['fairy'],
        ', links ' + ','.join(disp(x[0]) for x in s['links']) if s['links'] else ''))
    return rep, s


def check_mesh_bones(mesh_walk, skel_walk, subject='', report=None):
    """Bones used per submesh (V01 walk) against the skeleton (V02 walk)."""
    rep = report if report is not None else Report()
    handles = set(skel_walk['bones'])
    for i, s in enumerate(mesh_walk['subs']):
        used = mesh_walk['shared_bones'] if s['shared'] else s['bones']
        if not used:
            continue
        missing = sorted(b for b in used if b not in handles)
        if missing:
            rep.add(VID, ERROR, subject, 'submesh %d uses bone handle(s) missing in the skeleton: %s'
                    % (i, missing[:8]))
        if len(used) > MAX_SKIN_BONES:
            rep.add(VID, WARN, subject, 'submesh %d uses %d bones (> %d = MAX_SKIN_BONE_NUM of the skinning shader)'
                    % (i, len(used), MAX_SKIN_BONES))
    return rep
