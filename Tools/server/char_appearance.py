#!/usr/bin/env python3
r"""[review-red 18/09/2026] Xem / dat BO BA NGOAI HINH cua mot nhan vat TEST cho NHAT QUAN VOI GIOI TINH.

VI SAO CAN (do duoc, khong doan):
  logind.lua:492-500 dung LCRetCharList tu Mongo:  sex <- attrib.model, head <- attrib.face_style,
  hair <- attrib.hair_style.  Phia client, CysCreateRoleAppearance::Resolve (CysCreateRoleAppearance.cpp:176)
  DOI dung gioi tinh:
        if (... || (*face)[1].number != sex || (*hair)[1].number != sex) -> false
  Bang CysCreateFace / CysCreateHair (Overlay/Post/ConfigFolder) co cot 1 = gioi tinh:
        face id 100  -> sex 1 (nam)      face sex 0 (nu): 1, 2, 3, 4, 5, ...
        hair id 5    -> sex 1 (nam)      hair sex 0 (nu): 0, 1, 2, 3, 4, ...
  Ca 16 nhan vat test deu face_style=100 / hair_style=5 (NAM).  Doi RIENG attrib.model sang 0 tao ra mot ban
  ghi TU MAU THUAN (sex nu + mat/toc nam) -> Resolve false -> CGamePro_CharSel::SetModernCharacterList tra
  false -> GamePro_Login.cpp:443 "invalid list" -> dung han o man chon nhan vat.
  => Muon thu nhan vat NU that thi phai doi CA BA o cung luc, do la viec cua cong cu nay.

CHI cham GUID 200001..200016 va CHI ba o attrib.model / attrib.face_style / attrib.hair_style.
Server doc attrib luc nap nhan vat => nhan vat phai KHONG dang dang nhap khi ghi.

  char_appearance.py show   --guid 200014
  char_appearance.py female --guid 200014 --apply      # model 0, face 1, hair 0, portrait 1
  char_appearance.py male   --guid 200014 --apply      # model 1, face 100, hair 5, portrait 13 (mac dinh cu)
  char_appearance.py set    --guid 200014 --model 0 --face 3 --hair 2 --portrait 2 --apply
"""
import argparse
import json
import sys

sys.path.insert(0, '/mnt/c/TLBB/085/CY-Source/Tools/server')
from cs3b_menpai import provision  # noqa: E402

GUID_MIN, GUID_MAX = 200001, 200016
FIELDS = ('model', 'face_style', 'hair_style', 'portrait_id')
# (model, face_style, hair_style, portrait_id) - ca BON o deu phan chia theo gioi tinh.
# portrait: CysCreatePortrait sex 0 = 1,2,3...; sex 1 = 13,14,15...  Bo sot o nay thi
# CyPortraitById() TDThrow khi Lua ve danh sach (do duoc 18/09, luot gui-female-1).
PRESETS = {'female': (0, 1, 0, 1), 'male': (1, 100, 5, 13)}


def look_of(doc):
    a = doc.get('attrib') or {}
    return {k: a.get(k) for k in FIELDS}


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('show', 'female', 'male', 'set'):
        p = sub.add_parser(name)
        p.add_argument('--guid', type=int, required=True)
        p.add_argument('--apply', action='store_true')
        if name == 'set':
            p.add_argument('--model', type=int, required=True, choices=(0, 1))
            p.add_argument('--face', type=int, required=True)
            p.add_argument('--hair', type=int, required=True)
            p.add_argument('--portrait', type=int, required=True)
    args = ap.parse_args()
    if not (GUID_MIN <= args.guid <= GUID_MAX):
        sys.exit('GUID %d ngoai dai nhan vat test %d..%d' % (args.guid, GUID_MIN, GUID_MAX))

    rec = {'cmd': args.cmd, 'guid': args.guid, 'applied': False}
    server = provision()
    with server.database() as client:
        col = client['tlbb']['character']
        doc = col.find_one({'attrib.guid': args.guid}, {'_id': 0})
        if not doc:
            sys.exit('khong tim thay nhan vat %d' % args.guid)
        rec['before'] = look_of(doc)
        if args.cmd == 'show':
            print(json.dumps(rec, ensure_ascii=False, indent=1))
            return 0
        if args.cmd == 'set':
            model, face, hair, portrait = args.model, args.face, args.hair, args.portrait
        else:
            model, face, hair, portrait = PRESETS[args.cmd]
        rec['after_planned'] = {'model': model, 'face_style': face, 'hair_style': hair, 'portrait_id': portrait}
        if not args.apply:
            rec['note'] = 'chay thu; them --apply de ghi'
            print(json.dumps(rec, ensure_ascii=False, indent=1))
            return 0
        col.update_one({'attrib.guid': args.guid},
                       {'$set': {'attrib.model': model, 'attrib.face_style': face,
                                 'attrib.hair_style': hair, 'attrib.portrait_id': portrait}})
        doc2 = col.find_one({'attrib.guid': args.guid}, {'_id': 0})
        rec['after'] = look_of(doc2)
        rec['applied'] = True
        print(json.dumps(rec, ensure_ascii=False, indent=1))
    return 0


if __name__ == '__main__':
    sys.exit(main())
