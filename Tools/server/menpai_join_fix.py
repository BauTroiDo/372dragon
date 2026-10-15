# -*- coding: utf-8 -*-
"""menpai-join (20/09/2026): dua 111 hang so SO PHAI con nam tren truc GL ve truc CY, tren SERVER RIENG.

VI SAO: cs3b-menpai (14/09) doi server rieng sang so phai CY (唐门/鬼谷/桃花岛/绝情谷 = 11..14, 恶人谷 15, 慕容 10,
曼陀 16 = TAT) o bang + define + menpai_extensions, nhung BO SOT:
  * 103 tep Game_2/Script/scripts/obj/cy4/*.lua mang `faction=13|14|15|16` (con so nam duoi ten truong `faction`,
    nen moi phep `grep menpai` deu truot);
  * doi so cua LuaFnJoinMenpai + 6 ID tam phap trong 3 NPC nhap phai legacy (man da / ac nhan coc / mo dung);
  * 5 loi goi DispatchXinfaLevelInfo(.., 10|11|12).
Hau qua do duoc (Tools/server/menpai_join_sim.lua, E2): ca 7 NPC nhap phai dua nguoi choi vao SAI phai; rieng
Tuyet Tinh Coc (faction=16) roi vao o 16 = Man Da da tat => menpai doi nhung 0 tam phap + 0 chieu
("nhap phai khong co skill"). O 16 lot cong vi LEGACY_IDS co 16 va nhanh legacy cua check_ready `return true`
TRUOC moi phep kiem du lieu => cong thu hai: legacy ma khong co dong tam phap nao thi TU CHOI.

Toan van: Timeline/handoff/menpai-join-resume.md ; bang vi sai: Build/Logs/2026-09-20-menpai-join/02-bang-vi-sai.md

CHAY TRONG WSL TLBB bang root:
  python3 -B menpai_join_fix.py plan   --out <staging>      dung ban da va vao <staging>/, KHONG cham server
  python3 -B menpai_join_fix.py verify --root <cay>         kiem tinh mot cay (R, hoac <staging> phu len R)
  python3 -B menpai_join_fix.py apply  --staging <staging>  chep vao R, sao luu R/backups/menpai-join-<UTC>/
  python3 -B menpai_join_fix.py undo   --backup <thu-muc>   tra nguyen van tu ban sao luu

IDEMPOTENT THEO TEN TEP, KHONG THEO CON SO. Sau khi va, Dao Hoa Dao mang faction=13 - DUNG con so ma Duong Mon
mang TRUOC khi va. Mot cong cu "thay 13 -> 11" chay lan hai se pha Dao Hoa Dao. Vi vay gia tri dich duoc quyet
dinh boi TEN TEP (cy4_<phai>_*.lua) va kiem cheo voi `faction_name`, khong bao gio boi gia tri dang co.

KHONG BAO GIO ghi vao cay GOC (/home/ubuntu/GameServer, /home/ubuntu/Game_2) - do la cay song, chi doc.
"""
import argparse
import datetime
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

R = '/home/ubuntu/cys-test-20260913'
FORBIDDEN = ('/home/ubuntu/GameServer', '/home/ubuntu/Game_2', '/home/ubuntu/configs')
CY4_DIR = 'Game_2/Script/scripts/obj/cy4'
MARK = b'CYS-MENPAIJOIN'

# phai -> (so GL, so CY, ten trong faction_name)
CY4 = {
    'tangmen': (13, 11, 'Đường Môn'),
    'guigu': (14, 12, 'Quỷ Cốc'),
    'taohuadao': (15, 13, 'Đào Hoa Đảo'),
    'congren': (16, 14, 'Tuyệt Tình Cốc'),
}

REFUSE_MSG = 'Môn phái chưa sẵn sàng tiếp nhận đệ tử. Xin thử lại sau.'

# (tep, [(regex cu, chuoi moi, regex nhan-biet-da-va)])  -- moi regex phai khop DUNG MOT lan
def _call(fn, old, new):
    return (re.compile(rb'(' + fn + rb'\s*\(\s*selfId\s*,\s*(?:targetId\s*,\s*)?)' + str(old).encode() + rb'(\s*\))'),
            str(new).encode(),
            re.compile(fn + rb'\s*\(\s*selfId\s*,\s*(?:targetId\s*,\s*)?' + str(new).encode() + rb'\s*\)'))


def _xinfa(old, new):
    return (re.compile(rb'(LuaFnSetXinFaLevel\s*\(\s*selfId\s*,\s*)' + str(old).encode() + rb'(\s*,)'),
            str(new).encode(),
            re.compile(rb'LuaFnSetXinFaLevel\s*\(\s*selfId\s*,\s*' + str(new).encode() + rb'\s*,'))


LEGACY = {
    # Ac Nhan Coc: GL 11 -> CY 15 ; tam phap GL 81..86 -> CY 113..118 (48/48 ten khop thu tu: pha2/P2c-xinfa-names)
    'Game_2/Script/scripts/obj/erengu/erengu_duanyanqing.lua':
        [_call(rb'LuaFnJoinMenpai', 11, 15)] + [_xinfa(81 + i, 113 + i) for i in range(6)],
    'Game_2/Script/scripts/obj/erengu/erengu_yeerniang.lua': [_call(rb'DispatchXinfaLevelInfo', 11, 15)],
    'Game_2/Script/scripts/obj/erengu/erengu_shanliang.lua': [_call(rb'DispatchXinfaLevelInfo', 11, 15)],
    # Mo Dung: GL 12 -> CY 10 ; tam phap GL 89..94 -> CY 64..69
    'Game_2/Script/scripts/obj/gusu/ogusu_murongjie.lua':
        [_call(rb'LuaFnJoinMenpai', 12, 10)] + [_xinfa(89 + i, 64 + i) for i in range(6)],
    'Game_2/Script/scripts/obj/gusu/ogusu_murongchui.lua': [_call(rb'DispatchXinfaLevelInfo', 12, 10)],
    # Man Da: GL 10 -> CY 16 (TAT). Tam phap GL 64..69 o ta la cua MO DUNG => doi sang dai rieng +1000 ma cs3b da
    # chon cho o 16 (define.lua: MENPAI_7_XINFA=1070, MENPAI_8_XINFA=1071) de khong bao gio cap nham chieu Mo Dung.
    'Game_2/Script/scripts/obj/mantuo/omantuo_wangsushang.lua':
        [_xinfa(64 + i, 1064 + i) for i in range(6)],   # loi goi JoinMenpai xu ly rieng (them cong tra ve)
    'Game_2/Script/scripts/obj/mantuo/omantuo_wangheling.lua': [_call(rb'DispatchXinfaLevelInfo', 10, 16)],
    'Game_2/Script/scripts/obj/mantuo/mantuo_wangheling.lua': [_call(rb'DispatchXinfaLevelInfo', 10, 16)],
}
MANTUO_JOIN = 'Game_2/Script/scripts/obj/mantuo/omantuo_wangsushang.lua'
MANTUO_OLD = re.compile(rb'^([ \t]*)self:LuaFnJoinMenpai\(\s*selfId\s*,\s*10\s*\)[ \t]*(\r?)$', re.M)
MANTUO_DONE = re.compile(rb'if not self:LuaFnJoinMenpai\(\s*selfId\s*,\s*16\s*\) then')

REGISTRY = 'GameServer/lualib/menpai_registry.lua'
REG_OLD = b'    if registry.is_legacy(id) then return true, "legacy_configured" end\n'
REG_NEW = (
    b'    -- CYS-MENPAIJOIN (20/09): "legacy" chi co nghia "khoi kiem CHI TIET", KHONG co nghia "khoi can du lieu".\n'
    b'    -- O server goc moi phai legacy deu co du 8 tam phap nen hai nghia trung nhau. O day cs3b doi Man Da sang\n'
    b'    -- o 16, xoa het dong cua no, roi van de no trong LEGACY_IDS => o DUY NHAT vua "khoi kiem" vua "rong":\n'
    b'    -- LuaFnJoinMenpai(16) doi menpai nhung cap 0 tam phap + 0 chieu. Legacy ma KHONG co dong tam phap nao => tu choi.\n'
    b'    if registry.is_legacy(id) then\n'
    b'        local xinfa_v1 = read_config(get_config, "xinfa_v1")\n'
    b'        if not xinfa_v1 or #registry.xinfa_ids(xinfa_v1, id) == 0 then return false, "faction_disabled_no_data" end\n'
    b'        return true, "legacy_configured"\n'
    b'    end\n'
)

CY4_BASE = CY4_DIR + '/cy4_npc.lua'
CY4_BASE_OLD = b'-- Core faction NPC behavior. Data and initial skills are owned by the live registry.\n'
CY4_BASE_NEW = CY4_BASE_OLD + (
    b'-- CYS-MENPAIJOIN (20/09): `cfg.faction` cua moi tep cy4_<phai>_*.lua la SO PHAI CY cua server rieng\n'
    b'-- (tangmen 11, guigu 12, taohuadao 13, congren 14) - KHONG phai so GL 13..16 cua server goc. Con so nay di\n'
    b'-- thang vao LuaFnJoinMenpai / GetMenPai / DispatchXinfaLevelInfo / cy_four_training_config.factions[...].\n'
    b'-- Dung "sua cho giong server goc": kiem bang Tools/server/menpai_join_fix.py verify.\n'
)


def sha(b):
    return hashlib.sha256(b).hexdigest()


def guard_target(path):
    rp = os.path.realpath(path)
    for f in FORBIDDEN:
        if rp == f or rp.startswith(f + '/'):
            sys.exit('TU CHOI: %s nam trong cay GOC (chi doc)' % rp)


def cy4_files(root):
    d = os.path.join(root, CY4_DIR)
    out = []
    for n in sorted(os.listdir(d)):
        m = re.match(r'^cy4_(tangmen|guigu|taohuadao|congren)_.+\.lua$', n)
        if m:
            out.append((CY4_DIR + '/' + n, m.group(1)))
    return out


FACTION_RE = re.compile(rb'(\bfaction\s*=\s*)(\d+)')


def patch_cy4(data, sect, rel, problems):
    gl, cy, name = CY4[sect]
    hits = FACTION_RE.findall(data)
    if len(hits) != 1:
        problems.append('%s: mong doi dung 1 `faction=<so>`, thay %d' % (rel, len(hits)))
        return data, None
    cur = int(hits[0][1])
    if name.encode('utf-8') not in data:
        problems.append('%s: ten tep noi "%s" nhung khong thay faction_name="%s"' % (rel, sect, name))
        return data, None
    if cur == cy:
        return data, None
    if cur != gl:
        problems.append('%s: faction=%d khong phai GL %d cung khong phai CY %d' % (rel, cur, gl, cy))
        return data, None
    return FACTION_RE.sub(lambda m: m.group(1) + str(cy).encode(), data, count=1), (gl, cy)


def patch_edits(data, edits, rel, problems):
    changes = []
    for old_re, new, done_re in edits:
        n_old = len(old_re.findall(data))
        n_done = len(done_re.findall(data))
        if n_old == 1:
            data = old_re.sub(lambda m: m.group(1) + new + m.group(2), data, count=1)
            changes.append(new.decode())
        elif n_old == 0 and n_done >= 1:
            continue
        else:
            problems.append('%s: mau %s khop %d lan (da-va=%d)' % (rel, old_re.pattern[:60], n_old, n_done))
    return data, changes


def patch_mantuo_join(data, rel, problems):
    if MANTUO_DONE.search(data):
        return data, False
    ms = MANTUO_OLD.findall(data)
    if len(ms) != 1:
        problems.append('%s: khong tim thay dung 1 dong LuaFnJoinMenpai(selfId, 10) (thay %d)' % (rel, len(ms)))
        return data, False

    def rep(m):
        ind, cr = m.group(1), m.group(2)
        eol = cr + b'\n'
        lines = [
            ind + b'-- ' + MARK + b': o 16 (Man Da) DANG TAT tren server rieng - khong co dong XinFa_V1/SkillTemplate nao.',
            ind + b'-- Ban goc khong kiem gia tri tra ve (phai legacy o do khong bao gio bi tu choi). O day PHAI kiem: neu khong,',
            ind + b'-- 6 loi LuaFnSetXinFaLevel ben duoi van chay tren mot nhan vat CHUA vao phai.',
            ind + b'if not self:LuaFnJoinMenpai(selfId, 16) then',
            ind + b'\tself:MsgBox(selfId, targetId, "' + REFUSE_MSG.encode('utf-8') + b'")',
            ind + b'\treturn',
            ind + b'end',
        ]
        return eol.join(lines) + cr
    return MANTUO_OLD.sub(rep, data, count=1), True


def build(root):
    """Tra (files: {rel: (old_bytes, new_bytes)}, log, problems). Khong ghi gi."""
    files, log, problems = {}, [], []
    for rel, sect in cy4_files(root):
        old = open(os.path.join(root, rel), 'rb').read()
        new, ch = patch_cy4(old, sect, rel, problems)
        if ch:
            files[rel] = (old, new)
            log.append({'file': rel, 'kind': 'faction', 'from': ch[0], 'to': ch[1]})
    for rel, edits in LEGACY.items():
        old = open(os.path.join(root, rel), 'rb').read()
        new, ch = patch_edits(old, edits, rel, problems)
        if rel == MANTUO_JOIN:
            new, did = patch_mantuo_join(new, rel, problems)
            if did:
                ch = ch + ['JoinMenpai(16)+cong tra ve']
        if new != old:
            files[rel] = (old, new)
            log.append({'file': rel, 'kind': 'legacy', 'to': ch})
    old = open(os.path.join(root, REGISTRY), 'rb').read()
    if MARK not in old:
        if old.count(REG_OLD) != 1:
            problems.append('%s: dong legacy cua check_ready khop %d lan' % (REGISTRY, old.count(REG_OLD)))
        else:
            files[REGISTRY] = (old, old.replace(REG_OLD, REG_NEW, 1))
            log.append({'file': REGISTRY, 'kind': 'guard'})
    old = open(os.path.join(root, CY4_BASE), 'rb').read()
    if MARK not in old:
        if old.count(CY4_BASE_OLD) != 1:
            problems.append('%s: dong dau khong khop' % CY4_BASE)
        else:
            files[CY4_BASE] = (old, old.replace(CY4_BASE_OLD, CY4_BASE_NEW, 1))
            log.append({'file': CY4_BASE, 'kind': 'comment'})
    return files, log, problems


def luac(path):
    p = subprocess.run(['luac5.4', '-p', path], capture_output=True, text=True)
    return p.returncode == 0, (p.stderr or '').strip()


def cmd_plan(args):
    out = os.path.abspath(args.out)
    guard_target(out)
    files, log, problems = build(args.root)
    if problems:
        print('\n'.join('LOI: ' + p for p in problems))
        return 2
    if os.path.isdir(out) and os.listdir(out):
        sys.exit('thu muc plan da co du lieu - dung mot thu muc moi: ' + out)
    manifest = []
    for rel, (old, new) in sorted(files.items()):
        dst = os.path.join(out, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(new)
        ok, err = luac(dst)
        if not ok:
            problems.append('luac %s: %s' % (rel, err))
        manifest.append({'file': rel, 'sha_before': sha(old), 'sha_after': sha(new),
                         'bytes_before': len(old), 'bytes_after': len(new)})
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump({'when': datetime.datetime.now().isoformat(), 'root': args.root, 'files': manifest,
                   'log': log, 'problems': problems}, f, ensure_ascii=False, indent=1)
    kinds = {}
    for e in log:
        kinds[e['kind']] = kinds.get(e['kind'], 0) + 1
    print('plan: %d tep se doi %s ; luac loi=%d -> %s' % (len(files), kinds, len(problems), out))
    for p in problems:
        print('LOI: ' + p)
    return 2 if problems else 0


def overlay_read(root, overlay, rel):
    if overlay:
        p = os.path.join(overlay, rel)
        if os.path.exists(p):
            return open(p, 'rb').read()
    return open(os.path.join(root, rel), 'rb').read()


def cmd_verify(args):
    root, ov = args.root, args.overlay
    errs, n = [], 0
    for rel, sect in cy4_files(root):
        gl, cy, name = CY4[sect]
        data = overlay_read(root, ov, rel)
        hits = FACTION_RE.findall(data)
        n += 1
        if len(hits) != 1 or int(hits[0][1]) != cy:
            errs.append('%s: faction=%s, mong doi %d (%s)' % (rel, [int(h[1]) for h in hits], cy, name))
        if name.encode('utf-8') not in data:
            errs.append('%s: thieu faction_name "%s"' % (rel, name))
    for rel, edits in LEGACY.items():
        data = overlay_read(root, ov, rel)
        n += 1
        for old_re, new, done_re in edits:
            if old_re.search(data):
                errs.append('%s: con mau CU %s' % (rel, old_re.pattern[:70]))
            if not done_re.search(data):
                errs.append('%s: thieu mau MOI %s' % (rel, done_re.pattern[:70]))
    data = overlay_read(root, ov, MANTUO_JOIN)
    if not MANTUO_DONE.search(data) or MANTUO_OLD.search(data):
        errs.append('%s: loi goi nhap phai Man Da chua co cong tra ve / con so 10' % MANTUO_JOIN)
    data = overlay_read(root, ov, REGISTRY)
    if MARK not in data or b'faction_disabled_no_data' not in data:
        errs.append('%s: thieu cong "legacy khong co du lieu"' % REGISTRY)
    print('verify %s%s: %d tep kiem, %d loi' % (root, (' + ' + ov) if ov else '', n, len(errs)))
    for e in errs[:40]:
        print('  LOI: ' + e)
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump({'when': datetime.datetime.now().isoformat(), 'root': root, 'overlay': ov,
                       'checked': n, 'errors': errs}, f, ensure_ascii=False, indent=1)
    return 1 if errs else 0


def private_server_listening():
    hexports = {'%04X' % p for p in (15733, 15734)}
    for name in ('/proc/net/tcp', '/proc/net/tcp6'):
        try:
            for line in open(name).read().splitlines()[1:]:
                parts = line.split()
                if parts[1].split(':')[1] in hexports and parts[3] == '0A':
                    return True
        except OSError:
            pass
    return False


def cmd_apply(args):
    st = os.path.abspath(args.staging)
    plan = json.load(open(os.path.join(st, 'plan.json'), encoding='utf-8'))
    if plan.get('problems'):
        sys.exit('plan co loi - khong ap')
    if os.path.realpath(plan.get('root', '')) != R:
        sys.exit('plan khong duoc tao tu server rieng ' + R)
    if private_server_listening() and not args.allow_running:
        sys.exit('SERVER RIENG DANG CHAY (15733/15734 LISTEN). Game_2/Script duoc CACHE, GameServer can inject => '
                 'ap luc nay KHONG co hieu luc cho toi khi nap lai, va moi nap lai/restart phai qua dieu phoi. '
                 'Neu van muon dat tep len dia: them --allow-running.')
    # Validate every source and target before writing even the first file.
    # A plan may outlive another branch's edit (the travel scripts are shared).
    prepared = []
    seen = set()
    for e in plan['files']:
        rel = e['file']
        dst = os.path.realpath(os.path.join(R, rel))
        src = os.path.realpath(os.path.join(st, rel))
        if rel in seen or not dst.startswith(R + '/') or not src.startswith(st + '/'):
            sys.exit('duong dan plan khong hop le / trung lap: ' + rel)
        seen.add(rel)
        guard_target(dst)
        cur = open(dst, 'rb').read()
        new = open(src, 'rb').read()
        if sha(new) != e['sha_after']:
            sys.exit('staging da doi tu luc plan: ' + rel)
        ok, err = luac(src)
        if not ok:
            sys.exit('staging Lua khong hop le: %s: %s' % (rel, err))
        if sha(cur) == e['sha_after']:
            continue
        if sha(cur) != e['sha_before']:
            sys.exit('%s da doi tu luc plan - chay lai plan' % rel)
        prepared.append((e, dst, new))
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    bdir = os.path.join(R, 'backups', 'menpai-join-' + stamp)
    # Keep a complete recovery manifest before the first target mutation.
    if prepared:
        for e, dst, _ in prepared:
            b = os.path.join(bdir, e['file'])
            os.makedirs(os.path.dirname(b), exist_ok=True)
            shutil.copy2(dst, b)
            if sha(open(b, 'rb').read()) != e['sha_before']:
                sys.exit('ban sao luu khong khop: ' + e['file'])
        with open(os.path.join(bdir, 'manifest.json'), 'w', encoding='utf-8') as f:
            json.dump({'when': stamp, 'files': [e for e, _, _ in prepared]}, f, indent=1)
    done = []
    for e, dst, new in prepared:
        rel = e['file']
        if sha(open(dst, 'rb').read()) != e['sha_before']:
            sys.exit('tep doi trong luc apply; ban sao luu tai %s: %s' % (bdir, rel))
        with open(dst + '.menpai-join-tmp', 'wb') as f:
            f.write(new)
        os.chmod(dst + '.menpai-join-tmp', os.stat(dst).st_mode & 0o7777)
        try:
            stt = os.stat(dst)
            os.chown(dst + '.menpai-join-tmp', stt.st_uid, stt.st_gid)
        except OSError:
            pass
        os.replace(dst + '.menpai-join-tmp', dst)
        done.append(rel)
    print('apply: %d tep ghi, %d tep da dung san ; sao luu: %s' % (len(done), len(plan['files']) - len(done),
                                                                     bdir if done else '(khong can)'))
    return 0


def cmd_undo(args):
    b = os.path.abspath(args.backup)
    man = json.load(open(os.path.join(b, 'manifest.json'), encoding='utf-8'))
    n = 0
    for e in man['files']:
        dst = os.path.join(R, e['file'])
        guard_target(dst)
        src = os.path.join(b, e['file'])
        if sha(open(src, 'rb').read()) != e['sha_before']:
            sys.exit('ban sao luu %s khong khop sha_before' % e['file'])
        shutil.copy2(src, dst)
        n += 1
    print('undo: tra %d tep tu %s' % (n, b))
    return 0


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('plan'); p.add_argument('--out', required=True); p.add_argument('--root', default=R)
    v = sub.add_parser('verify'); v.add_argument('--root', default=R); v.add_argument('--overlay'); v.add_argument('--out')
    a = sub.add_parser('apply'); a.add_argument('--staging', required=True); a.add_argument('--allow-running', action='store_true')
    u = sub.add_parser('undo'); u.add_argument('--backup', required=True)
    args = ap.parse_args()
    return {'plan': cmd_plan, 'verify': cmd_verify, 'apply': cmd_apply, 'undo': cmd_undo}[args.cmd](args)


if __name__ == '__main__':
    sys.exit(main())
