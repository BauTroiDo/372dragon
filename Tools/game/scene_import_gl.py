# -*- coding: utf-8 -*-
"""NHAP TAI NGUYEN CANH TU NHANH GL SANG BO DU LIEU CY (dot 17/09/2026).

VI SAO CO CONG CU NAY
  Chot 14/09 cua du an la "MOI THU nhu CY, bo GL". Ngay 17/09 nguoi dung pha le co dieu kien:
  62+ canh dang bat / cho bat KHONG CO tep `.Scene` ben CY nen client khong ve duoc ban do nao
  ca. Nhanh GL co san tai nguyen cho phan lon so do. Dieu kien nguoi dung dat ra:
  **moi tep nhap vao phai ghi nhat ky va gan the nguon GL**, de sau nay thay bang ban CY that.
  => Cong cu nay la DUONG DUY NHAT duoc phep chep GL -> CY, va no luon ghi ke khai.

NGUYEN TAC (khong duoc pha)
  1. `Assets/Canonical` (GL) CHI DOC. Khong bao gio ghi vao do.
  2. KHONG BAO GIO ghi de mot tep CY da co. Tep CY la ban goc; trung ten => BO QUA + ghi log.
     (Nho vay cong cu la idempotent va khong the lam hong du lieu CY dang chay.)
  3. `all.material` / `all.effect` / `all.particle` KHONG bi dong toi. Dot nay chi chep TEP MOI.
     Ban do nao can them muc trong 3 tep do thi bi loai khoi ke hoach, khong "chep bua".
     (BAY da biet: all.material la GBK - doc bang errors='replace' roi ghi de da pha 60.161
      vat lieu; all.effect chet im lang vi mot dong chu thich.)
  4. Moi lan `apply` deu ghi ke khai: dich, nguon, sha256, kich thuoc, ngay, canh nao dung.
  5. `verify` DOC LAI TU DIA, khong tin bien trong bo nho.

CACH DUNG
  scene_import_gl.py plan   --maps a,b,c            in ke hoach, KHONG ghi gi
  scene_import_gl.py plan   --nhom sach             ke hoach cho nhom "sach" (xem NHOM)
  scene_import_gl.py apply  --maps a,b,c [--that]   `--that` moi thuc su ghi; khong co = chay kho
  scene_import_gl.py verify --maps a,b,c            doc lai tu dia va khang dinh du tep
  scene_import_gl.py undo   --maps a,b,c [--that]   xoa dung cac tep ke khai da them
  scene_import_gl.py list                           in bang phan nhom 68 ban do
  scene_import_gl.py registry                       sinh lai Registry/batches/*.yaml + .tsv tu ke khai

NHOM
  sach   = 0 mesh/model/texture/particle/material thieu sau khi chep thu muc canh, VA khong
           can them mot dong nao vao all.material / all.particle.
  themep = nhu tren nhung phai chep them vai tep mesh/model/texture (van 0 muc all.*).
  kho    = con phai them muc vao all.material / all.particle => KHONG lam trong dot nay.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import sys
import time

BS = chr(92)  # BAY: '\' trong chuoi Python
CYS = os.path.join('C:' + os.sep, 'TLBB', '085', 'CY-Source')
CY_DATA = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data')
GL_DATA = os.path.join(CYS, 'Assets', 'Canonical', 'Data')
LOG = os.path.join(CYS, 'Build', 'Logs', '2026-09-17-scene-import-gl')
MANIFEST = os.path.join(LOG, 'manifest.jsonl')
BATCH_YAML = os.path.join(CYS, 'Registry', 'batches', '2026-09-17-scene-import-gl.yaml')
LOCK = os.path.join(LOG, '.scene_import_gl.lock')

MODEL_DIRS = ['ModelFolder'] + ['Model%dFolder' % i for i in range(2, 9)]
GL_SCENE = os.path.join(GL_DATA, 'SceneFolder')
CY_SCENE = os.path.join(CY_DATA, 'SceneFolder')
CY_SCENE2 = os.path.join(CY_DATA, 'Scene2Folder')
GL_BRUSH = os.path.join(GL_DATA, 'BrushesFolder')
CY_BRUSH = os.path.join(CY_DATA, 'BrushesFolder')

# Duoi tep cua mot canh duoc phep chep. KHONG chep bua moi thu trung ten.
DUOI_CANH = ['.Scene', '.Terrain', '.Heightmap', '.GridInfo', '.WCollision', '.path',
             '.Region', '.skysphere', '.EnScene', '.hdr', '.newhdrbloom',
             '.newhdrbloom.hdr-new', '.hfog', '.godrays', '.esd', '.lightmap.png',
             '.Fly', '.movie', '.xsd', '.tsd', '.hdr-new']

# ---------------------------------------------------------------- ten tep GBK-as-cp1252


def ten_that(n):
    """Ten tren dia la BYTE GBK doc nham thanh cp1252 -> doi ve ten that (tieng Trung)."""
    try:
        return n.encode('cp1252').decode('gbk')
    except (UnicodeEncodeError, UnicodeDecodeError):
        return None


def ten_dia(t):
    """Nguoc lai: ten that -> ten tren dia."""
    try:
        return t.encode('gbk').decode('cp1252')
    except (UnicodeEncodeError, UnicodeDecodeError):
        return None


def rec_index(bases):
    """{ten-that-thuong: duong dan tuyet doi}, quet de quy, doi ma ten."""
    out = {}
    for base in bases:
        if not os.path.isdir(base):
            continue
        for dp, dn, fn in os.walk(base):
            rel = os.path.relpath(dp, base)
            parts = [] if rel == '.' else rel.split(os.sep)
            tp, ok = [], True
            for p in parts:
                t = ten_that(p)
                if t is None:
                    ok = False
                    break
                tp.append(t)
            if not ok:
                continue
            pre = ('/'.join(tp) + '/') if tp else ''
            for f in fn:
                t = ten_that(f)
                if t is not None:
                    out.setdefault((pre + t).lower(), os.path.join(dp, f))
    return out


def sha256(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


# ---------------------------------------------------------------- doc tham chieu


def scene_refs(path):
    d = open(path, encoding='utf-8', errors='replace').read()
    g = lambda k: sorted(set(re.findall(r'<Property name="' + k + r'" value="([^"]*)"', d)))
    return {'mesh': g('mesh name'), 'model': g('model name'),
            'particle': g('particle system name'), 'material': g('material')}


def terrain_tex(path):
    if not os.path.isfile(path):
        return []
    d = open(path, encoding='utf-8', errors='replace').read()
    return sorted(set(re.findall(r'<texture filename="([^"]*)"', d)))


def ten_muc(path, kieu):
    """Ten cac muc khai bao trong all.material / all.particle (GBK, CHI DOC)."""
    txt = open(path, 'rb').read().decode('gbk', 'replace')
    if kieu == 'material':
        return {m.group(1).strip()
                for m in re.finditer(r'^\s*material\s+([^\n:]+?)\s*(?::.*)?$', txt, re.M)}
    out = set()
    for m in re.finditer(r'^\s*particle_system\s+(\S+)', txt, re.M):
        out.add(m.group(1).strip('"'))
    for m in re.finditer(r'^\s*([^\s{}/][^\n{}]*?)\s*$\s*^\s*\{', txt, re.M):
        out.add(m.group(1).strip().strip('"'))
    return out


class Idx(object):
    """Chi muc du lieu hai nhanh. Nap tre vi quet ModelFolder mat vai giay."""

    def __init__(self):
        self._c = {}

    def __getattr__(self, k):
        if k in self._c:
            return self._c[k]
        if k == 'cy_model':
            v = rec_index([os.path.join(CY_DATA, d) for d in MODEL_DIRS])
        elif k == 'gl_model':
            v = rec_index([os.path.join(GL_DATA, d) for d in MODEL_DIRS])
        elif k == 'cy_brush':
            v = rec_index([CY_BRUSH])
        elif k == 'gl_brush':
            v = rec_index([GL_BRUSH])
        elif k == 'cy_mat':
            v = ten_muc(os.path.join(CY_DATA, 'MaterialFolder', 'all.material'), 'material')
        elif k == 'cy_par':
            v = ten_muc(os.path.join(CY_DATA, 'EffectFolder', 'all.particle'), 'particle')
        elif k == 'cy_scene':
            v = {}
            for d in (CY_SCENE, CY_SCENE2):
                for n in os.listdir(d):
                    v.setdefault(n.lower(), os.path.join(d, n))
        elif k == 'gl_scene':
            v = {n.lower(): os.path.join(GL_SCENE, n) for n in os.listdir(GL_SCENE)}
        elif k == 'gl_table_map':
            # scenes-lo2 17/09: {ten .Scene (thuong): {cot 10 szSceneMap}} tu bang client GL (text, 24 cot).
            # Cot 10 la TIEN TO o minimap: FalagardSceneMap::createTiledBackground (CEGUIFalagardEx/
            # FalagardSceneMap.cpp:431,470) tim "jpg_<cot10><''|_SJ|_QX>_<x>_<y>.dds" trong nhom
            # tai nguyen General; CY de chung o Scene2Folder. Vi du yewai -> `yewaiscene`.
            v = {}
            p = os.path.join(GL_DATA, 'ConfigFolder', 'SceneDefineEx.txt')
            if os.path.isfile(p):
                for line in open(p, 'rb').read().split(b'\n'):
                    c = line.rstrip(b'\r').split(b'\t')
                    if len(c) > 10 and c[0].strip().isdigit():
                        try:
                            sc, mp = c[4].decode('utf-8').strip().lower(), c[10].decode('utf-8').strip()
                        except UnicodeDecodeError:
                            continue
                        if sc and mp:
                            v.setdefault(sc, set()).add(mp)
        elif k == 'cy_minimap':
            v = {}
            for d in (CY_SCENE, CY_SCENE2):
                for n in os.listdir(d):
                    if n.lower().startswith('jpg_'):
                        v.setdefault(n.lower(), os.path.join(d, n))
        elif k == 'gl_minimap':
            v = {n.lower(): os.path.join(GL_SCENE, n) for n in os.listdir(GL_SCENE)
                 if n.lower().startswith('jpg_')}
        else:
            raise AttributeError(k)
        self._c[k] = v
        return v


def mesh_materials(path):
    """Ten vat lieu trong chunk M_SUBMESH (0x4000) cua tep Ogre .mesh."""
    b = open(path, 'rb').read()
    out, i, n = [], 0, len(b)
    while i + 6 <= n:
        cid, clen = struct.unpack_from('<HI', b, i)
        if cid == 0x4000 and 0 < clen < n:
            j = i + 6
            e = b.find(b'\n', j, min(j + 300, n))
            if e > j:
                try:
                    out.append(b[j:e].decode('gbk'))
                except UnicodeDecodeError:
                    out.append(b[j:e].decode('latin-1'))
        i += clen if (cid == 0x4000 and 6 < clen <= n - i) else 1
    return out


# ---------------------------------------------------------------- ke hoach


def ke_hoach_mot_ban_do(m, idx, par_bo_qua=()):
    """Tra ve {tep: [(dich, nguon)], thieu_*: [...], nhom: 'sach'|'themep'|'kho'}.

    CYS-MAPSKHO48 19/09: `par_bo_qua` = ten he hat DA CHUNG MINH la khong chi mang, tu `--particle-doi-chung`.
    """
    gp = idx.gl_scene.get((m + '.scene').lower())
    r = {'map': m, 'tep': [], 'bo_qua_da_co': [], 'nhom': 'kho',
         'thieu_mesh': [], 'thieu_model': [], 'thieu_tex': [],
         'thieu_particle': [], 'thieu_material': [], 'khong_co_o_GL': []}
    if not gp:
        r['loi'] = 'GL khong co %s.Scene' % m
        return r

    # 1) tep thu muc canh
    ml = m.lower()
    for low, src in sorted(idx.gl_scene.items()):
        if not low.startswith(ml + '.'):
            continue
        duoi = os.path.basename(src)[len(m):]
        if duoi.lower() not in [d.lower() for d in DUOI_CANH]:
            continue
        dst = os.path.join(CY_SCENE, os.path.basename(src))
        if low in idx.cy_scene:
            r['bo_qua_da_co'].append([idx.cy_scene[low], src])
        else:
            r['tep'].append([dst, src, 'scene'])

    # 1b) o minimap "jpg_<tien to>[_SJ|_QX]_<x>_<y>.dds" (scenes-lo2 17/09). Tien to = cot 10 cua
    #     bang GL cho ban do nay + chinh ten ban do (huashan khong co dong bang nao). Dich la
    #     Scene2Folder (noi CY de o minimap). Khong co o thi minimap tron chi trong - khong loi.
    tien_to = {m} | set(idx.gl_table_map.get((m + '.scene').lower(), ()))
    r['minimap_tien_to'] = sorted(tien_to)
    r['so_minimap'] = 0
    for low, src in sorted(idx.gl_minimap.items()):
        if not any(re.match(r'^jpg_' + re.escape(p.lower()) + r'(_sj|_qx)?_\d+_\d+\.dds$', low)
                   for p in tien_to):
            continue
        if low in idx.cy_minimap:
            r['bo_qua_da_co'].append([idx.cy_minimap[low], src])
            continue
        r['tep'].append([os.path.join(CY_SCENE2, os.path.basename(src)), src, 'minimap'])
        r['so_minimap'] += 1

    # 2) tham chieu cua .Scene / .Terrain  (doc TU GL vi CY chua co)
    refs = scene_refs(gp)
    tex = terrain_tex(idx.gl_scene.get((m + '.terrain').lower(), ''))
    for kind, key in (('mesh', 'mesh'), ('model', 'model')):
        for x in refs[key]:
            k = x.replace(BS, '/').lower()
            if k in idx.cy_model:
                continue
            src = idx.gl_model.get(k)
            if not src:
                r['khong_co_o_GL'].append(x)
                continue
            # dich: giu NGUYEN duong dan tuong doi, va dat vao DUNG Model*Folder ma GL dung.
            # Moi Model*Folder deu nam trong cung nhom tai nguyen "General" (WXResources.cfg),
            # nen ve mat tra cuu chon cai nao cung duoc; soi guong GL cho de doi chieu ve sau.
            tag = os.path.relpath(src, GL_DATA).split(os.sep)[0]
            rel = os.path.dirname(k)
            dia_rel = os.sep.join(filter(None, [ten_dia(p) or p for p in rel.split('/')]))
            dst = os.path.join(CY_DATA, tag, dia_rel, os.path.basename(src))
            r['thieu_' + kind].append(x)
            r['tep'].append([dst, src, kind])
            # mesh keo theo .skeleton cung ten neu co
            if src.lower().endswith('.mesh'):
                sk = src[:-5] + '.skeleton'
                if os.path.isfile(sk) and (k[:-5] + '.skeleton') not in idx.cy_model:
                    r['tep'].append([dst[:-5] + '.skeleton', sk, 'skeleton'])
    for x in tex:
        k = x.replace(BS, '/').lower()
        if k in idx.cy_brush:
            continue
        src = idx.gl_brush.get(k)
        if not src:
            r['khong_co_o_GL'].append(x)
            continue
        dia_rel = os.sep.join(filter(None, [ten_dia(p) or p
                                            for p in os.path.dirname(k).split('/')]))
        r['thieu_tex'].append(x)
        r['tep'].append([os.path.join(CY_BRUSH, dia_rel, os.path.basename(src)), src, 'texture'])
    # tep .Scene/.Terrain nam trong nhom "Scene", BrushesFolder nhom "Brushes",
    # moi Model*Folder / Material*Folder deu trong nhom "General" (Bin64/WXResources.cfg).

    # 3) muc trong all.particle / all.material  -> quyet dinh nhom
    r['thieu_particle'] = [x for x in refs['particle']
                           if x not in idx.cy_par and x not in par_bo_qua]
    # CYS-MAPSKHO48: he hat bi bo qua CO Y van duoc ghi lai, khong bien mat khoi ho so.
    r['particle_bo_qua_co_y'] = [x for x in refs['particle']
                                 if x not in idx.cy_par and x in par_bo_qua]
    mat_can = set(refs['material'])
    for dst, src, kind in r['tep']:
        if kind == 'mesh':
            mat_can.update(mesh_materials(src))
    r['thieu_material'] = sorted(x for x in mat_can if x not in idx.cy_mat)

    if r['khong_co_o_GL']:
        r['nhom'] = 'kho'
    elif r['thieu_particle'] or r['thieu_material']:
        r['nhom'] = 'kho'
    elif r['thieu_mesh'] or r['thieu_model'] or r['thieu_tex']:
        r['nhom'] = 'themep'
    else:
        r['nhom'] = 'sach'
    return r


def tat_ca_ban_do(idx):
    """68 ban do GL ma CY khong co .Scene, lay tu 11-thieu-scene-full.json neu co."""
    f = os.path.join(LOG, '11-thieu-scene-full.json')
    if os.path.isfile(f):
        rows = json.load(open(f, encoding='utf-8'))
        return sorted({r['map'] for r in rows if r['gl_scene']})
    return []


def canh_dung(m):
    """Canh nao dung ban do nay (tu 11-thieu-scene-full.json)."""
    f = os.path.join(LOG, '11-thieu-scene-full.json')
    if not os.path.isfile(f):
        return []
    return [{'scene': r['scene'], 'ten': r['ten'], 'type': r['type'], 'active': r['active']}
            for r in json.load(open(f, encoding='utf-8')) if r['map'] == m]


# ---------------------------------------------------------------- ghi / kiem


def doc_manifest():
    if not os.path.isfile(MANIFEST):
        return []
    return [json.loads(l) for l in open(MANIFEST, encoding='utf-8') if l.strip()]


def ghi_manifest(recs):
    os.makedirs(os.path.dirname(MANIFEST), exist_ok=True)
    with open(MANIFEST, 'a', encoding='utf-8') as f:
        for r in recs:
            f.write(json.dumps(r, ensure_ascii=False) + '\n')


def lay_khoa():
    os.makedirs(os.path.dirname(LOCK), exist_ok=True)
    for _ in range(600):
        try:
            fd = os.open(LOCK, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.write(fd, str(os.getpid()).encode())
            os.close(fd)
            return True
        except FileExistsError:
            time.sleep(0.1)
    sys.exit('khong lay duoc khoa %s' % LOCK)


def nha_khoa():
    try:
        os.remove(LOCK)
    except OSError:
        pass


def do_apply(plans, that_su):
    now = time.strftime('%Y-%m-%dT%H:%M:%S')
    recs, n_ghi, n_bo = [], 0, 0
    for p in plans:
        if p['nhom'] == 'kho' or p.get('loi'):
            continue
        scenes = canh_dung(p['map'])
        for dst, src, kind in p['tep']:
            if os.path.exists(dst):
                n_bo += 1
                continue
            if that_su:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy2(src, dst)
            n_ghi += 1
            recs.append({
                'ngay': now, 'dot': '2026-09-17-scene-import-gl', 'map': p['map'],
                'loai': kind, 'nguon_GL': src, 'dich_CY': dst,
                'sha256': sha256(src), 'kich_thuoc': os.path.getsize(src),
                'canh_dung': scenes, 'the': 'NGUON=GL (Assets/Canonical) - CHO BAN CY THAT',
            })
    if that_su and recs:
        ghi_manifest(recs)
    return {'da_ghi': n_ghi, 'bo_qua_da_co': n_bo, 'that_su': that_su, 'so_muc': len(recs)}


def do_registry():
    """Sinh Registry/batches/2026-09-17-scene-import-gl.yaml + .tsv TU ke khai (doc lai tu dia).

    YAML la so sach nguoi doc; TSV la bang tra "tep nay tu dau ra" cho TUNG tep.
    Ca hai deu sinh lai duoc, nen khong bao gio lech voi manifest.jsonl.
    """
    man = doc_manifest()
    os.makedirs(os.path.dirname(BATCH_YAML), exist_ok=True)
    tsv = BATCH_YAML[:-5] + '.tsv'

    def q(s):
        return '"%s"' % str(s).replace('"', '""')

    maps = sorted({r['map'] for r in man})
    L = []
    L.append('# So sach dot nhap tai nguyen canh GL -> CY. SINH RA BOI Tools/game/scene_import_gl.py')
    L.append('# ("scene_import_gl.py registry") - dung sua tay, chay lai cong cu.')
    L.append('# Dieu kien nguoi dung dat ra 17/09: moi tep nhap tu GL phai ghi nhat ky + gan the nguon.')
    L.append('schema: 1')
    L.append('batch: "2026-09-17-scene-import-gl"')
    L.append('status: "applied"')
    L.append('created: %s' % q(min([r['ngay'] for r in man]) if man else ''))
    L.append('tool: "Tools/game/scene_import_gl.py (plan|apply|verify|undo|registry)"')
    L.append('nguon:')
    L.append('  nhanh: "GL"')
    L.append('  root: "C:/TLBB/085/CY-Source/Assets/Canonical/Data"')
    L.append('  ghi_chu: "nhanh GL CHI DOC - cong cu khong bao gio ghi vao day"')
    L.append('dich:')
    L.append('  root: "C:/TLBB/085/CY-Source/Assets/CanonicalCY/Data"')
    L.append('  ghi_chu: "khong bao gio ghi de tep CY da co; trung ten = BO QUA"')
    L.append('the_nguon: "NGUON=GL (Assets/Canonical) - CHO BAN CY THAT"')
    L.append('ke_khai_chi_tiet: "Build/Logs/2026-09-17-scene-import-gl/manifest.jsonl"')
    L.append('bang_tra_tung_tep: "Registry/batches/2026-09-17-scene-import-gl.tsv"')
    L.append('tong:')
    L.append('  so_ban_do: %d' % len(maps))
    L.append('  so_tep: %d' % len(man))
    L.append('  tong_byte: %d' % sum(r['kich_thuoc'] for r in man))
    loai = {}
    for r in man:
        loai[r['loai']] = loai.get(r['loai'], 0) + 1
    L.append('  theo_loai:')
    for k in sorted(loai):
        L.append('    %s: %d' % (k, loai[k]))
    L.append('ban_do:')
    for m in maps:
        rs = [r for r in man if r['map'] == m]
        L.append('  - map: %s' % q(m))
        L.append('    so_tep: %d' % len(rs))
        L.append('    byte: %d' % sum(r['kich_thuoc'] for r in rs))
        L.append('    canh_dung:')
        for s in (rs[0]['canh_dung'] or []):
            L.append('      - { scene: %s, ten: %s, type: %s, active: %s }'
                     % (s['scene'], q(s['ten']), q(s['type']), q(s['active'])))
    L.append('hoan_tac: "python -X utf8 Tools/game/scene_import_gl.py undo --maps <ds> --that"')
    L.append('ap_lai_sau_khi_dung_lai_canonical:')
    L.append('  - "python -X utf8 Tools/game/scene_import_gl.py apply --maps %s --that"'
             % ','.join(maps))
    L.append('  - "python -X utf8 Tools/game/scene_import_gl.py verify --maps %s"' % ','.join(maps))
    open(BATCH_YAML, 'w', encoding='utf-8').write('\n'.join(L) + '\n')

    T = ['dich_CY\tnguon_GL\tten_that\tloai\tmap\tcanh\tsha256\tkich_thuoc\tngay']
    for r in man:
        tt = ten_that(os.path.basename(r['nguon_GL'])) or os.path.basename(r['nguon_GL'])
        canh = ';'.join(str(s['scene']) for s in (r['canh_dung'] or []))
        T.append('\t'.join([r['dich_CY'], r['nguon_GL'], tt, r['loai'], r['map'], canh,
                            r['sha256'], str(r['kich_thuoc']), r['ngay']]))
    open(tsv, 'w', encoding='utf-8').write('\n'.join(T) + '\n')
    return {'yaml': BATCH_YAML, 'tsv': tsv, 'so_tep': len(man), 'so_ban_do': len(maps)}


def do_verify(maps, idx):
    """DOC LAI TU DIA. Voi moi ban do: du tep canh? con thieu tham chieu nao?"""
    man = {r['dich_CY']: r for r in doc_manifest()}
    out = []
    for m in maps:
        cy = {}
        for d in (CY_SCENE, CY_SCENE2):
            for n in os.listdir(d):
                if n.lower().startswith(m.lower() + '.'):
                    cy[n.lower()] = os.path.join(d, n)
        r = {'map': m, 'co_Scene': (m + '.scene').lower() in cy, 'so_tep_canh': len(cy),
             'loi': []}
        for e in ('.Scene', '.Terrain', '.Heightmap', '.GridInfo'):
            if (m + e).lower() not in cy:
                r['loi'].append('THIEU ' + e)
        for e in ('.WCollision', '.path'):
            if (m + e).lower() not in cy:
                r['loi'].append('THIEU (nen co) ' + e)
        if r['co_Scene']:
            refs = scene_refs(cy[(m + '.scene').lower()])
            tex = terrain_tex(cy.get((m + '.terrain').lower(), ''))
            tm = [x for x in refs['mesh'] if x.replace(BS, '/').lower() not in idx.cy_model]
            to = [x for x in refs['model'] if x.replace(BS, '/').lower() not in idx.cy_model]
            tt = [x for x in tex if x.replace(BS, '/').lower() not in idx.cy_brush]
            tp = [x for x in refs['particle'] if x not in idx.cy_par]
            r['thieu'] = {'mesh': tm, 'model': to, 'texture': tt, 'particle': tp}
            for k, v in r['thieu'].items():
                if v:
                    r['loi'].append('THIEU %d %s' % (len(v), k))
            # o minimap co mat trong CY (thong tin, KHONG phai loi: thieu thi minimap tron trong)
            tien_to = {m} | set(idx.gl_table_map.get((m + '.scene').lower(), ()))
            r['minimap_o'] = sum(1 for low in idx.cy_minimap
                                 if any(re.match(r'^jpg_' + re.escape(p.lower()) + r'(_sj|_qx)?_\d+_\d+\.dds$', low)
                                        for p in tien_to))
        # doi chieu sha256 voi ke khai
        sai_hash = []
        for low, p in cy.items():
            if p in man and sha256(p) != man[p]['sha256']:
                sai_hash.append(p)
        if sai_hash:
            r['loi'].append('SHA256 khac ke khai: %d tep' % len(sai_hash))
        r['ok'] = not r['loi']
        out.append(r)
    return out


# ---------------------------------------------------------------- CLI


def chon_maps(args, idx):
    if args.maps:
        return [x.strip() for x in args.maps.split(',') if x.strip()]
    return tat_ca_ban_do(idx)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('lenh', choices=['plan', 'apply', 'verify', 'undo', 'list', 'registry'])
    ap.add_argument('--maps', default='')
    ap.add_argument('--nhom', default='', choices=['', 'sach', 'themep', 'kho'])
    ap.add_argument('--that', action='store_true', help='apply/undo: THUC SU ghi/xoa')
    # CYS-MAPSKHO48 19/09: he hat THIEU khong phai loi chi mang. Doi chung tren 154 ban do cua canh
    # `type=0` DANG BAT + `client=OK`: 4 ban do van thieu he hat ma van ve (`DHXYyongningcheng` thieu
    # DUNG `cj_妖塔_方向雾_黄`), 12 ban do con thieu ca `.path`. Bang chung:
    # Build/Logs/2026-09-19-maps-kho48/26-verify-154-dangbat.json.
    # Co MAC DINH TAT: chi bo qua ten duoc goi ten, va ten bi bo qua van hien o `particle_bo_qua_co_y`.
    ap.add_argument('--particle-doi-chung', default='',
                    help='ten he hat (ngan bang dau phay) DA CHUNG MINH khong chi mang tren mot canh '
                         'DANG VE; chung se khong xep ban do vao nhom `kho`')
    ap.add_argument('--out', default='')
    args = ap.parse_args()

    idx = Idx()

    if args.lenh == 'registry':
        rec = {'lenh': 'registry', 'ket_qua': do_registry()}
        print(json.dumps(rec, ensure_ascii=False, indent=1))
        return

    maps = chon_maps(args, idx)

    if args.lenh in ('plan', 'apply', 'list'):
        par_bo = {x.strip() for x in args.particle_doi_chung.split(',') if x.strip()}
        plans = [ke_hoach_mot_ban_do(m, idx, par_bo) for m in maps]
        if args.nhom:
            plans = [p for p in plans if p['nhom'] == args.nhom]
        rec = {'lenh': args.lenh, 'so_ban_do': len(plans),
               'nhom': {k: sum(1 for p in plans if p['nhom'] == k)
                        for k in ('sach', 'themep', 'kho')},
               'chi_tiet': [{'map': p['map'], 'nhom': p['nhom'], 'so_tep': len(p['tep']),
                             'da_co': len(p['bo_qua_da_co']),
                             'so_minimap': p.get('so_minimap', 0),
                             'minimap_tien_to': p.get('minimap_tien_to', []),
                             'thieu_material': p['thieu_material'],
                             'thieu_particle': p['thieu_particle'],
                             'particle_bo_qua_co_y': p.get('particle_bo_qua_co_y', []),
                             'khong_co_o_GL': p['khong_co_o_GL']} for p in plans]}
        if args.lenh == 'apply':
            lay_khoa()
            try:
                rec['ket_qua'] = do_apply(plans, args.that)
            finally:
                nha_khoa()
    elif args.lenh == 'verify':
        rec = {'lenh': 'verify', 'ket_qua': do_verify(maps, idx)}
        rec['ok'] = all(x['ok'] for x in rec['ket_qua'])
        rec['so_dat'] = sum(1 for x in rec['ket_qua'] if x['ok'])
        rec['so_hong'] = sum(1 for x in rec['ket_qua'] if not x['ok'])
    else:  # undo
        lay_khoa()
        try:
            man = doc_manifest()
            xoa = [r for r in man if r['map'] in maps and os.path.exists(r['dich_CY'])]
            if args.that:
                for r in xoa:
                    os.remove(r['dich_CY'])
            rec = {'lenh': 'undo', 'that_su': args.that, 'so_xoa': len(xoa),
                   'tep': [r['dich_CY'] for r in xoa]}
        finally:
            nha_khoa()

    print(json.dumps(rec, ensure_ascii=False, indent=1))
    if args.out:
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        json.dump(rec, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)


if __name__ == '__main__':
    main()
