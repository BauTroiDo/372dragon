'cy_gui_dict.py - StrDictionary for the CY GUI layer: CY 3.71 keys, Vietnamese text (user decision 14/09/2026:\n"Giữ tiếng Việt, tiếp tục đi").\n\nFor every key of the CY 3.71 dictionary (S4 Config.axp, binary 00CCBBDD, GBK) the value is chosen in this order:\n\nOutput text table: 2 header lines "STRING\tSTRING" + key\tvalue, UTF-8, CRLF (as the GL file). A value never contains\nTAB/CR/LF (CY 3.71 has none; asserted). Duplicate CY keys keep the first row (TLBB_DBC keeps the first as well).\n'
import collections
import hashlib
import os
import re
import struct
import sys

TRANSLATION = r'C:\TLBB\085\analysis\translation'
DB = os.path.join(TRANSLATION, 'translation.db')
GL_ZH = os.path.join(TRANSLATION, 'backup', 'configfolder', 'StrDictionary.txt')
REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
I18N = os.path.join(REPO, 'Registry', 'i18n')
API_TSV = os.path.join(I18N, 'cy_vi_api.tsv')            # zh \t vi \t src \t when   (cy_translate.py)
OVERRIDE_TSV = os.path.join(I18N, 'cy_vi_override.tsv')  # key-or-zh \t vi \t note  (hand: '#KEY' or zh text)
# item-text 15/09: short labels of the bag / shop / NPC dialog frames (same format; cy_vi_override.tsv wins on a clash)
ITEM_UI_OVERRIDE_TSV = os.path.join(I18N, 'cy_item_ui_override.tsv')
# CYS-I18NSCOPE (i18n-scope 19/09/2026): ghi de theo cap (KHOA, KHUNG).  key \t frame \t vi \t note
# VI SAO CAN: ghi de o tren la theo KHOA, nhung tran khung la theo KHUNG. Do duoc: 847 khoa bi rut
# ngan vi mot khung hep nhung con duoc dung o khung khac - noi thua cho. Xem Timeline/handoff/i18n-scope.md.
# CACH LAM: KHONG doi dinh dang bang (van 2 cot) va KHONG doi mot dong C++. Moi cap sinh THEM mot
# dong khoa `KHOA@Khung`; `Tools/reapply/i18n-scope/82-frame-keys.py` doi `#{KHOA}` -> `#{KHOA@Khung}`
# trong DUNG nhung tep layout do. Khoa goc giu nguyen ban rut gon => moi khung hep khong bi dong toi.
# An toan cua khoa co '@': tra khoa la `m_theDirectionary.find()` thuan (UIString.cpp:193) va khoa CY
# von da chua '(' ')' '+' dau cach '#' '%'; chi hai dieu cam: khoa khong duoc chua '}' (parser dung o
# do) va dong khong duoc bat dau bang '#' (CysUiDictionary.h coi la dong chu thich).
FRAME_OVERRIDE_TSV = os.path.join(I18N, 'cy_vi_frame_override.tsv')

DROP_DICT = ('world', 'cmp', 'index', 'blackvar', 'nameapi')   # StrDictionary: values never reach Lua comparisons
DROP_CODE = ('world',)                                         # Lua literals / layout text: logic reasons kept
HAN = re.compile(r'[\u4e00-\u9fff]')
# CYS-I18NRUN (19/09/2026): `%\d*[a-zA-Z]` dat chu so TRUOC chu cai (kieu C "%2d"), nhung TLBB dat chu so
# SAU ("%s0", "%s1" = CHI SO doi so). Thieu `\d?` thi "%s0" cat thanh "%s" + van ban "0", va buckets() thay
# %s0 == %s == %s24 -> validate() cho qua moi ban dich lam lech chi so (do duoc: 83 cap trong corpus).
# `\d?` = DUNG MOT chu so, y het CysPackedFormat::Substitute doc mot chu so sau %s (CysPackedFormat.h:136-140);
# nuot nhieu hon engine doc se bat oan. Loi ich chinh khong phai phat hien ma la PHONG NGUA: mask() nay goi
# chu so VAO TRONG moc [[i]] nen mo hinh khong the tach no ra nua.
TOK = re.compile(r'#[cC][0-9a-fA-F]{6}|#\{[^}]*\}|#[A-Za-z]|%\d*[a-zA-Z]\d?|\$\d+\$|\$[A-Za-z](?![A-Za-z0-9_])')

# CYS-I18NCOUNT (i18n-count 19/09/2026): the translation memory carries 209 rows wrecked by an old API batch -
# a GUID fragment and the batch separator " || " bled into the Vietnamese, and the text was cut at an arbitrary
# point, sometimes in the MIDDLE of a #{...} tag (found by ui-fit-3 on WYWSK_140417_04; 194 of the 209 are
# clean|color_diff so ViMap hands them out as usable). 13 cells had already reached CanonicalCY: 12 in
# StrDictionary.txt and 1 in CommonItem.txt (item 30111718, its NAME column held a 570-character blob).
# A rejected hit falls through to 'untranslated', which is the right end state: the cell keeps clean CY Chinese
# AND stays in the queue cy_translate.collect() builds, so the next paid API batch retranslates it.
# Do NOT "fix" such a row with a #KEY override: that takes it out of `untranslated` and freezes it as Chinese.
# Evidence + measurement: Build/Logs/2026-09-19-i18n-count/ ; Timeline/handoff/i18n-count.md m\u1ee5c 3.8.
_WRECK_GUID = re.compile(r'\b[0-9a-f]{4,12}-[0-9a-f]{4}-[0-9a-f]{4,12}\b')
_WRECK_SEP = ' || '


def _tag_open(s):
    """True when s ends with a '#{' that never closes."""
    i = 0
    while True:
        j = s.find('#{', i)
        if j < 0:
            return False
        e = s.find('}', j)
        if e < 0:
            return True
        i = e + 1


def _visible_len(s):
    """So ky tu that su hien ra: bo token TLBB (#c..., #{...}, %s0...) roi bo khoang trang hai dau."""
    return len(TOK.sub('', s or '').strip())


def wrecked(vi, zh=None):
    """True for a translation carrying the fingerprint of the broken API batch (see CYS-I18NCOUNT above).

    Deliberately narrow - marks of that one accident, never a judgement on wording:
      1. the batch separator " || " glued several answers together, or a bare GUID fragment leaked in;
      2. a '#{' the Vietnamese never closes WHILE the Chinese source closes all of its own. The second half
         of that test matters: 176 of the 178 rows whose Vietnamese has an open '#{' are legitimate - the
         SOURCE is itself a fragment ending in '#{_ITEM', '#{_MONEY'... and the translation mirrors it. Only
         a translation that opens a tag its source did not is evidence of a cut (measured 19/09: 2 rows,
         e.g. '#H...' rendered as '#{H...'). Without zh the test is skipped rather than guessed.
    """
    if not vi:
        return False
    if _WRECK_SEP in vi or _WRECK_GUID.search(vi):
        return True
    # CYS-I18NSCOPE (i18n-scope 19/09/2026): lop thu ba - ban dich KHONG LIEN QUAN GI toi nguon.
    # Do duoc: MOT chuoi "Nạp thêm tại: https://platform.beeknoee.com/billing" duoc TM tra ve cho
    # TAM chu Han don le khac nhau (风 逢 身 飞 翼 除 鞋 ...) o 9 khoa, cong 3 khoa nua cung dang.
    # Hai phep kiem cu MU hoan toan voi no: khong co " || ", khong co manh GUID, khong co the `#{`
    # ho. Dau hieu duy nhat con lai la DO DAI: mot nguon <= 2 chu Han khong the sinh ra 50 ky tu.
    # Nguong 4*len+14 do tu chinh corpus: no bat 12/154.776 dong va KHONG bat mot dong lanh nao
    # (doi chung o cy_gui_dict_wrecked_test); rong rai co y vi "买" -> "Mua vật phẩm" van phai qua.
    # Dong bi chan roi ve `untranslated` - giu chu Han sach VA o lai hang doi dich, dung dich sai.
    if zh is not None:
        lz, lv = _visible_len(zh), _visible_len(vi)
        if 0 < lz <= 2 and lv > 4 * lz + 14:
            return True
    return zh is not None and _tag_open(vi) and not _tag_open(zh)


# ---------------------------------------------------------------------------------------------
# CYS-PRINTFFIX (printf-fix 20/09/2026): CUA THU BA. `build()` xuat thang ket qua bo nho dich /
# tu dien GL / API ra StrDictionary, chi loc qua `wrecked()`. Bat bien printf chua bao gio duoc
# kiem o day, nen 134 o da lot ra voi NHIEU dac ta printf hon nguon Han.
#
# VI SAO NGUY HIEM: `_vsnprintf` o `UIString.cpp:918` (`ParserString_VarParam`) doc dung so dac ta
# CO TRONG CHUOI DANG DUNG, trong khi nguoi goi chi day so doi so khop voi NGUON HAN.
#
# DO TREN UCRT x64 THAT (MSVC 2022, /MD, KHONG cai invalid-parameter handler - y het game;
# Build/Logs/2026-09-20-printf-fix/ncheck.c):
#     "A% sB" + 1 doi so  -> rc=5  "AXYZB"          `% s` CO tieu thu doi so
#     "A% gB"             -> rc=15 "A 6.95144e-310B"  doc rac, khong vang
#     "A% pB"             -> rc=18 "A00007FF6...B"    CHI IN con tro, KHONG giai tham chieu
#     "A% nB"             -> tien trinh CHET NGAY, exit 0xC0000409 (__fastfail)  <-- nang nhat
#     "A%%B"              -> rc=3  "A%B"
# `%n` bi UCRT vo hieu hoa; `_invalid_parameter` mac dinh goi `__fastfail`, SEH KHONG BAT DUOC,
# nen khong co minidump. Do la mot cua tu "im lang" hoan toan.
#
# VI SAO DUNG `％` (U+FF05) CHU KHONG PHAI `%%`: mot khoa tu dien di theo HAI duong khac nhau -
#   * `ParserString_VarParam`  -> `_vsnprintf`   : `%` le LUON bi nuot ("A50%" -> "A50"), chi `%%` song;
#   * `#{KHOA}` trong Lua/NPC  -> `ParserString_Runtime*` : KHONG he goi printf, nen `%%` hien ra HAI dau.
# Hai duong nguoc nhau => khong co cach viet nao bang `%` ASCII dung o ca hai. `％` dung o ca hai,
# va do chinh la ky tu nguon Han dung san. Do be rong (FreeType, 8 font cua Schema): `％` rong hon
# `%` DUNG 1-2 px, va ca 8 font deu CO glyph. Bang chung: Build/Logs/2026-09-20-printf-fix/.
FULLWIDTH_PCT = u'％'
PRINTF_SPEC_FULL = re.compile(
    r'%(?!%)([-+ #0]*)([0-9]*)((?:\.[0-9]+)?)((?:hh|h|ll|l|L|z|j|t)?)([diouxXeEfFgGaAcspn])')


def n_printf_spec(s):
    return len(PRINTF_SPEC_FULL.findall(s or ''))


def _accidental(m):
    """Dac ta SINH RA DO VAN BAN, khong phai tham so that.

    Do tren ca hai ben 20/09 (155.044 dong): tham so that cua TLBB - `%s` 38.429, `%d` 712,
    `%i` 60, `%u` 6, `%e` 1, `%g` 1 - KHONG CO MOT CAI NAO mang flag. Cac dang co chu so that
    (`%.2f` 11, `%3d` 2, `%02d` 2) co mat y het o CA HAI ben va khong mang flag dau cach.
    Nen "co flag dau cach hoac '#', va khong co do rong/do chinh xac" = tai nan van ban:
      `50% gia tri`  -> `% g`       (chu Viet sau dau phan tram)
      `100%#cfff263` -> `%#c`       (dau phan tram dinh ngay ma mau)
    """
    return (' ' in m.group(1) or '#' in m.group(1)) and not m.group(2) and not m.group(3)


def n_args(zh):
    """So DOI SO nguoi goi thuc su day len = so dac ta cua nguon Han KHONG phai tai nan.

    CYS-PRINTFFIX 20/09, DINH CHINH MOT MO HINH SAI CUA CHINH TOI: phep do dau tien (va moc
    134/122 cua banh coc) so `len(specs(vi)) > len(specs(zh))`. Mo hinh do SAI o nhung dong ma
    CHINH NGUON HAN cung chua dac ta tai nan - CY 3.71 co 218 cho `%#c` (do `100%` dinh ngay ma
    mau `#cfff263`) va 15 o doc qua vi the. Nguoi goi day doi so theo nhung THAM SO TAC GIA THAT
    SU VIET (`%s0`, `%s1`, `%d`...), khong theo cai `%#c` do van ban sinh ra.

    Do duoc bang mo hinh nay (sau khi da sua 134 o theo mo hinh cu): ban Viet VAN con 195 o doc
    mot doi so khong ton tai, 16 trong so do bang `%s` (giai tham chieu). Hai o trong 16 la do
    ban dich lam TE HON nguon (`THYH_160510_189/190`: ban dich day `5%#c` len TRUOC `%s1`, nen
    `%s` tut xuong vi tri 2 trong khi chi co 2 doi so).
    """
    return sum(1 for m in PRINTF_SPEC_FULL.finditer(zh or '') if not _accidental(m))


def deparam_percent(zh, vi):
    """Doi dau `%` ASCII TAI NAN thanh `％` cho toi khi ban dich khong doc qua so doi so THAT.

    Go mot dac ta tai nan LUON LUON lam dung hon, khong bao gio lam sai di: no tra cac `%sN`
    phia sau ve DUNG chi so doi so ma tac gia dinh (vi du `[%s, %#c, %s]` voi 2 doi so - `%s`
    cuoi dang doc mot doi so khong ton tai - thanh `[%s, %s]` doc dung ca hai).
    Tra ve (vi_moi, so_cho_da_doi).
    """
    limit = n_args(zh)
    out, changed = vi, 0
    while True:
        specs = list(PRINTF_SPEC_FULL.finditer(out))
        if len(specs) <= limit:
            break
        cands = [m for m in specs if _accidental(m)]
        if not cands:
            break                      # con lai la tham so that -> khong phai viec cua cong nay
        pos = cands[-1].start()         # go tu PHAI sang TRAI
        out = out[:pos] + FULLWIDTH_PCT + out[pos + 1:]
        changed += 1
    return out, changed


def printf_over(zh, vi):
    """True khi ban dich doc qua so DOI SO THAT - tuc `_vsnprintf` lay mot doi so khong ton tai."""
    return n_printf_spec(vi) > n_args(zh)


def sha256_bytes(b):
    return hashlib.sha256(b).hexdigest()


def parse_binary_dbc(raw):
    """[(bytes col0, bytes col1)] for a 2-column STRING binary DBC."""
    if raw[:4] != b'\x00\xcc\xbb\xdd':
        raise ValueError('not a binary DBC')
    _, fields, records, strings = struct.unpack_from('<Iiii', raw, 0)
    kinds = struct.unpack_from('<%dI' % fields, raw, 16)
    if fields != 2 or kinds != (2, 2):
        raise ValueError('StrDictionary must be STRING STRING, got %r' % (kinds,))
    base = 16 + 4 * fields
    cells = struct.unpack_from('<%dI' % (fields * records), raw, base)
    pool = raw[base + 4 * fields * records:]
    out = []
    for r in range(records):
        row = []
        for c in range(fields):
            v = cells[r * fields + c]
            row.append(pool[v:pool.find(b'\0', v)])
        out.append(tuple(row))
    return out


def load_text_dict(path):
    d = {}
    with open(path, 'rb') as f:
        lines = f.read().split(b'\n')
    for ln in lines[2:]:
        ln = ln.rstrip(b'\r')
        if b'\t' not in ln:
            continue
        k, v = ln.split(b'\t', 1)
        k = k.decode('utf-8')
        if k not in d:
            d[k] = v.decode('utf-8')
    return d


class TM:
    'cy_gui_dict project helper.'

    def __init__(self, db=DB, drop=DROP_DICT):
        import sqlite3
        self.db = sqlite3.connect('file:%s?mode=ro' % db.replace('\\', '/'), uri=True)
        self.map, self.trim = {}, {}
        for zh, zt, vi, st in self.db.execute(
                "SELECT zh, zh_trim, vi, status FROM vimap WHERE status IN ('clean','color_diff')"):
            self.map[zh] = (vi, st)
            self.trim.setdefault(zt, (zh, vi, st))
        self.excl = {r[0] for r in self.db.execute(
            'SELECT zh FROM exclude WHERE reason NOT IN (%s)' % ','.join('?' * len(drop)), drop)}
        try:
            self.excl -= {r[0] for r in self.db.execute('SELECT zh FROM unlock')}
        except Exception:
            pass

    def lookup(self, s):
        if s in self.excl:
            return None
        hit = self.map.get(s)
        if hit:
            # CYS-I18NCOUNT 19/09: never hand out a row wrecked by the old API batch (see wrecked() above).
            return None if wrecked(hit[0], s) else hit
        st = s.strip()
        if st and st != s and st not in self.excl:
            t = self.trim.get(st)
            if t:
                zh0, vi, stat = t
                if wrecked(vi, zh0):
                    return None
                i = len(s) - len(s.lstrip())
                return s[:i] + vi + s[len(s.rstrip()):], stat
        return None


def load_tsv_dict(path, ncols=2):
    """{col0: col1} of a UTF-8 TSV with one header line (first row wins); missing file -> {}."""
    d = {}
    if not os.path.exists(path):
        return d
    with open(path, 'rb') as f:
        lines = f.read().decode('utf-8').split('\n')
    for ln in lines[1:]:
        ln = ln.rstrip('\r')
        parts = ln.split('\t')
        if len(parts) < ncols or not parts[0]:
            continue
        d.setdefault(parts[0], parts[1])
    return d


def load_frame_dict(path=None):
    """CYS-I18NSCOPE: {(key, frame): vi} tu cy_vi_frame_override.tsv (4 cot, dong dau la header).

    Tep vang -> {} (nen thay doi nay INERT voi moi nhanh khong dung toi no).
    """
    path = path or FRAME_OVERRIDE_TSV
    out = {}
    if not os.path.exists(path):
        return out
    with open(path, 'rb') as f:
        lines = f.read().decode('utf-8').split('\n')
    for ln in lines[1:]:
        p = ln.rstrip('\r').split('\t')
        if len(p) < 3 or not p[0] or not p[1]:
            continue
        out.setdefault((p[0], p[1]), p[2])
    return out


class Extra:
    """Project dictionary (API results) + hand overrides. lookup(zh) / by_key(key) -> vi | None."""

    def __init__(self, api_tsv=API_TSV, override_tsv=OVERRIDE_TSV):
        self.api = load_tsv_dict(api_tsv)
        over = load_tsv_dict(override_tsv)
        for k, v in load_tsv_dict(ITEM_UI_OVERRIDE_TSV).items():
            over.setdefault(k, v)
        self.over_key = {k[1:]: v for k, v in over.items() if k.startswith('#')}
        self.over_zh = {k: v for k, v in over.items() if not k.startswith('#')}
        self.by_frame = load_frame_dict()          # CYS-I18NSCOPE: {(key, frame): vi}

    def by_key(self, key):
        return self.over_key.get(key)

    def lookup(self, s):
        hit = self.over_zh.get(s)
        if hit is None:
            hit = self.api.get(s)
        if hit is None:
            st = s.strip()
            if st and st != s:
                inner = self.over_zh.get(st) or self.api.get(st)
                if inner is not None:
                    i = len(s) - len(s.lstrip())
                    hit = s[:i] + inner + s[len(s.rstrip()):]
        return hit


def translate_strings(strings, db_path=DB, drop=DROP_CODE, extra=None):
    """{zh: vi} for the strings that have an exact translation (same rules as apply_xml.py: display text only,
    exact match, exclusions of the translation pipeline; then the project dictionary). Strings without a hit are
    left out."""
    tm = TM(db_path, drop) if os.path.exists(db_path) else None
    extra = extra if extra is not None else Extra()
    out = {}
    stats = collections.Counter()
    for s in strings:
        if not HAN.search(TOK.sub('', s)):
            stats['no-han'] += 1
            continue
        # item-text 15/09: a hand override (zh text) is a layout decision (short label for a narrow CY frame) and wins
        # over the translation memory, which otherwise always had the long form (元宝： = "Nguyên Bảo:")
        if s in extra.over_zh:
            out[s] = extra.over_zh[s]
            stats['override-zh'] += 1
            continue
        hit = tm.lookup(s) if tm else None
        if hit is not None:
            out[s] = hit[0]
            stats['tm-' + hit[1]] += 1
            continue
        vi = extra.lookup(s)
        if vi is not None:
            out[s] = vi
            stats['api'] += 1
            continue
        stats['untranslated'] += 1
    stats['tm_available'] = tm is not None
    return out, dict(stats)


def build(cy_raw, gl_vi_path, gl_zh_path=GL_ZH, db_path=DB, printf_gate='raise'):
    """-> (bytes text_table, stats dict, rows [(key, source)], untranslated [(key, zh)]).

    `printf_gate` (CYS-PRINTFFIX 20/09) - cua thu ba, dat o DIEM MA MOI NGUON DEU DI QUA, khong
    rieng bo nho dich: do 20/09 cho thay 134 o vi pham den tu BON nguon khac nhau (tm-clean 95,
    tm-color_diff 21, gl-same-zh 15, api 3), nen mot cong chi gan vao `tm.lookup()` se BO SOT 18 o.
      'raise'  (mac dinh) sua duoc thi sua, con sot thi DUNG HAN va neu ten khoa;
      'zh'     con sot thi tra o do ve chu Han (an toan, nguoi dung thay ngay) va dem vao stats.
    KHONG co che do "bo qua": doc mot doi so khong ton tai la hanh vi khong xac dinh.

    Chi bat bien printf duoc chan CUNG o day. `cy_translate.validate()` day du con tu choi 5.836
    dong nua vi lech ma mau (do 20/09 tren 155.044 dong); chan cung ca cai do se day gan 6.000 o
    ve chu Han - mot hoi quy nguoi dung thay ngay - nen no van la viec rieng cua duong ong rut gon.
    """
    rows = parse_binary_dbc(cy_raw)
    gl_vi = load_text_dict(gl_vi_path)
    gl_zh = load_text_dict(gl_zh_path) if os.path.exists(gl_zh_path) else {}
    tm = TM(db_path) if os.path.exists(db_path) else None
    extra = Extra()
    stats = collections.Counter()
    seen = set()
    out = [b'STRING\tSTRING', b'STRING\tSTRING']
    src_rows, untranslated = [], []
    zh_by_key = {}                       # CYS-PRINTFFIX: de cong cung ap duoc cho dong (KHOA, KHUNG)
    for kb, vb in rows:
        key = kb.decode('gbk')
        if key in seen:
            stats['duplicate_key_skipped'] += 1
            continue
        seen.add(key)
        zh = vb.decode('gbk')
        zh_by_key[key] = zh
        assert '\t' not in zh and '\n' not in zh and '\r' not in zh and '\t' not in key, key
        over = extra.by_key(key)
        if over is not None:
            val, src = over, 'override-key'
        elif not HAN.search(TOK.sub('', zh)):
            val, src = zh, 'no-han'
        elif key in gl_vi and gl_zh.get(key) == zh:
            val, src = gl_vi[key], 'gl-same-zh'
        else:
            hit = None if (tm is None or key.startswith('GMDP_')) else tm.lookup(zh)
            if hit is not None:
                val, src = hit[0].replace('\t', ' '), 'tm-' + hit[1]
            elif extra.lookup(zh) is not None:
                val, src = extra.lookup(zh).replace('\t', ' '), 'api'
            else:
                val, src = zh, 'untranslated'
                untranslated.append((key, zh, 'key-in-gl' if key in gl_vi else 'cy-only'))
        val = val.replace('\r', ' ').replace('\n', ' ')
        # CYS-PRINTFFIX: cua thu ba - moi nguon deu qua day, ke ca `no-han`/`untranslated`
        # (hai cai do tra ve chinh `zh` nen khong bao gio vuot; cho chung qua de khong co ngoai le).
        if printf_over(zh, val):
            val, nfix = deparam_percent(zh, val)
            if nfix:
                stats['printf-deparam'] += nfix
                stats['printf-deparam-rows'] += 1
            if printf_over(zh, val):
                msg = ('cy_gui_dict: khoa %r co %d dac ta printf > nguon Han %d sau khi da go %d '
                       'dau phan tram tai nan. `_vsnprintf` (UIString.cpp:918) se doc mot doi so '
                       'KHONG TON TAI. Sua ban dich, dung noi long cong nay.'
                       % (key, n_printf_spec(val), n_printf_spec(zh), nfix))
                if printf_gate == 'raise':
                    raise SystemExit(msg)
                sys.stderr.write(msg + '\n')
                val, src = zh, 'printf-gate-fallback-zh'
        stats[src] += 1
        src_rows.append((key, src))
        out.append(key.encode('utf-8') + b'\t' + val.encode('utf-8'))
    # CYS-I18NSCOPE: dong THEM cho tung cap (KHOA, KHUNG). Dat o CUOI de moi dong goc giu nguyen
    # vi tri va noi dung => `diff` cua mot dot chi la phan noi them.
    for (fkey, frame), fval in sorted(extra.by_frame.items()):
        if fkey not in seen:
            raise SystemExit('cy_vi_frame_override: khoa goc %r khong co trong CY StrDictionary' % fkey)
        newkey = '%s@%s' % (fkey, frame)
        if newkey in seen:
            raise SystemExit('cy_vi_frame_override: khoa %r da ton tai' % newkey)
        if '}' in newkey or newkey.startswith('#'):
            raise SystemExit('cy_vi_frame_override: khoa %r pha parser #{...}' % newkey)
        assert '\t' not in fval and '\n' not in fval and '\r' not in fval, newkey
        # CYS-PRINTFFIX: dong (KHOA, KHUNG) di qua CUNG mot cong - khong de mot cua ngach nao lai
        fzh = zh_by_key.get(fkey, '')
        if printf_over(fzh, fval):
            fval, nfix = deparam_percent(fzh, fval)
            if nfix:
                stats['printf-deparam'] += nfix
                stats['printf-deparam-rows'] += 1
            if printf_over(fzh, fval):
                msg = ('cy_gui_dict: dong khung %r co %d dac ta printf > nguon Han %d. '
                       '`_vsnprintf` se doc mot doi so KHONG TON TAI.'
                       % (newkey, n_printf_spec(fval), n_printf_spec(fzh)))
                if printf_gate == 'raise':
                    raise SystemExit(msg)
                sys.stderr.write(msg + '\n')
                fval = fzh
        seen.add(newkey)
        stats['frame-override'] += 1
        src_rows.append((newkey, 'frame-override'))
        out.append(newkey.encode('utf-8') + b'\t' + fval.encode('utf-8'))
    text = b'\r\n'.join(out) + b'\r\n'
    stats = dict(stats)
    stats.update({'cy_rows': len(rows), 'keys': len(seen), 'gl_vi_keys': len(gl_vi), 'gl_zh_keys': len(gl_zh),
                  'tm_pairs': len(tm.map) if tm else 0, 'tm_available': tm is not None,
                  'vietnamese_or_neutral': sum(v for k, v in stats.items() if k != 'untranslated'
                                               and k != 'duplicate_key_skipped')})
    return text, stats, src_rows, untranslated


if __name__ == '__main__':
    here = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, os.path.join(here, '..', '..', 'Docs', 'evidence', 'assetinv'))
    import axp_index as AX
    a = AX.Axp(r'C:\TLBB\085\Tools\DATA NEW\CY Game\Data\Config.axp')
    _, raw = a.payload_full('StrDictionary.txt', 64 << 20)
    text, stats, _, untr = build(raw, r'C:\TLBB\085\CY-Source\Assets\Canonical\Data\ConfigFolder\StrDictionary.txt')
    print(stats, len(text))
