"""Read-only camera readback of a running CY 3.71 Game.exe (cy-oracle 15/09).

OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ) + ReadProcessMemory only (no debugger, no write, no injection).
Search: every private committed readable region for the float 16:9 (Ogre::Frustum::mAspect, 0x3FE38E39 at 1280x720;
--aspect for other sizes) with an FOV (0.2..2 rad), a near (0.01..200) and a far (>= 1000) within 32 bytes before it
(color-calib 15/09 found fov, far, near, aspect consecutive), then a row-major 4x4 view matrix (orthonormal 3x3, last row
0 0 0 1) within +32..+900 bytes. Prints JSON: candidates with eye, forward, target (eye + forward * --dist), fov (deg),
pitch/yaw (deg) and the TlbbViewer argument  --camera ex,ey,ez,tx,ty,tz,fovdeg  (render units, same as d3d9_trace_diff.py
camera). With --expect x,z (game units of the player, scene offset/scale of dali_new_320 by default) candidates are ranked
by the distance of the look ray to the player.
Usage: cy_camera_read.py --pid N [--out FILE] [--expect 160,150] [--offset -16000,-15700] [--scale 100]
"""
import argparse
import ctypes
import ctypes.wintypes as wt
import json
import math
import struct
import sys

import numpy as np

k32 = ctypes.WinDLL('kernel32', use_last_error=True)


class MBI(ctypes.Structure):
    _fields_ = [('BaseAddress', ctypes.c_void_p), ('AllocationBase', ctypes.c_void_p), ('AllocationProtect', wt.DWORD),
                ('PartitionId', wt.WORD), ('RegionSize', ctypes.c_size_t), ('State', wt.DWORD), ('Protect', wt.DWORD),
                ('Type', wt.DWORD)]


k32.OpenProcess.restype = wt.HANDLE
k32.VirtualQueryEx.argtypes = [wt.HANDLE, ctypes.c_void_p, ctypes.POINTER(MBI), ctypes.c_size_t]
k32.VirtualQueryEx.restype = ctypes.c_size_t
k32.ReadProcessMemory.argtypes = [wt.HANDLE, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_size_t,
                                  ctypes.POINTER(ctypes.c_size_t)]


def regions(h):
    addr, m = 0, MBI()
    while k32.VirtualQueryEx(h, ctypes.c_void_p(addr), ctypes.byref(m), ctypes.sizeof(m)):
        base, size = m.BaseAddress or 0, m.RegionSize
        rw = m.Protect & 0x04 or m.Protect & 0x40      # PAGE_READWRITE / PAGE_EXECUTE_READWRITE
        if m.State == 0x1000 and m.Type == 0x20000 and rw and not (m.Protect & 0x100) and size < (256 << 20):
            yield base, size
        addr = base + size
        if addr >= 0x7FFFFFFFFFFF:
            break


def read(h, base, size):
    buf = ctypes.create_string_buffer(size)
    got = ctypes.c_size_t()
    if not k32.ReadProcessMemory(h, ctypes.c_void_p(base), buf, size, ctypes.byref(got)):
        return b''
    return buf.raw[:got.value]


def view_candidates(data, off):
    out = []
    for j in range(off + 32, min(len(data) - 64, off + 900), 4):
        m = np.frombuffer(data, dtype='<f4', count=16, offset=j).reshape(4, 4).astype(np.float64)
        if not np.all(np.isfinite(m)) or abs(m[3, 3] - 1) > 1e-4 or np.any(np.abs(m[3, :3]) > 1e-4):
            continue
        r = m[:3, :3]
        if np.max(np.abs(r @ r.T - np.eye(3))) > 1e-3 or abs(np.linalg.det(r) - 1) > 1e-3:
            continue
        if np.allclose(r, np.eye(3), atol=1e-4):
            continue
        out.append((j - off, m))
    return out


def proj_fov(data, off, aspect):
    # Ogre perspective matrix (row-major): row1 [0, 1/tan(fovy/2), ., 0], row3 [0, 0, -1, 0], m00 = m11 / aspect
    for j in range(max(0, off - 900), min(len(data) - 64, off + 900), 4):
        m = struct.unpack_from('<16f', data, j)
        if m[12] == 0 and m[13] == 0 and m[14] == -1.0 and m[15] == 0 and m[1] == 0 and m[4] == 0:
            if m[0] > 0 and m[5] > 0 and abs(m[5] / m[0] - aspect) < 1e-3:
                return math.degrees(2 * math.atan(1 / m[5])), j - off
    return None, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--pid', type=int, required=True)
    ap.add_argument('--out')
    ap.add_argument('--aspect', type=float, default=1280 / 720)
    ap.add_argument('--expect', default='160,150')
    ap.add_argument('--offset', default='-16000,-15700')
    ap.add_argument('--scale', type=float, default=100.0)
    ap.add_argument('--dist', type=float, default=1000.0)
    a = ap.parse_args()
    h = k32.OpenProcess(0x0400 | 0x0010, False, a.pid)
    if not h:
        raise SystemExit('OpenProcess failed %d' % ctypes.get_last_error())
    pat = struct.pack('<f', a.aspect)
    ex, ez = [float(v) for v in a.expect.split(',')]
    ox, oz = [float(v) for v in a.offset.split(',')]
    px, pz = ex * a.scale + ox, ez * a.scale + oz
    cands, scanned = [], 0
    for base, size in regions(h):
        data = read(h, base, size)
        scanned += len(data)
        i = data.find(pat)
        while i >= 0:
            if i % 4 == 0 and i >= 32:
                pre = struct.unpack_from('<8f', data, i - 32)
                fov = [v for v in pre if 0.2 < v < 2.0]
                near = [v for v in pre if 0.01 < v < 200]
                far = [v for v in pre if 1000 <= v < 1e7]
                if fov and near and far:
                    for rel, m in view_candidates(data, i):
                        r, t = m[:3, :3], m[:3, 3]
                        eye = -r.T @ t
                        fwd = -r[2]
                        pitch = math.degrees(math.asin(max(-1, min(1, -fwd[1]))))
                        yaw = math.degrees(math.atan2(fwd[0], fwd[2]))
                        # distance of player point to the look ray (ignoring height)
                        v = np.array([px - eye[0], 0, pz - eye[2]])
                        f2 = np.array([fwd[0], 0, fwd[2]])
                        n2 = np.linalg.norm(f2)
                        miss = float(np.linalg.norm(v - f2 / n2 * (v @ f2 / n2))) if n2 > 1e-6 else 1e9
                        # look target = point of the view ray above/below the player (the orbit centre of the CY camera)
                        tdist = float(v @ f2 / n2) / n2 if n2 > 1e-6 else a.dist
                        tgt = eye + fwd * (tdist if tdist > 0 else a.dist)
                        post = struct.unpack_from('<8f', data, i + 4)
                        pfov, prel = proj_fov(data, i, a.aspect)
                        cands.append({'addr': hex(base + i), 'view_rel': rel, 'fov_rad': fov[0],
                                      'proj_fovy_deg': None if pfov is None else round(pfov, 3), 'proj_rel': prel,
                                      'floats_before_aspect': [round(v, 6) for v in pre],
                                      'floats_after_aspect': [round(v, 6) for v in post],
                                      'fov_deg': round(math.degrees(fov[0]), 3), 'near': near[0], 'far': far[0],
                                      'eye': [round(x, 2) for x in eye], 'forward': [round(x, 5) for x in fwd],
                                      'pitch_down_deg': round(pitch, 2), 'yaw_deg': round(yaw, 2),
                                      'orbit_target': [round(x, 2) for x in tgt], 'orbit_distance': round(tdist, 1),
                                      'player_render_xz': [px, pz], 'ray_miss_xz': round(miss, 1),
                                      'view_row_major': [[round(x, 6) for x in row] for row in m.tolist()],
                                      'tlbbviewer': '--camera %s' % ','.join('%.2f' % x for x in list(eye) + list(tgt) + [pfov if pfov else math.degrees(fov[0])])})
            i = data.find(pat, i + 1)
    k32.CloseHandle(h)
    cands.sort(key=lambda c: c['ray_miss_xz'])
    res = {'pid': a.pid, 'scanned_mb': round(scanned / 2 ** 20, 1), 'aspect': a.aspect, 'expect_game_xz': [ex, ez],
           'candidates': cands[:12]}
    txt = json.dumps(res, ensure_ascii=False, indent=1)
    if a.out:
        open(a.out, 'w', encoding='utf-8', newline='\n').write(txt + '\n')
    best = cands[0] if cands else None
    print('camera candidates %d, scanned %.0f MB; best %s' % (len(cands), res['scanned_mb'],
          json.dumps({k: best[k] for k in ('eye', 'pitch_down_deg', 'yaw_deg', 'proj_fovy_deg', 'ray_miss_xz', 'tlbbviewer')}) if best else '-'))


if __name__ == '__main__':
    main()
