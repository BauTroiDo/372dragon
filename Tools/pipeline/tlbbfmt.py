# -*- coding: utf-8 -*-
"Read-only format helpers for the CY-Source data pipeline (phase D0 index).\n\nGBK rule (Docs/08 muc 1.2): all.obj / all.material / all.effect / all.particle / all.skill\nare handled as BYTES. Names are decoded only for display (errors='replace') and for\nlookup keys (errors='surrogateescape', lower-cased). Nothing here writes to a source.\n"
import hashlib
import os
import re
import struct
import sys

AXP_READER_DIR = r'C:\TLBB\085\CY-Source\Docs\evidence\assetinv'
if AXP_READER_DIR not in sys.path:
    sys.path.insert(0, AXP_READER_DIR)
from axp_index import Axp, decode_header, decrypt, HDR_SIZE  # noqa: E402,F401

BIG = 64 << 20      # larger files are hashed in chunks and not parsed
PAD_MAX = 16        # a non-zero tail up to this size is treated as extractor padding


# ------------------------------------------------------------------ names
def disk_name_bytes(name, mojibake):
    """File name as returned by Windows -> real name bytes (GBK when possible).

    mojibake=True (S1 client_GL): the name is GBK bytes shown as cp1252; bytes
    0x81/0x8D/0x8F/0x90/0x9D (undefined in cp1252) come back as U+0081... and are kept raw.
    """
    if mojibake:
        out = bytearray()
        for ch in name:
            o = ord(ch)
            if o < 0x80:
                out.append(o)
                continue
            try:
                out += ch.encode('cp1252')
            except UnicodeEncodeError:
                if o < 0x100:
                    out.append(o)
                else:
                    out = None
                    break
        if out is not None:
            try:
                out.decode('gbk')
                return bytes(out)
            except UnicodeDecodeError:
                pass
    try:
        return name.encode('gbk')
    except UnicodeEncodeError:
        return name.encode('utf-8', 'surrogateescape')


def key_of(b):
    """Lookup key for a GBK byte name: decoded, lower-cased (ASCII/Latin only)."""
    return b.decode('gbk', 'surrogateescape').lower()


def disp(b):
    return b.decode('gbk', 'replace')


def base_of(b):
    """Basename of a byte path using / or \\ separators."""
    i = max(b.rfind(b'/'), b.rfind(b'\\'))
    return b[i + 1:] if i >= 0 else b


def magic_of(h):
    if h[:4] == b'DDS ':
        return 'DDS'
    if h[:8] == b'\x89PNG\r\n\x1a\n':
        return 'PNG'
    if h[:3] == b'\xff\xd8\xff':
        return 'JPEG'
    if h[:4] in (b'\x00\xcc\xbb\xdd', b'\xdd\xbb\xcc\x00'):
        return 'DBC'
    if h[:2] == b'\x00\x10':
        return 'OGRE'
    if len(h) >= 4 and all(32 <= c < 127 for c in h[:4]):
        return 'ascii:' + h[:4].decode('ascii')
    return 'bin:' + h[:4].hex()


# ------------------------------------------------------------------ mesh
_BA_RUN = {0x4100: re.compile(rb'(?:\x00\x41\x10\x00\x00\x00.{10})+', re.S),
           0x7000: re.compile(rb'(?:\x00\x70\x10\x00\x00\x00.{10})+', re.S)}
_MESH_TAIL = {0x8000, 0xB000, 0xC000, 0xD000, 0xE000}


def mesh_info(data):
    """Sequential walk of an Ogre/Fairy .mesh. Returns counts and the logical end offset
    (end of the last complete chunk); bytes after it are padding/garbage."""
    n = len(data)
    r = {'ver': '', 'subs': 0, 'verts': 0, 'tris': 0, 'idx32': 0, 'bones': 0,
         'skel': b'', 'mats': (), 'end': n, 'err': '', 'tail': ''}
    if n < 8 or data[:2] != b'\x00\x10':
        r['err'] = 'not-ogre'
        return r
    e = data.find(b'\n', 2, 80)
    if e < 0:
        r['err'] = 'no-version'
        return r
    r['ver'] = data[2:e].decode('latin-1')
    p = e + 1
    last = p
    subs = []
    sub = None
    mesh_bones = set()
    vc = vsz = 0
    tails = []
    try:
        while p + 6 <= n:
            cid, sz = struct.unpack_from('<HI', data, p)
            q = p + 6
            if cid == 0x3000:
                p = q + 1
            elif cid == 0x4000:
                k = data.index(b'\n', q, min(n, q + 1024))
                usv = data[k + 1]
                ic = struct.unpack_from('<I', data, k + 2)[0]
                i32 = data[k + 6]
                p = k + 7 + ic * (4 if i32 else 2)
                sub = {'mat': data[q:k], 'shared': bool(usv), 'ic': ic, 'op': 4, 'geo': False, 'bones': set()}
                subs.append(sub)
                if i32:
                    r['idx32'] = 1
            elif cid == 0x4010:
                if sub is not None:
                    sub['op'] = struct.unpack_from('<H', data, q)[0]
                p = q + 2
            elif cid in (0x4100, 0x7000):
                m = _BA_RUN[cid].match(data, p)
                if m:
                    run = data[p:m.end()]
                    bones = set(zip(run[10::16], run[11::16]))
                    p = m.end()
                else:
                    bones = {(data[q + 4], data[q + 5])}
                    p = q + 10
                if cid == 0x4100 and sub is not None:
                    sub['bones'] |= bones
                else:
                    mesh_bones |= bones
            elif cid == 0x4200:
                k = data.index(b'\n', q)
                k = data.index(b'\n', k + 1)
                p = k + 1
            elif cid == 0x5000:
                vc = struct.unpack_from('<I', data, q)[0]
                if sub is not None and not sub['shared'] and not sub['geo']:
                    sub['geo'] = True
                r['verts'] += vc
                p = q + 4
            elif cid in (0x5100, 0xA000):
                p = q
            elif cid == 0x5110:
                p = q + 10
            elif cid == 0x5200:
                vsz = struct.unpack_from('<H', data, q + 2)[0]
                p = q + 4
            elif cid == 0x5210:
                p = q + vc * vsz
            elif cid == 0x6000:
                k = data.index(b'\n', q, min(n, q + 1024))
                r['skel'] = data[q:k]
                p = k + 1
            elif cid == 0x9000:
                p = q + 28
            elif cid == 0xA100:
                k = data.index(b'\n', q + 2, min(n, q + 1026))
                p = k + 1
            elif cid in _MESH_TAIL and sz >= 6 and p + sz <= n:
                tails.append('%04X' % cid)
                p += sz
            else:
                break
            if p > n:
                r['err'] = 'overrun'
                break
            last = p
    except (ValueError, IndexError, struct.error) as ex:
        r['err'] = type(ex).__name__
    r['end'] = last
    r['subs'] = len(subs)
    tris = 0
    mb = 0
    for s in subs:
        if s['op'] == 4:
            tris += s['ic'] // 3
        elif s['op'] in (5, 6):
            tris += max(0, s['ic'] - 2)
        nb = len(mesh_bones) if s['shared'] else len(s['bones'])
        mb = max(mb, nb)
    if not subs and mesh_bones:
        mb = len(mesh_bones)
    r['tris'] = tris
    r['bones'] = mb
    r['mats'] = tuple(s['mat'] for s in subs)
    r['tail'] = ','.join(tails)
    return r


# ------------------------------------------------------------------ skeleton
def skel_info(data):
    n = len(data)
    r = {'ver': '', 'bones': 0, 'anims': 0, 'links': 0, 'end': n, 'err': ''}
    if n < 8 or data[:2] != b'\x00\x10':
        r['err'] = 'not-ogre'
        return r
    e = data.find(b'\n', 2, 80)
    if e < 0:
        r['err'] = 'no-version'
        return r
    r['ver'] = data[2:e].decode('latin-1')
    p = e + 1
    last = p
    try:
        while p + 6 <= n:
            cid, sz = struct.unpack_from('<HI', data, p)
            q = p + 6
            if cid == 0x1010:
                p = q + 2
            elif cid == 0x2000:
                k = data.index(b'\n', q, min(n, q + 1024))
                p = k + 1 + 2 + 28 + (12 if sz > 36 else 0)
                r['bones'] += 1
            elif cid == 0x3000:
                p = q + 4
            elif cid == 0x4000:
                k = data.index(b'\n', q, min(n, q + 1024))
                p = k + 1 + 4
                r['anims'] += 1
            elif cid == 0x4010:
                k = data.index(b'\n', q, min(n, q + 1024))
                p = k + 1 + 4
            elif cid == 0x4100:
                p = q + 2
            elif cid == 0x4120:
                cnt, fl = struct.unpack_from('<HH', data, q)
                p = q + 4 + cnt * (4 + (16 if fl & 1 else 0) + (12 if fl & 2 else 0) + (12 if fl & 4 else 0))
            elif cid == 0x4110:
                p = q + 32 + (12 if sz > 38 else 0)
            elif cid == 0x5000:
                k = data.index(b'\n', q, min(n, q + 1024))
                p = k + 1 + 4
                r['links'] += 1
            else:
                break
            if p > n:
                r['err'] = 'overrun'
                break
            last = p
    except (ValueError, IndexError, struct.error) as ex:
        r['err'] = type(ex).__name__
    r['end'] = last
    return r


# ------------------------------------------------------------------ textures
_FOURCC_BPB = {b'DXT1': 8, b'ATI1': 8, b'BC4U': 8, b'BC4S': 8,
               b'DXT2': 16, b'DXT3': 16, b'DXT4': 16, b'DXT5': 16,
               b'ATI2': 16, b'BC5U': 16, b'BC5S': 16, b'RXGB': 16}
_DXGI_BPB = {70: 8, 71: 8, 72: 8, 79: 8, 80: 8, 81: 8, 73: 16, 74: 16, 75: 16, 76: 16, 77: 16, 78: 16,
             82: 16, 83: 16, 84: 16, 94: 16, 95: 16, 96: 16, 97: 16, 98: 16, 99: 16}
_DXGI_BPP = {2: 16, 10: 8, 24: 4, 28: 4, 29: 4, 61: 1, 87: 4, 88: 4, 91: 4}
_D3D_BPP = {36: 8, 111: 2, 112: 4, 113: 8, 114: 4, 115: 8, 116: 16, 117: 2}


def dds_info(data):
    n = len(data)
    if n < 128 or data[:4] != b'DDS ':
        return {'fmt': 'NOT-DDS:' + magic_of(data[:16]), 'w': 0, 'h': 0, 'mips': 0, 'end': n}
    flags, h, w, pitch, depth, mips = struct.unpack_from('<6I', data, 8)
    pf_flags = struct.unpack_from('<I', data, 80)[0]
    fourcc = data[84:88]
    bits, rm, gm, bm, am = struct.unpack_from('<5I', data, 88)
    caps2 = struct.unpack_from('<I', data, 112)[0]
    hdr = 128
    bpb = bpp = 0
    if pf_flags & 4:
        if fourcc == b'DX10':
            hdr = 148
            dx = struct.unpack_from('<I', data, 128)[0] if n >= 132 else -1
            fmt = 'DX10/%d' % dx
            bpb = _DXGI_BPB.get(dx, 0)
            bpp = 0 if bpb else _DXGI_BPP.get(dx, 0)
        elif all(32 < c < 127 for c in fourcc):
            fmt = fourcc.decode('ascii')
            bpb = _FOURCC_BPB.get(fourcc, 0)
        else:
            v = struct.unpack('<I', fourcc)[0]
            fmt = 'D3DFMT_%d' % v
            bpp = _D3D_BPP.get(v, 0)
    else:
        if bits == 32:
            fmt = ('A8R8G8B8' if rm == 0xFF0000 else 'A8B8G8R8') if (pf_flags & 1 and am) else \
                  ('X8R8G8B8' if rm == 0xFF0000 else 'X8B8G8R8')
        elif bits == 24:
            fmt = 'R8G8B8'
        elif bits == 16:
            fmt = 'A8L8' if pf_flags & 0x20000 else ('A1R5G5B5' if am == 0x8000 else
                                                    ('A4R4G4B4' if am == 0xF000 else 'R5G6B5'))
        elif bits == 8:
            fmt = 'L8' if pf_flags & 0x20000 else 'A8'
        else:
            fmt = 'RGB%d' % bits
        bpp = bits // 8
    r = {'fmt': fmt, 'w': w, 'h': h, 'mips': mips, 'end': n}
    if not (bpb or bpp) or not w or not h:
        return r
    faces = 1
    if caps2 & 0x200:
        faces = bin(caps2 & 0xFC00).count('1') or 6
    d = max(1, depth) if caps2 & 0x200000 else 1

    def total(levels):
        t = 0
        for i in range(levels):
            wi = max(1, w >> i)
            hi = max(1, h >> i)
            di = max(1, d >> i)
            if bpb:
                t += ((wi + 3) // 4) * ((hi + 3) // 4) * bpb * di
            else:
                t += wi * hi * bpp * di
        return hdr + faces * t
    cands = [total(max(1, mips)) if flags & 0x20000 else total(1)]
    alt = total(max(1, mips))
    if alt not in cands:
        cands.append(alt)
    fit = [c for c in cands if c <= n]
    if fit:
        r['end'] = fit[0] if fit[0] == cands[0] else max(fit)
    else:
        r['err'] = 'short'
    return r


def png_info(data):
    if data[:8] != b'\x89PNG\r\n\x1a\n' or len(data) < 24:
        return None
    w, h = struct.unpack_from('>II', data, 16)
    i = data.rfind(b'IEND')
    end = i + 8 if 0 <= i and i + 8 <= len(data) else len(data)
    return {'fmt': 'PNG', 'w': w, 'h': h, 'end': end}


def jpg_info(data):
    if data[:3] != b'\xff\xd8\xff':
        return None
    n = len(data)
    p = 2
    w = h = 0
    while p + 9 < n:
        if data[p] != 0xFF:
            p += 1
            continue
        m = data[p + 1]
        if m == 0xFF:
            p += 1
            continue
        if m in (0xD8, 0x01) or 0xD0 <= m <= 0xD7:
            p += 2
            continue
        ln = (data[p + 2] << 8) | data[p + 3]
        if 0xC0 <= m <= 0xCF and m not in (0xC4, 0xC8, 0xCC):
            h, w = struct.unpack_from('>HH', data, p + 5)
            break
        if m == 0xDA:
            break
        p += 2 + ln
    i = data.rfind(b'\xff\xd9')
    return {'fmt': 'JPEG', 'w': w, 'h': h, 'end': i + 2 if i >= 0 else n}


def tga_info(data):
    if len(data) < 18:
        return None
    w, h = struct.unpack_from('<HH', data, 12)
    return {'fmt': 'TGA%d' % data[16], 'w': w, 'h': h, 'end': len(data)}


TEX_EXT = ('.dds', '.tga', '.png', '.jpg', '.jpeg', '.bmp')


def analyze(ext, data):
    if ext == '.mesh':
        return mesh_info(data)
    if ext == '.skeleton':
        return skel_info(data)
    if ext == '.dds':
        if data[:4] == b'DDS ':
            return dds_info(data)
        return png_info(data) or jpg_info(data) or {'fmt': 'NOT-DDS:' + magic_of(data[:16]),
                                                    'w': 0, 'h': 0, 'end': len(data)}
    if ext == '.png':
        return png_info(data) or {'fmt': 'NOT-PNG:' + magic_of(data[:16]), 'w': 0, 'h': 0, 'end': len(data)}
    if ext in ('.jpg', '.jpeg'):
        return jpg_info(data) or {'fmt': 'NOT-JPG:' + magic_of(data[:16]), 'w': 0, 'h': 0, 'end': len(data)}
    if ext == '.tga':
        return tga_info(data)
    return None


def info_text(ext, info):
    """Compact human-readable description for the per-file manifest."""
    if not info:
        return ''
    if ext == '.mesh':
        s = '%s sub=%d v=%d t=%d bones=%d%s' % (info['ver'].strip('[]').replace('MeshSerializer_', ''),
                                                info['subs'], info['verts'], info['tris'], info['bones'],
                                                ' idx32' if info['idx32'] else '')
        if info['skel']:
            s += ' skel=' + disp(info['skel'])
    elif ext == '.skeleton':
        s = 'bones=%d anims=%d' % (info['bones'], info['anims'])
        if info['links']:
            s += ' links=%d' % info['links']
    else:
        s = '%s %dx%d' % (info.get('fmt', ''), info.get('w', 0), info.get('h', 0))
        if info.get('mips'):
            s += ' m%d' % info['mips']
    if info.get('err'):
        s += ' ERR=' + info['err']
    return s


# ------------------------------------------------------------------ workers
def _classify_tail(data, end, size):
    if end >= size:
        return ''
    t = data[end:]
    if not t.strip(b'\x00'):
        return 'zero'
    return 'nonzero' if size - end <= PAD_MAX else 'extra'


def scan_batch(items):
    """items: [(rel, path, ext, canon)] -> list of result tuples.

    result = (rel, size, mtime_ns, sha256, fmt_end, tail, sha256_content,
              sha256_canon, canon_tail, info)
      fmt_end        logical length derived from the format (mesh/skeleton/dds/png/jpg), else size
      tail           '', 'zero', 'nonzero' (<= PAD_MAX bytes) or 'extra' after fmt_end
      sha256_content sha256 of data[:fmt_end] when tail is zero/nonzero, else = sha256
      sha256_canon   (S2 only) sha256 of data[:canon] where canon = S4 payload length
    """
    out = []
    for rel, path, ext, canon in items:
        try:
            st = os.stat(path)
            size = st.st_size
            if size > BIG:
                h = hashlib.sha256()
                hc = hashlib.sha256() if 0 <= canon < size else None
                done = 0
                with open(path, 'rb') as f:
                    while True:
                        b = f.read(8 << 20)
                        if not b:
                            break
                        h.update(b)
                        if hc is not None and done < canon:
                            hc.update(b[:canon - done])
                        done += len(b)
                sha = h.hexdigest()
                sc = sha if canon == size else (hc.hexdigest() if hc is not None else '')
                out.append((rel, size, st.st_mtime_ns, sha, size, '', sha, sc if canon >= 0 else '', '', None))
                continue
            with open(path, 'rb') as f:
                data = f.read()
            size = len(data)
            sha = hashlib.sha256(data).hexdigest()
            info = analyze(ext, data)
            end = min(info.get('end', size), size) if info else size
            tail = _classify_tail(data, end, size)
            sha_c = hashlib.sha256(data[:end]).hexdigest() if tail in ('zero', 'nonzero') else sha
            sc = ''
            ctail = ''
            if canon >= 0:
                if canon == size:
                    sc = sha
                elif canon < size:
                    sc = hashlib.sha256(data[:canon]).hexdigest()
                    ctail = 'zero' if not data[canon:].strip(b'\x00') else 'nonzero'
            if info is not None:
                info = dict(info)
                info.pop('end', None)
            out.append((rel, size, st.st_mtime_ns, sha, end, tail, sha_c, sc, ctail, info))
        except OSError as ex:
            out.append((rel, -1, 0, '', 0, 'ERR:' + type(ex).__name__, '', '', '', None))
    return out


def s4_hash_batch(task):
    """task = (archive_path, [(name, off, size, wrap, plen)]) sorted by offset.
    Returns (archive_path, [(name, sha256_of_payload or '', magic)]). Wrapper types 1-18
    are not decryptable with the known keys -> ''."""
    path, items = task
    out = []
    with open(path, 'rb') as f:
        for name, off, size, wrap, plen in items:
            if wrap and wrap < 19:
                out.append((name, '', ''))
                continue
            f.seek(off)
            if not wrap and size > BIG:
                h = hashlib.sha256()
                left = size
                head = b''
                while left > 0:
                    b = f.read(min(8 << 20, left))
                    if not b:
                        break
                    if not head:
                        head = b[:16]
                    h.update(b)
                    left -= len(b)
                out.append((name, h.hexdigest() if left == 0 else '', magic_of(head)))
                continue
            raw = f.read(size)
            if wrap:
                payload = decrypt(raw[HDR_SIZE:], wrap, plen)
                if payload is None:
                    out.append((name, '', ''))
                    continue
            else:
                payload = raw
            out.append((name, hashlib.sha256(payload).hexdigest(), magic_of(payload[:16])))
    return path, out


# ------------------------------------------------------------------ scripts (all.*)
_WSALL = re.compile(rb'\s+')


def norm_hash(body):
    """sha256 of a block with every whitespace run collapsed to one space."""
    return hashlib.sha256(_WSALL.sub(b' ', body).strip()).hexdigest()


def iter_blocks(data):
    """Top-level (depth-0) blocks of an Ogre-style script: 'HEADER' then '{ ... }'.
    Returns (blocks, stray) where blocks = [(header_bytes, block_bytes)] and stray counts
    depth-0 lines that do not open a block (the all.effect parser trap, Docs/08 4.1)."""
    blocks = []
    stray = 0
    depth = 0
    header = None
    start = 0
    opened = False
    pos = 0
    for line in data.splitlines(True):
        ln = len(line)
        s = line.split(b'//', 1)[0].strip()
        if not opened:
            if s:
                if s[:1] == b'{':
                    if header is None:
                        stray += 1
                        header = b''
                        start = pos
                    opened = True
                elif s[:1] == b'}':
                    stray += 1
                else:
                    if header is not None:
                        stray += 1
                    i = s.find(b'{')
                    header = (s if i < 0 else s[:i]).strip()
                    start = pos
                    if i >= 0:
                        opened = True
                if opened:
                    depth = s.count(b'{') - s.count(b'}')
                    pos += ln
                    if depth <= 0:
                        blocks.append((header, data[start:pos]))
                        header = None
                        opened = False
                        depth = 0
                    continue
            pos += ln
            continue
        depth += s.count(b'{') - s.count(b'}')
        pos += ln
        if depth <= 0:
            blocks.append((header, data[start:pos]))
            header = None
            opened = False
            depth = 0
    if header is not None:
        stray += 1
    return blocks, stray


def script_defs(data, kind):
    """Named definitions of all.effect ('effect'), all.particle ('particle'), all.skill
    ('skill'). Returns (defs, stats) with defs = {name_bytes: (norm_sha256, nbytes)};
    the first definition of a duplicated name wins (duplicates counted)."""
    blocks, stray = iter_blocks(data)
    defs = {}
    dup = other = 0
    for hdr, body in blocks:
        toks = hdr.split(None, 1)
        if kind == 'particle':
            if toks and toks[0] == b'particle_system' and len(toks) > 1:
                name = toks[1].strip()
            else:
                name = hdr.strip()
        else:
            if not toks or toks[0] != kind.encode('ascii') or len(toks) < 2:
                other += 1
                continue
            name = toks[1].strip()
        if name in defs:
            dup += 1
            continue
        defs[name] = (norm_hash(body), len(body))
    return defs, {'blocks': len(blocks), 'defs': len(defs), 'dup': dup, 'other_blocks': other, 'stray': stray}


def material_defs(data):
    """all.material -> {name: {'parent', 'alias' {alias: tex}, 'tex' [..], 'sha'}} + stats."""
    blocks, stray = iter_blocks(data)
    mats = {}
    dup = other = 0
    for hdr, body in blocks:
        toks = hdr.split(None, 1)
        if not toks or toks[0] != b'material' or len(toks) < 2:
            other += 1
            continue
        rest = toks[1].strip()
        parent = b''
        if b':' in rest:
            nm, parent = rest.split(b':', 1)
            nm = nm.strip()
            parent = parent.strip().split()[0] if parent.strip() else b''
        else:
            nm = rest.split()[0]
        if nm in mats:
            dup += 1
            continue
        alias = {}
        tex = []
        for ln in body.split(b'\n')[1:]:
            t = ln.split(b'//', 1)[0].split()
            if not t:
                continue
            if t[0] == b'set_texture_alias' and len(t) >= 3:
                alias[t[1]] = t[2]
            elif t[0] in (b'texture', b'anim_texture', b'cubic_texture') and len(t) >= 2:
                tex.append(t[1])
        mats[nm] = {'parent': parent, 'alias': alias, 'tex': tex, 'sha': norm_hash(body)}
    return mats, {'blocks': len(blocks), 'materials': len(mats), 'dup': dup, 'other_blocks': other, 'stray': stray}


def material_textures(name, mats, _cache=None, depth=0):
    """Texture file names used by a material, following parents defined in all.material
    (child set_texture_alias overrides the parent's alias of the same name). Templates
    from MaterialTemplates.zip are not followed."""
    if _cache is not None and name in _cache:
        return _cache[name]
    m = mats.get(name)
    if m is None or depth > 8:
        return ()
    alias = {}
    tex = []
    if m['parent'] and m['parent'] in mats and m['parent'] != name:
        ptex_alias, ptex = _material_alias_chain(m['parent'], mats, depth + 1)
        alias.update(ptex_alias)
        tex.extend(ptex)
    alias.update(m['alias'])
    tex.extend(m['tex'])
    out = []
    seen = set()
    for t in list(alias.values()) + tex:
        if b'.' in t and t not in seen:
            seen.add(t)
            out.append(t)
    out = tuple(out)
    if _cache is not None:
        _cache[name] = out
    return out


def _material_alias_chain(name, mats, depth):
    m = mats.get(name)
    if m is None or depth > 8:
        return {}, []
    alias = {}
    tex = []
    if m['parent'] and m['parent'] in mats and m['parent'] != name:
        a, t = _material_alias_chain(m['parent'], mats, depth + 1)
        alias.update(a)
        tex.extend(t)
    alias.update(m['alias'])
    tex.extend(m['tex'])
    return alias, tex


# ------------------------------------------------------------------ all.obj
_COMMENT = re.compile(rb'<!--.*?-->', re.S)
_OBJ = re.compile(rb'<Object\s+name="([^"]*)"\s*>(.*?)</Object>', re.S)
_KV = re.compile(rb'([A-Za-z_][\w]*)\s*=\s*"([^"]*)"')


def _tags(tag):
    return re.compile(rb'<' + tag + rb'\b([^>]*?)/?>', re.S)


_T_ENT = _tags(b'Entity')
_T_MAT = _tags(b'Material')
_T_SLOT = _tags(b'Slot')
_T_EFF = _tags(b'Effect')
_T_ATT = _tags(b'Attribute')
_T_SKL = _tags(b'Skeleton')
_T_LOC = re.compile(rb'<Locator\b')


def parse_all_obj(data):
    """all.obj -> (objects, stats). XML comments are removed first (commented-out
    <Effect> lines exist). Each object: name, sha (normalised block), entities, matlist,
    locators, slots, effects, attributes, skeletons (extra <Skeleton skeleton animations>)."""
    clean = _COMMENT.sub(b'', data)
    objs = []
    seen = set()
    dup = 0
    for m in _OBJ.finditer(clean):
        name, body = m.group(1), m.group(2)
        if name in seen:
            dup += 1
            continue
        seen.add(name)
        ents = [dict(_KV.findall(a)) for a in _T_ENT.findall(body)]
        mlist = [dict(_KV.findall(a)) for a in _T_MAT.findall(body)]
        slots = [dict(_KV.findall(a)).get(b'object', b'') for a in _T_SLOT.findall(body)]
        effs = [dict(_KV.findall(a)) for a in _T_EFF.findall(body)]
        atts = [dict(_KV.findall(a)) for a in _T_ATT.findall(body)]
        skls = [dict(_KV.findall(a)) for a in _T_SKL.findall(body)]
        objs.append({
            'name': name,
            'sha': norm_hash(body),
            'entities': ents,
            'matlist': mlist,
            'locators': len(_T_LOC.findall(body)),
            'slots': [s for s in slots if s],
            'effects': [e.get(b'effect', b'') for e in effs if e.get(b'effect')],
            'attributes': [(a.get(b'name', b''), a.get(b'value', b''), a.get(b'hints', b'')) for a in atts],
            'skeletons': [(s.get(b'skeleton', b''), s.get(b'animations', b'')) for s in skls],
        })
    return objs, {'objects': len(objs), 'dup': dup, 'raw_object_tags': data.count(b'<Object ')}
