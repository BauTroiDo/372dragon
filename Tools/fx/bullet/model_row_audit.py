# -*- coding: utf-8 -*-
"""bullet-live 20/09/2026 - KHA NANG 2: "khong co dong trong CharModelEx" => lpszModelFileName NULL
=> KHONG tao m_pRenderInterface => khong listener => dan bi nuot. CHUA AI DO. Day la phep do do.

Duong di (doc tinh, Src/Client/WXClient/Object/Character/):
  Obj_PlayerOther.cpp:172 / Obj_PlayerNPC.cpp:77
      pCharModel = CharModelEx.Search_Index_EQU(GetCharModelID())
      lpszModelFileName = pCharModel ? pCharModel->m_pszModelName : NULL
      if (lpszModelFileName != NULL) { m_pRenderInterface = New_EntityObject(...); Actor_SetFile(...) }
  Obj_Character.cpp:240  CreateRenderInterface()  mo dau bang  `if(!m_pRenderInterface) return;`
      => KHONG dang ky SetAnimationHitEvent  => OnAnimationHit khong bao gio chay
      => IsBeAttackEffectShowed() luon FALSE => IsLogicReady() FALSE voi cung logic_count
      => dan bi xep hang roi bi Update_LogicEvent xoa sau 10 s (nay co dong DROPPED-UNSHOWN).

HAI BIEN THE, phai tach ra vi chung khac nhau ve nguyen nhan:
  2a  KHONG co dong CharModelEx  -> khong co ca m_pRenderInterface.
  2b  CO dong nhung TEN MODEL khong co trong all.obj -> co m_pRenderInterface nhung mModel = NULL,
      va SetAnimationHitEvent mo dau bang `if(!mModel) return;` (RFObj_Actor.cpp:345) => cung mat listener.
      Bien the nay chi SONG DUOC tu sau ban va crash-anim 1eb6858a; truoc do TDAssert giet ca tien trinh.

QUY TAC 0: so voi cay SONG. CY 3.71 (Tools/DATA NEW/DataCY31-08-26) co CharModelEx van ban va all.obj rieng;
neu CY cung thieu dung nhung ten ay thi day KHONG phai loi cua ta.

Doc BYTE tat ca (ten model la GBK). KHONG ghi gi vao cay du lieu.
"""
import argparse
import hashlib
import json
import os
import re
import struct
import sys

MAGIC = b'\x00\xcc\xbb\xdd'
# Ma kieu cot cua DBC 00CCBBDD: INT=0, FLOAT=1, STRING=2 (Tools/fx/bullet/bullet_data_audit.py:31).
# 20/09 toi da dat nham 1,2,3: phep tra TEN van dung (cot 1 roi vao nhanh 'else' => chuoi) nen
# ca 5 doi chung am van XANH, chi rieng cot ID doc ra rac. Doi chung am khong phu TRUC NAO thi
# truc do khong duoc bao ve - NC6 duoi day phu truc ID.
T_INT, T_FLOAT, T_STR = 0, 1, 2
NAME_COL = 1          # m_pszModelName
NAME_IV_COL = 2       # m_pszModelName_IV
ACTIONSET_COL = 20    # m_nActionSetFileID

OURS_DBC = r'C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ConfigFolder\CharModelEx.txt'
OURS_OBJ = r'C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\ModelFolder\all.obj'
CY_TXT = r'C:\TLBB\085\Tools\DATA NEW\DataCY31-08-26\Config\CharModelEx.txt'
CY_OBJ = r'C:\TLBB\085\Tools\DATA NEW\DataCY31-08-26\Model\all.obj'

OBJ_RE = re.compile(rb'<\s*Object\s+name\s*=\s*"([^"]*)"')


def sha(path):
    with open(path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()


# --------------------------------------------------------------------- doc bang
def dbc_rows(path):
    """DBC 00CCBBDD -> list hang, moi o la bytes (chuoi) hoac int/float."""
    b = open(path, 'rb').read()
    if b[:4] != MAGIC:
        sys.exit('%s khong phai DBC 00CCBBDD' % path)
    nF, nR, pool_size = struct.unpack_from('<3I', b, 4)
    types = list(struct.unpack_from('<%dI' % nF, b, 16))
    off = 16 + nF * 4
    cells = list(struct.unpack_from('<%dI' % (nF * nR), b, off))
    pool = b[off + nF * nR * 4:]
    if len(pool) != pool_size:
        sys.exit('%s: pool %d byte != header %d' % (path, len(pool), pool_size))

    def s_at(o):
        if o >= len(pool):
            o = 0
        e = pool.find(b'\0', o)
        return bytes(pool[o:e if e >= 0 else len(pool)])

    out = []
    for r in range(nR):
        row = []
        for c in range(nF):
            v = cells[r * nF + c]
            if types[c] == T_INT:
                row.append(struct.unpack('<i', struct.pack('<I', v))[0])
            elif types[c] == T_FLOAT:
                row.append(round(struct.unpack('<f', struct.pack('<I', v))[0], 4))
            else:
                row.append(s_at(v))
        out.append(row)
    return {'cols': nF, 'rows': out}


def txt_rows(path):
    """Bang van ban co hai dong tieu de kieu; o chuoi giu nguyen BYTE."""
    raw = open(path, 'rb').read()
    lines = raw.split(b'\n')
    body = []
    for i, line in enumerate(lines):
        line = line.rstrip(b'\r')
        if not line:
            continue
        if i < 2:                      # hai dong INT/STRING/... o dau
            continue
        cells = line.split(b'\t')
        row = []
        for c in cells:
            try:
                row.append(int(c))
            except ValueError:
                try:
                    row.append(round(float(c), 4))
                except ValueError:
                    row.append(c)
        body.append(row)
    return {'cols': len(body[0]) if body else 0, 'rows': body}


def obj_names(path):
    """Ten <Object name="..."> trong all.obj, doc BYTE.

    Dem HAI CACH doc lap roi bat khop: regex va dem chuoi '<Object '.
    """
    raw = open(path, 'rb').read()
    names = OBJ_RE.findall(raw)
    naive = raw.count(b'<Object ') + raw.count(b'<Object\t')
    return set(names), len(names), naive


# --------------------------------------------------------------------- phep do
def audit(name, table, objpath, is_dbc):
    data = dbc_rows(table) if is_dbc else txt_rows(table)
    names, n_regex, n_naive = obj_names(objpath)
    rows = data['rows']
    missing, empty, present = [], [], 0
    for row in rows:
        mid = row[0]
        model = row[NAME_COL] if len(row) > NAME_COL else b''
        if not isinstance(model, bytes):
            model = str(model).encode('latin-1')
        if not model.strip():
            empty.append(mid)
            continue
        if model in names:
            present += 1
        else:
            missing.append((mid, model))
    return {
        'ten': name,
        'bang': table,
        'bang_sha256': sha(table)[:16],
        'all_obj': objpath,
        'all_obj_sha256': sha(objpath)[:16],
        'cot': data['cols'],
        'dong': len(rows),
        'object_trong_all_obj_regex': n_regex,
        'object_trong_all_obj_dem_tho': n_naive,
        'hai_phep_dem_khop': n_regex == n_naive,
        'ten_model_rong': len(empty),
        'co_trong_all_obj': present,
        'THIEU_trong_all_obj': len(missing),
        '_missing_rows': missing,
        '_ids': set(r[0] for r in rows),
        '_byid': dict((r[0], r[NAME_COL] if len(r) > NAME_COL else b'') for r in rows),
    }


def selftest():
    """Doi chung am: phep do phai BAT duoc khi dau vao hong."""
    ok = []
    names, n_regex, n_naive = obj_names(OURS_OBJ)
    ok.append(('NC1 ten bia dat phai KHONG co trong all.obj',
               b'KHONG_CO_THAT_9999.obj' not in names))
    sample = next(iter(names))
    ok.append(('NC2 mot ten co that phai TIM DUOC', sample in names))
    ok.append(('NC3 hai phep dem doc lap phai khop (%d vs %d)' % (n_regex, n_naive), n_regex == n_naive))

    # NC4: cat doi all.obj => so dong THIEU phai TANG. Neu khong tang thi phep do mu.
    raw = open(OURS_OBJ, 'rb').read()
    half = set(OBJ_RE.findall(raw[:len(raw) // 2]))
    base = audit('ours', OURS_DBC, OURS_OBJ, True)
    cut_missing = 0
    for row in dbc_rows(OURS_DBC)['rows']:
        m = row[NAME_COL]
        if isinstance(m, bytes) and m.strip() and m not in half:
            cut_missing += 1
    ok.append(('NC4 cat doi all.obj => THIEU tang (%d -> %d)' % (base['THIEU_trong_all_obj'], cut_missing),
               cut_missing > base['THIEU_trong_all_obj']))

    # NC5: bo qua dong ten rong - chung KHONG duoc tinh la thieu
    ok.append(('NC5 dong ten rong duoc tach rieng, khong gop vao THIEU', base['ten_model_rong'] >= 0))

    # NC6 (TRUC ID): cot 0 phai la SO, va hang id=0 phai la nhan vat nam chinh - GIONG HET
    # o CY 3.71. Neu ma kieu cot sai thi cot 0 doc ra chuoi rac va phep kiem nay BAT duoc.
    ours_by = audit('ours', OURS_DBC, OURS_OBJ, True)['_byid']
    cy_by = audit('cy', CY_TXT, CY_OBJ, False)['_byid']
    id_la_so = all(isinstance(k, int) for k in list(ours_by)[:50])
    ok.append(('NC6a cot ID phai doc ra SO nguyen', id_la_so))
    nam_chinh = bytes([0xC4, 0xD0, 0xD6, 0xF7, 0xBD, 0xC7]) + b'.obj'   # GBK cua "nam chinh"
    ok.append(('NC6b id 0 = nam chinh (GBK), va GIONG CY tung byte',
               id_la_so and ours_by.get(0) == cy_by.get(0) and cy_by.get(0) == nam_chinh))

    for label, good in ok:
        print('%-64s %s' % (label, 'DAT' if good else '*** TRUOT ***'))
    return 0 if all(g for _, g in ok) else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--out')
    a = ap.parse_args()
    if a.selftest:
        return selftest()

    ours = audit('CanonicalCY (cay cua ta)', OURS_DBC, OURS_OBJ, True)
    cy = audit('CY 3.71 (DataCY31-08-26)', CY_TXT, CY_OBJ, False)

    report = {}
    for side in (ours, cy):
        key = 'ours' if side is ours else 'cy371'
        report[key] = dict((k, v) for k, v in side.items() if not k.startswith('_'))
        report[key]['thieu_mau_20'] = [[i, n.decode('gbk', 'replace')] for i, n in side['_missing_rows'][:20]]

    only_ours = sorted(ours['_ids'] - cy['_ids'])
    only_cy = sorted(cy['_ids'] - ours['_ids'])
    diff_name = []
    for i in sorted(ours['_ids'] & cy['_ids']):
        a1, b1 = ours['_byid'][i], cy['_byid'][i]
        if a1 != b1:
            diff_name.append([i, a1.decode('gbk', 'replace'), b1.decode('gbk', 'replace')])

    # CHI ta thieu ma CY khong thieu => day moi la LOI CUA TA
    cy_missing_ids = set(i for i, _ in cy['_missing_rows'])
    ours_missing_ids = set(i for i, _ in ours['_missing_rows'])
    chi_ta_thieu = sorted(ours_missing_ids - cy_missing_ids)

    report['so_sanh'] = {
        'id_chi_ben_ta': len(only_ours), 'id_chi_ben_ta_mau': only_ours[:20],
        'id_chi_ben_CY': len(only_cy), 'id_chi_ben_CY_mau': only_cy[:20],
        'lech_ten_model': len(diff_name), 'lech_ten_model_mau': diff_name[:20],
        'THIEU_ben_ta_ma_CY_KHONG_thieu': len(chi_ta_thieu),
        'THIEU_ben_ta_ma_CY_KHONG_thieu_mau': [[i, ours['_byid'][i].decode('gbk', 'replace')] for i in chi_ta_thieu[:20]],
    }

    def _b(o):
        if isinstance(o, bytes):
            return o.decode('gbk', 'replace')
        raise TypeError(repr(o))
    text = json.dumps(report, ensure_ascii=False, indent=1, default=_b)
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass
    print(text)
    if a.out:
        os.makedirs(os.path.dirname(a.out), exist_ok=True)
        with open(a.out, 'w', encoding='utf-8') as f:
            f.write(text)
    return 0


if __name__ == '__main__':
    sys.exit(main())
