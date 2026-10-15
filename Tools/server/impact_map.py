#!/usr/bin/env python3
"""impact_map.py - tra lai DUNG hieu ung cho o `g_Impact1/2` cua script vat pham (server-data 17/09/2026).

VAN DE. Commit doi `configs/StandardImpact.txt` sang bang cua CY. Bang CY dung TRUC ID KHAC:
khoi hieu ung "do dung" (thuoc, thuc an, phu, bien than, hoa...) cua 0.85 nam o **ID + 30000** trong
bang CY, con ID cu thi CY da gan cho **chieu thuc chien dau**. Script vat pham (`Game_2/Script/scripts/
obj/commonitem/*.lua`) van mang ID cu ==> vat pham gui nham hieu ung.

  vi du da do LIVE: `item_4831.lua` (大理回城符) gui impact 4831 cho CHINH NGUOI DUNG.
      bang 0.85 : 4831  = 大理回城符          逻辑ID 9  (dich chuyen: canh 2, X 160, Z 160)
      bang CY   : 4831  = 宁闻不墨一段        逻辑ID 3  (SAT THUONG)
      bang CY   : 34831 = 大理回城符          逻辑ID 9  (dich chuyen: canh 2, X 160, Z 160)
  ==> nguoi choi mua phu bang vang, mat phu, **bi danh -31 HP**, va khong duoc dich chuyen.

DAY LA CUNG MOT LOP LOI voi `Exterior_Ride` (commit ed09b4f) va voi `cyfour_params.py`: doi truc ID cua
bang dich ma khong doi cac o TRO TOI bang do. Cach do dung la **so theo TEN/HIEU UNG, khong theo ID**.

LUAT SUA - chi doi mot o khi ca BON dieu kien dung, kiem tren bang SONG:

  1. gia tri cu `OLD` co dong o CA HAI bang (`/home/ubuntu/configs` 0.85 va `R/configs` CY);
  2. hai dong do KHAC TEN  ==> ID that su da doi nghia;
  3. `NEW = OLD + 30000` co dong trong bang CY, **cung TEN** va **cung 逻辑ID** voi dong 0.85 cua `OLD`;
     (du phong: neu khong co dong +30000 thi chap nhan dung MOT dong CY cung ten va cung 逻辑ID)
  4. `NEW` khong phai la mot gia tri da doi nghia lan nua (chong chay hai lan).

Sai mot dieu kien ==> BO O DO va ghi ly do, khong bia so.

KHONG DUNG toi `configs/StandardImpact.txt`: sua bang la sai huong. ID 4831 cua CY thuoc ve mot chieu
thuc cua CY (宁闻不墨一段) va dang duoc dung that; doi dong do la lam hong chieu thuc.

Lenh:

  impact_map.py survey [--json F]
        chi doc. Bao cao: bao nhieu o dang tro sai, anh xa nao giai duoc, cai nao khong, va vi sao.
  impact_map.py plan --out DIR
        dung DIR/plan.json + DIR/impact_map.tsv + DIR/files/<duong dan>.lua (ban da sua, muc BYTE)
  impact_map.py apply --staging DIR [--dry-run]
        kiem LAI tung dieu kien tren bang song, `luac -p` tung file, sao luu
        R/backups/impact-map-<UTC>/, roi chep vao R
  impact_map.py verify [--staging DIR]
        kiem tren cay song: 0 o con tro sai, moi o da doi deu tro toi dong dung ten+logic, cu phap Lua OK
  impact_map.py revert --backup DIR
        chep nguoc thu muc sao luu

Idempotent: chay lai `plan` sau khi `apply` thi `so_o_sua = 0` va `apply` bao "khong co gi de lam".
CAN RESTART: `Game_2/Script/**` chi duoc nap luc khoi dong scriptenginer.

Chay trong WSL TLBB bang root:
    python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/impact_map.py <lenh>
Dac ta: `Docs/specs/server/server-data_vi.md`.
"""
import argparse
import collections
import datetime
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table, g, sha  # noqa: E402

R = '/home/ubuntu/cys-test-20260913'
OLD = '/home/ubuntu'                      # server goc 0.85, CHI DOC
SI = 'configs/StandardImpact.txt'
SCRIPT_ROOT = 'Game_2/Script'
SHIFT = 30000                             # truc CY cua khoi hieu ung "do dung"
SI_ID, SI_NAME, SI_LOGIC = 0, 1, 2

# Hai dang o mang ID impact trong script, deu xu ly o muc BYTE (file .lua co the co chu Trung):
#   1. `g_Impact1 = 4831` / `g_Impact2=3301`
#   2. hang so o DOI SO THU TU cua `LuaFnSendSpecificImpactToUnit(selfId, sender, reciver, ID, n)`
#      (cho thu tu cua lop loi `ed09b4f`, tim ra 18/09: 300 loi goi, 59 gia tri hang so)
CELL = re.compile(rb'(g_Impact[12]\s*=\s*)(\d+)')

# Ba ham nhan **Data_Index cua StandardImpact**, kem VI TRI doi so (dem tu 0).
# Chu ky doc tu `GameServer/lualib/script_base.lua`:
#   :827  LuaFnSendSpecificImpactToUnit(selfId, sender_id, reciver_id, impact_id, delaytime)
#   :5271 LuaFnCancelSpecificImpact(selfId, data_index)      -> impact_cancel_impact_in_specific_data_index
#   :1201 LuaFnHaveImpactOfSpecificDataIndex(selfId, data_index) -> so voi imp:get_data_index()
# CO Y LOAI (khong phai data_index, so nham la hong):
#   LuaFnCancelImpactInSpecificImpact / LuaFnHaveImpactInSpecificCollection -> **collection id**
#   LuaFnHaveImpactOfSpecificMutexId                                        -> **mutex id**
CALLS = (
    (re.compile(rb'(?:LuaFn)?SendSpecificImpactToUnit\s*\(([^)]{0,200})\)'), 3),
    (re.compile(rb'(?:LuaFn)?CancelSpecificImpact\s*\(([^)]{0,200})\)'), 1),
    (re.compile(rb'(?:LuaFn)?HaveImpactOfSpecificDataIndex\s*\(([^)]{0,200})\)'), 1),
)
SEND = CALLS[0][0]
ARG_NUM = re.compile(rb'^\s*(\d+)\s*$')
ARG_NAME = re.compile(rb'^\s*([A-Za-z_]\w*)\s*$')
# `local Youhadu = 4918` / `Youhadu = 4918` - hang so giu ID impact roi truyen vao doi so 4.
ASSIGN = re.compile(rb'^([ \t]*(?:local[ \t]+)?([A-Za-z_]\w*)[ \t]*=[ \t]*)(\d+)[ \t]*$', re.M)
BLOCK_COMMENT = re.compile(rb'--\[(=*)\[.*?\]\1\]', re.S)


def comment_mask(raw):
    """bytearray cung do dai: 1 = byte nam trong chu thich Lua.

    BAY THAT: ban dau cong cu nay dem ca dong chu thich. 35/300 lan xuat hien hang so o doi so 4
    nam trong chu thich, va `5978` thi **toan bo 10 cho deu la chu thich** - neu khong loc thi bao
    cao "cuu duoc 10 o" la sai.
    """
    mask = bytearray(len(raw))
    for m in BLOCK_COMMENT.finditer(raw):
        for i in range(m.start(), m.end()):
            mask[i] = 1
    pos = 0
    for line in raw.split(b'\n'):
        i = line.find(b'--')
        if i >= 0 and not mask[pos + i]:
            for k in range(pos + i, pos + len(line)):
                mask[k] = 1
        pos += len(line) + 1
    return mask


def in_comment(mask, i):
    return i < len(mask) and mask[i] == 1


# ----------------------------------------------------------------- doc bang

def by_id(t):
    return {int(r[0]): r for r in t['rows']}


def load_tables(root=R, old=OLD):
    live = read_table(os.path.join(root, SI))
    base = read_table(os.path.join(old, SI))
    if live['types'] != base['types']:
        raise SystemExit('hai bang StandardImpact khac dong kieu -> tu choi so sanh')
    return by_id(live), by_id(base)


def name_index(H):
    idx = collections.defaultdict(list)
    for i, r in H.items():
        idx[g(r[SI_NAME])].append(i)
    return idx


def _arg4(raw, mask=None):
    """[(vi tri doi so mang ID, phan doi so)] cho MOI ham trong CALLS, NGOAI chu thich."""
    if mask is None:
        mask = comment_mask(raw)
    out = []
    for pat, want in CALLS:
        for m in pat.finditer(raw):
            if in_comment(mask, m.start()):
                continue
            args_start, pos, idx = m.start(1), 0, 0
            for part in m.group(1).split(b','):
                if idx == want:
                    out.append((args_start + pos, part))
                    break
                pos += len(part) + 1
                idx += 1
    return out


def send_cells(raw):
    """[(dau, cuoi, gia tri)] cho doi so 4 la HANG SO, bo qua chu thich."""
    out = []
    for base, part in _arg4(raw):
        a = ARG_NUM.match(part)
        if a:
            s = base + a.start(1)
            out.append((s, s + len(a.group(1)), int(a.group(1))))
    return out


def var_cells(raw):
    """[(dau, cuoi, gia tri, ten)] cho doi so 4 la BIEN hang so khai trong CHINH file nay.

    Chi nhan khi CHAC CHAN an toan: ten do duoc gan **dung mot lan** bang mot so nguyen, va **moi**
    lan xuat hien khac cua ten deu la o mang ID cua mot ham trong CALLS. Thoa het thi doi o
    KHAI BAO (khong doi loi goi). Sai mot dieu -> bo, vi bien co the con dung viec khac.
    """
    mask = comment_mask(raw)
    assigns = collections.defaultdict(list)
    for m in ASSIGN.finditer(raw):
        if in_comment(mask, m.start()):
            continue
        assigns[m.group(2)].append((m.start(3), m.end(3), int(m.group(3))))
    used = collections.defaultdict(int)
    for base, part in _arg4(raw):
        a = ARG_NAME.match(part)
        if a:
            used[a.group(1)] += 1
    out = []
    for name, n in used.items():
        if name not in assigns or len(assigns[name]) != 1:
            continue
        # moi lan ten xuat hien (ngoai chu thich) phai la: 1 lan khai bao + n lan lam doi so 4
        total = sum(1 for m in re.finditer(rb'\b' + re.escape(name) + rb'\b', raw)
                    if not in_comment(mask, m.start()))
        if total != n + 1:
            continue
        s, e, v = assigns[name][0]
        out.append((s, e, v, name.decode('ascii', 'replace'), n))
    return out


def lua_files(root=R):
    """Moi file .lua duoi Game_2/Script co it nhat mot o mang ID impact."""
    out = []
    top = os.path.join(root, SCRIPT_ROOT)
    for dp, _dn, fns in os.walk(top):
        for fn in sorted(fns):
            if not fn.endswith('.lua'):
                continue
            p = os.path.join(dp, fn)
            with open(p, 'rb') as f:
                raw = f.read()
            if CELL.search(raw) or send_cells(raw) or var_cells(raw):
                out.append((os.path.relpath(p, root).replace(os.sep, '/'), raw))
    return sorted(out)


def all_cells(raw):
    """Moi o mang ID impact trong MOT file, da bo chu thich: (gia tri, so lan tinh diem)."""
    mask = comment_mask(raw)
    out = []
    for m in CELL.finditer(raw):
        if not in_comment(mask, m.start()):
            out.append((int(m.group(2)), 1))
    for _s, _e, v in send_cells(raw):
        out.append((v, 1))
    for _s, _e, v, _n, n_use in var_cells(raw):
        out.append((v, n_use))
    return out


# ----------------------------------------------------------------- luat sua

def decide(old_id, H, S, names):
    """Tra (new_id, ly_do) hoac (None, ly_do bo)."""
    if old_id <= 0:
        return None, 'gia tri <= 0'
    if old_id not in S:
        return None, 'khong co dong o bang 0.85 (khong biet nghia goc)'
    if old_id not in H:
        return None, 'thieu dong o bang CY (viec cua item_impacts.py copy85)'
    n85 = g(S[old_id][SI_NAME])
    if g(H[old_id][SI_NAME]) == n85:
        return None, 'cung ten o ca hai bang -> khong doi nghia'
    l85 = g(S[old_id][SI_LOGIC]).strip()
    shifted = old_id + SHIFT
    cands = [i for i in names.get(n85, []) if g(H[i][SI_LOGIC]).strip() == l85]
    if shifted in cands:
        return shifted, 'dong CY +%d cung ten "%s" va cung 逻辑ID %s' % (SHIFT, n85, l85)
    if len(cands) == 1:
        return cands[0], 'dung MOT dong CY cung ten "%s" va cung 逻辑ID %s (khong co dong +%d)' % (
            n85, l85, SHIFT)
    if not cands:
        return None, 'bang CY khong co dong nao ten "%s" voi 逻辑ID %s' % (n85, l85)
    return None, 'bang CY co %d dong ten "%s" logic %s, khong co dong +%d -> nhap nhang' % (
        len(cands), n85, l85, SHIFT)


def build_map(H, S):
    """{old: new} + {old: ly do bo} cho MOI gia tri xuat hien trong o g_Impact."""
    names = name_index(H)
    seen = collections.Counter()
    where = collections.defaultdict(list)
    for rel, raw in lua_files():
        for v, n in all_cells(raw):
            seen[v] += n
            where[v].append(rel)
    mapping, declined = {}, {}
    for v in sorted(seen):
        new, why = decide(v, H, S, names)
        if new is None:
            declined[v] = why
        else:
            mapping[v] = (new, why)
    # dieu kien 4: dich den khong duoc la mot gia tri cung phai doi (chong chay hai lan)
    for v in list(mapping):
        new = mapping[v][0]
        if new in mapping:
            declined[v] = 'dich den %d lai nam trong bang anh xa -> tu choi (nguy co chay hai lan)' % new
            del mapping[v]
    return mapping, declined, seen, where


# ----------------------------------------------------------------- plan

def cmd_survey(args):
    H, S = load_tables()
    mapping, declined, seen, where = build_map(H, S)
    cells_fix = sum(seen[v] for v in mapping)
    out = {
        'bang_CY_dong': len(H), 'bang_085_dong': len(S),
        'so_gia_tri_g_impact': len(seen), 'so_o_g_impact': sum(seen.values()),
        'so_id_doi_nghia_sua_duoc': len(mapping), 'so_o_sua': cells_fix,
        'so_id_bo': len(declined),
        'so_file_anh_huong': len(set(f for v in mapping for f in where[v])),
        'ly_do_bo': collections.Counter(declined.values()),
    }
    print(json.dumps(out, ensure_ascii=False, indent=2, default=str))
    print()
    print('--- 12 o sua dau tien ---')
    for v in sorted(mapping)[:12]:
        print('  %6d -> %-6d  0.85="%s"  CY@cu="%s"  (%d o)'
              % (v, mapping[v][0], g(S[v][SI_NAME]), g(H[v][SI_NAME]), seen[v]))
    print('--- moi ly do bo, mot vi du ---')
    shown = set()
    for v in sorted(declined):
        if declined[v] in shown:
            continue
        shown.add(declined[v])
        print('  %6d  %s   (%d o, vd %s)' % (v, declined[v], seen[v], where[v][0]))
    if args.json:
        with open(args.json, 'w', encoding='utf-8') as f:
            json.dump({'tom_tat': out,
                       'anh_xa': {str(k): v[0] for k, v in mapping.items()},
                       'ly_do_anh_xa': {str(k): v[1] for k, v in mapping.items()},
                       'bo': {str(k): v for k, v in declined.items()},
                       'so_o': {str(k): v for k, v in seen.items()}},
                      f, ensure_ascii=False, indent=2, default=str)
        print('\n-> %s' % args.json)
    return 0


def rewrite(raw, mapping):
    """Doi ca hai dang o (g_Impact va hang so doi so 4) o muc BYTE. Tra (raw moi, {old: so o})."""
    hits = collections.Counter()

    mask = comment_mask(raw)

    def sub(m):
        v = int(m.group(2))
        if v in mapping and not in_comment(mask, m.start()):
            hits[v] += 1
            return m.group(1) + str(mapping[v][0]).encode('ascii')
        return m.group(0)

    raw = CELL.sub(sub, raw)
    # hai lop con lai thay theo khoang byte; lam NGUOC tu cuoi ve dau de khong lech vi tri.
    spans = [(s, e, v, 1) for s, e, v in send_cells(raw)]
    spans += [(s, e, v, n) for s, e, v, _name, n in var_cells(raw)]
    for s, e, v, n in sorted(spans, reverse=True):
        if v in mapping:
            hits[v] += n
            raw = raw[:s] + str(mapping[v][0]).encode('ascii') + raw[e:]
    return raw, hits


def cmd_plan(args):
    H, S = load_tables()
    mapping, declined, seen, where = build_map(H, S)
    os.makedirs(args.out, exist_ok=True)
    rows, total = [], 0
    for rel, raw in lua_files():
        new_raw, hits = rewrite(raw, mapping)
        if not hits:
            continue
        dst = os.path.join(args.out, 'files', rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(new_raw)
        for v, c in sorted(hits.items()):
            rows.append((rel, v, mapping[v][0], c, g(S[v][SI_NAME]), g(H[v][SI_NAME]),
                         g(S[v][SI_LOGIC]), mapping[v][1]))
            total += c
    tsv = os.path.join(args.out, 'impact_map.tsv')
    with open(tsv, 'w', encoding='utf-8', newline='') as f:
        f.write('file\tcu\tmoi\tso_o\tten_0.85\tten_CY_o_ID_cu\tlogic\tly_do\n')
        for r in rows:
            f.write('\t'.join(str(x) for x in r) + '\n')
    plan = {
        'utc': datetime.datetime.utcnow().isoformat() + 'Z',
        'root': R, 'old': OLD,
        'sha_StandardImpact_CY': sha(os.path.join(R, SI)),
        'sha_StandardImpact_085': sha(os.path.join(OLD, SI)),
        'anh_xa': {str(k): v[0] for k, v in mapping.items()},
        'ly_do_anh_xa': {str(k): v[1] for k, v in mapping.items()},
        'bo': {str(k): v for k, v in declined.items()},
        'so_file': len(set(r[0] for r in rows)), 'so_o_sua': total,
        'so_id_sua': len(set(r[1] for r in rows)),
        'files': sorted(set(r[0] for r in rows)),
    }
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=2)
    print(json.dumps({k: plan[k] for k in
                      ('so_file', 'so_o_sua', 'so_id_sua')}, ensure_ascii=False, indent=2))
    print('-> %s' % args.out)
    return 0


# ----------------------------------------------------------------- apply

def luac_ok(path):
    r = subprocess.run(['luac', '-p', path], capture_output=True)
    if r.returncode == 0:
        return True, ''
    r = subprocess.run(['luac5.4', '-p', path], capture_output=True)
    if r.returncode == 0:
        return True, ''
    return False, (r.stderr or r.stdout).decode('utf-8', 'replace')[:200]


def cmd_apply(args):
    plan = json.load(open(os.path.join(args.staging, 'plan.json'), encoding='utf-8'))
    H, S = load_tables()
    names = name_index(H)
    # kiem LAI tung anh xa tren bang SONG (bang co the da doi tu luc plan)
    bad = []
    for k, v in plan['anh_xa'].items():
        old_id, new_id = int(k), int(v)
        got, why = decide(old_id, H, S, names)
        if got != new_id:
            bad.append('%d: plan noi %d, bang song noi %s (%s)' % (old_id, new_id, got, why))
    if bad:
        print('TU CHOI - anh xa khong con dung tren bang song:')
        for b in bad:
            print('  ' + b)
        return 2
    mapping = {int(k): (int(v), plan['ly_do_anh_xa'][k]) for k, v in plan['anh_xa'].items()}
    todo = []
    for rel in plan['files']:
        live = os.path.join(R, rel)
        with open(live, 'rb') as f:
            raw = f.read()
        new_raw, hits = rewrite(raw, mapping)     # tron lai tu file SONG, khong chep de staging
        if hits:
            todo.append((rel, live, raw, new_raw, sum(hits.values())))
    if not todo:
        print(json.dumps({'ket_qua': 'khong co gi de lam', 'so_file': 0, 'so_o_sua': 0},
                         ensure_ascii=False))
        return 0
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'impact-map-%s' % stamp)
    if args.dry_run:
        print(json.dumps({'dry_run': True, 'so_file': len(todo),
                          'so_o_sua': sum(t[4] for t in todo)}, ensure_ascii=False))
        return 0
    os.makedirs(bdir, exist_ok=True)
    tmp = os.path.join(bdir, '_check.lua')
    for rel, live, raw, new_raw, _n in todo:
        with open(tmp, 'wb') as f:
            f.write(new_raw)
        ok, err = luac_ok(tmp)
        if not ok:
            os.remove(tmp)
            raise SystemExit('luac -p HONG cho %s: %s' % (rel, err))
    os.remove(tmp)
    for rel, live, raw, new_raw, _n in todo:
        b = os.path.join(bdir, rel)
        os.makedirs(os.path.dirname(b), exist_ok=True)
        with open(b, 'wb') as f:
            f.write(raw)
        with open(live, 'wb') as f:
            f.write(new_raw)
    res = {'sao_luu': bdir, 'so_file': len(todo), 'so_o_sua': sum(t[4] for t in todo)}
    with open(os.path.join(bdir, 'apply.json'), 'w', encoding='utf-8') as f:
        json.dump({**res, 'files': [t[0] for t in todo], 'anh_xa': plan['anh_xa']},
                  f, ensure_ascii=False, indent=2)
    print(json.dumps(res, ensure_ascii=False, indent=2))
    return 0


# ----------------------------------------------------------------- verify

def cmd_verify(args):
    H, S = load_tables()
    names = name_index(H)
    errors, still, ok_cells = [], collections.Counter(), 0
    targets = collections.Counter()
    for rel, raw in lua_files():
        for v, n in all_cells(raw):
            new, why = decide(v, H, S, names)
            if new is not None:
                still[v] += n
            else:
                ok_cells += n
            targets[v] += n
    # moi o dang tro toi dong nao?
    tro_dung, tro_thieu, tro_doi_nghia = 0, [], []
    for v, c in targets.items():
        if v not in H:
            tro_thieu.append((v, c))
        elif v in S and g(H[v][SI_NAME]) != g(S[v][SI_NAME]):
            tro_doi_nghia.append((v, c))
        else:
            tro_dung += c
    res = {
        'so_o_g_impact': sum(targets.values()),
        'con_tro_sai(sua_duoc)': sum(still.values()),
        'id_con_tro_sai': sorted(still),
        'o_tro_toi_dong_thieu': sum(c for _v, c in tro_thieu),
        'id_tro_toi_dong_thieu': sorted(v for v, _c in tro_thieu),
        'o_tro_toi_dong_doi_nghia_khong_sua_duoc': sum(c for _v, c in tro_doi_nghia),
        'id_doi_nghia_khong_sua_duoc': sorted(v for v, _c in tro_doi_nghia),
        'o_tro_dung': tro_dung,
    }
    # cu phap Lua cua moi file da dung toi
    bad_lua = []
    for rel, _raw in lua_files():
        ok, err = luac_ok(os.path.join(R, rel))
        if not ok:
            bad_lua.append('%s: %s' % (rel, err))
    res['luac_hong'] = bad_lua
    res['ok'] = (res['con_tro_sai(sua_duoc)'] == 0 and not bad_lua)
    print(json.dumps(res, ensure_ascii=False, indent=2))
    return 0 if res['ok'] else 1


# --------------------------------------------------------------- copy85

IMPACT_ENGINER = 'GameServer/lualib/impactenginer.lua'


def registered_logics(root=R):
    with open(os.path.join(root, IMPACT_ENGINER), encoding='utf-8', errors='replace') as f:
        text = f.read()
    return set(int(m) for m in re.findall(r'\[(\d+)\]\s*=\s*"scene\.skill\.impact_logic\.', text))


def copy85_plan(H, S):
    """ID duoc script tro toi, THIEU o bang CY nhung CO nguyen dong o bang 0.85.

    Day la luat KHAC voi luat doi truc: khong doi o nao ca, chi CHEP NGUYEN dong 0.85 vao
    bang CY tai dung ID cu (ID do dang TRONG ben CY nen khong de len gi).
    """
    seen = collections.Counter()
    where = collections.defaultdict(list)
    for rel, raw in lua_files():
        for v, n in all_cells(raw):
            seen[v] += n
            where[v].append(rel)
    reg = registered_logics()
    add, skip = [], []
    for v in sorted(seen):
        if v <= 0 or v in H:
            continue
        if v not in S:
            skip.append((v, seen[v], 'thieu o CA HAI bang -> khong co nguon de chep'))
            continue
        logic = g(S[v][SI_LOGIC]).strip()
        if logic.lstrip('-').isdigit() and int(logic) not in reg and int(logic) != 0:
            skip.append((v, seen[v], 'logic %s chua dang ky trong impactenginer' % logic))
            continue
        add.append((v, seen[v], g(S[v][SI_NAME]), logic, sorted(set(where[v]))[:3]))
    return add, skip


def cmd_copy85(args):
    import fcntl
    H, S = load_tables()
    add, skip = copy85_plan(H, S)
    print(json.dumps({'so_id_chep': len(add), 'so_o_duoc_cuu': sum(a[1] for a in add),
                      'so_id_bo': len(skip)}, ensure_ascii=False))
    for v, n, name, logic, files in add:
        print('  CHEP  %-8d x%-2d "%s" logic %s  %s' % (v, n, name, logic, files[0]))
    for v, n, why in skip:
        print('  BO    %-8d x%-2d %s' % (v, n, why))
    if not add or args.dry_run:
        return 0
    lockp = os.path.join(R, 'configs/.scene_install.lock')
    os.makedirs(os.path.dirname(lockp), exist_ok=True)
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'impact-copy85-%s' % stamp)
    os.makedirs(bdir, exist_ok=True)
    with open(lockp, 'a+') as lk:
        fcntl.flock(lk, fcntl.LOCK_EX)
        try:
            # TRON LAI TU BANG SONG ngay trong lock (nhanh khac cung ghi file nay)
            live = read_table(os.path.join(R, SI))
            have = {int(r[0]) for r in live['rows']}
            base = read_table(os.path.join(OLD, SI))
            src = {int(r[0]): r for r in base['rows']}
            ncol = len(live['types'])
            rows = list(live['rows'])
            done = []
            for v, _n, _name, _logic, _f in add:
                if v in have:                       # ai do vua them -> bo qua
                    continue
                r = list(src[v])
                if len(r) < ncol:
                    r += [b''] * (ncol - len(r))
                rows.append(r[:ncol])
                done.append(v)
            if not done:
                print(json.dumps({'ket_qua': 'khong co gi de lam'}, ensure_ascii=False))
                return 0
            rows.sort(key=lambda r: int(r[0]))
            shutil.copyfile(os.path.join(R, SI), os.path.join(bdir, 'StandardImpact.txt'))
            from cs3b_menpai import write_table       # tu kiem GBK toan file khi ghi
            write_table(os.path.join(R, SI), live['types'], live['names'], rows, live['eol'])
        finally:
            fcntl.flock(lk, fcntl.LOCK_UN)
    after = read_table(os.path.join(R, SI))
    ids = [int(r[0]) for r in after['rows']]
    res = {'sao_luu': bdir, 'da_chep': done, 'so_dong_truoc': len(live['rows']),
           'so_dong_sau': len(after['rows']),
           'id_tang_dan': all(a < b for a, b in zip(ids, ids[1:])),
           'so_id_trung': len(ids) - len(set(ids)),
           'sha_sau': sha(os.path.join(R, SI))}
    with open(os.path.join(bdir, 'apply.json'), 'w', encoding='utf-8') as f:
        json.dump(res, f, ensure_ascii=False, indent=2)
    print(json.dumps(res, ensure_ascii=False, indent=2))
    return 0


def cmd_revert(args):
    n = 0
    for dp, _dn, fns in os.walk(args.backup):
        for fn in fns:
            if not fn.endswith('.lua'):
                continue
            src = os.path.join(dp, fn)
            rel = os.path.relpath(src, args.backup).replace(os.sep, '/')
            dst = os.path.join(R, rel)
            shutil.copyfile(src, dst)
            n += 1
    print(json.dumps({'da_chep_nguoc': n, 'tu': args.backup}, ensure_ascii=False))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('survey'); p.add_argument('--json'); p.set_defaults(fn=cmd_survey)
    p = sub.add_parser('plan'); p.add_argument('--out', required=True); p.set_defaults(fn=cmd_plan)
    p = sub.add_parser('apply'); p.add_argument('--staging', required=True)
    p.add_argument('--dry-run', action='store_true'); p.set_defaults(fn=cmd_apply)
    p = sub.add_parser('verify'); p.add_argument('--staging'); p.set_defaults(fn=cmd_verify)
    p = sub.add_parser('copy85'); p.add_argument('--dry-run', action='store_true')
    p.set_defaults(fn=cmd_copy85)
    p = sub.add_parser('revert'); p.add_argument('--backup', required=True); p.set_defaults(fn=cmd_revert)
    a = ap.parse_args()
    sys.exit(a.fn(a))


if __name__ == '__main__':
    main()
