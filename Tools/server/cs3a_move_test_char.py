#!/usr/bin/env python3
"""CS3a — dời nhân vật test CYTest00 (GUID 200001, tài khoản test00) của SERVER RIÊNG về điểm hồi sinh bản đồ CY.

Chạy trong WSL TLBB bằng root, Mongo riêng 127.0.0.1:27018 phải đang chạy; credential đọc trong tiến trình qua
Tools/server/provision_test_wsl.py (không in ra). Chỉ chạm MỘT bản ghi `tlbb.character` có attrib.guid = 200001.

  cs3a_move_test_char.py inspect --out <json>                    tên khoá attrib có "pos"/"scene" + giá trị số
  cs3a_move_test_char.py apply --scene 2 --x 160 --z 150 --out <json> [--expect-scene 2]
      ghi bản sao các trường trước khi sửa vào <json>, rồi $set attrib.world_pos.x / .y (y của server = z bản đồ)
      và attrib.sceneid; từ chối khi còn client nối vào 15733/15734.
"""
import argparse
import importlib.util
import json
import os
import sys

GUID = 200001   # mặc định; --guid chọn nhân vật khác (CYS-MESHWIN 19/09, BẪY 4 của bot-pos-seq: trước đây ghi cứng)
HERE = os.path.dirname(os.path.abspath(__file__))


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


def projection(doc):
    attrib = doc.get('attrib') or {}
    out = {}
    for key, value in attrib.items():
        low = key.lower()
        if 'pos' in low or 'scene' in low:
            if isinstance(value, (int, float)) and not isinstance(value, bool):
                out[key] = value
            elif isinstance(value, dict):
                out[key] = {k: v for k, v in value.items() if isinstance(v, (int, float)) and not isinstance(v, bool)}
            else:
                out[key] = '<%s>' % type(value).__name__
    return {'guid': attrib.get('guid'), 'name_present': 'name' in attrib, 'fields': out}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('inspect'); a.add_argument('--out', required=True)
    a.add_argument('--guid', type=int, default=GUID)
    a = sub.add_parser('apply'); a.add_argument('--scene', type=int, required=True)
    a.add_argument('--x', type=float, required=True); a.add_argument('--z', type=float, required=True)
    a.add_argument('--expect-scene', type=int); a.add_argument('--out', required=True)
    a.add_argument('--guid', type=int, default=GUID)
    args = ap.parse_args()
    guid = args.guid   # CYS-MESHWIN: mọi truy vấn dưới đây dùng guid được chọn, không phải hằng 200001
    server = provision()
    with server.database() as client:
        col = client['tlbb']['character']
        docs = list(col.find({'attrib.guid': guid}, {'_id': 0, 'attrib': 1}))
        if len(docs) != 1:
            sys.exit('expected exactly one character with guid %d, found %d' % (guid, len(docs)))
        before = projection(docs[0])
        record = {'guid': guid, 'before': before}
        if args.cmd == 'apply':
            if clients():
                sys.exit('client connected to 15733/15734; refuse')
            scene = before['fields'].get('sceneid')
            if args.expect_scene is not None and scene != args.expect_scene:
                sys.exit('sceneid is %r, expected %r' % (scene, args.expect_scene))
            if os.path.exists(args.out):
                sys.exit('output exists: ' + args.out)
            with open(args.out, 'x', encoding='utf-8') as f:     # sao lưu trước khi ghi
                json.dump(record, f, ensure_ascii=False, indent=1)
            result = col.update_one({'attrib.guid': guid}, {'$set': {'attrib.world_pos.x': args.x,
                                                                      'attrib.world_pos.y': args.z,
                                                                      'attrib.sceneid': args.scene}})
            after = projection(col.find_one({'attrib.guid': guid}, {'_id': 0, 'attrib': 1}))
            record.update({'set': {'sceneid': args.scene, 'world_pos.x': args.x, 'world_pos.y': args.z},
                           'matched': result.matched_count, 'modified': result.modified_count, 'after': after})
            with open(args.out, 'w', encoding='utf-8') as f:
                json.dump(record, f, ensure_ascii=False, indent=1)
        else:
            with open(args.out, 'w', encoding='utf-8') as f:
                json.dump(record, f, ensure_ascii=False, indent=1)
        print(json.dumps(record, ensure_ascii=False))


if __name__ == '__main__':
    main()
