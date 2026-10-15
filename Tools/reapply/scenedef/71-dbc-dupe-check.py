# -*- coding: utf-8 -*-
"""Kiem TRUNG ID trong DBC SceneDefineEx cua client + doi chieu voi ban sao luu truoc khi noi them.

GIOI HAN CO Y (doc truoc khi dung lam bang chung): file nay CHI kiem "0 ID trung + cot 0 tang dan".
No **KHONG** biet dong nao PHAI co, nen xoa sach 242 dong reapply van ra `SO_ID_TRUNG = 0`
(da do 19/09, nhanh `reapply-guard`). Phep kiem ton tai dong la `73-scenedef-242.py verify`.

  71-dbc-dupe-check.py [--dbc F] [--bak DIR] [--stage F]     (reapply-guard 19/09: them 3 co)
"""
import struct, json, glob, os, collections, hashlib, argparse
MAGIC = b'\x00\xcc\xbb\xdd'; T_STRING = 2
DBC = r'C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ConfigFolder\SceneDefineEx.txt'
BAK = r'C:\TLBB\085\CY-Source\Build\Logs\2026-09-17-maps-cy4\backup-client'
STAGE = r'C:\TLBB\085\CY-Source\Build\world-gui\stage-fps-daiviet\Data\ConfigFolder\SceneDefineEx.txt'
# CYS-REAPPLY-GUARD 19/09: cho phep tro vao BAN SAO de tu kiem (mac dinh khong doi mot chu).
_ap = argparse.ArgumentParser(description='kiem 0 ID trung + cot 0 tang dan')
_ap.add_argument('--dbc', default=DBC, help='file DBC can kiem (mac dinh: Assets/CanonicalCY)')
_ap.add_argument('--bak', default=BAK, help='thu muc ban sao luu de doi chieu')
_ap.add_argument('--stage', default=STAGE, help='ban DBC trong stage choi thu')
_a = _ap.parse_args()
DBC, BAK, STAGE = _a.dbc, _a.bak, _a.stage

def rd(p):
    b = open(p, 'rb').read()
    nF, nR, ps = struct.unpack_from('<3I', b, 4)
    types = list(struct.unpack_from('<%dI' % nF, b, 16))
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]
    ids = [struct.unpack('<i', struct.pack('<I', cells[r * nF]))[0] for r in range(nR)]
    def s(o):
        e = pool.find(b'\0', o)
        return pool[o:e if e >= 0 else len(pool)].decode('utf-8', 'replace')
    return {'path': p, 'sha256': hashlib.sha256(b).hexdigest(), 'byte': len(b), 'nF': nF, 'nR': nR,
            'ids': ids, 'cells': cells, 'pool': pool, 'types': types, 's': s}

d = rd(DBC)
baks = sorted(glob.glob(os.path.join(BAK, 'SceneDefineEx.txt.truoc-maps-cy4-*')))
dup = {k: v for k, v in collections.Counter(d['ids']).items() if v > 1}
out = {
 'file_da_ghi': d['path'],
 'sha256': d['sha256'], 'so_byte': d['byte'],
 'so_cot': d['nF'], 'TONG_SO_DONG': d['nR'],
 'cot0_tang_dan': d['ids'] == sorted(d['ids']),
 'SO_ID_TRUNG': len(dup), 'ID_TRUNG': dup,
 'vi_tri_dong_2221_2222_2223': {k: [i for i, v in enumerate(d['ids']) if v == k] for k in (2221, 2222, 2223)},
 '5_dong_cuoi': [{'hang': i, 'id': d['ids'][i], 'ten': d['s'](d['cells'][i * d['nF'] + 1]),
                  'kt': '%dx%d' % (d['cells'][i * d['nF'] + 2], d['cells'][i * d['nF'] + 3]),
                  'scene': d['s'](d['cells'][i * d['nF'] + 4])} for i in range(d['nR'] - 5, d['nR'])],
}
for b in baks:
    e = rd(b)
    dupb = {k: v for k, v in collections.Counter(e['ids']).items() if v > 1}
    out.setdefault('ban_sao_luu', []).append(
        {'file': os.path.basename(b), 'so_dong': e['nR'], 'sha256': e['sha256'][:16],
         'co_2221_2222_2223': [k for k in (2221, 2222, 2223) if k in e['ids']],
         'so_ID_trung': len(dupb),
         'pool_giong_ban_dang_dung': e['pool'] == d['pool'],
         'cells_la_tien_to_cua_ban_moi': d['cells'][:len(e['cells'])] == e['cells']})
if os.path.exists(STAGE):
    st = rd(STAGE)
    out['stage_fps_daiviet'] = {'so_dong': st['nR'], 'sha256_giong_CanonicalCY': st['sha256'] == d['sha256']}
else:
    out['stage_fps_daiviet'] = 'duong dan la symlink toi CanonicalCY (khong co file rieng)'
print(json.dumps(out, ensure_ascii=False, indent=1))
