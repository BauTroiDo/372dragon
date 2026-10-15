#!/usr/bin/env python3
r"""[host-power 17/09/2026] Cap quyen so huu mot con thu cuoi cho nhan vat TEST tren server rieng.

VI SAO CAN (do duoc, khong doan):
  human.lua:4188 get_riders_max_speed_up() duyet `self.exterior.rides` = bo thu **DA SO HUU** va lay speed_up
  lon nhat. Con CGExteriorRequest type 7 / category 3 (scenecore.lua:3761 -> human:set_ride) chi ghi o "ride"
  va **KHONG kiem so huu**. Vi vay chon mot con khong so huu => speed_up = 0 => exterior_ride_conf.impacts[0]
  la nil => khong co impact => ride_model van -1 => server im lang. Do la mat xich dut cua duong cuoi thu.
  human.lua:6235 add_expiration_time(index, -1) ghi dung mot phan tu { id = index, term = -1, terminable = 0 }
  vao `exterior.rides`; ham do khong goi duoc tu CGExecuteScript nen cong cu nay ghi thang cung hinh dang do.

CHI cham GUID trong dai nhan vat test 200001..200016, va chi khoa `exterior.rides`.
Server doc `exterior` luc nap nhan vat, nen nhan vat phai KHONG dang dang nhap khi ghi.

  ride_grant.py show  --guid 200010
  ride_grant.py grant --guid 200010 --ride 1 --apply     # 1 = 陆行雕, 门派 -1 (moi mon phai deu dung duoc)
  ride_grant.py clear --guid 200010 --apply              # tra ve rong
"""
import argparse
import json
import sys

sys.path.insert(0, '/mnt/c/TLBB/085/CY-Source/Tools/server')
from cs3b_menpai import provision  # noqa: E402

GUID_MIN, GUID_MAX = 200001, 200016


def rides_of(doc):
    ext = doc.get('exterior') or {}
    rides = ext.get('rides')
    if isinstance(rides, dict):          # Lua table rong -> {} khi serialise
        rides = [v for _, v in sorted(rides.items())] if rides else []
    return rides or []


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('show', 'grant', 'clear'):
        p = sub.add_parser(name)
        p.add_argument('--guid', type=int, required=True)
        p.add_argument('--apply', action='store_true')
        if name == 'grant':
            p.add_argument('--ride', type=int, required=True)
    a = ap.parse_args()
    if not (GUID_MIN <= a.guid <= GUID_MAX):
        sys.exit('chi cho phep GUID nhan vat test %d..%d' % (GUID_MIN, GUID_MAX))

    with provision().database() as client:
        col = client['tlbb']['character']
        docs = list(col.find({'attrib.guid': a.guid}))
        if len(docs) != 1:
            sys.exit('mong doi dung mot nhan vat %d, thay %d' % (a.guid, len(docs)))
        doc = docs[0]
        before = rides_of(doc)
        out = {'cmd': a.cmd, 'guid': a.guid, 'applied': False,
               'before': {'rides': before, 'ride_selected': (doc.get('attrib') or {}).get('ride')}}
        if a.cmd == 'show':
            print(json.dumps(out, ensure_ascii=False, indent=1, default=str))
            return 0
        if a.cmd == 'grant':
            if any(int(r.get('id', -1)) == a.ride for r in before):
                out['note'] = 'da so huu tu truoc, khong ghi'
                print(json.dumps(out, ensure_ascii=False, indent=1, default=str))
                return 0
            after = list(before) + [{'id': a.ride, 'term': -1, 'terminable': 0}]
        else:
            after = []
        out['after'] = {'rides': after}
        if a.apply:
            col.update_one({'attrib.guid': a.guid}, {'$set': {'exterior.rides': after}})
            out['applied'] = True
        print(json.dumps(out, ensure_ascii=False, indent=1, default=str))
    return 0


if __name__ == '__main__':
    sys.exit(main())
