#!/usr/bin/env python3
"""menpai-audit: bản ghi nhân vật test CYTest00..CYTest15 (GUID 200001..200016) trên Mongo server riêng. Không in credential.

  MỌI lệnh con nhận --guid G (mặc định 200001 = CYTest00) để đo SONG SONG trên nhiều nhân vật (bot-pos-seq 17/09).
  Mỗi lệnh chỉ chạm ĐÚNG MỘT bản ghi tlbb.character có attrib.guid = G, nên hai tiến trình dùng hai GUID khác nhau
  không thể giẫm lên nhau. Bản gốc (--original) là file RIÊNG của từng nhân vật; restore/refill từ chối nếu file
  ghi guid khác (chặn việc trả CYTest07 về theo bản lưu của CYTest00).

  char_menpai.py inspect --out F [--guid G]                  chỉ đọc (projection)
  char_menpai.py save-original --out F [--guid G]            lưu bản đầy đủ lần đầu (không ghi đè)
  char_menpai.py set --menpai M --xinfa-level L --out F [--static static-menpai.json] [--hp N] [--mp N] [--rage N] [--level N] [--guid G] [--online-check any|self]
        [--scene S --pos-x X --pos-z Z]: đặt điểm xuất phát của phiên bot (maps-sect 17/09). Dùng cho cảnh KHÔNG có
                cổng vào (495 唐家堡) nên không thể tới bằng NPC dịch chuyển. Ghi sau --refill-from nên luôn thắng.
        đặt menpai/reputation/xinfa_list/skill_list như LuaFnJoinMenpai + học 6 tâm pháp tới L; từ chối khi còn client
        --hp N: đặt attrib.hp = N NGAY TRƯỚC phiên bot (bot-pos-seq 17/09). Dùng để đo chiêu trị liệu: máu đầy thì
                GCDetailHealsAndDamages không có gì để hồi nên heal_sum = 0, không phân biệt "chạy" với "vô tác dụng".
                Ghi sau --refill-from nên luôn thắng giá trị gốc. Server đọc thẳng attrib.hp khi đăng nhập
                (services/msgagent.lua:1143) và chỉ kẹp XUỐNG theo hp_max, không tự hồi đầy.
  char_menpai.py refill --original F --out F [--guid G]      đặt lại attrib.hp/mp = bản gốc (trước mỗi phiên bot)
  char_menpai.py restore --original F --out F [--guid G] [--online-check any|self]
        trả menpai/reputation/xinfa_list/skill_list/level/sceneid/world_pos/hp/mp về bản gốc

  --online-check any  (MẶC ĐỊNH, như cũ): từ chối set/restore khi CÒN BẤT KỲ kết nối nào trên 15733/15734.
  --online-check self (đo song song): chỉ quan tâm nhân vật NÀY. Server hiện KHÔNG công bố cờ online theo nhân vật —
        mark_login_status trong services/game/gamed.lua bị chú thích ở cả ba chỗ gọi (dòng 98/247/269) nên
        trường character.is_online không bao giờ được ghi. Vì vậy 'self' chỉ đọc được cờ đó nếu server bật lại;
        ngoài ra nó dựa vào KHOÁ THEO TÀI KHOẢN của người gọi (menpai_check.ps1 -> Build\\<account>.lock).
        Điều đó vẫn an toàn vì mỗi lệnh chỉ ghi đúng một document theo attrib.guid. Mức kiểm thực tế được ghi
        vào file --out ở khoá 'online_check' để bằng chứng không nói quá.
"""
import argparse, json, os, subprocess, sys

sys.path.insert(0, '/mnt/c/TLBB/085/CY-Source/Tools/server')
from cs3b_menpai import provision  # noqa: E402

GUID_DEFAULT = 200001
GUID_MIN, GUID_MAX = 200001, 200016   # CYTest00..CYTest15; ngoài dải này là nhân vật người chơi -> từ chối
HERE = os.path.dirname(os.path.abspath(__file__))
BASE_SKILLS = [0, 1, 2, 3, 21, 22, 34, 35, 43]
REPUTATION = {0: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 7, 7: 8, 8: 9, 9: 12, 10: 37, 15: 36, 11: 59, 12: 60, 13: 61, 14: 62}
YUANGONG = {0: 4742, 1: 4743, 2: 4744, 7: 4745, 10: 4746}
RESTORE_KEYS = ['attrib.menpai', 'attrib.reputation', 'attrib.level', 'attrib.sceneid', 'attrib.world_pos', 'attrib.hp', 'attrib.mp',
                'xinfa_list', 'skill_list']


def clients():
    out = subprocess.run(['ss', '-Htn', 'state', 'established', '( sport = :15733 or sport = :15734 )'], capture_output=True, text=True).stdout
    return [l for l in out.splitlines() if l.strip()]


def get(doc, dotted):
    cur = doc
    for p in dotted.split('.'):
        if not isinstance(cur, dict) or p not in cur:
            return None
        cur = cur[p]
    return cur


def proj(doc):
    a = doc.get('attrib') or {}
    return {'guid': a.get('guid'), 'name': a.get('name'), 'menpai': a.get('menpai'), 'reputation': a.get('reputation'),
            'level': a.get('level'), 'exp': a.get('exp'), 'money': a.get('money'), 'sceneid': a.get('sceneid'), 'world_pos': a.get('world_pos'),
            'hp': a.get('hp'), 'mp': a.get('mp'), 'rage': a.get('rage'), 'rage_max': a.get('rage_max'),
            'is_online': doc.get('is_online'), 'xinfa_list': doc.get('xinfa_list'),
            'skill_list': doc.get('skill_list'), 'save_lv': (doc.get('game_flag') or {}).get('save_lv')}


def load_original(path, guid):
    """Bản gốc phải thuộc ĐÚNG nhân vật đang thao tác (đo song song: mỗi GUID một file riêng)."""
    data = json.load(open(path, encoding='utf-8'))
    saved = data.get('guid')
    if saved is not None and int(saved) != int(guid):
        sys.exit('original %s belongs to guid %s, not %d; refuse' % (path, saved, guid))
    return data['restore_values']


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    # --guid cho MOI lenh con: doc song song tren CYTest00..CYTest15 (200001..200016)
    def guid_arg(p):
        p.add_argument('--guid', type=int, default=GUID_DEFAULT)
        return p
    a = guid_arg(sub.add_parser('inspect')); a.add_argument('--out', required=True)
    a = guid_arg(sub.add_parser('save-original')); a.add_argument('--out', required=True)
    a = guid_arg(sub.add_parser('set')); a.add_argument('--menpai', type=int, required=True); a.add_argument('--xinfa-level', type=int, required=True)
    a.add_argument('--out', required=True); a.add_argument('--static', default=os.path.join(HERE, '..', 'static-menpai.json'))
    a.add_argument('--refill-from', default='')
    a.add_argument('--extra-skills', default='')  # them id ky nang ngoai learn_ids (chieu bien the)
    a.add_argument('--level', type=int, default=0)   # 0 = giu nguyen cap
    a.add_argument('--mp', type=int, default=0)      # 0 = giu nguyen (server kep theo MP toi da)
    a.add_argument('--hp', type=int, default=0)      # 0 = giu nguyen; > 0 = dat mau thap truoc phien (do chieu tri lieu)
    a.add_argument('--rage', type=int, default=0)    # 0 = giu nguyen; > 0 = dat attrib.rage (do chieu doi NO KHI, or_code -25)
    # CYS-MAPS-SECT (17/09): dat thang attrib.sceneid + attrib.world_pos truoc phien bot. Dung cho canh KHONG co
    # cong vao (vd 495 唐家堡): khong the dung NPC dich chuyen nen phai dat diem xuat phat. Ghi SAU --refill-from
    # de luon thang gia tri goc, giong cach --hp/--mp lam. Ca ba tham so phai di cung nhau.
    a.add_argument('--scene', type=int, default=0)   # 0 = giu nguyen; > 0 = dat attrib.sceneid
    a.add_argument('--pos-x', type=float, default=0.0)
    a.add_argument('--pos-z', type=float, default=0.0)
    a.add_argument('--online-check', choices=('any', 'self'), default='any')
    a = guid_arg(sub.add_parser('restore')); a.add_argument('--original', required=True); a.add_argument('--out', required=True)
    a.add_argument('--online-check', choices=('any', 'self'), default='any')
    a = guid_arg(sub.add_parser('refill')); a.add_argument('--original', required=True); a.add_argument('--out', required=True)
    args = ap.parse_args()
    guid = args.guid
    if not (GUID_MIN <= guid <= GUID_MAX):
        sys.exit('guid %d is outside the test characters %d..%d; refuse' % (guid, GUID_MIN, GUID_MAX))
    with provision().database() as client:
        col = client['tlbb']['character']
        docs = list(col.find({'attrib.guid': guid}))
        if len(docs) != 1:
            sys.exit('expected one character %d, found %d' % (guid, len(docs)))
        doc = docs[0]
        rec = {'cmd': args.cmd, 'guid': guid, 'before': proj(doc)}
        if args.cmd == 'save-original':
            if os.path.exists(args.out):
                sys.exit('original exists, not overwriting: ' + args.out)
            d = dict(doc); d.pop('_id', None)
            os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
            with open(args.out, 'x', encoding='utf-8') as f:
                json.dump({'guid': guid, 'full_doc': d, 'restore_values': {k: get(doc, k) for k in RESTORE_KEYS}}, f, ensure_ascii=False, indent=1, default=str)
            print(json.dumps(rec['before'], ensure_ascii=False, default=str)); return
        if args.cmd in ('set', 'restore'):
            mode = args.online_check
            if mode == 'any':
                c = clients()
                if c:
                    sys.exit('client connected to 15733/15734; refuse: %d' % len(c))
                rec['online_check'] = 'any: 0 connections on 15733/15734'
            else:
                # 'self': chi nhan vat nay. Server khong ghi character.is_online (gamed.lua mark_login_status
                # bi chu thich), nen doc duoc thi dung, khong thi phai noi ro la dua vao khoa cua nguoi goi.
                if doc.get('is_online'):
                    sys.exit('character %d is online; refuse' % guid)
                rec['online_check'] = ('self: is_online=false' if 'is_online' in doc
                                       else 'self: server publishes no per-character online flag, relying on the caller lock')
        if args.cmd == 'set':
            st = json.load(open(args.static, encoding='utf-8'))[str(args.menpai)]
            L = args.xinfa_level
            xinfa = [{'m_nXinFaID': x, 'm_nXinFaLevel': L} for x in st['base_xinfa']]
            skills = list(BASE_SKILLS)
            for s in st['learn_ids']:
                if s not in skills:
                    skills.append(s)
            for extra in (args.extra_skills or '').split(','):
                extra = extra.strip()
                if extra.lstrip('-').isdigit() and int(extra) > 0 and int(extra) not in skills:
                    skills.append(int(extra))
            y = YUANGONG.get(args.menpai)
            if y is not None and y not in skills and any(t['id'] == y for t in st['skills']):
                skills.append(y)
            sets = {'attrib.menpai': args.menpai, 'attrib.reputation': REPUTATION[args.menpai], 'xinfa_list': xinfa, 'skill_list': skills}
            if args.refill_from:
                orig = load_original(args.refill_from, guid)
                sets.update({'attrib.hp': orig['attrib.hp'], 'attrib.mp': orig['attrib.mp'],
                             # bãi quái Vô Lượng Sơn (cảnh 6) — agent khác có thể đã dời nhân vật về Đại Lý
                             'attrib.sceneid': 6, 'attrib.world_pos': {'x': 40.0, 'y': 150.0}})
            # luot do bo sung: nang cap de co du MP cho chieu dat (xem 20-level-patch.py)
            if args.level and args.level > 0:
                sets['attrib.level'] = args.level
            if args.mp and args.mp > 0:
                sets['attrib.mp'] = args.mp
            # bot-pos-seq: dat mau thap SAU --refill-from de do chieu tri lieu (3557 kim cham do kiep, 3558 lieu am hoa minh).
            # Phai > 0: hp = 0 la chet -> server cho ve trang thai hon, phien do vo nghia.
            # Kep theo attrib.hp_max DANG LUU: dat hp > max thi khong con la "mau thap" va server se cat xuong o lan
            # tinh sat thuong dau tien. Kep o day de ghi ro trong file --out thay vi de server im lang sua.
            if args.hp and args.hp > 0:
                hp_max = get(doc, 'attrib.hp_max')
                hp_set = args.hp
                if isinstance(hp_max, int) and hp_max > 0 and hp_set > hp_max:
                    rec['hp_clamped'] = {'asked': args.hp, 'hp_max': hp_max}
                    hp_set = hp_max
                sets['attrib.hp'] = hp_set
            # 17/09: 10 chieu tra ve OR_NOT_ENOUGH_RAGE (-25, define.lua:418) vi bot luon co rage = 0.
            # condition_delplete_core.lua:347 la cho duy nhat tra ma nay. Dat thang attrib.rage nhu hp/mp;
            # kep theo attrib.rage_max DANG LUU vi character:set_rage() cung kep, dat cao hon chi de server im lang cat.
            if args.rage and args.rage > 0:
                rage_max = get(doc, 'attrib.rage_max')
                rage_set = args.rage
                if isinstance(rage_max, int) and rage_max > 0 and rage_set > rage_max:
                    rec['rage_clamped'] = {'asked': args.rage, 'rage_max': rage_max}
                    rage_set = rage_max
                sets['attrib.rage'] = rage_set
            # CYS-MAPS-SECT (17/09): diem xuat phat cua phien bot. Ghi sau --refill-from nen thang gia tri goc.
            if args.scene and args.scene > 0:
                if not (0 < args.pos_x <= 4096 and 0 < args.pos_z <= 4096):
                    sys.exit('--scene can --pos-x/--pos-z trong khoang 0..4096')
                sets['attrib.sceneid'] = args.scene
                sets['attrib.world_pos'] = {'x': float(args.pos_x), 'y': float(args.pos_z)}
            r = col.update_one({'attrib.guid': guid}, {'$set': sets})
            rec.update({'set': sets, 'matched': r.matched_count, 'modified': r.modified_count})
        elif args.cmd == 'refill':
            # hồi HP/MP về giá trị gốc giữa các phiên (kỹ năng dẫn/lặp rút MP, MP lưu qua đăng xuất)
            orig = load_original(args.original, guid)
            sets = {'attrib.hp': orig['attrib.hp'], 'attrib.mp': orig['attrib.mp']}
            r = col.update_one({'attrib.guid': guid}, {'$set': sets})
            rec.update({'set': sets, 'matched': r.matched_count, 'modified': r.modified_count})
        elif args.cmd == 'restore':
            orig = load_original(args.original, guid)
            sets = {k: v for k, v in orig.items() if v is not None}
            r = col.update_one({'attrib.guid': guid}, {'$set': sets})
            rec.update({'set': sets, 'matched': r.matched_count, 'modified': r.modified_count})
        rec['after'] = proj(col.find_one({'attrib.guid': guid}))
        with open(args.out, 'w', encoding='utf-8') as f:
            json.dump(rec, f, ensure_ascii=False, indent=1, default=str)
        print(json.dumps({k: rec[k] for k in rec if k != 'before'}, ensure_ascii=False, default=str)[:1500])


if __name__ == '__main__':
    main()
