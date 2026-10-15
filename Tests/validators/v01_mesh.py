# -*- coding: utf-8 -*-
"""V01 mesh_parse - every .mesh reads sequentially (Docs/05 muc 7, Docs/08 muc 2.1-2.4).

Checks: Ogre header, version in {[MeshSerializer_v1.40], [MeshSerializer_v1.30]}, sequential walk to the
end of the data (container chunk sizes are wrong in the originals, so they are not trusted), at least one
submesh, every submesh has vertices, indices < vertex count, 16-bit indices only when <= 65535 vertices,
bone-assignment vertex indices in range, a POSITION element in each vertex declaration, trailing bytes
(padding = warn, unparsed data = error).
walk_mesh() is also used by V02 (bones per submesh) and V03.
"""
import array
import struct
import sys

from .common import ERROR, WARN, INFO, PAD_MAX, Report, disp

VID = 'V01'
VERSIONS = (b'[MeshSerializer_v1.40]', b'[MeshSerializer_v1.30]')
TAIL_CHUNKS = {0x8000, 0xB000, 0xC000, 0xD000, 0xE000}     # LOD, edge lists, poses, animations, extremes
SEM_POSITION, SEM_TEXCOORD = 1, 7


def _indices(data, start, count, i32):
    a = array.array('I' if i32 else 'H')
    a.frombytes(data[start:start + count * (4 if i32 else 2)])
    if sys.byteorder != 'little':
        a.byteswap()
    return a


def walk_mesh(data):
    """Sequential walk of a Fairy/Ogre .mesh.
    Returns dict: ver, subs [{mat, shared, ic, idx32, max_index, verts, op, bones set, ba, ba_vmax, decl}],
    shared_verts, shared_decl, shared_bones, skel, skel_span (q, k) of the 0x6000 string, end, err, bounds."""
    n = len(data)
    r = {'ver': b'', 'subs': [], 'shared_verts': 0, 'shared_decl': set(), 'shared_bones': set(), 'shared_ba': 0,
         'shared_ba_vmax': -1, 'skel': b'', 'skel_span': None, 'end': 0, 'err': '', 'bounds': None,
         'chunks': 0, 'tails': []}
    if n < 8 or data[:2] != b'\x00\x10':
        r['err'] = 'not an Ogre mesh (header chunk 0x1000 missing)'
        return r
    e = data.find(b'\n', 2, 80)
    if e < 0:
        r['err'] = 'no version string'
        return r
    r['ver'] = data[2:e]
    p = e + 1
    last = p
    sub = None
    decl_target = None
    vc = 0
    vsz = 0
    try:
        while p + 6 <= n:
            cid, sz = struct.unpack_from('<HI', data, p)
            q = p + 6
            if cid == 0x3000:                                   # M_MESH (bool skeletallyAnimated)
                p = q + 1
            elif cid == 0x4000:                                 # M_SUBMESH
                k = data.index(b'\n', q, min(n, q + 1024))
                usv = data[k + 1]
                ic = struct.unpack_from('<I', data, k + 2)[0]
                i32 = data[k + 6]
                ib = k + 7
                p = ib + ic * (4 if i32 else 2)
                if p > n:
                    r['err'] = 'index buffer overruns the file (submesh %d)' % len(r['subs'])
                    break
                idx = _indices(data, ib, ic, i32) if ic else ()
                sub = {'mat': data[q:k], 'shared': bool(usv), 'ic': ic, 'idx32': bool(i32),
                       'max_index': max(idx) if ic else -1, 'verts': 0, 'op': 4, 'bones': set(), 'ba': 0,
                       'ba_vmax': -1, 'decl': set(), 'geo': 0, 'span': (p, q, k)}
                r['subs'].append(sub)
                decl_target = None
            elif cid == 0x4010:                                 # M_SUBMESH_OPERATION
                if sub is not None:
                    sub['op'] = struct.unpack_from('<H', data, q)[0]
                p = q + 2
            elif cid in (0x4100, 0x7000):                       # bone assignment: u32 vertex, u16 bone, f32 weight
                vtx, bone, _w = struct.unpack_from('<IHf', data, q)
                p = q + 10
                if cid == 0x4100 and sub is not None:
                    sub['bones'].add(bone)
                    sub['ba'] += 1
                    sub['ba_vmax'] = max(sub['ba_vmax'], vtx)
                else:
                    r['shared_bones'].add(bone)
                    r['shared_ba'] += 1
                    r['shared_ba_vmax'] = max(r['shared_ba_vmax'], vtx)
            elif cid == 0x4200:                                 # M_SUBMESH_TEXTURE_ALIAS: two strings
                k = data.index(b'\n', q)
                k = data.index(b'\n', k + 1)
                p = k + 1
            elif cid == 0x5000:                                 # M_GEOMETRY (u32 vertex count)
                vc = struct.unpack_from('<I', data, q)[0]
                if sub is None:
                    r['shared_verts'] = vc
                    decl_target = r['shared_decl']
                else:
                    sub['geo'] += 1
                    sub['verts'] = vc
                    decl_target = sub['decl']
                p = q + 4
            elif cid in (0x5100, 0xA000):                       # containers: declaration, submesh name table
                p = q
            elif cid == 0x5110:                                 # vertex element: source, type, semantic, offset, index
                _src, _typ, sem, _off, _ix = struct.unpack_from('<5H', data, q)
                if decl_target is not None:
                    decl_target.add(sem)
                p = q + 10
            elif cid == 0x5200:                                 # vertex buffer: bind index, vertex size
                vsz = struct.unpack_from('<H', data, q + 2)[0]
                p = q + 4
            elif cid == 0x5210:                                 # vertex buffer data
                p = q + vc * vsz
            elif cid == 0x6000:                                 # M_MESH_SKELETON_LINK
                k = data.index(b'\n', q, min(n, q + 1024))
                r['skel'] = data[q:k]
                r['skel_span'] = (p, q, k)
                p = k + 1
            elif cid == 0x9000:                                 # M_MESH_BOUNDS: min, max, radius
                r['bounds'] = struct.unpack_from('<7f', data, q)
                p = q + 28
            elif cid == 0xA100:                                 # submesh name: u16 index + string
                k = data.index(b'\n', q + 2, min(n, q + 1026))
                p = k + 1
            elif cid in TAIL_CHUNKS and sz >= 6 and p + sz <= n:
                r['tails'].append('%04X' % cid)
                p += sz
            else:
                break
            if p > n:
                r['err'] = 'chunk 0x%04X overruns the file' % cid
                break
            r['chunks'] += 1
            last = p
    except (ValueError, IndexError, struct.error) as ex:
        r['err'] = '%s at offset %d' % (type(ex).__name__, p)
    r['end'] = last
    return r


def check(data, subject='', report=None):
    """Validate one mesh (bytes as stored). Returns (report, walk result)."""
    rep = report if report is not None else Report()
    m = walk_mesh(data)
    if m['err'] and not m['ver']:
        rep.add(VID, ERROR, subject, m['err'])
        return rep, m
    if m['ver'] not in VERSIONS:
        rep.add(VID, ERROR, subject, 'version %s not in %s (OgreMain reads up to v1.40)'
                % (disp(m['ver']), '/'.join(v.decode() for v in VERSIONS)))
    if m['err']:
        rep.add(VID, ERROR, subject, 'parse error: ' + m['err'])
    tail = len(data) - m['end']
    if tail > 0:
        t = data[m['end']:]
        if not t.strip(b'\x00'):
            rep.add(VID, WARN, subject, '%d zero padding byte(s) after the last chunk' % tail)
        elif tail <= PAD_MAX:
            rep.add(VID, WARN, subject, '%d non-zero trailing byte(s) after the last chunk (extractor padding)' % tail)
        else:
            rep.add(VID, ERROR, subject, '%d unparsed byte(s) after offset %d (unknown chunk 0x%04X)'
                    % (tail, m['end'], struct.unpack_from('<H', data, m['end'])[0] if tail >= 2 else 0))
    if not m['subs']:
        rep.add(VID, ERROR, subject, 'no submesh')
    total_v = m['shared_verts']
    for i, s in enumerate(m['subs']):
        vcount = m['shared_verts'] if s['shared'] else s['verts']
        decl = m['shared_decl'] if s['shared'] else s['decl']
        total_v += 0 if s['shared'] else s['verts']
        tag = 'submesh %d (%s)' % (i, disp(s['mat']))
        if not s['shared'] and s['geo'] == 0:
            rep.add(VID, ERROR, subject, tag + ': no geometry and useSharedVertices=false')
            continue
        if vcount == 0:
            rep.add(VID, ERROR, subject, tag + ': 0 vertices')
            continue
        if s['ic'] and s['max_index'] >= vcount:
            rep.add(VID, ERROR, subject, tag + ': index %d >= vertex count %d' % (s['max_index'], vcount))
        if not s['idx32'] and vcount > 65536:
            rep.add(VID, ERROR, subject, tag + ': %d vertices with 16-bit indices' % vcount)
        if s['op'] == 4 and s['ic'] % 3:
            rep.add(VID, WARN, subject, tag + ': triangle list with %d indices (not a multiple of 3)' % s['ic'])
        if s['ba'] and s['ba_vmax'] >= vcount:
            rep.add(VID, ERROR, subject, tag + ': bone assignment vertex %d >= vertex count %d' % (s['ba_vmax'], vcount))
        if SEM_POSITION not in decl:
            rep.add(VID, ERROR, subject, tag + ': vertex declaration without POSITION')
        elif SEM_TEXCOORD not in decl:
            rep.add(VID, WARN, subject, tag + ': vertex declaration without TEXTURE_COORDINATES')
    if m['shared_ba'] and m['shared_ba_vmax'] >= m['shared_verts']:
        rep.add(VID, ERROR, subject, 'shared bone assignment vertex %d >= shared vertex count %d'
                % (m['shared_ba_vmax'], m['shared_verts']))
    rep.add(VID, INFO, subject, '%s, %d submesh, %d vertices%s%s' % (
        disp(m['ver']).strip('[]'), len(m['subs']), total_v,
        ', idx32' if any(s['idx32'] for s in m['subs']) else '',
        ', skeleton ' + disp(m['skel']) if m['skel'] else ''))
    return rep, m
