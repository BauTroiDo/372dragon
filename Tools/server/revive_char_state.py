#!/usr/bin/env python3
"""CYS-REVIVE — đọc/sửa trạng thái "chết kẹt" của nhân vật test trong Mongo riêng.

Chạy trong WSL TLBB bằng root; Mongo riêng 127.0.0.1:27018 phải đang chạy.
Credential đọc trong tiến trình qua Tools/server/provision_test_wsl.py (không in ra).

  revive_char_state.py inspect --guid 200012 [--guid ...] --out <json>
      In hp / hp_max / can_action_1 / can_action_2 / ride_model / sceneid / số impact đang lưu.
      KHÔNG ghi gì vào Mongo.

  revive_char_state.py revive --guid 200012 --out <json> [--dry-run]
      Đặt lại hp = hp_max (và mp = mp_max nếu có), xoá danh sách impact đang lưu.
      Từ chối khi còn client nối vào 15733/15734 (sửa DB dưới chân một phiên đang chạy sẽ bị
      ghi đè khi phiên đó lưu lại). Ghi bản sao trường trước khi sửa vào <json>.
"""
import argparse
import importlib.util
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

# Khoá quan tâm: -37 OR_LIMIT_USE_SKILL đến từ can_action_1/can_action_2 == 0 hoặc ride_model hợp lệ
# (GameServer/services/scene/obj/character.lua : can_use_this_skill_in_this_status).
WATCH = ('guid', 'name', 'hp', 'hp_max', 'mp', 'mp_max', 'can_action_1', 'can_action_2',
         'ride_model', 'sceneid', 'level', 'camp_id')


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


def summarize(doc):
    out = {'top_level_keys': sorted(doc.keys())}
    attrib = doc.get('attrib') or {}
    fields = {}
    for key in WATCH:
        if key in attrib:
            value = attrib[key]
            fields[key] = value if isinstance(value, (int, float, str)) and not isinstance(value, bool) else '<%s>' % type(value).__name__
    out['attrib'] = fields
    # mọi khoá attrib có "action", "impact", "buff", "die", "relive" trong tên
    extra = {}
    for key, value in attrib.items():
        low = key.lower()
        if any(w in low for w in ('action', 'impact', 'buff', 'die', 'relive', 'ghost')):
            if isinstance(value, list):
                extra[key] = 'list[%d]' % len(value)
            elif isinstance(value, dict):
                extra[key] = 'dict[%d]' % len(value)
            else:
                extra[key] = value
    out['attrib_matching'] = extra
    # danh sách impact có thể nằm ngoài attrib
    for key, value in doc.items():
        if key in ('_id', 'attrib'):
            continue
        low = key.lower()
        if any(w in low for w in ('impact', 'buff')):
            out.setdefault('doc_matching', {})[key] = 'list[%d]' % len(value) if isinstance(value, list) else repr(value)[:120]
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('inspect')
    a.add_argument('--guid', type=int, action='append', required=True)
    a.add_argument('--out', required=True)
    a = sub.add_parser('revive')
    a.add_argument('--guid', type=int, action='append', required=True)
    a.add_argument('--out', required=True)
    a.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    server = provision()
    record = {'cmd': args.cmd, 'guids': args.guid, 'chars': {}}
    with server.database() as client:
        col = client['tlbb']['character']
        if args.cmd == 'revive' and not args.dry_run and clients():
            sys.exit('client connected to 15733/15734; refuse')
        for guid in args.guid:
            docs = list(col.find({'attrib.guid': guid}, {'_id': 0}))
            if len(docs) != 1:
                record['chars'][str(guid)] = {'error': 'found %d documents' % len(docs)}
                continue
            entry = {'before': summarize(docs[0])}
            if args.cmd == 'revive':
                attrib = docs[0].get('attrib') or {}
                sets = {}
                hp_max = attrib.get('hp_max')
                if isinstance(hp_max, (int, float)) and hp_max > 0:
                    sets['attrib.hp'] = int(hp_max)
                mp_max = attrib.get('mp_max')
                if isinstance(mp_max, (int, float)) and mp_max > 0:
                    sets['attrib.mp'] = int(mp_max)
                for key in ('can_action_1', 'can_action_2'):
                    if key in attrib:
                        sets['attrib.' + key] = 1
                unsets = {}
                for key, value in list(docs[0].items()):
                    if key == '_id':
                        continue
                    if 'impact' in key.lower() or 'buff' in key.lower():
                        unsets[key] = ''
                for key, value in list(attrib.items()):
                    if 'impact' in key.lower() or 'buff' in key.lower():
                        unsets['attrib.' + key] = ''
                entry['set'] = sets
                entry['unset'] = sorted(unsets)
                if not args.dry_run:
                    update = {}
                    if sets:
                        update['$set'] = sets
                    if unsets:
                        update['$unset'] = unsets
                    if update:
                        result = col.update_one({'attrib.guid': guid}, update)
                        entry['matched'] = result.matched_count
                        entry['modified'] = result.modified_count
                    entry['after'] = summarize(col.find_one({'attrib.guid': guid}, {'_id': 0}))
            record['chars'][str(guid)] = entry
    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump(record, f, ensure_ascii=False, indent=1)
    print(json.dumps(record, ensure_ascii=False, indent=1))


if __name__ == '__main__':
    main()
