# -*- coding: utf-8 -*-
"""CYS-PETSKILL (pet-skill-12, 19/09) — đặt kỹ năng cho MỘT trân thú của nhân vật TEST trên server riêng.

Vì sao cần: khung trân thú của CY vẽ 12 nút kỹ năng (`Pet.lua:24 PETSKILL_BUTTONS_NUM = 12`) và gói 512 mang
13 ô, nhưng **dữ liệu server hiện tại không sinh nổi trân thú quá 5 kỹ năng**:
`petmanager:create_skill_of_pet` chỉ đọc `PetSkillDistribute.txt` (tối đa 5 cột / dòng; kỳ vọng cao nhất 3,888 ở
麒麟 3330-3335), còn 6..12 kỹ năng chỉ đến từ đường HỌC (`pet_detail:skill_modify_study`, trần 2 chủ động +
10 bị động = 12) — đường đó cần gói chọn trân thú đích do client gửi. Không có trân thú > 6 kỹ năng thì không đo
được việc mở 13 ô, nên công cụ này dựng điều kiện đo.

LUẬT (y như `give_item.py`):
  - CHỈ ghi cho GUID 200001..200016 (nhân vật test). Ngoài dải đó thì từ chối.
  - Từ chối khi còn kết nối game sống (server ghi đè khi thoát).
  - Kỹ năng phải là ID có thật trong `PetSkillIndexTable.txt` (94 ID 652..745) — không tự chế ID.
  - Hình dạng `skills` = `{'activate': {'1': id, '2': id}, 'positive': {'1': id, ...}}`, đúng kiểu bảng Lua khoá
    số mà lớp Mongo của dự án đã dùng cho `pet_bag_list` (khoá chuỗi '1'..'5'); server đọc thẳng
    `self.skill_list = data.skills` (`pet_detail.lua:20`) và ghi ra dây theo `skills.activate[1..2]` +
    `skills.positive[1..11]` (`pet_detail.lua:874-886`).
  - Trần của chính server: 2 chủ động + 10 bị động (`get_skill_max_control_by_player/ai`), nên `--skills` nhận
    tối đa 12 ID; ô dây thứ 13 (`positive_11`) server không bao giờ điền.
  - Luôn ghi `pet_bag_list` TRƯỚC khi đổi ra `--out` để hoàn tác được.

  pet_skill_seed.py show    --guid G [--out F]
  pet_skill_seed.py seed    --guid G --slot S --skills 652,655,660,668,670,692,722,728 [--out F]
  pet_skill_seed.py restore --from F
"""
import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, '/mnt/c/TLBB/085/CY-Source/Tools/server')
from cs3b_menpai import provision  # noqa: E402

GUID_MIN, GUID_MAX = 200001, 200016
BAG = 'pet_bag_list'
CONFIGS = '/home/ubuntu/cys-test-20260913/configs'
MAX_ACTIVATE, MAX_POSITIVE = 2, 10       # pet_detail:get_skill_max_control_by_player / _by_ai


def connected():
    out = subprocess.run(['ss', '-Htn', 'state', 'established',
                          '( sport = :15733 or sport = :15734 )'], capture_output=True, text=True).stdout
    return [l for l in out.splitlines() if l.strip()]


def known_skill_ids():
    path = os.path.join(CONFIGS, 'PetSkillIndexTable.txt')
    ids = set()
    with open(path, 'rb') as f:
        for n, raw in enumerate(f):
            if n < 2:
                continue
            parts = raw.decode('gbk', 'replace').rstrip('\r\n').split('\t')
            if len(parts) >= 2 and parts[1].strip().lstrip('-').isdigit():
                ids.add(int(parts[1]))
    return ids


def guard(guid):
    if not (GUID_MIN <= guid <= GUID_MAX):
        sys.exit('refuse: guid %d is not a test character (%d..%d)' % (guid, GUID_MIN, GUID_MAX))
    live = connected()
    if live:
        sys.exit('refuse: %d live game connection(s); log every client out first' % len(live))


def char(client, guid):
    docs = list(client['tlbb']['character'].find({'attrib.guid': guid}, {'_id': 0, BAG: 1}))
    if len(docs) != 1:
        sys.exit('expected one character %d, found %d' % (guid, len(docs)))
    return docs[0]


def describe(bag):
    rows = []
    items = sorted(bag.items()) if isinstance(bag, dict) else list(enumerate(bag or []))
    for key, pet in items:
        attrib = (pet or {}).get('attrib') or {}
        skills = (pet or {}).get('skills') or {}
        rows.append({'slot': str(key), 'data_id': attrib.get('data_id'), 'name': attrib.get('name'),
                     'level': attrib.get('level'), 'lingxing': attrib.get('lingxing'),
                     'attack_type': attrib.get('attack_type'), 'con_perception': attrib.get('con_perception'),
                     'activate': skills.get('activate') or {}, 'positive': skills.get('positive') or {}})
    return rows


def write_out(path, payload):
    if not path:
        return
    os.makedirs(os.path.dirname(os.path.abspath(path)) or '.', exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)


def cmd_show(args):
    client = provision().database()
    try:
        doc = char(client, args.guid)
        rows = describe(doc.get(BAG) or {})
        print(json.dumps(rows, ensure_ascii=False, indent=1))
        write_out(args.out, {'guid': args.guid, 'pets': rows})
    finally:
        client.close()


def cmd_seed(args):
    guard(args.guid)
    ids = [int(x) for x in args.skills.split(',') if x.strip()]
    known = known_skill_ids()
    unknown = [i for i in ids if i not in known]
    if unknown:
        sys.exit('refuse: %s are not pet skills of PetSkillIndexTable.txt' % unknown)
    if len(ids) != len(set(ids)):
        sys.exit('refuse: duplicate skill id; the server never stores the same skill twice')
    if len(ids) > MAX_ACTIVATE + MAX_POSITIVE:
        sys.exit('refuse: %d skills; the server itself holds at most %d (2 activate + 10 positive)'
                 % (len(ids), MAX_ACTIVATE + MAX_POSITIVE))
    client = provision().database()
    try:
        doc = char(client, args.guid)
        bag = doc.get(BAG) or {}
        if args.slot not in bag:
            sys.exit('refuse: slot %s not in %s (slots: %s)' % (args.slot, BAG, sorted(bag)))
        before = describe(bag)
        act, pos = ids[:MAX_ACTIVATE], ids[MAX_ACTIVATE:]
        if args.shape == 'doc':
            # BSON document with string keys - the shape `pet_bag_list` itself has. MEASURED 19/09: this does NOT
            # work for skills. skynet's bson decodes a document into a Lua table with STRING keys, and
            # pet_detail.lua indexes skill_list.activate[1] / positive[i] with a NUMBER, so every cell read nil and
            # the pet went on the wire with 13 x -1 (Build/Logs/2026-09-19-pet-skill-12/live/skill-after-074927).
            # pet_bag_list survives the same encoding only because it is walked with pairs(), never indexed.
            skills = {'activate': {str(i + 1): v for i, v in enumerate(act)},
                      'positive': {str(i + 1): v for i, v in enumerate(pos)}}
        else:
            # BSON array -> Lua sequence with integer keys 1..n, which is what pet_detail.lua indexes.
            skills = {'activate': list(act), 'positive': list(pos)}
        res = client['tlbb']['character'].update_one(
            {'attrib.guid': args.guid}, {'$set': {'%s.%s.skills' % (BAG, args.slot): skills}})
        after = describe(char(client, args.guid).get(BAG) or {})
        payload = {'guid': args.guid, 'slot': args.slot, 'skills': ids, 'shape': args.shape, 'written': skills,
                   'matched': res.matched_count, 'modified': res.modified_count,
                   'before': before, 'after': after,
                   'restore': 'pet_skill_seed.py restore --from <this file>'}
        write_out(args.out, payload)
        print(json.dumps({k: payload[k] for k in ('guid', 'slot', 'skills', 'written', 'matched', 'modified')},
                         ensure_ascii=False, indent=1))
        print('after: %s' % json.dumps([r for r in after if r['slot'] == args.slot], ensure_ascii=False))
    finally:
        client.close()


def cmd_restore(args):
    with open(args.source, encoding='utf-8') as f:
        payload = json.load(f)
    guid = int(payload['guid'])
    guard(guid)
    old = next((r for r in payload['before'] if r['slot'] == payload['slot']), None)
    if old is None:
        sys.exit('refuse: backup has no slot %s' % payload['slot'])
    skills = {'activate': old.get('activate') or {}, 'positive': old.get('positive') or {}}
    # CYS-PETSKILL: mỗi lần `seed` ghi đè `before` bằng trạng thái NGAY TRƯỚC lần gieo đó, nên gieo hai lần thì bản
    # sao thứ hai chỉ đưa về lần gieo thứ nhất, KHÔNG về trạng thái gốc. Dùng bản sao ĐẦU TIÊN của chuỗi.
    if skills['activate'] or skills['positive']:
        print('CANH BAO: bản sao này ghi lại một trạng thái ĐÃ CÓ kỹ năng (%s / %s).\n'
              '          Nếu muốn về trạng thái gốc thì dùng file `seed` ĐẦU TIÊN của chuỗi.'
              % (skills['activate'], skills['positive']))
    client = provision().database()
    try:
        res = client['tlbb']['character'].update_one(
            {'attrib.guid': guid}, {'$set': {'%s.%s.skills' % (BAG, payload['slot']): skills}})
        after = describe(char(client, guid).get(BAG) or {})
        print(json.dumps({'guid': guid, 'slot': payload['slot'], 'restored': skills,
                          'matched': res.matched_count, 'modified': res.modified_count,
                          'now': [r for r in after if r['slot'] == payload['slot']]}, ensure_ascii=False, indent=1))
    finally:
        client.close()


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('show'); a.add_argument('--guid', type=int, required=True); a.add_argument('--out')
    a = sub.add_parser('seed')
    a.add_argument('--guid', type=int, required=True)
    a.add_argument('--slot', required=True)
    a.add_argument('--skills', required=True)
    a.add_argument('--shape', choices=('array', 'doc'), default='array')
    a.add_argument('--out')
    a = sub.add_parser('restore'); a.add_argument('--from', dest='source', required=True)
    args = ap.parse_args()
    {'show': cmd_show, 'seed': cmd_seed, 'restore': cmd_restore}[args.cmd](args)


if __name__ == '__main__':
    main()
