#!/usr/bin/env python3
"""CYS-REVIVE — gỡ ĐÚNG MỘT hiệu ứng (theo Data_Index) khỏi ĐÚNG MỘT nhân vật trong Mongo riêng.

Dùng khi nhân vật OFFLINE. Khi nhân vật đang online thì lối đúng là chuột phải icon buff trong game
(是否可以被手动取消 = 1) — đường đó đã được mở lại bởi bản vá CYS-REVIVE, xem Timeline/handoff/revive.md.
`character:impact_on_move()` chỉ gỡ được hiệu ứng có `开始移动时是否消失 = 1`, nên KHÔNG dùng được cho
những hiệu ứng như 43101 坐骑 (cờ đó = 0).

Ba lớp khoá, tất cả đều bắt buộc:
  --guid G           đúng một nhân vật
  --expect-name N    tên nhân vật phải khớp (chặn gõ nhầm guid)
  --data-index D     đúng một Data_Index; mọi hiệu ứng khác được giữ nguyên
Từ chối khi còn client nối vào 15733/15734 (sửa DB dưới chân một phiên đang chạy sẽ bị ghi đè khi nó lưu).
In TRẠNG THÁI TRƯỚC VÀ SAU trên cùng một dòng, và ghi bản sao các mục bị gỡ vào --out trước khi ghi.

  revive_drop_impact.py --guid 200010 --expect-name CYTest09 --data-index 43101 --out <json> [--dry-run]
"""
import argparse
import importlib.util
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BLOCK_KEYS = ('可否使用任何技能（CanAction1标记，-1为无效）',
              '可否使用任何技能（CanAction2标记,-1为无效）',
              '可否移动（CanMove标记,-1为无效）')


def provision():
    spec = importlib.util.spec_from_file_location('private_server', os.path.join(HERE, 'provision_test_wsl.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def clients():
    n = 0
    for name in ('/proc/net/tcp', '/proc/net/tcp6'):
        for line in open(name).read().splitlines()[1:]:
            parts = line.split()
            port = int(parts[1].split(':')[1], 16)
            if port in (15733, 15734) and parts[3] == '01':
                n += 1
    return n


def as_list(raw):
    if isinstance(raw, list):
        return list(raw)
    if isinstance(raw, dict):
        return [raw[k] for k in sorted(raw)]
    return []


def snapshot(doc):
    """Một dòng mô tả trạng thái: hiệu ứng nào đang có và cổng hành động của chúng."""
    attrib = doc.get('attrib') or {}
    parts = []
    for imp in as_list(doc.get('impact_list')):
        if not isinstance(imp, dict):
            continue
        params = imp.get('params') or {}
        gates = [('CanAction1', params.get(BLOCK_KEYS[0])), ('CanAction2', params.get(BLOCK_KEYS[1])),
                 ('CanMove', params.get(BLOCK_KEYS[2]))]
        blocked = ','.join('%s=0' % name for name, value in gates if value == 0) or 'khong-khoa'
        parts.append('%s(sn=%s,class=%s,%s)' % (imp.get('data_index'), imp.get('sn'), imp.get('class_id'), blocked))
    return 'impacts=[%s] db_can_action_1=%s db_can_action_2=%s ride_model=%s hp=%s/%s scene=%s' % (
        ' '.join(parts) if parts else '', attrib.get('can_action_1'), attrib.get('can_action_2'),
        attrib.get('ride_model'), attrib.get('hp'), attrib.get('hp_max'), attrib.get('sceneid'))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--guid', type=int, required=True)
    ap.add_argument('--expect-name', required=True)
    ap.add_argument('--data-index', type=int, required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    if os.path.exists(args.out):
        sys.exit('output exists: ' + args.out)
    online = clients()
    if online and not args.dry_run:
        sys.exit('%d client(s) connected to 15733/15734; refuse (nhan vat phai offline)' % online)

    server = provision()
    with server.database() as client:
        col = client['tlbb']['character']
        docs = list(col.find({'attrib.guid': args.guid}, {'_id': 0}))
        if len(docs) != 1:
            sys.exit('expected exactly one character with guid %d, found %d' % (args.guid, len(docs)))
        doc = docs[0]
        name = (doc.get('attrib') or {}).get('name')
        if name != args.expect_name:
            sys.exit('guid %d is %r, expected %r; refuse' % (args.guid, name, args.expect_name))

        before_line = snapshot(doc)
        raw = doc.get('impact_list')
        keep, dropped = [], []
        for imp in as_list(raw):
            if isinstance(imp, dict) and imp.get('data_index') == args.data_index:
                dropped.append(imp)
            else:
                keep.append(imp)
        record = {'guid': args.guid, 'name': name, 'data_index': args.data_index,
                  'client_connections': online, 'before': before_line,
                  'dropped': dropped, 'kept_count': len(keep), 'dry_run': bool(args.dry_run)}
        if not dropped:
            record['after'] = before_line
            record['note'] = 'khong co hieu ung %d tren nhan vat nay; KHONG ghi gi' % args.data_index
        elif args.dry_run:
            record['after'] = '(dry-run, khong ghi)'
        else:
            with open(args.out, 'x', encoding='utf-8') as f:      # sao lưu TRƯỚC khi ghi
                json.dump(record, f, ensure_ascii=False, indent=1)
            result = col.update_one({'attrib.guid': args.guid}, {'$set': {'impact_list': keep}})
            record['matched'] = result.matched_count
            record['modified'] = result.modified_count
            record['after'] = snapshot(col.find_one({'attrib.guid': args.guid}, {'_id': 0}))
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(record, f, ensure_ascii=False, indent=1)

    print('%s guid=%d name=%s drop=%d' % ('DRY-RUN' if args.dry_run else 'DA GO', args.guid, name, len(dropped)))
    print('  TRUOC: %s' % record['before'])
    print('  SAU  : %s' % record['after'])
    if record.get('note'):
        print('  GHI CHU: %s' % record['note'])


if __name__ == '__main__':
    main()
