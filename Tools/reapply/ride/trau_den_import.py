#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ride-finish (18/09/2026) — dua thu cuoi NGUOI DUNG TU LAM `Trau Den` (越南黑水牛, 06/09, model trau JX3 10/09)
tu client_GL vao Assets/CanonicalCY, theo ngoai le da duyet cho tai nguyen GL: CHI THEM, KHONG DE, ke khai
nguon + sha256 vao Registry/batches/.

    python -X utf8 Tools/reapply/ride/trau_den_import.py plan
    python -X utf8 Tools/reapply/ride/trau_den_import.py apply   [--bak Build/reapply-bak/trau-den]
    python -X utf8 Tools/reapply/ride/trau_den_import.py verify
    python -X utf8 Tools/reapply/ride/trau_den_import.py undo --bak DIR

CHUOI NGOAI HINH (client CY): ride 1180 (server, 模型索引 1220) -> CharMount 1220 -> CharModelEx 9994 (trau_den.obj)
  -> all.obj <Object name="trau_den.obj"> (Entity trau_den.mesh, material trau_den, 11 locator ke ca attach1)
  -> Model3Folder/trau_den.mesh + trau_den.skeleton (JX3, 64 xuong, 7 animation ten nhu ActionSet 白牦牛)
  -> all.material `material trau_den : Mtl_Character_PSLit` (template co trong MaterialTemplates.zip cua CY)
  -> Material5Folder/tga_trau_den.dds.

DONG DBC MOI (nhi phan 00CCBBDD, noi them dong o CUOI + noi pool string, giu nguyen moi byte cu):
  CharMount 1220        = ban sao dong 17 白牦牛 cua CY (con vat goc cua Trau Den) doi id/ten/ModelID:
                          rider 829/1425 (女/男主角_白牦牛), col 5 = 461 (CY 白牦牛 cung 461), AddHeight 0.6, khong bay.
  CharModelEx 9994      = ban sao dong 1006 白牦牛.obj doi id + ten obj (linked id ho 牦牛 3166..3176, ActionSet 1481 白牦牛.txt).
  ExteriorRideCamera 1220 = ban sao dong 17 doi id + ten.
Ma hoa: pool CY la GBK cho ten (虎, 白牦牛...) => ten 越南黑水牛 ghi GBK (giong bang server). `attach1` dung lai offset co san.

Server KHONG can doi: ride 1180 (dai do xe 1000+r) da tro 模型索引 1220 va impact 骑乘ID 1220. Cap cho nhan vat test:
`ride_grant.py grant --guid 200016 --ride 1180 --apply`.
"""
import argparse
import datetime
import hashlib
import json
import os
import shutil
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
GL = r'C:\TLBB\085\client_GL\Data'
CY = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data')
DATA = os.path.join(HERE, 'data')
BATCH = '2026-09-18-trau-den-cy'
MAGIC = b'\x00\xcc\xbb\xdd'
T_INT, T_FLOAT, T_STRING = 0, 1, 2

FILES = [('Model3Folder', 'trau_den.mesh'), ('Model3Folder', 'trau_den.skeleton'),
         ('Material5Folder', 'tga_trau_den.dds')]
OBJ_MARK = b'<Object name="trau_den.obj">'
MAT_MARK = b'material trau_den'
NAME_GBK = '越南黑水牛'.encode('gbk')
CM_ID, CME_ID, TEMPLATE_CM, TEMPLATE_CME = 1220, 9994, 17, 1006


def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


# --------------------------------------------------------------------------- DBC
def dbc_read(path):
    raw = open(path, 'rb').read()
    if raw[:4] != MAGIC:
        raise SystemExit('khong phai DBC: %s' % path)
    _, fields, records, strings = struct.unpack_from('<Iiii', raw, 0)
    types = list(struct.unpack_from('<%dI' % fields, raw, 16))
    base = 16 + 4 * fields
    cells = list(struct.unpack_from('<%dI' % (fields * records), raw, base))
    pool = raw[base + 4 * fields * records: base + 4 * fields * records + strings]
    return types, records, cells, pool


def dbc_decode_row(types, cells, pool, r):
    out = []
    n = len(types)
    for c in range(n):
        v = cells[r * n + c]
        t = types[c]
        if t == T_FLOAT:
            out.append(round(struct.unpack('<f', struct.pack('<I', v))[0], 6))
        elif t == T_STRING:
            end = pool.find(b'\0', v)
            out.append(pool[v:end] if 0 <= v < len(pool) and end >= 0 else b'')
        else:
            out.append(struct.unpack('<i', struct.pack('<I', v))[0])
    return out


def dbc_rows(path):
    types, records, cells, pool = dbc_read(path)
    return types, [dbc_decode_row(types, cells, pool, r) for r in range(records)], pool


def pool_offset(pool, s):
    """Offset cua chuoi s da co trong pool (NUL-terminated, dau chuoi = sau NUL hoac dau pool), hoac None."""
    needle = s + b'\0'
    k = pool.find(needle)
    while k >= 0:
        if k == 0 or pool[k - 1] == 0:
            return k
        k = pool.find(needle, k + 1)
    return None


def dbc_append_rows(path, new_rows):
    """Noi dong o CUOI (id moi phai > id lon nhat) + noi pool. Tra ve raw moi (chua ghi)."""
    types, records, cells, pool = dbc_read(path)
    n = len(types)
    ids = [struct.unpack('<i', struct.pack('<I', cells[r * n]))[0] for r in range(records)]
    if ids != sorted(ids):
        raise SystemExit('cot 0 cua %s khong tang dan' % path)
    pool = bytearray(pool)
    if not pool or pool[-1] != 0:
        pool.append(0)
    add = []
    for row in new_rows:
        if len(row) != n:
            raise SystemExit('dong moi %r co %d o, bang %d o' % (row[0], len(row), n))
        if row[0] <= ids[-1]:
            raise SystemExit('id %d khong lon hon id cuoi %d (%s)' % (row[0], ids[-1], os.path.basename(path)))
        enc = []
        for c, v in enumerate(row):
            t = types[c]
            if t == T_STRING:
                s = v if isinstance(v, bytes) else str(v).encode('gbk')
                off = pool_offset(bytes(pool), s)
                if off is None:
                    off = len(pool)
                    pool += s + b'\0'
                enc.append(off)
            elif t == T_FLOAT:
                enc.append(struct.unpack('<I', struct.pack('<f', float(v)))[0])
            else:
                enc.append(struct.unpack('<I', struct.pack('<i', int(v)))[0])
        add.append(enc)
        ids.append(row[0])
    out = bytearray(MAGIC)
    out += struct.pack('<iii', n, records + len(add), len(pool))
    out += struct.pack('<%dI' % n, *types)
    out += struct.pack('<%dI' % len(cells), *cells)
    for enc in add:
        out += struct.pack('<%dI' % n, *enc)
    out += bytes(pool)
    return bytes(out)


# --------------------------------------------------------------------------- ke hoach
def build_plan():
    P = {'batch': BATCH, 'files': [], 'appends': [], 'dbc': [], 'skip': [], 'abort': []}
    for sub, name in FILES:
        src = os.path.join(GL, sub, name)
        dst = os.path.join(CY, sub, name)
        if not os.path.exists(src):
            P['abort'].append('thieu nguon %s' % src)
            continue
        ssha = sha(src)
        if os.path.exists(dst):
            if sha(dst) == ssha:
                P['skip'].append('%s/%s da co, cung sha' % (sub, name))
            else:
                P['abort'].append('%s/%s DA CO ben CY voi noi dung KHAC — khong de' % (sub, name))
            continue
        P['files'].append({'src': src, 'dst': dst, 'sha256': ssha, 'bytes': os.path.getsize(src)})

    obj = os.path.join(CY, 'ModelFolder', 'all.obj')
    raw = open(obj, 'rb').read()
    blk = open(os.path.join(DATA, 'trau_den.obj.block.xml'), 'rb').read()
    if OBJ_MARK in raw:
        P['skip'].append('all.obj da co Object trau_den.obj')
    else:
        k = raw.rfind(b'</AllObjects>')
        if k < 0:
            P['abort'].append('all.obj khong co </AllObjects>')
        else:
            P['appends'].append({'file': obj, 'at': k, 'insert_bytes': len(blk), 'what': 'Object trau_den.obj (11 locator, effects)'})
    mat = os.path.join(CY, 'MaterialFolder', 'all.material')
    raw = open(mat, 'rb').read()
    mblk = open(os.path.join(DATA, 'trau_den.material.txt'), 'rb').read()
    if MAT_MARK in raw:
        P['skip'].append('all.material da co material trau_den')
    else:
        P['appends'].append({'file': mat, 'at': len(raw), 'insert_bytes': len(mblk) + 2, 'what': 'material trau_den : Mtl_Character_PSLit (tga_trau_den.dds)'})

    # DBC
    cm_path = os.path.join(CY, 'ConfigFolder', 'CharMount.txt')
    types, rows, _ = dbc_rows(cm_path)
    by = dict((r[0], r) for r in rows)
    if CM_ID in by:
        P['skip'].append('CharMount %d da co: %s' % (CM_ID, by[CM_ID][1].decode('gbk', 'replace')))
    else:
        t = list(by[TEMPLATE_CM])
        t[0], t[1], t[3] = CM_ID, NAME_GBK, CME_ID
        P['dbc'].append({'file': cm_path, 'row': [x.decode('latin-1') if isinstance(x, bytes) else x for x in t],
                         'template': TEMPLATE_CM})
    cme_path = os.path.join(CY, 'ConfigFolder', 'CharModelEx.txt')
    types, rows, _ = dbc_rows(cme_path)
    by = dict((r[0], r) for r in rows)
    if CME_ID in by:
        P['skip'].append('CharModelEx %d da co: %s' % (CME_ID, by[CME_ID][1].decode('gbk', 'replace')))
    else:
        t = list(by[TEMPLATE_CME])
        t[0], t[1], t[2] = CME_ID, b'trau_den.obj', b'trau_den.obj'
        P['dbc'].append({'file': cme_path, 'row': [x.decode('latin-1') if isinstance(x, bytes) else x for x in t],
                         'template': TEMPLATE_CME})
    erc_path = os.path.join(CY, 'ConfigFolder', 'ExteriorRideCamera.txt')
    types, rows, _ = dbc_rows(erc_path)
    by = dict((r[0], r) for r in rows)
    if CM_ID in by:
        P['skip'].append('ExteriorRideCamera %d da co' % CM_ID)
    else:
        t = list(by[TEMPLATE_CM])
        t[0], t[1] = CM_ID, NAME_GBK
        P['dbc'].append({'file': erc_path, 'row': [x.decode('latin-1') if isinstance(x, bytes) else x for x in t],
                         'template': TEMPLATE_CM})
    return P


def apply(bak_root):
    P = build_plan()
    if P['abort']:
        print(json.dumps(P, ensure_ascii=False, indent=1))
        return 2
    if not (P['files'] or P['appends'] or P['dbc']):
        print('khong co gi de lam (idempotent)')
        return 0
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(bak_root, stamp)
    os.makedirs(bak, exist_ok=True)
    touched = set(a['file'] for a in P['appends']) | set(d['file'] for d in P['dbc'])
    before = {}
    for f in touched:
        shutil.copy2(f, os.path.join(bak, os.path.basename(f)))
        before[f] = sha(f)
    manifest = []
    today = datetime.date.today().isoformat()
    for f in P['files']:
        os.makedirs(os.path.dirname(f['dst']), exist_ok=True)
        shutil.copy2(f['src'], f['dst'])
        if sha(f['dst']) != f['sha256']:
            raise SystemExit('chep hong: %s' % f['dst'])
        manifest.append([f['dst'], f['src'], os.path.basename(f['dst']), 'file-them-moi', f['sha256'], f['bytes'], today, 'NGUON=GL client_GL (Trau Den do nguoi dung lam 06-10/09)'])
    for a in P['appends']:
        raw = open(a['file'], 'rb').read()
        if a['file'].endswith('all.obj'):
            blk = open(os.path.join(DATA, 'trau_den.obj.block.xml'), 'rb').read()
            k = raw.rfind(b'</AllObjects>')
            new = raw[:k] + blk + raw[k:]
        else:
            mblk = open(os.path.join(DATA, 'trau_den.material.txt'), 'rb').read()
            new = raw + (b'' if raw.endswith(b'\n') else b'\r\n') + b'\r\n' + mblk
        tmp = a['file'] + '.cys-tmp'
        open(tmp, 'wb').write(new)
        os.replace(tmp, a['file'])
        manifest.append([a['file'], os.path.join(DATA, os.path.basename(a['file']) == 'all.obj' and 'trau_den.obj.block.xml' or 'trau_den.material.txt'),
                         os.path.basename(a['file']), 'noi-them-khoi', sha(a['file']), os.path.getsize(a['file']), today,
                         'them %d byte tai offset %d; sha truoc %s' % (a['insert_bytes'], a['at'], before[a['file']])])
    for d in P['dbc']:
        row = [x.encode('latin-1') if isinstance(x, str) else x for x in d['row']]
        new = dbc_append_rows(d['file'], [row])
        tmp = d['file'] + '.cys-tmp'
        open(tmp, 'wb').write(new)
        os.replace(tmp, d['file'])
        manifest.append([d['file'], 'ban sao dong %d cua chinh bang' % d['template'], os.path.basename(d['file']), 'dbc-them-dong',
                         sha(d['file']), os.path.getsize(d['file']), today, 'them dong id %s; sha truoc %s' % (row[0], before[d['file']])])
    # so sach
    reg = os.path.join(CYS, 'Registry', 'batches')
    os.makedirs(reg, exist_ok=True)
    tsv = os.path.join(reg, BATCH + '.tsv')
    new_file = not os.path.exists(tsv)
    with open(tsv, 'a', encoding='utf-8', newline='\n') as fh:
        if new_file:
            fh.write('dich_CY\tnguon\tten_that\tloai\tsha256\tkich_thuoc\tngay\tghi_chu\n')
        for m in manifest:
            fh.write('\t'.join(str(x) for x in m) + '\n')
    yml = os.path.join(reg, BATCH + '.yaml')
    if not os.path.exists(yml):
        with open(yml, 'w', encoding='utf-8', newline='\n') as fh:
            fh.write('# So sach: thu cuoi Trau Den (越南黑水牛) nguoi dung tu lam, dua tu client_GL vao CanonicalCY (ride-finish 18/09).\n')
            fh.write('# Ngoai le da duyet 17/09 cho tai nguyen GL: chi them, khong de, moi tep co nguon + sha256. Sinh boi Tools/reapply/ride/trau_den_import.py.\n')
            fh.write('schema: 1\nbatch: "%s"\nstatus: "applied"\ncreated: "%s"\n' % (BATCH, datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S')))
            fh.write('tool: "Tools/reapply/ride/trau_den_import.py (plan|apply|verify|undo)"\n')
            fh.write('nguon:\n  nhanh: "GL"\n  root: "C:/TLBB/085/client_GL/Data"\n  ghi_chu: "chi doc; Trau Den = model trau JX3 (Tools/DATA NEW/trau) do nguoi dung dung 06-10/09"\n')
            fh.write('dich:\n  root: "C:/TLBB/085/CY-Source/Assets/CanonicalCY/Data"\n  ghi_chu: "khong ghi de tep/dong CY da co"\n')
            fh.write('the_nguon: "NGUON=GL (client_GL) - THU CUOI NGUOI DUNG TU LAM, KHONG PHAI CY"\n')
            fh.write('bang_tra_tung_tep: "Registry/batches/%s.tsv"\n' % BATCH)
            fh.write('chuoi:\n  ride_server: 1180\n  charmount_cy: 1220\n  charmodelex_cy: 9994\n  obj: "trau_den.obj"\n  mesh: "Model3Folder/trau_den.mesh"\n  skeleton: "Model3Folder/trau_den.skeleton"\n  material: "trau_den (all.material, Mtl_Character_PSLit)"\n  texture: "Material5Folder/tga_trau_den.dds"\n')
    print(json.dumps({'backup': bak, 'files': len(P['files']), 'appends': len(P['appends']), 'dbc': len(P['dbc']),
                      'registry': tsv}, ensure_ascii=False, indent=1))
    return 0


def verify():
    rep = {'ok': True, 'checks': []}

    def chk(name, ok, detail=''):
        rep['checks'].append({'name': name, 'ok': bool(ok), 'detail': detail})
        if not ok:
            rep['ok'] = False
    for sub, name in FILES:
        src = os.path.join(GL, sub, name)
        dst = os.path.join(CY, sub, name)
        chk('tep %s/%s co va cung sha voi GL' % (sub, name), os.path.exists(dst) and sha(dst) == sha(src))
    raw = open(os.path.join(CY, 'ModelFolder', 'all.obj'), 'rb').read()
    chk('all.obj co dung 1 Object trau_den.obj, van ket thuc </AllObjects>', raw.count(OBJ_MARK) == 1 and raw.rstrip().endswith(b'</AllObjects>'))
    chk('all.obj khoi trau_den giai ma GBK', raw[raw.find(OBJ_MARK):raw.find(b'</Object>', raw.find(OBJ_MARK))].decode('gbk', 'strict') is not None)
    raw = open(os.path.join(CY, 'MaterialFolder', 'all.material'), 'rb').read()
    chk('all.material co dung 1 material trau_den', raw.count(MAT_MARK) == 1)
    types, rows, pool = dbc_rows(os.path.join(CY, 'ConfigFolder', 'CharMount.txt'))
    by = dict((r[0], r) for r in rows)
    r = by.get(CM_ID)
    chk('CharMount 1220 = 越南黑水牛, ModelID 9994, rider 829/1425, attach1', bool(r) and r[1] == NAME_GBK and r[3] == CME_ID and r[6] == 829 and r[7] == 1425 and r[8] == b'attach1',
        str([x.decode('gbk', 'replace') if isinstance(x, bytes) else x for x in r]) if r else 'thieu')
    chk('CharMount: 354 dong, cot 0 tang dan, pool ket thuc NUL', len(rows) == 354 and [x[0] for x in rows] == sorted(x[0] for x in rows) and pool.endswith(b'\0'))
    types, rows, pool = dbc_rows(os.path.join(CY, 'ConfigFolder', 'CharModelEx.txt'))
    by = dict((r[0], r) for r in rows)
    r = by.get(CME_ID)
    chk('CharModelEx 9994 = trau_den.obj, ActionSet 1481', bool(r) and r[1] == b'trau_den.obj' and r[2] == b'trau_den.obj' and r[20] == 1481,
        str([x.decode('gbk', 'replace') if isinstance(x, bytes) else x for x in r]) if r else 'thieu')
    chk('CharModelEx: 7617 dong, cot 0 tang dan', len(rows) == 7617 and [x[0] for x in rows] == sorted(x[0] for x in rows))
    types, rows, pool = dbc_rows(os.path.join(CY, 'ConfigFolder', 'ExteriorRideCamera.txt'))
    by = dict((r[0], r) for r in rows)
    chk('ExteriorRideCamera 1220 co', CM_ID in by and by[CM_ID][1] == NAME_GBK)
    # doc lai bang Tools/game/dbc_inventory.Table (mo phong TLBB_DBC.cpp)
    try:
        sys.path.insert(0, os.path.join(CYS, 'Tools', 'game'))
        import dbc_inventory
        t = dbc_inventory.Table(os.path.join(CY, 'ConfigFolder', 'CharMount.txt'))
        n = getattr(t, 'records', None) or getattr(t, 'nrows', None) or (len(t.rows) if hasattr(t, 'rows') else None)
        chk('dbc_inventory.Table doc lai CharMount', n in (354, None), 'records=%s' % n)
    except Exception as e:  # noqa: BLE001
        chk('dbc_inventory.Table doc lai CharMount', False, repr(e)[:200])
    return rep


def undo(bak):
    n = 0
    for name in os.listdir(bak):
        src = os.path.join(bak, name)
        for sub in ('ModelFolder', 'MaterialFolder', 'ConfigFolder'):
            dst = os.path.join(CY, sub, name)
            if os.path.exists(dst):
                shutil.copy2(src, dst)
                print('tra lai', dst)
                n += 1
    for sub, name in FILES:
        dst = os.path.join(CY, sub, name)
        if os.path.exists(dst):
            os.remove(dst)
            print('xoa tep da them', dst)
            n += 1
    return 0 if n else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('plan', 'apply', 'verify', 'undo'))
    ap.add_argument('--bak', default=os.path.join(CYS, 'Build', 'reapply-bak', 'trau-den'))
    a = ap.parse_args()
    if a.cmd == 'plan':
        print(json.dumps(build_plan(), ensure_ascii=False, indent=1))
        return 0
    if a.cmd == 'apply':
        return apply(a.bak)
    if a.cmd == 'verify':
        rep = verify()
        print(json.dumps(rep, ensure_ascii=False, indent=1))
        return 0 if rep['ok'] else 1
    return undo(a.bak)


if __name__ == '__main__':
    sys.exit(main())
