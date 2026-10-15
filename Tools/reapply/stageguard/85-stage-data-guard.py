# -*- coding: utf-8 -*-
"""data-regress (20/09/2026): CONG CANH HO SO DU LIEU CUA STAGE + LOI SCHEMA DBC LUC CHAY.

VI SAO CAN — cu vang da ton mot dem cua ba nhanh
  Dem 19->20/09, nam stage dung moi deu VANG `ucrtbase+0xED921` tai
  `GMActionSystem_Item.cpp:67` (`m_strIconName = pItem->GetIconName()`) ngay luc vao the gioi.
  Moi nguoi (ke ca dieu phoi) ket luan "mot thay doi DU LIEU toi nay lam hong bang vat pham".
  SAI. Khong tep du lieu nao hong. Nam stage do deu dung bang
      python Tools\\game\\stage_game.py build --name X --bin ... --out ...
  tuc THIEU `--data CanonicalCY`. `stage_game.py` mac dinh `--data Canonical` (cay du lieu GL
  0.85 cu), nen stage tro vao `Assets/Canonical/Data` thay vi `Assets/CanonicalCY/Data`.

CO CHE — vi sao con tro RAC chu khong phai NULL (phep kiem NULL o dong 66 khong bat duoc)
  `CObject_Item_Equip::GetIconName()` tra `m_theBaseDef.pDefineAsWhite->szIcon`, tuc mot o
  CO DINH trong struct `_DBC_ITEM_EQUIP_WHITE`. Bang GL co schema KHAC bang CY — chinh client
  in ra trong `WXClient.log`:
      DBC ERROR: EquipBase.txt schema IIIIIIIIIISISSIIIIIII SS...  (expected ...IIII SS...),
                 record 432 bytes (struct 440)
  Bang GL co 101 cot / ban ghi 432 B; struct CY cho 102 cot / 440 B, va cho lech ngay tu cot 17
  (du lieu co BA cot INT thua truoc hai cot STRING). => o `szIcon` roi dung vao mot o INT.
  So nguyen 32 bit doc thanh con tro 64 bit => KHAC NULL nhung RAC => `strlen` di ra ngoai vung.
  Dia chi loi trong `WXC_SML.TXT` la `0xFFFFFFFF00000000` — dung hinh dang hai o 32 bit ghep lai.

VI SAO CAC CONG DANG CO KHONG BAT DUOC (cau hoi quan trong ngang ban va)
  1. `stage_game.py` CO kiem junction (dong ~1276) nhung chi doi chieu voi ho so CHINH NO vua
     chon. Dung ho so mac dinh `Canonical` thi phep kiem do DAT — no khong bao gio biet nguoi
     goi quen co. Phep kiem chi biet TRUOT khi co MOT nguon so; day la dung lop loi cua
     `DIEU-PHOI-19-09.md` muc 17 (cong chay hoan hao tren mot dinh nghia thieu).
  2. Client CO phat hien schema lech va CO in `DBC ERROR:` — roi NAP TIEP. 29 dong loi tren
     mot luot, khong dong nao lam luot do that bai. Bo nghiem thu 20 muc cua
     `run_world_gui_live.ps1` khong doc `DBC ERROR:`.
  => Hai cong deu xanh, client van chet.

PHEP KIEM NAY PHAI BIET TRUOT
  `check-run` KHONG chi doi `DBC ERROR == 0`: mot log RONG hoac bi cat cung cho 0 loi va se
  lot. Nen no doi THEM `DBC: ... OK columns >= MIN_OK`. Chay `selftest` de thay no phan tach
  that tren bang chung co san trong kho (doi chung am la cac luot da vang thuc su).

SO DO DA CHAY (data-regress, 20/09) — 784 luot co dau vet DBC trong Build\\Logs:
      750 luot 0 loi | 24 luot 1 loi (14/09) | 1 luot 26 loi (14/09) | 9 luot 29 loi
  Ca 9 luot 29 loi deu la stage ho so `Canonical` cua dem nay, va CA CHIN deu vang.
  Khong luot nao cua ho so `CanonicalCY` co du mot dong `DBC ERROR:` — ke ca cac luot chay SAU
  hai thay doi du lieu 23:47:55 va 23:57:44 (`ui-frames/live-2` 00:19-00:21, 20/20 PASS).

CACH DUNG
  85-stage-data-guard.py check-stage --stage DIR [--out F]   # truoc khi chay, khong can khe
  85-stage-data-guard.py check-run   --run   DIR [--out F]   # sau mot luot live
  85-stage-data-guard.py selftest                 [--out F]  # doi chung am + duong tren kho
  Ma thoat 0 = DAT, 1 = TRUOT, 2 = khong do duoc (thieu tep).
"""
import argparse
import json
import os
import re
import sys

ROOT = r'C:\TLBB\085\CY-Source'

# Ho so du lieu DUY NHAT dung cho client CY. `Canonical` la cay GL 0.85, chi danh cho build GL.
WANT_PROFILE = 'CanonicalCY'
WANT_TARGET = 'Assets/CanonicalCY/Data'

# Bang moc: 40 bang co mat o CA HAI cay nhung KHAC DINH DANG (GL = van ban, CY = DBC 00CCBBDD).
# Lay sau bang trai deu cac he (vat pham / quai / ky nang / canh / ngoai hinh) de mot cay sai
# khong the lot bang cach trung hop.
SENTINELS = ['EquipBase.txt', 'CommonItem.txt', 'MonsterAttrExTable.txt', 'SkillTemplate_V1.txt',
             'SceneDefineEx.txt', 'ItemVisualLocator.txt', 'Exterior_Ride.txt', 'PetAttrTable.txt']
DBC_MAGIC = b'\x00\xcc\xbb\xdd'

# Thu muc CHI CO trong bo cuc CY. `WXResources.cfg` cua ho so GL thieu dung chin dong nay.
CY_ONLY_FOLDERS = ['Model4Folder', 'Model5Folder', 'Model6Folder', 'Model7Folder', 'Model8Folder',
                   'Material6Folder', 'Material7Folder', 'Material8Folder', 'Scene2Folder']

# Luot CanonicalCY lanh do duoc 62 dong OK. Luot GL chi 33. Nguong 55 chan ca log rong/bi cat.
MIN_OK = 55

RE_OK = re.compile(rb'DBC: [^\n]*? OK columns')


def _fail(res, msg):
    res['failures'].append(msg)


def check_stage(stage, res):
    """Cong TINH: chay truoc khi xin khe, khong ton mot luot nao."""
    res['stage'] = stage
    man = os.path.join(stage, 'Bin64', 'game_data_stage.json')
    if not os.path.isfile(man):
        _fail(res, 'thieu Bin64/game_data_stage.json: %s' % man)
        res['unmeasurable'] = True
        return
    with open(man, 'rb') as fh:
        m = json.loads(fh.read().decode('utf-8-sig'))
    data = m.get('data', {})
    res['manifest_profile'] = data.get('profile')
    res['manifest_target'] = data.get('target')
    if data.get('profile') != WANT_PROFILE:
        _fail(res, 'ho so du lieu = %r, phai la %r (thieu --data CanonicalCY luc stage_game.py build)'
                   % (data.get('profile'), WANT_PROFILE))
    if (data.get('target') or '').replace('\\', '/') != WANT_TARGET:
        _fail(res, 'dich junction ghi trong ban ke = %r, phai la %r' % (data.get('target'), WANT_TARGET))

    # KHONG tin ban ke: giai lai junction tren dia. ("log noi xong" khong phai bang chung.)
    link = os.path.join(stage, 'Data')
    real = os.path.realpath(link) if os.path.exists(link) else None
    res['junction_resolves_to'] = real
    want_real = os.path.realpath(os.path.join(ROOT, 'Assets', 'CanonicalCY', 'Data'))
    if real is None:
        _fail(res, 'khong co thu muc/junction Data trong stage')
    elif os.path.normcase(real) != os.path.normcase(want_real):
        _fail(res, 'junction Data tro toi %s, phai tro toi %s' % (real, want_real))

    # Moc dinh dang bang: cay GL de cac bang nay o dang VAN BAN, cay CY o dang DBC 00CCBBDD.
    bad = []
    if real:
        for n in SENTINELS:
            p = os.path.join(real, 'ConfigFolder', n)
            if not os.path.isfile(p):
                bad.append(n + '=THIEU')
                continue
            with open(p, 'rb') as fh:
                if fh.read(4) != DBC_MAGIC:
                    bad.append(n + '=KHONG-PHAI-DBC')
    res['sentinels_checked'] = len(SENTINELS)
    res['sentinels_bad'] = bad
    if bad:
        _fail(res, 'bang moc sai dinh dang (dau hieu cay du lieu GL): %s' % ', '.join(bad))

    # Bo cuc thu muc trong WXResources.cfg.
    cfg = os.path.join(stage, 'Bin64', 'WXResources.cfg')
    if os.path.isfile(cfg):
        with open(cfg, 'rb') as fh:
            body = fh.read()
        miss = [f for f in CY_ONLY_FOLDERS if ('../Data/%s' % f).encode() not in body]
        res['cfg_missing_cy_folders'] = miss
        if miss:
            _fail(res, 'WXResources.cfg thieu %d thu muc chi-CY: %s' % (len(miss), ', '.join(miss)))
    else:
        _fail(res, 'thieu Bin64/WXResources.cfg')


def check_run(run, res):
    """Cong SAU LUOT: doc chinh cai client da in ra."""
    res['run'] = run
    log = os.path.join(run, 'WXClient.log')
    if not os.path.isfile(log):
        _fail(res, 'thieu WXClient.log: %s' % log)
        res['unmeasurable'] = True
        return
    with open(log, 'rb') as fh:
        body = fh.read()
    err = body.count(b'DBC ERROR:')
    ok = len(RE_OK.findall(body))
    res['dbc_error'] = err
    res['dbc_ok'] = ok
    res['log_bytes'] = len(body)
    if err:
        first = [l.decode('gbk', 'replace').strip()
                 for l in body.split(b'\n') if b'DBC ERROR:' in l][:3]
        res['dbc_error_samples'] = first
        _fail(res, '%d dong "DBC ERROR:" — bang DBC lech schema so voi struct da bien dich; '
                   'moi truy cap o STRING cua cac bang do tra con tro RAC' % err)
    # Doi chung chong "log rong cung dat": phai co du so bang nap THANH CONG.
    if ok < MIN_OK:
        _fail(res, 'chi %d dong "DBC: ... OK columns" (can >= %d) — log rong/bi cat, hoac stage '
                   'dang nap cay du lieu khac' % (ok, MIN_OK))


def selftest(res):
    """DOI CHUNG AM + DUONG tren bang chung co san trong kho — phep kiem phai BIET TRUOT."""
    logs = os.path.join(ROOT, 'Build', 'Logs')
    cases = [
        # (duong dan luot, ky vong DAT?, ghi chu)
        (r'2026-09-19-crash-cegui\live-playfix-1', False, 'AM: stage-play-fix, ho so Canonical, da vang'),
        (r'2026-09-19-crash-cegui\live-a-2', False, 'AM: stage-crash-cegui-a, ho so Canonical, da vang'),
        (r'2026-09-19-crash-cegui\live-base-2', False, 'AM: stage-crash-cegui-base (KHONG co ban va), da vang'),
        (r'2026-09-19-crash-cegui\live-playctrl-1', False, 'AM: stage-play-ctrl, ho so Canonical, da vang'),
        (r'2026-09-19-crash-cegui\live-c-2', True, 'DUONG: stage-crash-cegui-c, ho so CanonicalCY, sach'),
        (r'2026-09-19-ui-frames\live-2', True, 'DUONG: chay 00:19-00:21, SAU ca hai thay doi du lieu, 20/20 PASS'),
        (r'2026-09-19-npc-data\live-2', True, 'DUONG: chay 00:02, SAU thay doi MonsterAttrExTable 23:47:55'),
        (r'2026-09-19-user-play-2', True, 'DUONG: chinh phien choi cua NGUOI DUNG'),
    ]
    rows = []
    bad = 0
    for rel, want_pass, note in cases:
        sub = {'failures': []}
        check_run(os.path.join(logs, rel), sub)
        got_pass = not sub['failures'] and not sub.get('unmeasurable')
        agree = (got_pass == want_pass)
        if not agree:
            bad += 1
        rows.append({'run': rel, 'note': note, 'expect_pass': want_pass, 'got_pass': got_pass,
                     'dbc_error': sub.get('dbc_error'), 'dbc_ok': sub.get('dbc_ok'), 'agree': agree})
    res['cases'] = rows
    res['negative_controls'] = sum(1 for _, w, _ in cases if not w)
    res['positive_controls'] = sum(1 for _, w, _ in cases if w)
    if bad:
        _fail(res, '%d/%d ca khong khop ky vong — phep kiem nay KHONG phan tach duoc' % (bad, len(cases)))
    if res['negative_controls'] == 0:
        _fail(res, 'khong co doi chung am: phep kiem khong chung minh duoc no biet TRUOT')


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('check-stage'); a.add_argument('--stage', required=True); a.add_argument('--out')
    b = sub.add_parser('check-run'); b.add_argument('--run', required=True); b.add_argument('--out')
    c = sub.add_parser('selftest'); c.add_argument('--out')
    ns = ap.parse_args()

    res = {'cmd': ns.cmd, 'failures': []}
    if ns.cmd == 'check-stage':
        check_stage(os.path.abspath(ns.stage), res)
    elif ns.cmd == 'check-run':
        check_run(os.path.abspath(ns.run), res)
    else:
        selftest(res)

    res['verdict'] = 'KHONG DO DUOC' if res.get('unmeasurable') else ('DAT' if not res['failures'] else 'TRUOT')
    text = json.dumps(res, ensure_ascii=False, indent=2)
    if ns.out:
        os.makedirs(os.path.dirname(os.path.abspath(ns.out)) or '.', exist_ok=True)
        with open(ns.out, 'w', encoding='utf-8') as fh:
            fh.write(text + '\n')
    sys.stdout.write(text + '\n')
    return 2 if res.get('unmeasurable') else (0 if not res['failures'] else 1)


if __name__ == '__main__':
    sys.exit(main())
