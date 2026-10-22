'cy_translate.py - Vietnamese for the CY 3.71 GUI strings the translation memory does not have (cy-gui-2, 14/09/2026).\n\nSources (all read from the CY archives, the same way build_canonical_cy.py builds the GUI layer):\n  dict    ConfigFolder/StrDictionary.txt values (CY keys) that cy_gui_dict.build leaves \'untranslated\'\n  layout  Text/Tooltip/ColumnHeader values of the 2.032 CY layouts without an exact translation\n  lua     free display literals ("...") of the 2.043 CY UI scripts (cy_lua_i18n: comparison/index/name-API/\n          blacklisted-variable/custom-table sites are never translated; a literal coupled to code at ANY site is\n          excluded everywhere -> Registry/i18n/cy_lua_exclude.tsv)\n\nusage:  python -B cy_translate.py collect [--out DIR]      counts + need lists (no API)\n        python -B cy_translate.py run [--max N] [--workers 6] [--sources dict,layout,lua] [--out DIR]\n        python -B cy_translate.py shorten --fit fit.tsv     labels cy_layout_fit.py flagged -> shorter versions\n                                                            (<= max_chars) into Registry/i18n/cy_vi_override.tsv\n        python -B cy_translate.py stats\n'
import argparse
import collections
import datetime
import json
import os
import re
import sqlite3
import sys
import threading
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'Docs', 'evidence', 'assetinv'))
sys.path.insert(0, HERE)
import axp_index as AX                      # noqa: E402
import cy_gui_dict as GDICT                 # noqa: E402
import cy_lua_i18n as LI                    # noqa: E402
import cy_lua_unpack as LUA                 # noqa: E402

S4 = r'C:\TLBB\085\Tools\DATA NEW\CY Game\Data'
GL_DICT = r'C:\TLBB\085\CY-Source\Assets\Canonical\Data\ConfigFolder\StrDictionary.txt'
CFG = r'C:\TLBB\085\Tools\TLBBTranslationStudioPro\config\config.json'
TERM = r'C:\TLBB\085\Tools\TLBBTranslationStudioPro\data\termbase.db'
MODEL_FILE = r'C:\TLBB\085\analysis\translation\manifest\api_model.txt'
I18N = GDICT.I18N
API_TSV = GDICT.API_TSV
FAIL_TSV = os.path.join(I18N, 'cy_vi_api_fail.tsv')
EXCL_TSV = os.path.join(I18N, 'cy_lua_exclude.tsv')
HAN = GDICT.HAN
TOK = GDICT.TOK
MASK = re.compile(r'\[\[(\d+)\]\]')
MAXSEG = 260

PROMPT = (
    'Bạn là dịch giả game kiếm hiệp Thiên Long Bát Bộ (Trung → Việt). Dịch các dòng sau sang tiếng Việt, '
    'phong cách kiếm hiệp, xưng hô ta/ngươi, ngắn gọn như nhãn giao diện game.\n'
    'QUY TẮC BẮT BUỘC:\n'
    '1. Các mốc dạng [[0]] [[1]] ... là MÃ ĐIỀU KHIỂN đã được thay thế: giữ NGUYÊN VẸN từng mốc, đúng số lượng, '
    'đúng thứ tự tương ứng với văn bản; KHÔNG dịch, KHÔNG xoá, KHÔNG thêm mốc mới.\n'
    '2. Danh từ riêng chuyển Hán-Việt (少林 = Thiếu Lâm, 丐帮 = Cái Bang, 大理 = Đại Lý).\n'
    '3. Tuân thủ THUẬT NGỮ BẮT BUỘC nếu có trong danh sách dưới.\n'
    '4. Không thêm giải thích, không thêm dấu ngoặc kép, không để sót chữ Hán.\n'
    '5. Trả về ĐÚNG định dạng: mỗi dòng `ID<TAB>bản dịch`, đủ mọi ID, không bỏ dòng nào.\n')


# ------------------------------------------------------------------------------------------------ helpers
def buckets(s):
    ph, br, co = [], 0, []
    for t in TOK.findall(s):
        if t.startswith('#{') or t.startswith('%') or t.startswith('$'):
            ph.append(t)
        elif t == '#r':
            br += 1
        else:
            co.append(t)
    return sorted(ph), br, sorted(co)


def mask(s):
    toks = []

    def rep(m):
        toks.append(m.group(0))
        return '[[%d]]' % (len(toks) - 1)
    return TOK.sub(rep, s), toks


def unmask(s, toks):
    seen = set()

    def rep(m):
        i = int(m.group(1))
        if i >= len(toks):
            raise ValueError('stray mark')
        seen.add(i)
        return toks[i]
    try:
        out = MASK.sub(rep, s)
    except ValueError:
        return None
    if len(seen) != len(toks):
        return None
    return re.sub(r'(\$[A-Za-z])(?=[A-Za-z0-9_])', r'\1 ', out)


# CYS-I18NRUN (19/09/2026): dac ta printf THAT SU tieu thu mot doi so. Dung cho phep kiem ngay duoi.
# Do tren CRT that (ctypes -> msvcrt.sprintf): 'A% sB' + "XYZ" -> 'AXYZB'  => "% s" CO tieu thu doi so.
PRINTF_SPEC = re.compile(r'%(?!%)[-+ #0]*[0-9]*(?:\.[0-9]+)?(?:hh|h|ll|l|L|z|j|t)?[diouxXeEfFgGaAcspn]')


def validate(zh, vi):
    if not vi or not vi.strip():
        return 'empty'
    # CYS-I18NRUN: lop loi CHI SINH RA KHI DICH SANG TIENG VIET. "gay 10% sat thuong" tao ra "% s"
    # (co dau cach = co flag), va _vsnprintf trong ParserString_VarParam (UIString.cpp:918) se LAY THEM
    # mot doi so KHONG TON TAI -> doc con tro rac. Tieng Trung khong bao gio mac vi "100%的" - "的" khong
    # phai ky tu chuyen doi. TOK/buckets() KHONG bat duoc vi "% s" co dau cach nen khong thanh token.
    # Chi chan chieu TANG: giam so dac ta thi _vsnprintf chi bo qua doi so thua, khong doc qua.
    if len(PRINTF_SPEC.findall(vi)) > len(PRINTF_SPEC.findall(zh)):
        return 'printf specifiers added'
    if HAN.search(TOK.sub('', vi)):
        return 'han left'
    if '\n' in vi or '\r' in vi or '\t' in vi:
        return 'forbidden whitespace'
    if re.search(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', vi):
        return 'control char'
    if '[[' in vi or ']]' in vi:
        return 'mark left'
    if buckets(zh) != buckets(vi):
        return 'token buckets differ'
    if len(vi) > len(zh) * 14 + 60:
        return 'too long'
    return None


def split_segments(s):
    parts = re.split(r'(#r)', s)
    out = []
    for p in parts:
        if p == '#r' or len(p) <= MAXSEG:
            out.append(p)
            continue
        buf = ''
        for chunk in re.split(r'(?<=[。！？；])', p):
            if len(buf) + len(chunk) > MAXSEG and buf:
                out.append(buf)
                buf = ''
            buf += chunk
        if buf:
            out.append(buf)
    return out


def parse_reply(txt):
    out = {}
    for ln in txt.splitlines():
        m = re.match(r'^\s*(\d+)\s*[\t:>.\-|]+\s*(.*)$', ln)
        if m:
            out[int(m.group(1))] = m.group(2).strip()
    return out


def load_terms():
    if not os.path.exists(TERM):
        return []
    db = sqlite3.connect('file:%s?mode=ro' % TERM.replace('\\', '/'), uri=True)
    terms = []
    for (t,) in db.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall():
        cols = [r[1] for r in db.execute('PRAGMA table_info(%s)' % t)]
        # CYS-I18NRUN (19/09/2026): termbase.db dung `zh_term`/`vi_term`, KHONG phai `term_zh`/`term_vi`
        # (dao chu). Thieu hai ten do thi load_terms() tra ve 0/4.406 thuat ngu, glossary rong,
        # va PROMPT quy tac 3 ("THUAT NGU BAT BUOC") khong bao gio duoc cap du lieu - im lang.
        # Giu ca BON bien the de khong ai phai dat ten thu nam.
        zh = next((c for c in cols if c in ('zh', 'source', 'term_zh', 'zh_term', 'chinese')), None)
        vi = next((c for c in cols if c in ('vi', 'target', 'term_vi', 'vi_term', 'vietnamese')), None)
        if zh and vi:
            terms = db.execute('SELECT %s, %s FROM %s' % (zh, vi, t)).fetchall()
            break
    return [(a, b) for a, b in terms if a and b and HAN.search(a)]


def glossary_for(terms, texts):
    joined = '\n'.join(texts)
    g = [(a, b) for a, b in terms if a in joined]
    g.sort(key=lambda x: -len(x[0]))
    return g[:40]


class Api:
    def __init__(self):
        c = json.load(open(CFG, encoding='utf-8'))
        self.keys = [k for k in (c.get('api_keys') or []) if k] or [c.get('api_key')]
        self.base = c['base_url'].rstrip('/')
        self.model = c.get('model', 'gpt-5.5')
        if os.path.exists(MODEL_FILE):
            m = open(MODEL_FILE, encoding='utf-8').read().strip()
            if m:
                self.model = m
        self.i = 0
        self.lock = threading.Lock()
        self.abort = threading.Event()
        # CYS-I18NRUN (19/09/2026): cong CO THE tra ve `usage`, nhung call() truoc nay chi lay
        # choices[0].message.content roi VUT phan con lai, va api-raw.jsonl chi ghi chuoi noi dung.
        # Nen "ban ghi tho khong co usage" KHONG chung minh duoc "cong khong tra usage" - do thu A
        # roi ket luan ve thu B. Ghi lai o day thi lot goi DAU TIEN sau khi nap tien tra loi dut diem,
        # khong ton them mot luot nao. run() do ra <out>/api-usage.jsonl.
        self.usage = []
        # CYS-I18NRUN: thread-local de handle() lay DUNG usage cua LOI GOI CUA CHINH NO.
        # Ghep theo THU TU giua api-raw.jsonl va api-usage.jsonl la KHONG dang tin (6 luong song song,
        # hai khoa khac nhau) - do la cach toi da khop hoi quy len hai tap lech nhau va ra he so am.
        self.tls = threading.local()

    def call(self, content, timeout=120):
        body = json.dumps({'model': self.model, 'temperature': 0.3,
                           'messages': [{'role': 'user', 'content': content}]}).encode()
        last = None
        for attempt in range(4):
            with self.lock:
                k = self.keys[self.i % len(self.keys)]
                self.i += 1
            req = urllib.request.Request(self.base + '/chat/completions', data=body,
                                         headers={'Content-Type': 'application/json', 'Authorization': 'Bearer ' + k})
            try:
                with urllib.request.urlopen(req, timeout=timeout) as r:
                    d = json.loads(r.read().decode())
                    # CYS-I18NRUN: giu lai muc tieu thu + han muc con lai TRUOC khi vut phan con lai
                    rec = {'usage': d.get('usage'), 'model': d.get('model'),
                           'quota': {k: v for k, v in r.headers.items()
                                     if 'ratelimit' in k.lower() or 'quota' in k.lower()
                                     or 'credit' in k.lower() or 'balance' in k.lower()}}
                    self.tls.last = rec                       # CYS-I18NRUN: ghep chinh xac
                    with self.lock:
                        self.usage.append(rec)
                        # CYS-I18NRUN: ghi NGAY, khong doi cuoi chang - don gia phai biet sau LO DAU
                        if getattr(self, 'usage_path', None):
                            with open(self.usage_path, 'a', encoding='utf-8') as uf:
                                uf.write(json.dumps(rec, ensure_ascii=False) + '\n')
                    text = d['choices'][0]['message']['content']
                    low = text.lower()
                    if 'số dư' in low or 'nạp thêm' in low or 'insufficient' in low or 'billing' in low:
                        self.abort.set()
                        raise RuntimeError('API balance exhausted; stop and top up')
                    return text
            except RuntimeError:
                raise
            except Exception as e:      # network / HTTP: retry with the next key
                last = e
                time.sleep(3 * (attempt + 1))
        raise RuntimeError('API failed 4 times: %s %s' % (type(last).__name__, str(last)[:100]))


# ------------------------------------------------------------------------------------------------ collect
def collect(out_dir=None):
    """-> dict(need={zh: [source tags]}, exclude=set, stats)"""
    stats = collections.OrderedDict()
    extra = GDICT.Extra()
    tm_dict = GDICT.TM(GDICT.DB, GDICT.DROP_DICT)
    tm_code = GDICT.TM(GDICT.DB, GDICT.DROP_CODE)
    need = collections.defaultdict(set)
    # dictionary
    ca = AX.Axp(os.path.join(S4, 'Config.axp'))
    _, raw = ca.payload_full('StrDictionary.txt', 256 << 20)
    ca.f.close()
    _text, dstats, _rows, untr = GDICT.build(raw, GL_DICT)
    for key, zh, _scope in untr:
        need[zh].add('dict')
    stats['dict'] = {k: v for k, v in dstats.items() if k in ('untranslated', 'api', 'tm-clean', 'tm-color_diff',
                                                              'gl-same-zh', 'no-han', 'keys', 'override-key')}
    # layouts + lua
    ia = AX.Axp(os.path.join(S4, 'Interface.axp'))
    texts = set()
    lua_texts = []
    n_lua = n_layout = 0
    for name, _rest in ia.file_list():
        low = name.lower()
        if low.endswith('.layout.xml'):
            n_layout += 1
            _, data = ia.payload_full(name, 32 << 20)
            try:
                if data[:2] in (b'\xff\xfe', b'\xfe\xff'):
                    text = data[2:].decode('utf-16-le' if data[:2] == b'\xff\xfe' else 'utf-16-be')
                elif data[:3] == b'\xef\xbb\xbf':
                    text = data[3:].decode('utf-8')
                else:
                    text = data.decode('utf-8')
            except UnicodeDecodeError:
                continue
            for m in re.finditer(r'<Property\s+Name="(?:Text|Tooltip|ColumnHeader)"\s+Value="([^"]*)"', text):
                if m.group(1) and HAN.search(TOK.sub('', m.group(1))):
                    texts.add(m.group(1))
        elif low.endswith('.lua'):
            n_lua += 1
            _, data = ia.payload_full(name, 32 << 20)
            lua_texts.append(LI.decode_lua(data, LUA.unpack))
    ia.f.close()
    lua_lits, coupled = LI.census(lua_texts)
    exclude = set(coupled)
    layout_hit = {s: v for s, v in GDICT.translate_strings(sorted(texts), extra=extra)[0].items()}
    for s in texts:
        if s not in layout_hit:
            need[s].add('layout')
    lua_free = [s for s in lua_lits if s not in exclude and s.strip() not in exclude]
    lua_hit, lstats = GDICT.translate_strings(sorted(lua_free), extra=extra)
    for s in lua_free:
        if s not in lua_hit:
            need[s].add('lua')
    stats['layout'] = {'files': n_layout, 'han_texts': len(texts), 'translated': len(layout_hit),
                       'untranslated': len(texts) - len(layout_hit)}
    stats['lua'] = {'files': n_lua, 'han_literals': len(lua_lits), 'coupled_excluded': len(exclude),
                    'free': len(lua_free), 'translated': len(lua_hit), 'untranslated': len(lua_free) - len(lua_hit),
                    'by': {k: v for k, v in lstats.items() if k != 'tm_available'}}
    stats['need_distinct'] = len(need)
    stats['need_chars'] = sum(len(z) for z in need)
    os.makedirs(I18N, exist_ok=True)
    with open(EXCL_TSV, 'w', encoding='utf-8', newline='\n') as f:
        f.write('zh\tcontexts\n')
        for zh in sorted(coupled):
            f.write(zh.replace('\t', ' ') + '\t' + ','.join('%s:%d' % kv for kv in sorted(coupled[zh].items())) + '\n')
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
        with open(os.path.join(out_dir, 'need.tsv'), 'w', encoding='utf-8', newline='\n') as f:
            f.write('zh\tsources\n')
            for zh in sorted(need, key=lambda z: (len(z), z)):
                f.write(zh.replace('\t', ' ') + '\t' + ','.join(sorted(need[zh])) + '\n')
        with open(os.path.join(out_dir, 'collect-stats.json'), 'w', encoding='utf-8') as f:
            json.dump(stats, f, ensure_ascii=False, indent=1)
    return need, exclude, stats, tm_dict, tm_code


# ------------------------------------------------------------------------------------------------ run
def append_rows(rows, src):
    when = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
    new = not os.path.exists(API_TSV)
    with open(API_TSV, 'a', encoding='utf-8', newline='\n') as f:
        if new:
            f.write('zh\tvi\tsrc\twhen\n')
        for zh, vi in rows:
            f.write('%s\t%s\t%s\t%s\n' % (zh, vi, src, when))


def rewrite_sorted():
    d = GDICT.load_tsv_dict(API_TSV)
    rows = []
    with open(API_TSV, 'rb') as f:
        for ln in f.read().decode('utf-8').split('\n')[1:]:
            p = ln.rstrip('\r').split('\t')
            if len(p) >= 4 and p[0] in d and d[p[0]] == p[1]:
                rows.append(tuple(p[:4]))
    seen = set()
    with open(API_TSV, 'w', encoding='utf-8', newline='\n') as f:
        f.write('zh\tvi\tsrc\twhen\n')
        for r in sorted(rows):
            if r[0] in seen:
                continue
            seen.add(r[0])
            f.write('\t'.join(r) + '\n')
    return len(seen)


def run(args):
    out_dir = args.out
    need, _exclude, stats, tm_dict, tm_code = collect(out_dir)
    sources = set(args.sources.split(','))
    todo = [z for z in sorted(need, key=lambda z: (len(z), z)) if need[z] & sources]
    if args.max:
        todo = todo[:args.max]
    known = GDICT.load_tsv_dict(API_TSV)
    known.update({z: v for z, (v, _st) in tm_code.map.items()})
    failed = GDICT.load_tsv_dict(FAIL_TSV)
    # segments
    segmap, needseg = {}, []
    for z in todo:
        for seg in split_segments(z):
            if seg == '#r' or seg in segmap:
                continue
            if not HAN.search(TOK.sub('', seg)):
                segmap[seg] = seg
            elif seg in known:
                segmap[seg] = known[seg]
            elif seg.strip() in known:
                i = len(seg) - len(seg.lstrip())
                segmap[seg] = seg[:i] + known[seg.strip()] + seg[len(seg.rstrip()):]
            elif seg in failed and not args.retry_failed:
                segmap[seg] = None
            else:
                needseg.append(seg)
    needseg = list(dict.fromkeys(needseg))
    print('strings %d, segments to call %d (%d chars)' % (len(todo), len(needseg), sum(len(s) for s in needseg)),
          flush=True)
    if not needseg:
        assemble(todo, segmap)
        return
    api = Api()
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
        api.usage_path = os.path.join(out_dir, 'api-usage.jsonl')     # CYS-I18NRUN
    terms = load_terms()
    batches, cur, chars = [], [], 0
    for seg in needseg:
        if cur and (len(cur) >= args.batch or chars + len(seg) > args.chars):
            batches.append(cur)
            cur, chars = [], 0
        cur.append(seg)
        chars += len(seg)
    if cur:
        batches.append(cur)
    lock = threading.Lock()
    done = fail = 0
    raw_path = os.path.join(out_dir, 'api-raw.jsonl') if out_dir else None
    raw_f = open(raw_path, 'a', encoding='utf-8') if raw_path else None
    t0 = time.time()

    def handle(batch):
        nonlocal done, fail
        if api.abort.is_set():
            return
        items = list(enumerate(batch))
        masks = {i: mask(seg) for i, seg in items}
        gl = glossary_for(terms, batch)
        gtxt = ('THUẬT NGỮ BẮT BUỘC:\n' + '\n'.join('%s = %s' % ab for ab in gl) + '\n\n') if gl else ''
        body = '\n'.join('%d\t%s' % (i, masks[i][0]) for i, _ in items)
        try:
            reply = api.call(PROMPT + '\n' + gtxt + 'CÁC DÒNG CẦN DỊCH:\n' + body)
        except RuntimeError as e:
            with lock:
                print('  BATCH ERROR:', str(e)[:120], flush=True)
                fail += len(batch)
            return
        if raw_f:
            with lock:
                # CYS-I18NRUN: dinh kem usage cua CHINH loi goi nay -> khong con phai ghep theo thu tu
                raw_f.write(json.dumps({'req': body, 'resp': reply, 'kind': 'batch',
                                        'nseg': len(batch),
                                        'usage': getattr(api.tls, 'last', None)},
                                       ensure_ascii=False) + '\n')
                raw_f.flush()
        got = parse_reply(reply)
        ok_rows, bad = [], []
        for i, seg in items:
            vi = got.get(i, '')
            vi = unmask(vi, masks[i][1]) if vi else None
            why = validate(seg, vi) if vi else 'missing line / marks'
            if why:
                bad.append((i, seg, why))
            else:
                ok_rows.append((seg, vi))
        for i, seg, why in bad:            # one retry, single string
            if api.abort.is_set():
                break
            m, toks = mask(seg)
            try:
                rep = api.call(PROMPT + '\nLỗi lần trước: %s. Số mốc phải giữ: %d.\nCÁC DÒNG CẦN DỊCH:\n%d\t%s'
                               % (why, len(toks), i, m))
            except RuntimeError:
                break
            # CYS-I18NRUN (19/09/2026): TRUOC DAY chi lan goi theo LO duoc ghi vao api-raw.jsonl, con
            # lan thu lai don le thi khong -> raw co 12 ban ghi trong khi usage co 30, va ai ghep hai
            # tep do lai voi nhau se khop hoi quy len hai tap khac nhau (toi da sap bay do). Ghi ca hai.
            if raw_f:
                with lock:
                    raw_f.write(json.dumps({'req': '%d\t%s' % (i, m), 'resp': rep,
                                            'kind': 'retry', 'why': why, 'nseg': 1,
                                            'usage': getattr(api.tls, 'last', None)},
                                           ensure_ascii=False) + '\n')
                    raw_f.flush()
            vi = parse_reply(rep).get(i) or rep.strip().split('\n')[-1].strip()
            vi = unmask(vi, toks) if vi else None
            why2 = validate(seg, vi) if vi else 'missing line / marks'
            if why2:
                with lock:
                    with open(FAIL_TSV, 'a', encoding='utf-8', newline='\n') as f:
                        if os.path.getsize(FAIL_TSV) == 0:
                            f.write('zh\treason\n')
                        f.write('%s\t%s\n' % (seg.replace('\t', ' '), why2))
                    fail += 1
            else:
                ok_rows.append((seg, vi))
        with lock:
            for seg, vi in ok_rows:
                segmap[seg] = vi
            if ok_rows:
                append_rows(ok_rows, 'api-seg')
            done += len(ok_rows)
            if done % 200 < len(ok_rows) or fail:
                print('  +%d (ok %d, failed %d, %.0f s)' % (len(ok_rows), done, fail, time.time() - t0), flush=True)

    if not os.path.exists(FAIL_TSV):
        open(FAIL_TSV, 'w', encoding='utf-8', newline='\n').write('zh\treason\n')
    threads = []
    for b in batches:
        if api.abort.is_set():
            break
        while len([t for t in threads if t.is_alive()]) >= args.workers:
            time.sleep(0.2)
        t = threading.Thread(target=handle, args=(b,))
        t.start()
        threads.append(t)
        time.sleep(0.15)
    for t in threads:
        t.join()
    if raw_f:
        raw_f.close()
    # CYS-I18NRUN: chi TONG KET. KHONG ghi lai api-usage.jsonl o day - Api.call da ghi tung ban ghi
    # ngay khi no ve. Ban dau toi ghi ca hai cho, va tep co DUNG GAP DOI so ban ghi (27 luot -> 54 dong),
    # lam moi phep tinh token cao gap doi. Mot lan nua: phai dem so dong, dung tin so luot.
    if out_dir and api.usage:
        tot = collections.Counter()
        for rec in api.usage:
            for k, v in (rec.get('usage') or {}).items():
                if isinstance(v, int):
                    tot[k] += v
        have = sum(1 for rec in api.usage if rec.get('usage'))
        print('usage: %d/%d loi goi co du lieu tieu thu%s'
              % (have, len(api.usage), (' | tong ' + ', '.join('%s=%d' % kv for kv in tot.most_common()))
                 if tot else ' (cong KHONG tra ve usage)'), flush=True)
    print('segments ok %d failed %d in %.0f s' % (done, fail, time.time() - t0), flush=True)
    assemble(todo, segmap)
    if api.abort.is_set():
        sys.exit(2)


def assemble(todo, segmap):
    """Whole strings from their segments -> cy_vi_api.tsv (only when every segment is known)."""
    known = GDICT.load_tsv_dict(API_TSV)
    rows = []
    for z in todo:
        if z in known:
            continue
        parts = []
        for seg in split_segments(z):
            if seg == '#r':
                parts.append(seg)
                continue
            vi = segmap.get(seg)
            if vi is None:
                parts = None
                break
            parts.append(vi)
        if parts is None:
            continue
        vi = ''.join(parts)
        if validate(z, vi) is None:
            rows.append((z, vi))
    if rows:
        append_rows(rows, 'api')
    n = rewrite_sorted()
    print('dictionary %s: %d entries (+%d whole strings now)' % (os.path.relpath(API_TSV, REPO), n, len(rows)))


SHORT_PROMPT = (
    'Bạn là dịch giả game kiếm hiệp Thiên Long Bát Bộ. Mỗi dòng dưới là một NHÃN giao diện đã dịch sang tiếng Việt '
    'nhưng QUÁ DÀI so với khung của nó. Hãy viết lại NGẮN HƠN, giữ đúng nghĩa, tự nhiên trong game, tối đa số ký tự '
    'ghi ở cột MAX (đếm cả dấu cách; viết tắt hợp lý nếu cần, ví dụ "Tài khoản" thay "Nhập tài khoản", "MK" chỉ khi '
    'không còn cách nào).\n'
    'QUY TẮC: giữ nguyên vẹn mọi mốc [[0]] [[1]] ... (mã điều khiển), không thêm mốc, không thêm giải thích, không '
    'dấu ngoặc kép, không để sót chữ Hán. Trả về mỗi dòng `ID<TAB>bản rút gọn`, đủ mọi ID.\n')


def shorten(args):
    """Rows of cy_layout_fit.py -> shorter Vietnamese (<= max_chars) into cy_vi_override.tsv (#KEY or zh)."""
    rows = []
    with open(args.fit, 'rb') as f:
        lines = f.read().decode('utf-8').split('\n')
    head = lines[0].rstrip('\r').split('\t')
    for ln in lines[1:]:
        ln = ln.rstrip('\r')
        if not ln:
            continue
        r = dict(zip(head, ln.split('\t')))
        rows.append(r)
    over = GDICT.load_tsv_dict(GDICT.OVERRIDE_TSV)
    todo = [r for r in rows if r['ident'] not in over and r['vi']]
    print('fit rows %d, to shorten %d' % (len(rows), len(todo)), flush=True)
    if not todo:
        return
    api = Api()
    out_rows = []
    fails = []
    for i in range(0, len(todo), 10):
        batch = todo[i:i + 10]
        masks = {k: mask(r['vi']) for k, r in enumerate(batch)}
        body = '\n'.join('%d\tMAX=%s\t%s' % (k, r['max_chars'], masks[k][0]) for k, r in enumerate(batch))
        try:
            reply = api.call(SHORT_PROMPT + '\nCÁC DÒNG (ID, MAX, nhãn):\n' + body)
        except RuntimeError as e:
            print('  BATCH ERROR:', str(e)[:120], flush=True)
            continue
        got = parse_reply(reply)
        for k, r in enumerate(batch):
            vi = got.get(k, '')
            vi = re.sub(r'^MAX=\d+\s*', '', vi).strip()
            vi = unmask(vi, masks[k][1]) if vi else None
            why = validate(r['vi'], vi) if vi else 'missing line / marks'
            if not why and len(TOK.sub('', vi)) > int(r['max_chars']) + 2:
                why = 'still too long (%d > %s)' % (len(TOK.sub('', vi)), r['max_chars'])
            if why:
                fails.append((r['ident'], r['vi'], why))
            else:
                out_rows.append((r['ident'], vi, 'fit %s px %s (%s)' % (r['width_px'], r['layout'], r['window'])))
        print('  %d/%d shortened, %d failed' % (len(out_rows), len(todo), len(fails)), flush=True)
    new = not os.path.exists(GDICT.OVERRIDE_TSV)
    with open(GDICT.OVERRIDE_TSV, 'a', encoding='utf-8', newline='\n') as f:
        if new:
            f.write('ident\tvi\tnote\n')
        for ident, vi, note in out_rows:
            f.write('%s\t%s\t%s\n' % (ident, vi, note))
    if args.out:
        with open(os.path.join(args.out, 'shorten-fail.tsv'), 'w', encoding='utf-8', newline='\n') as f:
            f.write('ident\tvi\treason\n')
            for r in fails:
                f.write('\t'.join(r) + '\n')
    print('override %s: +%d' % (os.path.relpath(GDICT.OVERRIDE_TSV, REPO), len(out_rows)))


def stats_cmd():
    d = GDICT.load_tsv_dict(API_TSV)
    f = GDICT.load_tsv_dict(FAIL_TSV)
    print('api entries', len(d), 'failed', len(f))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('mode', choices=('collect', 'run', 'shorten', 'stats'))
    ap.add_argument('--fit', help='shorten: TSV written by cy_layout_fit.py')
    ap.add_argument('--out', help='evidence directory (need.tsv, collect-stats.json, api-raw.jsonl)')
    ap.add_argument('--max', type=int, default=0)
    ap.add_argument('--workers', type=int, default=6)
    ap.add_argument('--batch', type=int, default=12)
    ap.add_argument('--chars', type=int, default=1100)
    ap.add_argument('--sources', default='dict,layout,lua')
    ap.add_argument('--retry-failed', action='store_true')
    args = ap.parse_args()
    if args.mode == 'collect':
        _need, _ex, stats, _a, _b = collect(args.out)
        print(json.dumps(stats, ensure_ascii=False, indent=1))
    elif args.mode == 'run':
        run(args)
    elif args.mode == 'shorten':
        shorten(args)
    else:
        stats_cmd()


if __name__ == '__main__':
    main()
