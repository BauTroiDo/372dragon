# -*- coding: utf-8 -*-
"""bullet-fx (19/09/2026): cap ky nang PHAI TAM XA (co dan) cho mot nhan vat test, de tai hien duoc "hinh anh ve dan".

VI SAO CAN: nhan vat nguoi dung choi hom nay co 9 ky nang toan tien ich va `GCDetailXinFaList count=0` — khong
mot chieu nao mang dan. Danh thuong can chien KHONG co dan theo thiet ke (ca CY lan ta). Muon tra loi dut diem
bao cao "khong co hinh anh ve dan" thi phai co mot nhan vat BAM DUOC mot chieu tam xa.

CHAY TRONG WSL TLBB bang root:
  wsl -d TLBB -u root -- python3 -B /mnt/c/TLBB/085/CY-Source/Tools/fx/bullet/grant_bullet_skill.py show
  wsl -d TLBB -u root -- python3 -B .../grant_bullet_skill.py apply --uid test09 --menpai 3 --skills 371,381,385 --out <json>

BA DIEU KIEN AN TOAN (dieu phoi chot 19/09, va bay da sap that trong du an nay):
  1. **DA TAI KHOAN TRUOC, SUA DB SAU** — ban luu phien trong RAM ghi DE len ban vua sua. Cong cu nay TU CHOI
     ghi khi con socket toi 15733/15734 ("0 socket" van chua chac la offline: kiem ca tien trinh Game.exe o
     phia Windows truoc khi tin).
  2. **KHONG restart server.** Cong cu nay khong dung toi server; no chi ghi Mongo.
  3. Luon sao luu NGUYEN VAN ca document truoc khi ghi (`backup_full_doc` trong tep --out), de hoan tac duoc.

KHONG dung `cs3b_menpai.py mongo-apply`: ham do ghim cung GUID 200001 va lam viec khac han (doi he ID GL->CY).
"""
import argparse
import datetime
import importlib.util
import json
import os
import sys

PROVISION = '/mnt/c/TLBB/085/CY-Source/Tools/server/provision_test_wsl.py'

# bullet-live 20/09: GameServer/lualib/define.lua:311,326 - hai tam phap KHONG duoc cap khi vao phai.
MENPAI_7_XINFA = {0: 55, 1: 56, 2: 57, 3: 58, 4: 59, 5: 60}
MENPAI_8_XINFA = {0: 72, 1: 73, 2: 74, 3: 75, 4: 76, 5: 77}
# Tam phap cua tung phai, doc tu cot 10 (m_nSkillClass) cua SkillTemplate_V1 cho cac skill cung cot 1 (menpai).
# Vo Dang (3): 19,20,21,22,23,24 (+58 va 75 bi luat tren loai ra). Khung ActionSkill chi co 7 nut tam phap.
MENPAI_XINFA = {3: [19, 20, 21, 22, 23, 24]}


def load_provision():
    spec = importlib.util.spec_from_file_location('provision_test_wsl', PROVISION)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def connected_clients():
    """So socket dang mo toi cong login/game cua server rieng."""
    n = 0
    for name in ('/proc/net/tcp', '/proc/net/tcp6'):
        try:
            with open(name) as f:
                for line in f.read().splitlines()[1:]:
                    parts = line.split()
                    port = int(parts[1].split(':')[1], 16)
                    if port in (15733, 15734) and parts[3] == '01':
                        n += 1
        except OSError:
            pass
    return n


def projection(doc):
    a = doc.get('attrib') or {}
    return {'guid': a.get('guid'), 'name': a.get('name'), 'menpai': a.get('menpai'), 'level': a.get('level'),
            'skill_list': doc.get('skill_list'), 'xinfa_list': doc.get('xinfa_list')}


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('show')
    s.add_argument('--uid')
    a = sub.add_parser('apply')
    a.add_argument('--uid', required=True)
    a.add_argument('--menpai', type=int, required=True)
    a.add_argument('--skills', required=True, help='danh sach id skill, phan cach bang dau phay')
    a.add_argument('--level', type=int)
    a.add_argument('--xinfa', help='danh sach id tam phap, phan cach bang dau phay; '
                                   '"server" = dung dung luat cua script_base.lua cho --menpai')
    a.add_argument('--out', required=True)
    args = ap.parse_args()

    prov = load_provision()
    cl = prov.database()
    accounts = cl['tlbb']['account']
    chars = cl['tlbb']['character']

    if args.cmd == 'show':
        q = {'uid': args.uid} if args.uid else {}
        for acc in accounts.find(q, {'_id': 0}).limit(40):
            uid = acc.get('uid')
            guids = [g for g in (acc.get('char_list') or []) if g]
            print('account uid=%-8s keys=%s' % (uid, sorted(k for k in acc if k != 'password')[:10]))
            for d in chars.find({'attrib.guid': {'$in': guids}} if guids else {'account': uid}, {'_id': 0}):
                p = projection(d)
                print('   char guid=%s name=%s menpai=%s level=%s skills=%d %s' % (
                    p['guid'], p['name'], p['menpai'], p['level'],
                    len(p['skill_list'] or []), (p['skill_list'] or [])[:14]))
        return 0

    # ---- apply
    if connected_clients():
        sys.exit('CO socket toi 15733/15734 — da tai khoan TRUOC roi moi chay lai (ban luu RAM se ghi de).')
    docs = list(chars.find({'attrib.account': args.uid}, {'_id': 0}))
    if not docs:
        acc = accounts.find_one({'uid': args.uid}, {'_id': 0})
        guids = [g for g in ((acc or {}).get('char_list') or []) if g]
        docs = list(chars.find({'attrib.guid': {'$in': guids}}, {'_id': 0})) if guids else []
    if len(docs) != 1:
        sys.exit('mong doi dung MOT nhan vat cua %s, tim thay %d' % (args.uid, len(docs)))
    doc = docs[0]
    guid = (doc.get('attrib') or {}).get('guid')
    before = projection(doc)

    want = [int(x) for x in args.skills.split(',') if x.strip()]
    skills = list(doc.get('skill_list') or [])
    added = [s for s in want if s not in skills]
    skills += added
    sets = {'attrib.menpai': args.menpai, 'skill_list': skills}

    # bullet-live 20/09 - VI SAO PHAI CO CAI NAY. Ban dau cong cu chi ghi menpai + skill_list, tuc mot
    # trang thai ma CHINH SERVER KHONG BAO GIO tao ra: `script_base.lua:194-208` (duong vao phai that)
    # luon cap CA HAI - xinfa_list TRUOC roi moi toi skill. Thieu xinfa thi client 0.85 goc
    # (client/Data/InterfaceFolder/ActionSkill/ActionSkill.lua:240-268) do het 7 nut tam phap ve -1,
    # khong bao gio goi ActionSkill_Update_Cliecked, nen KHONG mot nut chieu thuc (Zhaoshi) nao duoc ve:
    # nhan vat CO skill trong skill_list nhung KHONG CACH NAO bam duoc no, va do la ly do
    # "khong co hinh anh ve dan" - khong phai loi ve dan.
    xinfa_ids = None
    if args.xinfa == 'server':
        xinfa_ids = MENPAI_XINFA.get(args.menpai)
        if xinfa_ids is None:
            sys.exit('chua co bang tam phap cho menpai %d; truyen --xinfa <id,...> tuong minh' % args.menpai)
    elif args.xinfa:
        xinfa_ids = [int(x) for x in args.xinfa.split(',') if x.strip()]
    if xinfa_ids is not None:
        bad = [i for i in xinfa_ids
               if i in (MENPAI_7_XINFA.get(args.menpai), MENPAI_8_XINFA.get(args.menpai))]
        if bad:
            sys.exit('tam phap %s nam trong MENPAI_7/8, server khong cap khi vao phai' % bad)
        sets['xinfa_list'] = [{'m_nXinFaID': i, 'm_nXinFaLevel': 1} for i in xinfa_ids]
    if args.level:
        sets['attrib.level'] = args.level

    if os.path.exists(args.out):
        sys.exit('tep --out da ton tai: ' + args.out)
    with open(args.out, 'x', encoding='utf-8') as f:
        json.dump({'utc': datetime.datetime.utcnow().isoformat(), 'uid': args.uid, 'guid': guid,
                   'backup_full_doc': doc, 'planned_set': sets, 'added_skills': added},
                  f, ensure_ascii=False, indent=1, default=str)
    r = chars.update_one({'attrib.guid': guid}, {'$set': sets})
    after = projection(chars.find_one({'attrib.guid': guid}, {'_id': 0}))
    out = {'uid': args.uid, 'guid': guid, 'matched': r.matched_count, 'modified': r.modified_count,
           'added_skills': added, 'before': before, 'after': after}
    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump({**out, 'backup_full_doc': doc}, f, ensure_ascii=False, indent=1, default=str)
    print(json.dumps(out, ensure_ascii=False, default=str, indent=1))
    return 0


if __name__ == '__main__':
    sys.exit(main())
