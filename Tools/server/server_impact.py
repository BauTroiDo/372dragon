#!/usr/bin/env python3
"""server-impact — kỹ năng CY có tác dụng thật trên SERVER RIÊNG (sau CS3c).

StandardImpact server (tlbb15/HJS, 23.523 dòng) cũ hơn client CY 3.71: SkillData/SkillTemplate/EquipBase CY trỏ tới hàng nghìn impact
không có dòng; 88 logic impact của tlbb15 chưa cài trong skynet GL; skill logic CY chưa cài rơi về skill_0 và bỏ nhãn CY mới;
Lua GL ghi cứng impact GL (ID nay mang nghĩa CY khác). Công cụ này:

  server_impact.py plan   --out <dir>                  dựng configs/StandardImpact.txt + lua/<GameServer…> + plan.json + *.tsv (không chạm R)
  server_impact.py apply  --staging <dir> [--dry-run]  chép vào R (sao lưu từng file R/backups/server-impact-<UTC>/), idempotent
  server_impact.py verify [--staging <dir>] [--out json] GBK/tab/ID, tham chiếu impact 100 % được phân loại, logic đã đăng ký, SE,
                                                        luac5.4 -p, test Lua đơn vị (server_impact_tests.lua), staging = R
  server_impact.py char-skill --out <json> --add <tid,…> | --restore <json>   (Mongo riêng, chỉ khi skynet dừng) thêm/khôi phục skill_list CYTest00

Chạy trong WSL TLBB bằng root (python3 -B). Nguồn chỉ đọc: R tại BASE_REV (76e15ba, trước lượt này), GL 995c2df (bảng trước CS3b),
client CY (Tools/DATA NEW/DataCY31-08-26/Config). Bảng server GBK mức byte. Đặc tả: Docs/specs/server/server-impact_vi.md.

Quy tắc suy ra dòng impact thiếu (ưu tiên từ trên xuống, mỗi dòng ghi nguồn trong plan.json/missing_impacts.tsv):
  R1 series   cùng SkillTemplate + cùng vị trí tham số ở cấp khác có dòng → chép dòng gần nhất; số liệu nội suy tuyến tính theo cấp
              (≥ 2 cấp có), 参数值/修正步长 lấy đúng {A:x B:y} trong tip SkillData khi dòng mẫu khớp A của cấp mẫu.
  R2 gl       dòng GL (995c2df) cùng ID và có bằng chứng: A trong tip = một 参数值 của dòng GL, hoặc tên dòng GL chứa tên kỹ năng.
  R3 tip      tip SkillData có "…攻击增加{A:x B:y}" → dòng logic 3 (khuôn dòng HJS logic 3 bảy tham số) ở ô impact đầu;
              "…定身/昏迷/…N秒" → dòng logic 14 (khuôn dòng HJS cùng loại khống chế) ở ô impact tiếp theo, thời gian = N s.
  còn lại     không suy ra (ghi lý do) — không bịa.
"""
import argparse
import collections
import datetime
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table_bytes, read_table, write_table, g, sha, provision, clients, GUID  # noqa: E402

R = '/home/ubuntu/cys-test-20260913'
BASE_REV = '76e15ba'          # server riêng trước server-impact (sau CS3a2)
GL_REV = '995c2df'            # bảng GL trước CS3b (dòng GL cùng ID; hằng Lua GL)
CY_DIR = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Config'
LUA_SRC = os.path.join(HERE, 'server_impact_lua')
TESTS = os.path.join(HERE, 'server_impact_tests.lua')
SI = 'configs/StandardImpact.txt'
GS = 'GameServer'
GL_REMAP_BASE = 63000         # ID dải riêng (< 65536) cho dòng GL mà Lua GL ghi cứng; bỏ qua ID đã có/đã được tham chiếu
MARK = 'server-impact'

# --- nhãn tham số SkillData
IMPACT_WORDS = ('效果', 'buff', 'BUFF', 'Buff')
EXCLUDE_WORDS = ('几率', '概率', '集合', '陷阱', '次数', '数目', '上限', '半径', '时间', '距离', '类型', '百分', '%', '权重', '层数', '脚本',
                 '冷却', '范围', '说明', '宽度', '步长', '技能ID', '阈值', '倍率', '系数')
SELF_WORDS = ('自己', '自身', '给自己', '对自己', '激活', '变身', '霸体', '免控', '无敌', '护盾', '治疗')
ATTR_WORD = {'外功攻击': '物理攻击+', '内功攻击': '魔法攻击+', '冰攻击': '冰系攻击', '火攻击': '火系攻击', '玄攻击': '电系攻击', '毒攻击': '毒系攻击',
             '冰系攻击': '冰系攻击', '火系攻击': '火系攻击', '玄系攻击': '电系攻击', '毒系攻击': '毒系攻击'}
DAMAGE_LABELS = ['物理攻击+', '魔法攻击+', '冰系攻击', '火系攻击', '电系攻击', '毒系攻击', '伤害数值']
CONTROL_WORDS = ('定身', '昏迷', '眩晕', '封穴', '麻痹', '沉默', '封印', '减速', '失明', '散功', '昏睡', '击倒')
COLOR_RE = re.compile(r'#c[0-9A-Fa-f]{6}|#[rRWGYBnbe]')

# --- logic impact mới / bí danh (Lua trong server_impact_lua). None = null_logic_buff (dòng không tham số, chỉ hiện buff)
NEW_LOGICS = {
    2: 'std_impact_002', 67: 'std_impact_067', 16: 'std_impact_016', 43: 'std_impact_043', 91: 'std_impact_091', 109: 'std_impact_091',
    114: 'std_impact_114', 122: 'std_impact_114', 145: 'std_impact_114', 162: 'std_impact_114',
    149: 'std_impact_149', 150: 'std_impact_149', 116: 'std_impact_149', 157: 'std_impact_149',
    170: 'std_impact_170', 156: 'std_impact_170', 187: 'std_impact_170', 110: 'std_impact_170',
    76: 'std_impact_076', 113: 'std_impact_113', 130: 'std_impact_130',
    175: 'std_impact_015', 176: 'std_impact_015', 185: 'std_impact_009',
    98: 'std_impact_098', 101: 'std_impact_101', 102: 'std_impact_102', 103: 'std_impact_103',
    155: 'std_impact_155', 169: 'std_impact_169',
    97: None, 51: None, 87: None,
}
LOGIC_NOTES = {
    2: 'mới: % máu tối đa, sát thương trực tiếp', 67: 'mới: xác suất, % máu hiện tại, tối thiểu', 16: 'mới: % STR/Con/SPR/INT/DEX',
    43: 'mới: kháng 4 hệ + hệ số nộ', 91: 'mới: % công ngoại/nội', 109: 'dùng std_impact_091 (物理/魔法攻击修正率, MAX_HP修正率)',
    114: 'mới: tỉ lệ trúng/né/hội tâm (%)', 122: 'dùng std_impact_114 (闪避修正)', 145: 'dùng std_impact_114 (% 4 chỉ số)',
    162: 'dùng std_impact_114 (% 4 chỉ số + 给目标的效果)', 149: 'mới: 基础伤害增强 (các nhãn khác chưa rõ đơn vị [SL])',
    150: 'dùng std_impact_149 (% theo hệ)', 116: 'dùng std_impact_149 (máu thấp)', 157: 'dùng std_impact_149 (dòng 157 mang nhãn 149)',
    170: 'mới: miễn % + phản đòn', 156: 'dùng std_impact_170 (免疫率)', 187: 'dùng std_impact_170 (免疫率; 回复/附加 chưa)',
    110: 'dùng std_impact_170 (miễn % sát thương từ trân thú)', 76: 'mới: sát thương cộng khi trúng impact thuộc tập',
    113: 'mới: khiên máu', 130: 'mới: giới hạn dưới giảm kháng', 175: 'bí danh std_impact_015 (nhãn trùng 100 %)',
    176: 'bí danh std_impact_015 (nhãn trùng 100 %)', 185: 'bí danh std_impact_009 (瞬移, nhãn trùng 100 %)',
    97: 'buff rỗng (坐骑 tlbb15 không tham số)', 51: 'buff rỗng (分身 không tham số)', 87: 'buff rỗng (搭乘坐骑 không tham số)',
    98: 'mới: khiên nhóm 慈航普度 giảm sát thương cho chủ/đồng minh trong bán kính (RE Serverhook)',
    101: 'mới: 怒火连斩 đếm đao + phát 加速BUFF, đạt ngưỡng tăng sát thương (RE main Server)',
    102: 'mới: 一日丧命散 AOE khi kích hoạt/tan (激活/消散/死亡效果) (RE main Server)',
    103: 'mới: 横扫AOE mỗi nhịp quét địch gửi子效果1/2/3 (RE main Server)',
    155: 'mới: 魂离魄散 quét địch gửi impact khi kích hoạt/chết (RE Serverhook)',
    169: 'mới: 拘魂·命/金刚不坏 hồi máu-khí theo千分比 mỗi nhịp + 免疫率 (RE Serverhook)',
}
LUA_NEW_FILES = ['services/scene/skill/impact_logic/cy_impact_util.lua'] + \
    ['services/scene/skill/impact_logic/%s.lua' % m for m in sorted({v for v in NEW_LOGICS.values() if v and v not in ('std_impact_015', 'std_impact_009')})] + \
    ['services/scene/skill/human/skill_cy_generic.lua']
KNOWN_LABELS_FILE = 'services/scene/skill/human/skill_cy_generic_known.lua'
REMAP_FILE = 'lualib/cys_gl_impact_remap.lua'

# SkillTemplate (R, bố cục GL)
ST_MENPAI, ST_NAME, ST_XLIMIT, ST_WEAPON, ST_XINFA, ST_PET_IMPACT, ST_STAND, ST_TARGET_LOGIC = 2, 3, 5, 7, 11, 30, 42, 38
ST_LEVELS = list(range(58, 74))
SD_TIP, SD_LOGIC, SD_PARAM0 = 3, 5, 24
EQUIP_IMPACT_COL = 19


def git_show(rev, rel):
    return subprocess.run(['git', '-C', R, 'show', '%s:%s' % (rev, rel)], capture_output=True, check=True).stdout


def ival(b):
    try:
        return int(b)
    except (ValueError, TypeError):
        return None


def fval(b):
    try:
        return float(b)
    except (ValueError, TypeError):
        return None


def has_any(s, words):
    return any(w in s for w in words)


def is_impact_label(d):
    return bool(d) and has_any(d, IMPACT_WORDS) and not has_any(d, EXCLUDE_WORDS)


def clean_tip(b):
    return COLOR_RE.sub('', g(b).replace('#r', '。'))     # #r = xuống dòng trong tip → ranh giới mệnh đề


def tip_ab(tip):
    """[(A, B, cửa sổ chữ trước)] theo thứ tự trong tip"""
    out = []
    for m in re.finditer(r'\{A:\s*(-?[\d.]+)\s*B:\s*(-?[\d.]+)\}', tip):
        out.append((float(m.group(1)), float(m.group(2)), tip[max(0, m.start() - 18):m.start()]))
    return out


def tip_damage(tip):
    """(nhãn tham số logic 3, A, B) đầu tiên có thuộc tính rõ ràng; None nếu tip là hồi máu/không rõ"""
    for a, b, win in tip_ab(tip):
        if has_any(win, ('治疗', '回复', '恢复', '护盾', '吸收', '血上限', '防御')):
            continue
        hits = [(win.rfind(w), lab) for w, lab in ATTR_WORD.items() if w in win]
        if hits:
            return max(hits)[1], a, b
        if '伤害' in win:
            return '伤害数值', a, b
    return None


def tip_control(tip):
    m = re.search(r'(%s)[^。；，,#{}]{0,10}?(\d+(?:\.\d+)?)\s*秒' % '|'.join(CONTROL_WORDS), tip)
    if m:
        return m.group(1), float(m.group(2))
    m = re.search(r'(\d+(?:\.\d+)?)\s*秒[^。；]{0,6}?(%s)' % '|'.join(CONTROL_WORDS), tip)
    if m:
        return m.group(2), float(m.group(1))
    return None


# thuộc tính buff/debuff (từ khoá tip → logic, nhãn StandardImpact); dài trước ngắn
ATTR_BUFF = [
    ('内外功防御', 11, ['物理防御+', '魔法防御+']), ('内外防', 11, ['物理防御+', '魔法防御+']),
    ('内功攻击', 11, ['魔法攻击+']), ('外功攻击', 11, ['物理攻击+']), ('内功防御', 11, ['魔法防御+']), ('外功防御', 11, ['物理防御+']),
    ('生命值', 11, ['MAX_HP修正']), ('血上限', 11, ['MAX_HP修正']), ('气上限', 11, ['MAX_MP修正']),
    ('冰抗', 11, ['冰系抗性修正']), ('火抗', 11, ['火系抗性修正']), ('玄抗', 11, ['电系抗性修正']), ('毒抗', 11, ['毒系抗性修正']),
    ('会心防御', 13, ['会心防御+']), ('会心攻击', 13, ['会心攻击+']), ('命中', 13, ['命中+']), ('闪避', 13, ['闪避+']),
    ('所有属性', 15, ['STR修正(0为无效)', 'Con修正(0为无效)', 'SPR修正(0为无效)', 'INT修正(0为无效)', 'DEX修正(0为无效)']),
    ('体力', 15, ['Con修正(0为无效)']), ('定力', 15, ['SPR修正(0为无效)']), ('力量', 15, ['STR修正(0为无效)']),
    ('灵气', 15, ['INT修正(0为无效)']), ('身法', 15, ['DEX修正(0为无效)']),
    ('移动速度', 14, ['移动速度修正%（0为无效）']),
]
DUR_RE = re.compile(r'持续\s*(\d+(?:\.\d+)?)\s*(秒|分钟)')
AB_RE = re.compile(r'\{A:\s*(-?[\d.]+)\s*B:\s*(-?[\d.]+)\}')


def tip_effects(tip, hostile=True):
    """Hiệu ứng theo thứ tự trong tip: {'kind': damage|attr|control, 'pos', …}. attr/control cần 持续N秒/分钟 trong mệnh đề
    hoặc 2 mệnh đề sau; sát thương = {A} sau từ công/伤害 mà KHÔNG có thời lượng (không phải buff)."""
    tip = tip.replace('（拖至快捷栏中使用）', '')
    parts, pos = [], 0
    for m in re.finditer(r'[，,。；;]', tip + '。'):
        parts.append((pos, tip[pos:m.start()]))
        pos = m.end()
    out = []

    def duration(i):
        for j in range(i, min(i + 3, len(parts))):
            d = DUR_RE.search(parts[j][1])
            if d:
                return float(d.group(1)) * (60 if d.group(2) == '分钟' else 1), j == i
            if j > i and AB_RE.search(parts[j][1]):
                break
        return None, False
    for i, (off, c) in enumerate(parts):
        dur, dur_here = duration(i)
        ab = AB_RE.search(c)
        if ab and float(ab.group(1)) == 0 and float(ab.group(2)) == 0:
            ab = None                                     # {A:0 B:0}: tip rỗng số liệu
        attack_word = any(w in c for w in ATTR_WORD)
        if hostile and ab and attack_word and not dur_here and not has_any(c, ('队友', '自身', '自己', '强化', '状态', '增益')):
            dur = None                                    # kỹ năng tấn công: 攻击增加{A} là sát thương; 持续N秒 thuộc mệnh đề sau
        ctl = next((w for w in CONTROL_WORDS if w in c), None)
        sign = -1 if re.search('降低|减少|下降', c) else (1 if re.search('增加|提高|提升', c) else 0)
        attrs = []
        rest = c
        first_kw = None
        for kw, lg, labs in ATTR_BUFF:
            if kw in rest:
                attrs.append((kw, lg, labs))
                first_kw = c.find(kw) if first_kw is None else min(first_kw, c.find(kw))
                rest = rest.replace(kw, '')
        if dur is not None and sign and attrs:
            a, b = None, 0.0
            tail = c[first_kw:]
            if attrs[0][1] == 14:
                m = re.search(r'(\d+(?:\.\d+)?)\s*%', tail)
                a = float(m.group(1)) if m else None
            elif ab and ab.start() >= first_kw:
                a, b = float(ab.group(1)), float(ab.group(2))
            else:
                m = re.search(r'(\d+(?:\.\d+)?)\s*点', tail)
                a = float(m.group(1)) if m else None
            if a is not None and len({x[1] for x in attrs}) == 1:
                out.append({'kind': 'attr', 'pos': off, 'logic': attrs[0][1], 'labels': [l for x in attrs for l in x[2]], 'a': sign * a, 'b': sign * b,
                            'sec': dur, 'text': c[:40]})
                continue
        if ctl and not ab and not has_any(c, ('解除', '免疫', '驱散', '净化', '清除', '抵抗')):
            m = re.search(r'(\d+(?:\.\d+)?)\s*秒', c)
            sec = dur if dur is not None else (float(m.group(1)) if m else None)
            out.append({'kind': 'control', 'pos': off, 'word': ctl, 'sec': sec, 'text': c[:40]})
            continue
        if ab and dur is None:
            win = c[:ab.start()]
            if has_any(win, ('治疗', '回复', '恢复', '护盾', '吸收', '血上限', '防御', '几率')):
                continue
            hits = [(win.rfind(w), lab) for w, lab in ATTR_WORD.items() if w in win]
            lab = max(hits)[1] if hits else ('伤害数值' if '伤害' in win or '伤害' in c else None)
            if lab:
                out.append({'kind': 'damage', 'pos': off, 'label': lab, 'a': float(ab.group(1)), 'b': float(ab.group(2)), 'text': c[:40]})
    return out


def fmt_ab(x):
    return str(int(x)).encode() if float(x).is_integer() else ('%.6f' % x).rstrip('0').rstrip('.').encode()


def fmt_num(x, like):
    """giữ kiểu ô gốc: số nguyên nếu ô mẫu là số nguyên"""
    if re.fullmatch(rb'-?\d+', like.strip() or b'0'):
        return str(int(round(x))).encode()
    s = ('%.6f' % x).rstrip('0').rstrip('.')
    return s.encode()


# ---------------------------------------------------------------- nguồn
class Src:
    def __init__(self):
        self.si = read_table_bytes(git_show(BASE_REV, SI))
        self.si_by = {int(r[0]): r for r in self.si['rows']}
        self.gl_si = {int(r[0]): r for r in read_table_bytes(git_show(GL_REV, SI))['rows']}
        self.sd = read_table_bytes(git_show(BASE_REV, 'configs/SkillData_V1.txt'))
        self.sd_by = {int(r[0]): r for r in self.sd['rows']}
        self.st = read_table_bytes(git_show(BASE_REV, 'configs/SkillTemplate_V1.txt'))
        self.st_by = {int(r[0]): r for r in self.st['rows']}
        self.eb = read_table_bytes(git_show(BASE_REV, 'configs/EquipBase.txt'))
        self.se_cy = {int(r[0]): r for r in read_table(os.path.join(CY_DIR, 'ImpactSEData_V1.txt'))['rows']}
        self.lua = {}
        pd = [i for i, n in enumerate(self.sd['names']) if g(n) == '参数说明']
        assert pd and pd[0] == SD_PARAM0, pd[:2]
        self.param_pos = pd
        # SkillData → (template, cấp)
        self.data_levels = collections.defaultdict(list)
        for r in self.st['rows']:
            for k, c in enumerate(ST_LEVELS):
                v = ival(r[c]) if c < len(r) else None
                if v is not None and v >= 0:
                    self.data_levels[v].append((int(r[0]), k + 1))

    def lua_base(self, rel):
        if rel not in self.lua:
            self.lua[rel] = git_show(BASE_REV, GS + '/' + rel).decode('utf-8')
        return self.lua[rel]


def known_labels(src):
    txt = src.lua_base('lualib/cfghelper.lua')
    a = txt.index('function cfghelper:read_skill_data()')
    b = txt.index('\nfunction cfghelper:', a + 10)
    body = txt[a:b]
    labels = set(re.findall(r'desc == "([^"]*)"', body))
    for fmt in re.findall(r'string\.format\("([^"]*%d[^"]*)", idx\)', body):     # vòng for idx = 0..11 trong read_skill_data
        for i in range(0, 12):
            labels.add(fmt.replace('%d', str(i)))
    return labels


# ---------------------------------------------------------------- tham chiếu
def collect_refs(src):
    """[(nguồn, id_nguồn, vị trí, nhãn, impact_id)]"""
    refs = []
    for r in src.sd['rows']:
        sid = int(r[0])
        for p in src.param_pos:
            if p + 1 >= len(r):
                continue
            d = g(r[p]).strip()
            v = ival(r[p + 1])
            if v is None or v < 0 or not is_impact_label(d):
                continue
            refs.append(('SkillData', sid, p, d, v))
    for r in src.st['rows']:
        v = ival(r[ST_PET_IMPACT]) if ST_PET_IMPACT < len(r) else None
        if v is not None and v > 0:
            refs.append(('SkillTemplate.珍兽技能产生的效果ID', int(r[0]), ST_PET_IMPACT, '珍兽技能产生的效果ID', v))
    for r in src.eb['rows']:
        v = ival(r[EQUIP_IMPACT_COL]) if EQUIP_IMPACT_COL < len(r) else None
        if v is not None and v >= 0:
            refs.append(('EquipBase.19', int(r[0]), EQUIP_IMPACT_COL, 'EquipBase.19', v))
    return refs


def template_info(src, sid):
    lv = src.data_levels.get(sid)
    if not lv:
        return None
    tid, k = min(lv, key=lambda x: (x[1], x[0]))
    t = src.st_by[tid]
    return {'tid': tid, 'level': k, 'menpai': ival(t[ST_MENPAI]), 'name': t[ST_NAME], 'xlimit': ival(t[ST_XLIMIT]),
            'stand': ival(t[ST_STAND]), 'weapon': ival(t[ST_WEAPON])}


def priority(ti):
    if not ti:
        return 'P3'
    if ti['menpai'] is not None and 0 <= ti['menpai'] <= 15 and ti['menpai'] != 9:
        return 'P1' if ti['level'] <= 4 else 'P2'
    return 'P3'


# ---------------------------------------------------------------- suy ra dòng
class Deriver:
    def __init__(self, src, plan):
        self.src, self.plan = src, plan
        self.n = len(src.si['types'])
        self.new = {}          # id → (row, nguồn, ghi chú)
        self.damage_donor = self.find_damage_donor()
        self.control_donor = self.find_control_donors()

    def row(self, iid):
        if iid in self.src.si_by:
            return self.src.si_by[iid]
        if iid in self.new:
            return self.new[iid][0]
        return None

    def find_damage_donor(self):
        for iid in sorted(self.src.si_by):
            r = self.src.si_by[iid]
            if r[2] == b'3' and [g(r[27 + 3 * k]).strip() for k in range(7)] == DAMAGE_LABELS and ival(r[5]) is not None:
                return iid
        raise SystemExit('không tìm được dòng logic 3 mẫu')

    def find_control_donors(self):
        refc = collections.Counter()
        for r in self.src.sd['rows']:
            for p in self.src.param_pos:
                if p + 1 < len(r):
                    v = ival(r[p + 1])
                    if v is not None and v in self.src.si_by:
                        refc[v] += 1
        out = {}
        for w in CONTROL_WORDS:
            cands = []
            for iid, r in self.src.si_by.items():
                nm = g(r[1])
                if r[2] != b'14' or w not in nm or r[4] != b'1':
                    continue
                if sum(1 for x in CONTROL_WORDS if x in nm) != 1 or has_any(nm, ('无敌', '免疫', '解除', '沉默', '+', '＋')):
                    continue
                se = ival(r[5])
                cands.append((0 if se in self.src.se_cy else 1, -refc[iid], iid))
            if cands:
                out[w] = min(cands)[2]
        return out

    def pad(self, r):
        return (list(r) + [b''] * self.n)[:self.n]

    # R1
    def series(self, sid, pos, v):
        best = None
        for tid, k in self.src.data_levels.get(sid, ()):
            t = self.src.st_by[tid]
            pts = {}
            for j, c in enumerate(ST_LEVELS):
                o = ival(t[c]) if c < len(t) else None
                if o is None or o < 0 or o not in self.src.sd_by:
                    continue
                orow = self.src.sd_by[o]
                if pos + 1 >= len(orow) or g(orow[pos]).strip() != g(self.src.sd_by[sid][pos]).strip():
                    continue
                ov = ival(orow[pos + 1])
                if ov is not None and ov != v and ov in self.src.si_by:
                    pts[j + 1] = (ov, o)
            if pts:
                cand = (min(abs(j - k) for j in pts), tid, k, pts)
                if best is None or cand[:2] < best[:2]:
                    best = cand
        if not best:
            return None
        _, tid, k, pts = best
        near = sorted(pts, key=lambda j: (abs(j - k), j))
        j1 = near[0]
        donor = self.src.si_by[pts[j1][0]]
        row = self.pad(donor)
        row[0] = str(v).encode()
        notes = ['mẫu %d (cấp %d)' % (pts[j1][0], j1)]
        j2 = next((j for j in near[1:] if j != j1), None)
        cols = [20] + [28 + 3 * m for m in range(16)]
        if j2 is not None:
            d2 = self.src.si_by[pts[j2][0]]
            changed = 0
            for c in cols:
                a, b = fval(donor[c]), fval(d2[c]) if c < len(d2) else None
                if a is None or b is None or a == b:
                    continue
                x = a + (b - a) * (k - j1) / (j2 - j1)
                row[c] = fmt_num(x, donor[c])
                changed += 1
            if changed:
                notes.append('nội suy tuyến tính %d ô theo cấp %d,%d' % (changed, j1, j2))
        # tip A/B chính xác
        tk, tj = tip_ab(clean_tip(self.src.sd_by[sid][SD_TIP])), tip_ab(clean_tip(self.src.sd_by[pts[j1][1]][SD_TIP]))
        if tk and tj and len(tk) == len(tj):
            for m, (aj, bj, _) in enumerate(tj):
                for q in range(16):
                    dv = fval(donor[28 + 3 * q])
                    if dv is not None and dv != 0 and abs(dv - aj) < 0.51:
                        row[28 + 3 * q] = fmt_ab(tk[m][0])
                        row[29 + 3 * q] = fmt_ab(tk[m][1])
                        notes.append('tip A/B → tham số %d' % (q + 1))
                        break
        return row, 'R1-series', '; '.join(notes)

    # R2
    def gl_same_id(self, sid, v, ti):
        r = self.src.gl_si.get(v)
        if r is None or ival(r[2]) is None or int(r[2]) >= 8000:
            return None
        ev = None
        for a, b, _ in tip_ab(clean_tip(self.src.sd_by[sid][SD_TIP])) if sid in self.src.sd_by else []:
            if any(fval(r[28 + 3 * q]) is not None and fval(r[28 + 3 * q]) != 0 and abs(fval(r[28 + 3 * q]) - a) < 0.51 for q in range(16)):
                ev = 'tip A=%s trùng 参数值 dòng GL' % a
                break
        if not ev and ti:
            tn = re.split('[（(·]', g(ti['name']))[0]
            gn = re.split('[（(·]', g(r[1]))[0]
            if len(tn) >= 2 and (tn in g(r[1]) or (len(gn) >= 2 and gn in g(ti['name']))):
                ev = 'tên GL "%s" ↔ kỹ năng "%s"' % (g(r[1]), g(ti['name']))
        if not ev:
            return None
        row = self.pad(r)
        se = ival(row[5])
        if se is not None and se > 0 and se not in self.src.se_cy:
            row[5] = b'-1'
            ev += '; SE GL %d không có ở client CY → -1' % se
        return row, 'R2-gl', ev

    def se_for(self, ti):
        if not ti:
            return b'-1'
        name = re.split('[（(·]', g(ti['name']))[0]
        if len(name) < 2:
            return b'-1'
        for iid in sorted(self.src.se_cy):
            if name in g(self.src.se_cy[iid][16]):
                return str(iid).encode()
        return b'-1'

    # R3
    def row_kind(self, r):
        lg = ival(r[2])
        if lg == 3:
            return 'damage'
        if lg == 14:
            return 'control' if has_any(g(r[1]), CONTROL_WORDS) else 'attr'
        if lg in (11, 12, 13, 15, 16, 43, 91):
            return 'attr'
        return 'other'

    def slot_effects(self, sid):
        """{vị trí tham số: hiệu ứng tip} cho các ô impact CHƯA có dòng của SkillData sid"""
        if not hasattr(self, '_slot_cache'):
            self._slot_cache = {}
        if sid in self._slot_cache:
            return self._slot_cache[sid]
        r = self.src.sd_by[sid]
        ti = template_info(self.src, sid)
        eff = tip_effects(clean_tip(r[SD_TIP]), hostile=ti is None or (ti['stand'] is not None and ti['stand'] < 0))
        slots = [(p, ival(r[p + 1]), g(r[p]).strip()) for p in self.src.param_pos if p + 1 < len(r) and is_impact_label(g(r[p]).strip()) and (ival(r[p + 1]) or -1) >= 0]
        for p, v, d in slots:
            if v in self.src.si_by:
                k = self.row_kind(self.src.si_by[v])
                i = next((i for i, e in enumerate(eff) if e['kind'] == k), None)
                if i is not None:
                    eff.pop(i)
        out = {}
        for p, v, d in slots:
            if v in self.src.si_by:
                continue
            i = next((i for i, e in enumerate(eff) if not (has_any(d, SELF_WORDS) and e['kind'] in ('damage', 'control'))), None)
            if i is not None:
                out[p] = eff.pop(i)
        self._slot_cache[sid] = out
        return out

    def donor_with(self, logic, labels):
        key = (logic, tuple(labels))
        if not hasattr(self, '_donor_cache'):
            self._donor_cache = {}
        if key not in self._donor_cache:
            best = None
            for iid in sorted(self.src.si_by):
                r = self.src.si_by[iid]
                if ival(r[2]) != logic or r[4] != b'1':
                    continue
                labs = [g(r[27 + 3 * k]).strip().strip('"') for k in range(16)]
                if all(l in labs for l in labels):
                    if logic == 14 and has_any(g(r[1]), CONTROL_WORDS):
                        continue
                    best = iid
                    break
            self._donor_cache[key] = best
        return self._donor_cache[key]

    def zero_params(self, row):
        for k in range(16):
            lab = g(row[27 + 3 * k])
            if not lab.strip():
                continue
            row[28 + 3 * k] = b'-1' if ('-1为无效' in lab or row[28 + 3 * k].strip() == b'-1') else b'0'
            row[29 + 3 * k] = b'0'

    def tip_synth(self, sid, pos, v, ti):
        if sid not in self.src.sd_by:
            return None
        e = self.slot_effects(sid).get(pos)
        if not e:
            return None
        name = ti['name'] if ti else self.src.sd_by[sid][2]
        hostile = ti is None or (ti['stand'] is not None and ti['stand'] < 0)
        if e['kind'] == 'damage' and hostile:
            row = self.pad(self.src.si_by[self.damage_donor])
            row[0] = str(v).encode()
            row[1] = name + '（CY推导伤害）'.encode('gbk')
            row[5] = self.se_for(ti)
            for q, dl in enumerate(DAMAGE_LABELS):
                row[28 + 3 * q] = (fmt_ab(e['a']) if dl == e['label'] else (b'' if dl == '伤害数值' else b'0'))
                row[29 + 3 * q] = (fmt_ab(e['b']) if dl == e['label'] else b'0')
            return row, 'R3-tip-damage', 'khuôn %d; %s=%s bước %s; tip "%s"; SE %s' % (self.damage_donor, e['label'], e['a'], e['b'], e['text'], g(row[5]))
        if e['kind'] == 'control' and e['word'] in self.control_donor:
            donor = self.control_donor[e['word']]
            row = self.pad(self.src.si_by[donor])
            row[0] = str(v).encode()
            row[1] = name + ('（CY推导%s）' % e['word']).encode('gbk')
            note = 'khuôn %d (%s); tip "%s"' % (donor, g(self.src.si_by[donor][1]), e['text'])
            if e['sec']:
                row[20] = str(int(round(e['sec'] * 1000))).encode()
                note += '; %s giây' % e['sec']
            else:
                note += '; tip không ghi thời lượng → giữ thời lượng dòng mẫu %s ms [SL]' % g(row[20])
            return row, 'R3-tip-control', note
        if e['kind'] == 'attr':
            donor = self.donor_with(e['logic'], e['labels'])
            if donor is None:
                return None
            row = self.pad(self.src.si_by[donor])
            self.zero_params(row)
            row[0] = str(v).encode()
            row[1] = name + '（CY推导属性）'.encode('gbk')
            row[5] = self.se_for(ti)
            row[20] = str(int(round(e['sec'] * 1000))).encode()
            for k in range(16):
                if g(row[27 + 3 * k]).strip().strip('"') in e['labels']:
                    row[28 + 3 * k] = fmt_ab(e['a'])
                    row[29 + 3 * k] = fmt_ab(e['b'])
            return row, 'R3-tip-attr', 'khuôn %d (logic %d); %s=%s bước %s, %s giây; tip "%s"; SE %s' % (
                donor, e['logic'], '/'.join(e['labels']), e['a'], e['b'], e['sec'], e['text'], g(row[5]))
        return None


def derive_all(src, plan, refs):
    der = Deriver(src, plan)
    der.ref_ids = {v for *_, v in refs}
    missing = collections.OrderedDict()
    for kind, oid, pos, d, v in refs:
        if v in src.si_by:
            continue
        missing.setdefault(v, []).append((kind, oid, pos, d))
    order = sorted(missing, key=lambda v: (min(priority(template_info(src, o)) if k == 'SkillData' else 'P3' for k, o, _, _ in missing[v]), v))
    rows_out = []
    for v in order:
        res, why = None, []
        for kind, oid, pos, d in missing[v]:
            if kind != 'SkillData':
                continue
            ti = template_info(src, oid)
            for fn in (lambda: der.series(oid, pos, v), lambda: der.gl_same_id(oid, v, ti), lambda: der.tip_synth(oid, pos, v, ti)):
                res = fn()
                if res:
                    break
            if res:
                break
        if not res:
            kinds = collections.Counter(k for k, _, _, _ in missing[v])
            if kinds.get('SkillData'):
                sid = next(o for k, o, _, _ in missing[v] if k == 'SkillData')
                tip = clean_tip(src.sd_by[sid][SD_TIP])
                why = 'không có cấp khác/dòng GL có bằng chứng; tip %s' % ('không có hiệu ứng số liệu rõ (công/thuộc tính+thời lượng/khống chế)' if not tip_effects(tip) else 'có hiệu ứng nhưng không ghép được với ô này (ô đã có dòng cùng loại / ô tự thân / thiếu dòng khuôn)')
            else:
                why = 'chỉ tham chiếu từ %s (không có ngữ cảnh kỹ năng)' % ','.join(kinds)
            der.plan['unresolved'][v] = why
            continue
        row, source, note = res
        der.new[v] = (row, source, note)
    return der, missing


# ---------------------------------------------------------------- Lua
def patch_once(text, old, new, what):
    """thay đúng 1 lần; chịu file CRLF (cfghelper.lua) — neo viết bằng LF"""
    if text.count(old) == 1:
        return text.replace(old, new)
    o2, n2 = old.replace('\n', '\r\n'), new.replace('\n', '\r\n')
    if text.count(o2) == 1:
        return text.replace(o2, n2)
    raise SystemExit('neo Lua không khớp đúng 1 lần: %s (LF %d, CRLF %d)' % (what, text.count(old), text.count(o2)))


def lua_edits(src, plan):
    files = {}
    # 1. đăng ký logic mới trong impactenginer
    rel = 'lualib/impactenginer.lua'
    t = src.lua_base(rel)
    anchor = '    [549] = "scene.skill.impact_logic.std_impact_549",\n'
    add = ''.join('    [%d] = "scene.skill.impact_logic.%s", -- %s: %s\n' % (lg, NEW_LOGICS[lg] or 'null_logic_buff', MARK, LOGIC_NOTES[lg]) for lg in sorted(NEW_LOGICS))
    t = patch_once(t, anchor, anchor + add, 'impactenginer anchor')
    old_fb = '''            else
                self.logics[logic_id] = std_impact_003.new()
            end'''
    new_fb = '''            elseif type(logic_id_2_conf[logic_id]) == "table" and timed_only[logic_id] then
                -- %s: logic tlbb15 chưa cài mà mọi dòng là hiệu ứng duy trì → buff rỗng (trước: std_impact_003.on_active gọi on_damages với sát thương 0)
                self.logics[logic_id] = require("scene.skill.impact_logic.null_logic_buff").new()
            else
                self.logics[logic_id] = std_impact_003.new()
            end''' % MARK
    t = patch_once(t, old_fb, new_fb, 'impactenginer fallback')
    old_loop = '''    local logic_id_2_conf = {}
    for _, c in pairs(self.std_impact_config) do
        if c.logic_id then
            logic_id_2_conf[c.logic_id] = c
        end
    end'''
    new_loop = '''    local logic_id_2_conf = {}
    local timed_only = {} -- %s
    for _, c in pairs(self.std_impact_config) do
        if c.logic_id then
            logic_id_2_conf[c.logic_id] = c
            if timed_only[c.logic_id] == nil then timed_only[c.logic_id] = true end
            if not c.is_over_timed then timed_only[c.logic_id] = false end
        end
    end''' % MARK
    t = patch_once(t, old_loop, new_loop, 'impactenginer loop')
    files[rel] = t
    # 2. cfghelper: cặp nhãn/giá trị thô
    rel = 'lualib/cfghelper.lua'
    t = src.lua_base(rel)
    old = '''        local impact_desc = conf["参数说明"]
        local impact_values = conf["参数值"]
'''
    new = old + '''        t.cy_raw_params = {} -- %s: cặp (nhãn, DataIndex) thô cho scene.skill.human.skill_cy_generic
        for i, desc in ipairs(impact_desc) do
            local v = tonumber(impact_values[i])
            if type(desc) == "string" and desc ~= "" and v then
                t.cy_raw_params[#t.cy_raw_params + 1] = {desc, v}
            end
        end
''' % MARK
    files[rel] = patch_once(t, old, new, 'cfghelper anchor')
    # 3. skillinfo
    rel = 'lualib/skillinfo.lua'
    t = src.lua_base(rel)
    old = '    self.impacts = table.clone(data.impacts)\n'
    files[rel] = patch_once(t, old, old + '    self.cy_raw_params = data.cy_raw_params -- %s (chỉ đọc)\n' % MARK, 'skillinfo anchor')
    # 4. skillenginer: logic chưa cài → skill_cy_generic
    rel = 'lualib/skillenginer.lua'
    t = src.lua_base(rel)
    old = '''            else
                self.skill_logics[skill.logic_id] = default_skill.new()
            end'''
    new = '''            else
                -- %s: skill_0 + nhãn impact CY mà cfghelper không nhận
                self.skill_logics[skill.logic_id] = require("scene.skill.human.skill_cy_generic").new()
            end''' % MARK
    files[rel] = patch_once(t, old, new, 'skillenginer anchor')
    # 5. nhãn cfghelper đã xử lý
    labels = sorted(known_labels(src))
    body = '-- SINH MÁY bởi Tools/server/server_impact.py từ lualib/cfghelper.lua (read_skill_data) — đừng sửa tay.\nreturn {\n'
    body += ''.join('    [%s] = true,\n' % json.dumps(l, ensure_ascii=False) for l in labels) + '}\n'
    files[KNOWN_LABELS_FILE] = body
    plan['lua_known_labels'] = len(labels)
    # 6. file mới
    for rel in LUA_NEW_FILES:
        files[rel] = open(os.path.join(LUA_SRC, GS, rel), encoding='utf-8').read()
    return files


LITERAL_PATTERNS = [
    re.compile(r'(send_impact_to_unit\(\s*[^,()]+,\s*)(\d{2,6})\b'),
    re.compile(r'(init_impact_from_data\(\s*)(\d{2,6})\b'),
    re.compile(r'((?:IMPACT|DATA_INDEX|BUFF)[A-Z_0-9]*\s*=\s*)(\d{3,6})\b'),
    re.compile(r'(impact_get_first_impact_of_specific_data_index(?:_2)?\(\s*)(\d{3,6})'),
    re.compile(r'((?:impact_id|data_index|buff_id|imp_id)\s*=\s*)(\d{3,6})\b'),
]
LIST_PATTERN = re.compile(r'(IMPACT_IDS\s*=\s*\{)([\d,\s]+)(\})')


def same_meaning(gl_row, si_row):
    if gl_row is None or si_row is None:
        return False
    a, b = g(gl_row[1]), g(si_row[1])
    if a == b:
        return True
    core = lambda s: re.split('[（(·]', s)[0]
    return gl_row[2] == si_row[2] and len(core(a)) >= 2 and (b.startswith(core(a)) or a.startswith(core(b)))


def lua_consts(src, plan, files, der):
    """Hằng impact GL trong Lua: cùng nghĩa ở CY → giữ; khác nghĩa/không có → chép dòng GL sang ID+100000 và đổi hằng."""
    remap, log = {}, []
    used = set(src.si_by) | set(der.new) | set(der.ref_ids)
    nxt = [GL_REMAP_BASE]

    def alloc():
        while nxt[0] in used:
            nxt[0] += 1
        used.add(nxt[0])
        return nxt[0]
    ls = subprocess.run(['git', '-C', R, 'ls-tree', '-r', '--name-only', BASE_REV, GS + '/services', GS + '/lualib'], capture_output=True, text=True, check=True).stdout.split()
    for path in ls:
        if not path.endswith('.lua') or '/cy_four_combat/' in path:
            continue
        rel = path[len(GS) + 1:]
        text = files.get(rel) if rel in files else None
        base_text = text if text is not None else src.lua_base(rel)
        lines = base_text.split('\n')
        changed = False
        for i, line in enumerate(lines):
            if line.strip().startswith('--'):
                continue
            ids = []
            for pt in LITERAL_PATTERNS:
                ids += [(m.start(2), m.end(2), int(m.group(2))) for m in pt.finditer(line)]
            m = LIST_PATTERN.search(line)
            if m:
                off = m.start(2)
                ids += [(off + mm.start(), off + mm.end(), int(mm.group())) for mm in re.finditer(r'\d+', m.group(2))]
            if not ids:
                continue
            new_line = line
            for s, e, v in sorted(set(ids), reverse=True):
                glr, sir = src.gl_si.get(v), src.si_by.get(v)
                if glr is None or same_meaning(glr, sir):
                    status = 'same' if glr is not None else ('cy_only' if sir is not None else 'none')
                    log.append({'file': rel, 'line': i + 1, 'id': v, 'status': status, 'gl': g(glr[1]) if glr else None, 'cy': g(sir[1]) if sir else None})
                    continue
                if ival(glr[2]) is not None and int(glr[2]) >= 8000:
                    log.append({'file': rel, 'line': i + 1, 'id': v, 'status': 'gl_bridge_skip', 'gl': g(glr[1])})
                    continue
                if v not in remap:
                    remap[v] = alloc()
                nid = remap[v]
                new_line = new_line[:s] + str(nid) + new_line[e:]
                log.append({'file': rel, 'line': i + 1, 'id': v, 'new_id': nid, 'status': 'changed' if sir is not None else 'gl_only', 'gl': g(glr[1]), 'cy': g(sir[1]) if sir else None})
            if new_line != line:
                cr = '\r' if new_line.endswith('\r') else ''
                lines[i] = new_line.rstrip('\r') + ' -- %s: ID impact GL → dải riêng (xem %s)' % (MARK, REMAP_FILE) + cr
                changed = True
        if changed:
            files[rel] = '\n'.join(lines)
    for v, nid in sorted(remap.items()):
        glr = src.gl_si[v]
        row = der.pad(glr)
        row[0] = str(nid).encode()
        se = ival(row[5])
        note = 'hằng Lua GL %d (%s)' % (v, g(glr[1]))
        if se is not None and se > 0 and se not in src.se_cy:
            row[5] = b'-1'
            note += '; SE GL %d không có ở client CY → -1' % se
        assert nid not in src.si_by and nid not in der.new, nid
        der.new[nid] = (row, 'GL-remap', note)
    body = '-- SINH MÁY bởi Tools/server/server_impact.py: ID impact GL ghi cứng trong Lua → ID dải riêng (dòng GL chép sang StandardImpact).\n'
    body += '-- ID gốc mang nghĩa khác (hoặc không có) trong StandardImpact CY. Tra cứu: require("cys_gl_impact_remap")[id_gl].\nreturn {\n'
    body += ''.join('    [%d] = %d, -- %s\n' % (v, nid, g(src.gl_si[v][1])) for v, nid in sorted(remap.items())) + '}\n'
    files[REMAP_FILE] = body
    plan['lua_consts'] = {'counts': dict(collections.Counter(x['status'] for x in log)), 'remapped': len(remap), 'items': log}


# ---------------------------------------------------------------- plan / apply / verify
def cmd_plan(args):
    st = os.path.abspath(args.out)
    if os.path.exists(os.path.join(st, 'plan.json')):
        if '/Build/Logs/' not in st:
            sys.exit('--out đã có plan.json và không nằm dưới Build/Logs: ' + st)
        shutil.rmtree(st)
    os.makedirs(os.path.join(st, 'configs'), exist_ok=True)
    src = Src()
    plan = {'base_rev': BASE_REV, 'gl_rev': GL_REV, 'unresolved': {}}
    refs = collect_refs(src)
    der, missing = derive_all(src, plan, refs)
    files = lua_edits(src, plan)
    lua_consts(src, plan, files, der)
    # bảng
    rows = [der.pad(r) for r in src.si['rows']] + [r for r, _, _ in der.new.values()]
    rows.sort(key=lambda r: int(r[0]))
    write_table(os.path.join(st, SI), src.si['types'], src.si['names'], rows, src.si['eol'])
    for rel, text in files.items():
        p = os.path.join(st, 'lua', GS, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
    # báo cáo
    ref_ids = collections.defaultdict(list)
    for kind, oid, pos, d, v in refs:
        ref_ids[v].append((kind, oid, d))
    stat = collections.Counter()
    with open(os.path.join(st, 'missing_impacts.tsv'), 'w', encoding='utf-8') as f:
        f.write('impact_id\tuu_tien\tmon_phai\tskill_template\tcap\tten_ky_nang\tskill_data\tnhan\tso_tham_chieu\tnguon_suy_ra\tghi_chu\n')
        for v in sorted(missing, key=lambda x: x):
            lst = missing[v]
            sd = next((o for k, o, _, _ in lst if k == 'SkillData'), None)
            ti = template_info(src, sd) if sd is not None else None
            pr = priority(ti) if sd is not None else 'P3'
            src_tag, note = (der.new[v][1], der.new[v][2]) if v in der.new else ('unresolved', plan['unresolved'].get(v, ''))
            stat[(pr, src_tag)] += 1
            f.write('%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\t%s\t%s\n' % (v, pr, ti['menpai'] if ti else '', ti['tid'] if ti else '', ti['level'] if ti else '',
                                                                 g(ti['name']) if ti else '', sd if sd is not None else '', lst[0][3], len(lst), src_tag, note))
    logic_rows = collections.Counter(ival(r[2]) for r in rows)
    installed = installed_logics(files)
    missing_logic = {lg: n for lg, n in logic_rows.items() if lg is not None and lg < 8000 and lg not in installed}
    plan['summary'] = {
        'refs_total': len(refs), 'refs_present_before': sum(1 for *_, v in refs if v in src.si_by),
        'missing_ids_before': len(missing), 'missing_refs_before': sum(len(x) for x in missing.values()),
        'missing_by_source': dict(collections.Counter(k for x in missing.values() for k, _, _, _ in x)),
        'derived': dict(collections.Counter(s for _, s, _ in der.new.values())),
        'refs_present_after': sum(1 for *_, v in refs if v in src.si_by or v in der.new),
        'by_priority_and_rule': {'%s/%s' % k: n for k, n in sorted(stat.items())},
        'rows_before': len(src.si['rows']), 'rows_after': len(rows),
        'logics_missing_before': len({lg for lg in (ival(r[2]) for r in src.si['rows']) if lg is not None and lg < 8000 and lg not in installed_logics({})}),
        'logic_rows_missing_before': sum(1 for r in src.si['rows'] if ival(r[2]) is not None and ival(r[2]) < 8000 and ival(r[2]) not in installed_logics({})),
        'logics_missing_after_explicit': len(missing_logic), 'logics_missing_after_rows': sum(missing_logic.values()),
    }
    plan['logics'] = {str(lg): {'module': NEW_LOGICS[lg] or 'null_logic_buff', 'note': LOGIC_NOTES[lg], 'rows': logic_rows.get(lg, 0)} for lg in sorted(NEW_LOGICS)}
    plan['logics_still_fallback'] = {str(lg): n for lg, n in sorted(missing_logic.items(), key=lambda x: -x[1])}
    plan['derived_rows'] = {str(v): [s, n] for v, (_, s, n) in sorted(der.new.items())}
    plan['faction_lowlevel'] = faction_report(src, der)
    with open(os.path.join(st, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1, default=str)
    print(json.dumps({'summary': plan['summary'], 'lua_consts': plan['lua_consts']['counts'], 'faction_lowlevel': plan['faction_lowlevel']['totals'],
                      'files': sorted(files)}, ensure_ascii=False, indent=1))


_BASE_ENGINE = {}


def installed_logics(files):
    t = files.get('lualib/impactenginer.lua')
    if t is None:
        if 'txt' not in _BASE_ENGINE:
            _BASE_ENGINE['txt'] = git_show(BASE_REV, GS + '/lualib/impactenginer.lua').decode('utf-8')
        t = _BASE_ENGINE['txt']
    return {int(m.group(1)) for m in re.finditer(r'\[(\d+)\]\s*=\s*"scene\.skill\.impact_logic\.', t)}


def faction_report(src, der):
    """Kỹ năng 15 phái, cấp kỹ năng 1–4 (nhân vật cấp 1–30): mỗi dòng SkillData → trạng thái impact trước/sau.
    ok = mọi ô impact có dòng + logic đã cài + nhãn được logic kỹ năng đọc; partial = một phần; none = không ô nào; no_impact_param = không có ô impact."""
    before_logics = installed_logics({})
    after_logics = before_logics | set(NEW_LOGICS)
    skill_logics = set(int(m.group(1)) for m in re.finditer(r'\[(\d+)\]\s*=\s*"scene\.skill\.', src.lua_base('lualib/skillenginer.lua')))
    known = known_labels(src)
    tot = collections.Counter()
    per = collections.defaultdict(collections.Counter)
    items = []

    def state(imps, slg, after):
        if not imps:
            return 'no_impact_param', []
        bad = []
        for d, v in imps:
            rr = src.si_by.get(v) or (der.new[v][0] if after and v in der.new else None)
            if rr is None:
                bad.append('missing:%d' % v)
                continue
            lg = ival(rr[2])
            if lg is not None and lg < 8000 and lg not in (after_logics if after else before_logics):
                bad.append('logic%d:%d' % (lg, v))
                continue
            if d not in known and (slg in skill_logics or not after):
                bad.append('label:%s' % d)
        return ('ok' if not bad else ('partial' if len(bad) < len(imps) else 'none')), bad

    for r in src.st['rows']:
        mp = ival(r[ST_MENPAI])
        if mp is None or mp < 0 or mp > 15 or mp == 9:
            continue
        seen = set()
        for k in range(4):
            sid = ival(r[ST_LEVELS[k]])
            if sid is None or sid < 0 or sid in seen or sid not in src.sd_by:
                continue
            seen.add(sid)
            row = src.sd_by[sid]
            slg = ival(row[SD_LOGIC])
            imps = [(g(row[p]).strip(), ival(row[p + 1])) for p in src.param_pos if p + 1 < len(row) and is_impact_label(g(row[p]).strip()) and (ival(row[p + 1]) or -1) >= 0]
            (b, bb), (a, ab) = state(imps, slg, False), state(imps, slg, True)
            tot['before_' + b] += 1
            tot['after_' + a] += 1
            per[mp]['before_' + b] += 1
            per[mp]['after_' + a] += 1
            if b != 'ok' or a != 'ok':
                items.append({'menpai': mp, 'tid': int(r[0]), 'name': g(r[ST_NAME]), 'level': k + 1, 'skill_data': sid, 'skill_logic': slg,
                              'skill_logic_installed': slg in skill_logics, 'before': b, 'after': a, 'why_before': bb, 'why_after': ab, 'impacts': imps})
    return {'totals': dict(tot), 'by_menpai': {str(k): dict(v) for k, v in sorted(per.items())}, 'items': items}


def staged(st):
    out = [(os.path.join(st, SI), SI)]
    base = os.path.join(st, 'lua')
    for dp, _, fns in os.walk(base):
        for fn in fns:
            p = os.path.join(dp, fn)
            out.append((p, os.path.relpath(p, base).replace('\\', '/')))
    return sorted(out, key=lambda x: x[1])


def cmd_apply(args):
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'server-impact-' + stamp)
    changed, same = [], 0
    for p, rel in staged(args.staging):
        dst = os.path.join(R, rel)
        new = open(p, 'rb').read()
        old = open(dst, 'rb').read() if os.path.exists(dst) else None
        if old == new:
            same += 1
            continue
        changed.append(rel)
        if args.dry_run:
            continue
        if old is not None:
            bp = os.path.join(bdir, rel)
            os.makedirs(os.path.dirname(bp), exist_ok=True)
            open(bp, 'wb').write(old)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'wb').write(new)
    print(json.dumps({'dry_run': args.dry_run, 'changed': changed, 'unchanged': same, 'backup_dir': bdir if changed and not args.dry_run else None}, ensure_ascii=False, indent=1))


def cmd_verify(args):
    rep = {'ok': True, 'errors': [], 'checks': {}}
    err = rep['errors'].append
    C = rep['checks']
    data = open(os.path.join(R, SI), 'rb').read()
    try:
        data.decode('gbk')
    except UnicodeDecodeError as ex:
        err('StandardImpact không phải GBK: %s' % ex)
    tb = read_table_bytes(data)
    n = len(tb['types'])
    ids = [int(r[0]) for r in tb['rows']]
    bad = [r[0] for r in tb['rows'] if len(r) != n]
    C['table'] = {'rows': len(ids), 'cols': n, 'bad_tab_rows': len(bad), 'dup': len(ids) - len(set(ids)), 'sorted': ids == sorted(ids)}
    if bad or len(ids) != len(set(ids)) or ids != sorted(ids):
        err('StandardImpact: tab/ID lỗi %s' % C['table'])
    by = {int(r[0]): r for r in tb['rows']}
    # tham chiếu: 100 % được phân loại (có dòng / suy ra / không suy ra có lý do)
    src = Src()
    refs = collect_refs(src)
    plan = None
    if args.staging:
        plan = json.load(open(os.path.join(args.staging, 'plan.json'), encoding='utf-8'))
    unresolved = {int(k) for k in (plan or {}).get('unresolved', {})}
    present = sum(1 for *_, v in refs if v in by)
    classified = sum(1 for *_, v in refs if v in by or v in unresolved)
    C['refs'] = {'total': len(refs), 'present': present, 'unresolved_classified': classified - present, 'classified_pct': round(100.0 * classified / len(refs), 3) if refs else 100.0}
    if plan and classified != len(refs):
        err('tham chiếu impact chưa phân loại: %d' % (len(refs) - classified))
    # dòng mới: logic đã đăng ký, SE có ở client CY hoặc -1, nhãn tham số giữ nguyên bộ 16
    eng = open(os.path.join(R, GS, 'lualib/impactenginer.lua'), encoding='utf-8').read()
    reg = {int(m.group(1)) for m in re.finditer(r'\[(\d+)\]\s*=\s*"scene\.skill\.impact_logic\.', eng)}
    new_ids = [i for i in by if i not in src.si_by]
    bad_se = [i for i in new_ids if (ival(by[i][5]) or -1) > 0 and ival(by[i][5]) not in src.se_cy]
    timed_only = {}
    for r in tb['rows']:
        lg = ival(r[2])
        if lg is not None:
            timed_only[lg] = timed_only.get(lg, True) and r[4] == b'1'
    cand = sorted({ival(by[i][2]) for i in new_ids if ival(by[i][2]) is not None and ival(by[i][2]) < 8000 and ival(by[i][2]) not in reg})
    fallback_null = [lg for lg in cand if timed_only.get(lg)]          # impactenginer: mọi dòng duy trì → null_logic_buff (vá server-impact)
    unreg = [lg for lg in cand if not timed_only.get(lg)]
    C['new_rows'] = {'n': len(new_ids), 'se_not_in_cy_client': len(bad_se), 'logic_fallback_null_buff': fallback_null, 'logic_not_registered': unreg,
                     'by_source_plan': dict(collections.Counter(v[0] for v in (plan or {}).get('derived_rows', {}).values()))}
    if bad_se:
        err('dòng mới trỏ SE không có ở client CY: %s' % bad_se[:10])
    if unreg:
        err('dòng mới dùng logic chưa đăng ký mà không phải buff duy trì (sẽ rơi về std_impact_003): %s' % unreg)
    if 'timed_only[c.logic_id]' not in eng:
        err('impactenginer thiếu vá fallback null_logic_buff')
    for lg, mod in NEW_LOGICS.items():
        m = re.search(r'\[%d\]\s*=\s*"scene\.skill\.impact_logic\.([\w]+)"' % lg, eng)
        if not m or m.group(1) != (mod or 'null_logic_buff'):
            err('impactenginer: logic %d không trỏ %s' % (lg, mod))
    # module tồn tại
    for lg, mod in NEW_LOGICS.items():
        if not os.path.exists(os.path.join(R, GS, 'services/scene/skill/impact_logic/%s.lua' % (mod or 'null_logic_buff'))):
            err('thiếu module %s' % mod)
    # hằng Lua đã đổi phải có dòng
    remap_txt = open(os.path.join(R, GS, REMAP_FILE), encoding='utf-8').read() if os.path.exists(os.path.join(R, GS, REMAP_FILE)) else ''
    remap = {int(a): int(b) for a, b in re.findall(r'\[(\d+)\]\s*=\s*(\d+)', remap_txt)}
    C['gl_remap'] = {'n': len(remap), 'rows_present': sum(1 for v in remap.values() if v in by)}
    if C['gl_remap']['n'] != C['gl_remap']['rows_present']:
        err('remap GL thiếu dòng StandardImpact')
    # luac + test
    lua_files = sorted({rel for _, rel in staged(args.staging)} if args.staging else set()) or [GS + '/' + x for x in LUA_NEW_FILES + [KNOWN_LABELS_FILE, REMAP_FILE, 'lualib/impactenginer.lua', 'lualib/cfghelper.lua', 'lualib/skillinfo.lua', 'lualib/skillenginer.lua']]
    lua_files = [x for x in lua_files if x.endswith('.lua')]
    fails = []
    for rel in lua_files:
        r = subprocess.run(['luac5.4', '-p', os.path.join(R, rel)], capture_output=True, text=True)
        if r.returncode != 0:
            fails.append((rel, r.stderr[-300:]))
    C['luac'] = {'files': len(lua_files), 'fail': fails}
    if fails:
        err('luac: %s' % fails)
    r = subprocess.run(['lua5.4', TESTS, R], capture_output=True, text=True)
    C['lua_tests'] = {'rc': r.returncode, 'tail': r.stdout[-1500:] + r.stderr[-800:]}
    if r.returncode != 0:
        err('test Lua đơn vị thất bại')
    if args.staging:
        drift = [rel for p, rel in staged(args.staging) if not os.path.exists(os.path.join(R, rel)) or sha(os.path.join(R, rel)) != sha(p)]
        C['staging_drift'] = drift
        if drift:
            err('staging khác R: %s' % drift[:10])
    rep['ok'] = not rep['errors']
    if args.out:
        json.dump(rep, open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps(rep, ensure_ascii=False, indent=1))
    sys.exit(0 if rep['ok'] else 1)


def cmd_char_skill(args):
    """CYTest00: thêm template kỹ năng vào skill_list (bài kiểm bot) hoặc khôi phục từ bản sao. Chỉ khi skynet dừng (DataCenter có thể giữ cache)."""
    if clients():
        sys.exit('client connected to 15733/15734; refuse')
    busy = subprocess.run(['pgrep', '-f', R + '/GameServer/framework/'], capture_output=True, text=True).stdout.split()
    if busy:
        sys.exit('skynet của server riêng còn chạy (pid %s); dừng trước' % ' '.join(busy))
    with provision().database() as client:
        col = client['tlbb']['character']
        doc = col.find_one({'attrib.guid': GUID}, {'_id': 0})
        if doc is None:
            sys.exit('không có nhân vật %d' % GUID)
        if args.restore:
            saved = json.load(open(args.restore, encoding='utf-8'))
            res = col.update_one({'attrib.guid': GUID}, {'$set': {'skill_list': saved['before_skill_list']}})
            rec = {'restored_from': args.restore, 'modified': res.modified_count, 'skill_list': col.find_one({'attrib.guid': GUID}, {'_id': 0, 'skill_list': 1})['skill_list']}
        else:
            if os.path.exists(args.out):
                sys.exit('output exists: ' + args.out)
            add = [int(x) for x in args.add.split(',') if x.strip()]
            before = list(doc.get('skill_list') or [])
            new = before + [x for x in add if x not in before]
            with open(args.out, 'x', encoding='utf-8') as f:
                json.dump({'guid': GUID, 'before_skill_list': before, 'added': add, 'backup_full_doc': doc}, f, ensure_ascii=False, indent=1, default=str)
            res = col.update_one({'attrib.guid': GUID}, {'$set': {'skill_list': new}})
            rec = {'backup': args.out, 'modified': res.modified_count, 'skill_list': new}
    print(json.dumps(rec, ensure_ascii=False))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('plan'); a.add_argument('--out', required=True)
    a = sub.add_parser('apply'); a.add_argument('--staging', required=True); a.add_argument('--dry-run', action='store_true')
    a = sub.add_parser('verify'); a.add_argument('--staging'); a.add_argument('--out')
    a = sub.add_parser('char-skill'); a.add_argument('--out'); a.add_argument('--add', default=''); a.add_argument('--restore')
    args = ap.parse_args()
    {'plan': cmd_plan, 'apply': cmd_apply, 'verify': cmd_verify, 'char-skill': cmd_char_skill}[args.cmd](args)


if __name__ == '__main__':
    main()
