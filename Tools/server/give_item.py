# -*- coding: utf-8 -*-
"""Đặt một vật phẩm vào túi nhân vật TEST trên server riêng, để dựng điều kiện đo.

Vì sao cần: vài chiêu chỉ đo được khi nhân vật ở một trạng thái mà bot không tự tạo ra. Ví dụ
408 起死回生 và 423 金针渡劫 đều là chiêu HỒI SINH (`base.lua`: `must_in_special_state == 1` đòi
`not obj_tar:is_alive_in_deed()`), nên muốn đo thì phải có MỘT CÁI XÁC. Cách chắc chắn nhất hiện
nay là dùng chính một lỗi đã đo được: **phù hồi thành** `30501004/5/6` nay đánh chính người dùng
(−31 HP, agent item-live đo live) — đặt `attrib.hp = 1` rồi dùng phù là chết.

LUẬT (giống mọi công cụ dữ liệu khác của dự án):
  - CHỈ ghi cho GUID 200001..200016 (nhân vật test). Ngoài dải đó thì từ chối.
  - Dòng mới là BẢN SAO SHAPE của một dòng THẬT cùng LỚP vật phẩm (`floor(item_index / 1e7)`), chỉ
    đổi `item_index`, số lượng và `guid.series`. Không tự chế trường nào.
  - `guid.series` lấy lớn nhất đang dùng trên MỌI nhân vật rồi +1, nên không đụng vật phẩm nào khác.
  - Từ chối khi nhân vật đang đăng nhập (server ghi đè túi lúc thoát).
  - Ghi lại trạng thái túi TRƯỚC khi đổi vào file `--out` để hoàn tác được.

  give_item.py give   --guid G --item ITEM_INDEX [--count N] [--out F]
  give_item.py remove --guid G --item ITEM_INDEX [--out F]
  give_item.py show   --guid G [--out F]
"""
import argparse
import copy
import json
import os
import subprocess
import sys

sys.path.insert(0, '/mnt/c/TLBB/085/CY-Source/Tools/server')
from cs3b_menpai import provision  # noqa: E402

GUID_MIN, GUID_MAX = 200001, 200016
BAGS = ('prop_bag_list', 'bank_bag_list', 'material_bag_list', 'pet_bag_list', 'fashion_bag_list')
BAG = 'prop_bag_list'


def item_class(index):
    return int(index) // 10000000


def connected():
    out = subprocess.run(['ss', '-Htn', 'state', 'established',
                          '( sport = :15733 or sport = :15734 )'], capture_output=True, text=True).stdout
    return [l for l in out.splitlines() if l.strip()]


def scan(col):
    """(series lớn nhất đang dùng, một dòng mẫu thật cho từng lớp vật phẩm)."""
    top, sample = 0, {}
    for doc in col.find({}, {k: 1 for k in BAGS}):
        for key in BAGS:
            for row in (doc.get(key) or {}).values():
                if not isinstance(row, dict):
                    continue
                top = max(top, int((row.get('guid') or {}).get('series') or 0))
                cls = item_class(row.get('item_index') or 0)
                sample.setdefault(cls, row)
    return top, sample


def bag_of(col, guid):
    doc = col.find_one({'attrib.guid': guid})
    if not doc:
        sys.exit('khong co nhan vat guid %d' % guid)
    return doc, dict(doc.get(BAG) or {})


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('give', 'remove', 'show'))
    ap.add_argument('--guid', type=int, required=True)
    ap.add_argument('--item', type=int, default=0)
    ap.add_argument('--count', type=int, default=1)
    ap.add_argument('--out', default='')
    args = ap.parse_args()
    if not (GUID_MIN <= args.guid <= GUID_MAX):
        sys.exit('guid %d ngoai dai nhan vat test %d..%d; tu choi' % (args.guid, GUID_MIN, GUID_MAX))
    if args.cmd != 'show' and args.item <= 0:
        sys.exit('--item bat buoc')

    rec = {'lenh': args.cmd, 'guid': args.guid, 'item': args.item, 'count': args.count}
    with provision().database() as client:
        col = client['tlbb']['character']
        doc, bag = bag_of(col, args.guid)
        rec['truoc'] = {k: {'item_index': v.get('item_index'), 'count': v.get('count')}
                        for k, v in bag.items() if isinstance(v, dict)}
        if args.cmd == 'show':
            print(json.dumps(rec, ensure_ascii=False, indent=1))
            return 0

        online = connected()
        if online:
            sys.exit('co %d ket noi 15733/15734; dong bot/client roi chay lai (server ghi de tui luc thoat)'
                     % len(online))

        if args.cmd == 'remove':
            keys = [k for k, v in bag.items() if isinstance(v, dict) and v.get('item_index') == args.item]
            for k in keys:
                bag.pop(k)
            rec['da_bo_o'] = keys
        else:
            top, sample = scan(col)
            cls = item_class(args.item)
            mau = sample.get(cls)
            if mau is None:
                sys.exit('khong co dong mau THAT nao thuoc lop %d de chep shape; tu choi che dong moi' % cls)
            row = copy.deepcopy(mau)
            row['item_index'] = args.item
            row['count'] = args.count
            row['lay_count'] = args.count
            row['guid'] = dict(row.get('guid') or {})
            row['guid']['series'] = top + 1
            # item.lua: so luong chong nam TRONG khoi cua tung lop (item-live 17/09); lop 3 = unknow_20[0]
            if cls == 3 and isinstance(row.get('unknow_20'), list) and row['unknow_20']:
                row['unknow_20'] = list(row['unknow_20'])
                row['unknow_20'][0] = args.count
            slot = next(str(i) for i in range(1, 81) if str(i) not in bag)
            bag[slot] = row
            rec.update({'o_moi': slot, 'series_moi': top + 1, 'lop': cls,
                        'mau_tu_item_index': mau.get('item_index')})

        r = col.update_one({'attrib.guid': args.guid}, {'$set': {BAG: bag}})
        rec.update({'matched': r.matched_count, 'modified': r.modified_count})
        doc2, bag2 = bag_of(col, args.guid)
        rec['sau'] = {k: {'item_index': v.get('item_index'), 'count': v.get('count')}
                      for k, v in bag2.items() if isinstance(v, dict)}
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(rec, f, ensure_ascii=False, indent=1, default=str)
    return 0


if __name__ == '__main__':
    sys.exit(main())
