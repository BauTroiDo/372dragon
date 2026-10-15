#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extract_cursors.py -- pure-Python PE resource parser that rebuilds .cur
files from a Windows PE image's RT_GROUP_CURSOR + RT_CURSOR resources,
preserving each frame's hotspot exactly as compiled into the binary.

Why this exists (CY-Source cursor task): client_GL's Game.exe ("B") draws
its mouse cursors from resources embedded in the EXE (LoadCursor + a
resource ID), instead of loading external .ani files like the 0.85
lineage does. To reuse B's actual cursor art in our own Game.rc we need
real .cur files on disk, extracted byte-for-byte (image data + hotspot)
from B's binary. This script does that extraction; it does not depend on
any Windows-only API (no ctypes, no ExtractIconEx) so it also works for
offline/static inspection of a copied binary.

No third-party dependencies for the extraction itself (stdlib only:
struct, zlib, json, pathlib, hashlib, argparse). Pillow is used ONLY if
present and only to additionally render a PNG preview per cursor for
human/visual evidence; the .cur rebuild logic never depends on it.

PE/resource format notes (why the code does what it does):
  - IMAGE_RESOURCE_DIRECTORY / IMAGE_RESOURCE_DIRECTORY_ENTRY form a
    3-level tree under the Resource Table data directory: Type -> Name
    (ID) -> Language -> IMAGE_RESOURCE_DATA_ENTRY. All offsets inside the
    tree are relative to the start of the resource directory (the .rsrc
    section's RVA); only the final IMAGE_RESOURCE_DATA_ENTRY.OffsetToData
    is an absolute RVA (relative to the image base) and must be resolved
    through the section table like any other RVA.
  - RT_GROUP_CURSOR (type 12) data is a NEWHEADER (like ICONDIR) followed
    by idCount x 14-byte GRPCURSORDIRENTRY {wWidth, wHeight, wPlanes,
    wBitCount, dwBytesInRes, nID}; nID indexes into RT_CURSOR (type 1) by
    Name ID. Some references claim wPlanes/wBitCount are repurposed as
    the hotspot (x, y) for cursor groups; empirically (checked byte-for-
    byte against client_GL's own Game.exe, see Build/re/cursor for the
    scratch verification) that is NOT what this toolchain wrote: those
    two fields hold the real color-plane count and bit depth, identical
    in meaning to an icon group entry, and wHeight here is the *doubled*
    DIB height (XOR+AND stacked), not the visual height. Neither field is
    used below for anything but a sanity cross-check; width/height/
    hotspot are all derived from the RT_CURSOR payload itself (next
    bullet), which is the one place Windows' own LoadCursor/
    CreateIconFromResourceEx actually reads them from.
  - RT_CURSOR (type 1) raw data, UNLIKE RT_ICON, is prefixed with a 4-byte
    {WORD xHotspot; WORD yHotspot;} before the DIB (BITMAPINFOHEADER +
    color table + XOR mask + AND mask). The on-disk .cur file format does
    NOT keep that prefix inside the image data block -- the hotspot moves
    into the ICONDIRENTRY instead. Getting this prefix-stripping right is
    the one part of this format that silently produces corrupt .cur files
    if skipped; it is verified here two ways: (a) biSize inside the DIB
    that remains after stripping 4 bytes must read as 40 (a valid
    BITMAPINFOHEADER) -- with the prefix left in place it reads as 0 and
    is instantly recognizable as wrong; (b) the DIB's own biHeight, once
    halved for the stacked XOR+AND masks, must reconcile exactly with the
    resource's total byte size (also asserted below).
"""
import argparse
import hashlib
import json
import struct
import sys
import zlib
from pathlib import Path

IMAGE_RESOURCE_DIRECTORY_SIZE = 16
IMAGE_RESOURCE_DIRECTORY_ENTRY_SIZE = 8
IMAGE_RESOURCE_DATA_ENTRY_SIZE = 16

RT_CURSOR = 1
RT_GROUP_CURSOR = RT_CURSOR + 11  # 12, per the well-known RT_*+11 alias rule


def u16(b, o):
    return struct.unpack_from('<H', b, o)[0]


def u32(b, o):
    return struct.unpack_from('<I', b, o)[0]


def u64(b, o):
    return struct.unpack_from('<Q', b, o)[0]


class PEImage:
    """Minimal PE32/PE32+ reader: sections + data directories + RVA->file
    offset mapping. Enough to walk the resource tree; nothing else."""

    def __init__(self, path):
        self.path = Path(path)
        self.data = self.path.read_bytes()
        data = self.data
        if data[0:2] != b'MZ':
            raise ValueError(f"{path}: not an MZ/PE file")
        e_lfanew = u32(data, 0x3C)
        if data[e_lfanew:e_lfanew + 4] != b'PE\0\0':
            raise ValueError(f"{path}: missing PE signature")
        coff_off = e_lfanew + 4
        self.machine = u16(data, coff_off)
        num_sections = u16(data, coff_off + 2)
        opt_hdr_size = u16(data, coff_off + 16)
        opt_off = coff_off + 20
        magic = u16(data, opt_off)
        self.is_pe32plus = (magic == 0x20B)
        if magic not in (0x10B, 0x20B):
            raise ValueError(f"{path}: unrecognized optional header magic 0x{magic:x}")
        if self.is_pe32plus:
            self.image_base = u64(data, opt_off + 24)
            data_dir_off = opt_off + 112
        else:
            self.image_base = u32(data, opt_off + 28)
            data_dir_off = opt_off + 96
        # Data directory index 2 = Resource Table
        self.rsrc_rva = u32(data, data_dir_off + 8 * 2)
        self.rsrc_size = u32(data, data_dir_off + 8 * 2 + 4)

        sec_off = opt_off + opt_hdr_size
        self.sections = []
        for i in range(num_sections):
            s = sec_off + i * 40
            name = data[s:s + 8].rstrip(b'\0').decode('ascii', 'replace')
            vsize = u32(data, s + 8)
            vaddr = u32(data, s + 12)
            rawsize = u32(data, s + 16)
            rawptr = u32(data, s + 20)
            self.sections.append((name, vaddr, vsize, rawptr, rawsize))

    def rva2off(self, rva):
        for name, vaddr, vsize, rawptr, rawsize in self.sections:
            span = max(vsize, rawsize)
            if vaddr <= rva < vaddr + span:
                return rawptr + (rva - vaddr)
        raise ValueError(f"RVA 0x{rva:x} not mapped by any section")

    def resource_root_offset(self):
        if not self.rsrc_rva:
            raise ValueError(f"{self.path}: no resource directory (empty .rsrc)")
        return self.rva2off(self.rsrc_rva)


def parse_resource_dir(pe, dir_file_off, rsrc_base_file_off):
    """Return list of (id_or_name, is_named, entry_offset_in_file) for one
    IMAGE_RESOURCE_DIRECTORY located at dir_file_off (absolute file
    offset). rsrc_base_file_off is the file offset of the resource
    section's start (all intra-tree offsets are relative to it)."""
    data = pe.data
    n_named = u16(data, dir_file_off + 12)
    n_id = u16(data, dir_file_off + 14)
    entries = []
    entry_base = dir_file_off + IMAGE_RESOURCE_DIRECTORY_SIZE
    for i in range(n_named + n_id):
        e = entry_base + i * IMAGE_RESOURCE_DIRECTORY_ENTRY_SIZE
        name_field = u32(data, e)
        offset_field = u32(data, e + 4)
        is_named = bool(name_field & 0x80000000)
        if is_named:
            str_off = rsrc_base_file_off + (name_field & 0x7FFFFFFF)
            strlen = u16(data, str_off)
            name = data[str_off + 2:str_off + 2 + strlen * 2].decode('utf-16-le', 'replace')
            key = name
        else:
            key = name_field & 0xFFFF
        is_subdir = bool(offset_field & 0x80000000)
        target_off = rsrc_base_file_off + (offset_field & 0x7FFFFFFF)
        entries.append((key, is_named, is_subdir, target_off))
    return entries


def find_type_entries(pe, type_id):
    """Walk Type -> Name -> Language and yield (name_id, lang_id, data_rva,
    data_size) for every resource under the given top-level Type ID."""
    root_off = pe.resource_root_offset()
    rsrc_base = root_off
    for type_key, _named, is_subdir, type_target in parse_resource_dir(pe, root_off, rsrc_base):
        if type_key != type_id or not is_subdir:
            continue
        for name_key, _n2, is_subdir2, name_target in parse_resource_dir(pe, type_target, rsrc_base):
            if not is_subdir2:
                continue
            for lang_key, _n3, is_subdir3, lang_target in parse_resource_dir(pe, name_target, rsrc_base):
                if is_subdir3:
                    continue  # not expected at this depth
                data_rva = u32(pe.data, lang_target)
                data_size = u32(pe.data, lang_target + 4)
                yield name_key, lang_key, data_rva, data_size


def read_resource_data(pe, data_rva, data_size):
    off = pe.rva2off(data_rva)
    return pe.data[off:off + data_size]


# ---------------------------------------------------------------------
# .cur rebuilding
# ---------------------------------------------------------------------

class CursorFrame:
    __slots__ = ('width', 'height', 'hotspot_x', 'hotspot_y', 'dib', 'local_id')

    def __init__(self, width, height, hotspot_x, hotspot_y, dib, local_id):
        self.width = width
        self.height = height
        self.hotspot_x = hotspot_x
        self.hotspot_y = hotspot_y
        self.dib = dib  # BITMAPINFOHEADER + colors + XOR + AND, no hotspot prefix
        self.local_id = local_id


def parse_group_cursor(pe, group_data, rt_cursor_by_id):
    """Parse one RT_GROUP_CURSOR blob (NEWHEADER + GRPCURSORDIRENTRY[]).
    Returns a list of CursorFrame, resolving each entry's nID against the
    rt_cursor_by_id map ({local_id: raw_bytes})."""
    reserved, idtype, count = struct.unpack_from('<HHH', group_data, 0)
    if reserved != 0 or idtype != 2:
        raise ValueError(f"not a cursor group header (reserved={reserved} type={idtype})")
    frames = []
    for i in range(count):
        eo = 6 + i * 14
        group_w, group_h, group_planes, group_bitcount, bytes_in_res, local_id = \
            struct.unpack_from('<HHHHIH', group_data, eo)
        raw = rt_cursor_by_id.get(local_id)
        if raw is None:
            raise ValueError(f"RT_CURSOR id {local_id} referenced by group but not found")
        if len(raw) < 4:
            raise ValueError(f"RT_CURSOR id {local_id} too small ({len(raw)} bytes)")
        if bytes_in_res not in (len(raw), 0):
            sys.stderr.write(
                f"warning: group entry dwBytesInRes=0x{bytes_in_res:x} != "
                f"RT_CURSOR#{local_id} size 0x{len(raw):x}\n")

        # The hotspot Windows actually uses at runtime (via
        # CreateIconFromResourceEx) is this 4-byte prefix on the RT_CURSOR
        # payload -- NOT the group entry's wPlanes/wBitCount (see module
        # docstring for the byte-level proof).
        hot_x, hot_y = struct.unpack_from('<HH', raw, 0)
        dib = raw[4:]

        # Derive the true (undoubled) visual width/height from the DIB
        # itself rather than trusting the group entry's wWidth/wHeight:
        # empirically this binary's group entries store the *doubled*
        # height (matching biHeight, which stacks XOR+AND), not the
        # visual height a .cur ICONDIRENTRY needs. biSize must read 40
        # (a valid BITMAPINFOHEADER) once the hotspot prefix is stripped;
        # if it does not, the resource is not shaped as expected and we
        # fall back to the group entry rather than emit a bogus header.
        width, height = group_w, group_h
        if len(dib) >= 8:
            bihsize, biw, bih2 = struct.unpack_from('<Iii', dib, 0)
            if bihsize == 40:
                width, height = biw, abs(bih2) // 2
        frames.append(CursorFrame(width, height, hot_x, hot_y, dib, local_id))
    return frames


def build_cur_file(frames):
    """Serialize a list of CursorFrame into a standard multi-frame .cur
    file byte string (ICONDIR + ICONDIRENTRY[] + image data[])."""
    count = len(frames)
    header = struct.pack('<HHH', 0, 2, count)
    entry_size = 16
    entries = b''
    image_blob = b''
    data_offset = 6 + entry_size * count
    for f in frames:
        w = f.width if f.width < 256 else 0
        h = f.height if f.height < 256 else 0
        color_count = 0
        try:
            bihsize, biw, bih, biplanes, bibitcount = struct.unpack_from('<IiiHH', f.dib, 0)
            if bibitcount != 0 and bibitcount <= 8:
                clr_used = u32(f.dib, 32) if len(f.dib) >= 36 else 0
                color_count = clr_used if clr_used else (1 << bibitcount)
                if color_count >= 256:
                    color_count = 0
        except struct.error:
            pass
        entries += struct.pack('<BBBBHHII', w, h, color_count, 0,
                                f.hotspot_x, f.hotspot_y, len(f.dib), data_offset)
        image_blob += f.dib
        data_offset += len(f.dib)
    return header + entries + image_blob


# ---------------------------------------------------------------------
# Minimal DIB -> RGBA -> PNG, used only as a dependency-free fallback
# evidence renderer when Pillow is unavailable. Handles the common cases:
# 32bpp BGRA (alpha used directly), 24bpp BGR (+AND mask), 8/4/1bpp
# palettized (+AND mask). Good enough for a visual sanity screenshot; not
# a general BMP decoder.
# ---------------------------------------------------------------------

def dib_to_rgba(dib):
    bihsize, biw, biheight_x2, biplanes, bibitcount = struct.unpack_from('<IiiHH', dib, 0)
    compression = u32(dib, 16)
    if compression not in (0, 3):  # BI_RGB or BI_BITFIELDS
        raise ValueError(f"unsupported DIB compression {compression}")
    width = biw
    height = biheight_x2 // 2  # stored height covers XOR+AND masks stacked
    colors_off = bihsize
    row_xor_stride = ((width * bibitcount + 31) // 32) * 4
    xor_size = row_xor_stride * height
    and_row_stride = ((width + 31) // 32) * 4
    and_size = and_row_stride * height

    palette = []
    if bibitcount <= 8:
        n_colors = 1 << bibitcount
        clr_used = u32(dib, 32) if bihsize >= 36 else 0
        if clr_used:
            n_colors = clr_used
        for i in range(n_colors):
            o = colors_off + i * 4
            b, g, r, _a = dib[o], dib[o + 1], dib[o + 2], dib[o + 3]
            palette.append((r, g, b))
        pixels_off = colors_off + n_colors * 4
    else:
        pixels_off = colors_off
        if compression == 3:
            pixels_off += 12  # 3 DWORD channel masks

    xor_data = dib[pixels_off:pixels_off + xor_size]
    and_data = dib[pixels_off + xor_size:pixels_off + xor_size + and_size]

    rgba = bytearray(width * height * 4)

    def put(x, y, r, g, b, a):
        row = height - 1 - y  # bottom-up DIB
        o = (row * width + x) * 4
        rgba[o:o + 4] = bytes((r, g, b, a))

    has_and = len(and_data) >= and_size and and_size > 0

    for y in range(height):
        if bibitcount == 32:
            row = xor_data[y * row_xor_stride: y * row_xor_stride + width * 4]
            for x in range(width):
                b, g, r, a = row[x * 4:x * 4 + 4]
                if a == 0 and not any((b, g, r)):
                    a = 0
                put(x, y, r, g, b, a if any(row[x * 4:x * 4 + 4]) or a else a)
        elif bibitcount == 24:
            row = xor_data[y * row_xor_stride: y * row_xor_stride + width * 3]
            and_row = and_data[y * and_row_stride: y * and_row_stride + and_row_stride] if has_and else None
            for x in range(width):
                b, g, r = row[x * 3:x * 3 + 3]
                a = 255
                if and_row is not None:
                    byte = and_row[x // 8]
                    bit = 7 - (x % 8)
                    if (byte >> bit) & 1:
                        a = 0
                put(x, y, r, g, b, a)
        elif bibitcount in (1, 4, 8):
            row_bits = xor_data[y * row_xor_stride: (y + 1) * row_xor_stride]
            and_row = and_data[y * and_row_stride: y * and_row_stride + and_row_stride] if has_and else None
            for x in range(width):
                if bibitcount == 8:
                    idx = row_bits[x]
                elif bibitcount == 4:
                    byte = row_bits[x // 2]
                    idx = (byte >> 4) if x % 2 == 0 else (byte & 0xF)
                else:
                    byte = row_bits[x // 8]
                    bit = 7 - (x % 8)
                    idx = (byte >> bit) & 1
                r, g, b = palette[idx] if idx < len(palette) else (0, 0, 0)
                a = 255
                if and_row is not None:
                    byte = and_row[x // 8]
                    bit = 7 - (x % 8)
                    if (byte >> bit) & 1:
                        a = 0
                put(x, y, r, g, b, a)
        else:
            raise ValueError(f"unsupported bit depth {bibitcount}")
    return width, height, bytes(rgba)


def write_png(path, width, height, rgba):
    def chunk(tag, payload):
        return (struct.pack('>I', len(payload)) + tag + payload +
                struct.pack('>I', zlib.crc32(tag + payload) & 0xFFFFFFFF))

    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)  # filter type 0 (None) per scanline
        raw += rgba[y * stride:(y + 1) * stride]
    idat = zlib.compress(bytes(raw), 9)
    png = sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')
    Path(path).write_bytes(png)


def render_png(cur_bytes, out_path):
    """Render the first frame of a .cur byte string to a PNG. Uses Pillow
    if importable (handles every edge case Windows itself supports);
    otherwise falls back to the small DIB decoder above."""
    try:
        from PIL import Image
        import io
        img = Image.open(io.BytesIO(cur_bytes))
        img.convert('RGBA').save(out_path)
        return 'pillow'
    except Exception:
        pass
    count = struct.unpack_from('<H', cur_bytes, 4)[0]
    w, h, ccount, _res, hx, hy, bytes_in_res, image_off = struct.unpack_from('<BBBBHHII', cur_bytes, 6)
    dib = cur_bytes[image_off:image_off + bytes_in_res]
    width, height, rgba = dib_to_rgba(dib)
    write_png(out_path, width, height, rgba)
    return 'fallback-decoder'


# ---------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------

def extract(exe_path, out_dir, wanted_ids=None):
    pe = PEImage(exe_path)
    rt_cursor = {}
    for name_id, lang_id, rva, size in find_type_entries(pe, RT_CURSOR):
        rt_cursor[name_id] = read_resource_data(pe, rva, size)

    groups = {}
    for name_id, lang_id, rva, size in find_type_entries(pe, RT_GROUP_CURSOR):
        groups.setdefault(name_id, (lang_id, rva, size))  # first language wins

    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        'source_exe': str(exe_path),
        'source_sha256': hashlib.sha256(pe.data).hexdigest(),
        'groups': {},
    }

    ids_to_do = sorted(groups) if not wanted_ids else [i for i in sorted(groups) if i in wanted_ids]
    for group_id in ids_to_do:
        lang_id, rva, size = groups[group_id]
        group_data = read_resource_data(pe, rva, size)
        frames = parse_group_cursor(pe, group_data, rt_cursor)
        cur_bytes = build_cur_file(frames)
        cur_path = out_dir / f"group_{group_id}.cur"
        cur_path.write_bytes(cur_bytes)
        png_path = out_dir / f"group_{group_id}.png"
        renderer = None
        try:
            renderer = render_png(cur_bytes, png_path)
        except Exception as exc:  # pragma: no cover - evidence only, never fatal
            sys.stderr.write(f"warning: could not render PNG for group {group_id}: {exc}\n")

        manifest['groups'][str(group_id)] = {
            'lang': lang_id,
            'frames': [
                {
                    'local_cursor_id': f.local_id,
                    'width': f.width,
                    'height': f.height,
                    'hotspot_x': f.hotspot_x,
                    'hotspot_y': f.hotspot_y,
                    'dib_bytes': len(f.dib),
                }
                for f in frames
            ],
            'cur_path': str(cur_path),
            'cur_sha256': hashlib.sha256(cur_bytes).hexdigest(),
            'png_path': str(png_path) if renderer else None,
            'png_renderer': renderer,
        }
        print(f"group {group_id}: {len(frames)} frame(s), "
              f"{frames[0].width}x{frames[0].height} hotspot=({frames[0].hotspot_x},{frames[0].hotspot_y}) "
              f"-> {cur_path.name}")

    manifest_path = out_dir / 'manifest.json'
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding='utf-8')
    print(f"wrote {manifest_path} ({len(ids_to_do)} group(s))")
    return manifest


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('exe', help='Path to the PE file to extract cursors from')
    ap.add_argument('out_dir', help='Directory to write group_<id>.cur / .png / manifest.json into')
    ap.add_argument('--ids', help='Comma-separated RT_GROUP_CURSOR ids to extract (default: all)')
    args = ap.parse_args()
    wanted = None
    if args.ids:
        wanted = {int(x, 0) for x in args.ids.split(',') if x.strip()}
    extract(args.exe, args.out_dir, wanted)


if __name__ == '__main__':
    main()
