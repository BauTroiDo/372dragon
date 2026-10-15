# -*- coding: utf-8 -*-
"""bullet-fx (19/09/2026): sinh kich ban replay OFFLINE de do duong dan — khong server, khong quai, khong giet.

VI SAO OFFLINE: goi `GCTargetListAndHitFlags` (909) la **loi vao DUY NHAT** cua dan tren client
(`CysModernHandlers.cpp OnGCTargetListAndHitFlags` / `GCTargetListAndHitFlagsHandler.cpp`). Phat lai dung
goi do bang `CYS_WORLD_SCENARIO` chay het chuoi tao + ve dan ma **khong dung toi duong giet quai** (nhanh
`crash-anim` dang giu cho ay) va khong can tai khoan co ky nang phai.

BA PHA — day la phep A/B/C tra loi "khong tao hay khong ve", va neu khong ve thi TAI DAU:
  A. `targetlist` DON DOC, caster chua tung ra chieu (`m_nLogicCount` khoi tao -1)
     => `CObject_Character::IsLogicReady` tra TRUE ngay (nhanh CYS-PARITY) => dan chay NGAY.
     Neu pha A cung khong co dan thi loi nam o **tao/ve**, khong lien quan hoat anh.
  B. `skill` TRUOC roi `targetlist` cung `logic` => caster (NPC) vao CHARACTER_LOGIC_SKILL_SEND
     => `IsLogicReady` doi `IsBeAttackEffectShowed()`, chi bat trong `OnAnimationHit()`.
     Neu A co dan ma B khong => loi nam o **cong hoat anh**, dung dia phan `crash-anim`.
  C. Nhu B nhung caster la **MYSELF** (nhan vat nguoi choi, mo hinh + ActionSet that).
     Day la duong GAN NHAT voi luc nguoi dung choi: A/B tren bu nhin rom chi do CO CHE,
     con C do dung bo hoat anh ma nguoi choi thuc su chay.

BA DOI CHUNG AM (bat buoc — phep do phai BIET TRUOT):
  NEG-A skill 281  : co trong bang nhung `m_nBulletID = -1` => PHAI khong co dong `create`.
  NEG-B skill 999999: khong co trong bang       => PHAI khong co dong `create`.
  NEG-C skill 2501 : co dan (195) nhung o FlyEffect RONG => PHAI co `create` ma KHONG co `attach effect`.
        Day la ca "tao ma khong ve" CO THAT trong du lieu: neu phep do khong tach duoc no khoi cac ca lanh
        thi phep do mu, va moi ket luan "co dan" deu vo gia tri.

DUNG:
  python -B Tools/fx/bullet/bullet_scenario.py --out <thu muc> [--name run1]
"""
import argparse
import io
import json
import os
import re

# Toa do. May quay quay quanh MySelf va NHIN VAO MySelf (orbit 14,6 m, yaw -24, addh 1,5 m — cung bo voi
# fx-cy-baseline). Vi vay hanh lang bay phai di qua NGAY CHO may quay dang nhin, khong thi dan co that van
# nam ngoai khung hinh va phep dem diem anh se bao "khong thay" mot cach oan uong.
# => caster va target thang hang qua diem nhin, cach nhau 20 m: toc do 10 m/s cho ~2 s bay, du dai de 4 lan
#    chup (moi lan dong hinh ~196 ms, fx-perf) van bat duoc dan khi dang bay.
MYSELF_OBJ = 1
MY_X, MY_Z = 160.0, 147.0
CASTER_OBJ, CASTER_X, CASTER_Z = 2002, 150.0, 150.0
TARGET_OBJ, TARGET_X, TARGET_Z = 2001, 170.0, 150.0
NPC_RACE = 305          # 稻草人 (bu nhin rom) — mau fx-cy-baseline dung, co mo hinh chac chan nap duoc
STEP_MS = 9000          # moi ca mot cua so 9 s: dan cham nhat (speed 10, 20 m) bay 2 s + 4 lan chup dong hinh

# (nhan, skill, ghi chu) — duong dan cua tung ca da tra o 01-bullet-data-audit.json
CASES = [
    ('P1-s371',  371,    'bullet 92  speed 10 fly a_y_wudang_zd          (duong lanh, cham nhat)'),
    ('P2-s306',  306,    'bullet 122 speed 15 fly g01_ci hang pho do_01  (duong lanh)'),
    ('P3-s401',  401,    'bullet 93  speed 10 fly a_y_emei_zd            (duong lanh)'),
    ('P4-s461',  461,    'bullet 95  speed 10 fly a_y_dali_zd            (duong lanh)'),
    ('NA-s281',  281,    'DOI CHUNG AM: skill co that, bullet = -1'),
    ('NB-s999999', 999999, 'DOI CHUNG AM: skill khong ton tai'),
    ('NC-s2501', 2501,   'DOI CHUNG AM: bullet 195 co that nhung FlyEffect RONG (tao ma khong ve)'),
]


def build(name):
    L = ['# CYS-BULLETFX kich ban %s (Tools/fx/bullet/bullet_scenario.py)' % name,
         '# A = targetlist don doc, caster NPC chua ra chieu (logic 0)  -> IsLogicReady TRUE ngay',
         '# B = skill roi targetlist, caster NPC (cung logic > 0)       -> qua cong IsBeAttackEffectShowed',
         '# C = skill roi targetlist, caster la MYSELF (nguoi choi)     -> duong GAN NHAT voi luc choi that',
         'scene id=2 x=%g z=%g obj=%d name=CYTest00' % (MY_X, MY_Z, MYSELF_OBJ),
         'at=0 npc obj=%d race=%d x=%g z=%g dir=90 level=1 name=BulletTarget' % (TARGET_OBJ, NPC_RACE, TARGET_X, TARGET_Z),
         'at=0 npc obj=%d race=%d x=%g z=%g dir=270 level=1 name=BulletCaster' % (CASTER_OBJ, NPC_RACE, CASTER_X, CASTER_Z)]
    plan = ([('A', c) for c in CASES]
            + [('B', c) for c in CASES[:2]]
            + [('C', c) for c in CASES[:2]])
    tags, t = [], 4000
    for phase, (label, skill, note) in plan:
        caster = MYSELF_OBJ if phase == 'C' else CASTER_OBJ
        tag = '%s-%s' % (phase, label)
        L.append('')
        L.append('# %s : %s' % (tag, note))
        L.append('at=%d tag %s' % (t, tag))
        if phase == 'A':
            L.append('at=%d targetlist caster=%d target=%d skill=%d logic=0' % (t, caster, TARGET_OBJ, skill))
        else:
            # logic count phai > 0 va BANG NHAU o ca hai goi (cong IsLogicReady canh dung cho nay)
            logic = 100 + len(tags)
            L.append('at=%d skill caster=%d target=%d skill=%d logic=%d' % (t, caster, TARGET_OBJ, skill, logic))
            L.append('at=%d targetlist caster=%d target=%d skill=%d logic=%d' % (t + 400, caster, TARGET_OBJ, skill, logic))
        tags.append({'tag': tag, 'phase': phase, 'label': label, 'skill': skill, 'at_ms': t,
                     'caster': caster, 'note': note})
        t += STEP_MS
    return L, tags, t


# --------------------------------------------------------------------------------------------------
# PREFLIGHT — vi sao cong nay ton tai
#
# `LoadScenario` (ReplayStream.cpp) TU CHOI CA TEP khi gap mot `kind` la: no ghi dung MOT dong
# `CYS scenario: rejected (scenario line N: unknown step kind)` roi client **chay tiep binh thuong**
# bang ban phat lai thuong. Khong crash, khong bao loi, luot do van ra day log va anh — chi la khong co
# mot buoc nao cua kich ban chay. **Toi mat mot luot khe that vi dieu nay** (21:24, `run-r1`).
#
# Dung dang benh muc 17 cua dieu phoi: phep do chay hoan hao tren mot tien de sai, khong trieu chung.
# Cach chan: **doi chieu HAI NGUON DOC LAP** truoc khi ghi kich ban ra dia —
#   (1) ma nguon dung de dung binary se chay (worktree, khong phai cay chung), va
#   (2) chinh BINARY do (chuoi literal phai nam trong Game.exe).
# Hai nguon phai cung dong y. Mot nguon thi khong bao gio tu biet no dang doc nham cay.
# --------------------------------------------------------------------------------------------------
HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
# Cay dung CUA NHANH NAY (binary do dac), khong phai cay chung: stage chay tu day.
REPLAY_SRC = os.path.join(CYS, 'Build', 'wt-bulletfx', 'Src', 'Client', 'NetCore', 'ReplayStream.cpp')
STAGE_EXE = os.path.join(CYS, 'Build', 'world-gui', 'stage-bulletfx', 'Bin64', 'Game.exe')


def kinds_client_accepts(path=None):
    """Doc dong kiem kind trong ReplayStream.cpp; tra ve tap kind duoc chap nhan (khong ke `scene`/`tag`)."""
    path = path or REPLAY_SRC
    if not os.path.isfile(path):
        return None
    src = io.open(path, encoding='utf-8', errors='replace').read()
    m = re.search(r'if \(step\.kind != "npc".*?return fail\("unknown step kind"\);', src, re.S)
    if not m:
        return None
    return set(re.findall(r'step\.kind != "([a-z_]+)"', m.group(0)))


def kinds_in_binary(exe=None):
    """Nguon thu HAI, doc lap: chuoi literal cua tung kind co nam trong Game.exe se chay khong."""
    exe = exe or STAGE_EXE
    if not os.path.isfile(exe):
        return None
    blob = io.open(exe, 'rb').read()
    return blob


def preflight(lines, path=None, exe=None):
    """Moi kind trong kich ban phai duoc CA HAI nguon chap nhan. Tra ve (ok, thong diep)."""
    used = set()
    for ln in lines:
        w = ln.strip().split()
        if not w or w[0].startswith('#'):
            continue
        i = 1 if w[0].startswith('at=') else 0
        if i < len(w):
            used.add(w[i])
    used -= {'scene', 'tag'}

    ok_kinds = kinds_client_accepts(path)
    if ok_kinds is None:
        return False, 'KHONG doc duoc danh sach kind trong %s — kiem tay truoc khi chiem khe' % (path or REPLAY_SRC)
    bad = sorted(used - ok_kinds)
    if bad:
        return False, ('NGUON 1 (ma nguon): client SE TU CHOI ca kich ban vi kind la: %s (duoc phep: %s)'
                       % (', '.join(bad), ', '.join(sorted(ok_kinds))))

    blob = kinds_in_binary(exe)
    if blob is None:
        return True, ('preflight MOT NUA: %d kind deu co trong ma nguon, nhung CHUA co %s de doi chieu '
                      '- dung binary roi chay lai' % (len(used), exe or STAGE_EXE))
    missing = sorted(k for k in used if k.encode('ascii') not in blob)
    if missing:
        return False, ('NGUON 2 (binary): %s KHONG co trong %s - binary cu hon ma nguon, dung lai truoc khi chiem khe'
                       % (', '.join(missing), exe or STAGE_EXE))
    return True, 'preflight OK: %d kind, ma nguon VA binary deu chap nhan (%s)' % (len(used), ', '.join(sorted(used)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--name', default='run1')
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    lines, tags, end = build(a.name)
    ok, msg = preflight(lines)
    print(msg)
    if not ok:
        raise SystemExit(2)
    replay = os.path.join(a.out, a.name + '.replay.txt')
    with open(replay, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')
    meta = {
        'schema': 1, 'name': a.name, 'replay': os.path.abspath(replay),
        'myself': {'obj': MYSELF_OBJ, 'x': MY_X, 'z': MY_Z},
        'caster': {'obj': CASTER_OBJ, 'x': CASTER_X, 'z': CASTER_Z},
        'target': {'obj': TARGET_OBJ, 'x': TARGET_X, 'z': TARGET_Z},
        'flight_metres': abs(TARGET_X - CASTER_X),
        # 4 moc chup. Chon theo phep do r2: dan NHANH NHAT trong bo (bullet 92 do MySelf ban, 10,6 m @ 10 m/s)
        # trung o ~1.059 ms, nen phai co IT NHAT HAI moc duoi nguong do, neu khong thi khong the do duoc
        # "co thay dan DANG BAY" (chi do duoc vu no luc trung, va vu no thi ca dan khong-co-hinh-bay cung co).
        'shot_ms': '300,700,1100,1600',
        'tags': tags, 'end_ms': end,
        'seconds_needed': int(end / 1000) + 20,
    }
    with open(os.path.join(a.out, a.name + '.meta.json'), 'w', encoding='utf-8') as f:
        json.dump(meta, f, ensure_ascii=False, indent=1)
    print('%s : %d tag, ket thuc %d ms, can >= %d s' % (replay, len(tags), end, meta['seconds_needed']))
    print('shot_ms=%s' % meta['shot_ms'])


if __name__ == '__main__':
    main()
