"""cy_lua_i18n.py - Vietnamese display literals in the CY 3.71 UI scripts (cy-gui-2, 14/09/2026).

Port of analysis/translation/manifest/lua_lexer.py + the context rules of apply_clientlua.py (translation pipeline
of the big project, 24/08/2026) so that build_canonical_cy.py can translate the Lua literals of the CY GUI layer
without the WSL pipeline. Only double-quoted string literals ("...") that contain Han characters outside TLBB tokens
are candidates; a literal is left alone when its call site couples it to code:

  cmp      `== "..."` / `"..." ~=`                          (compared with server/host strings)
  index    `t["..."]`                                        (table key)
  strfn    argument of string.find/gsub/gfind/match/len/sub  (pattern / measured text)
  nameapi  argument of AutoRuntoTargetExWithName / AxTrace   (lookup name / debug trace)
  blackvar assigned to g_Name*/npcname/... (server lookup names)
  custom   inside g_Custom*/g_SignPost table constructors
  excluded in the global exclusion set (a literal coupled somewhere is excluded everywhere: same string, same
           semantics - cy_translate.py collects it from every CY script)

After a replacement the token stream must be identical except for the replaced literals (verify_lex_equal).
"""
import re
from collections import Counter

HAN = re.compile(r'[\u4e00-\u9fff]')
# CYS-I18NRUN (19/09/2026): ban SAO cua cy_gui_dict.TOK - phai giu GIONG HET no, ke ca `\d?` moi them
# (chi so doi so "%s0"; xem chu thich day du o cy_gui_dict.py).
TOK = re.compile(r'#[cC][0-9a-fA-F]{6}|#\{[^}]*\}|#[A-Za-z]|%\d*[a-zA-Z]\d?|\$\d+\$|\$[A-Za-z](?![A-Za-z0-9_])')
NAPI = re.compile(r'\b(AutoRuntoTargetExWithName|AxTrace)\s*\([^()]*$')
STRFN = re.compile(r'\b(?:string\.(?:find|gsub|gfind|match|len|sub|byte)|strfind|strlen|strsub)\s*\([^()]*$')
BVAR = re.compile(r'(?:^|[^\w])(?:\w+_)?(g_Name\d*|npcname|g_AccomplishNPC_Name\d*|g_AcceptNPC_Name\d*|'
                  r'g_TargetNpcName\w*|g_szMonsterName|g_CopySceneName)\s*=\s*$')
TBLVAR = re.compile(r'(?:\w+_)?(g_Custom\d*|g_SignPost)\s*=\s*\{')


def _long_bracket(text, i):
    j = i + 1
    lv = 0
    while j < len(text) and text[j] == '=':
        lv += 1
        j += 1
    if j < len(text) and text[j] == '[':
        return lv, j + 1
    return None, i


def _skip_long(text, i, lv):
    close = ']' + '=' * lv + ']'
    k = text.find(close, i)
    return len(text) if k < 0 else k + len(close)


def lex(text):
    """yield (kind, start, end): kind in code|comment|dstring|sstring|lstring; spans cover the whole text."""
    n = len(text)
    i = 0
    code_start = 0
    while i < n:
        c = text[i]
        if c == '-' and text[i:i + 2] == '--':
            if code_start < i:
                yield ('code', code_start, i)
            j = i + 2
            lv, k = (None, j)
            if j < n and text[j] == '[':
                lv, k = _long_bracket(text, j)
            if lv is not None:
                end = _skip_long(text, k, lv)
            else:
                e = text.find('\n', i)
                end = n if e < 0 else e
            yield ('comment', i, end)
            i = end
            code_start = i
        elif c == '"' or c == "'":
            if code_start < i:
                yield ('code', code_start, i)
            q = c
            j = i + 1
            while j < n:
                if text[j] == '\\':
                    j += 2
                    continue
                if text[j] == q or text[j] == '\n':
                    break
                j += 1
            end = min(j + 1, n) if j < n and text[j] == q else min(j, n)
            yield ('dstring' if q == '"' else 'sstring', i, end)
            i = end
            code_start = i
        elif c == '[':
            lv, k = _long_bracket(text, i)
            if lv is not None:
                if code_start < i:
                    yield ('code', code_start, i)
                end = _skip_long(text, k, lv)
                yield ('lstring', i, end)
                i = end
                code_start = i
            else:
                i += 1
        else:
            i += 1
    if code_start < n:
        yield ('code', code_start, n)


def escape_lua(s):
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')


def unescape_lua(s):
    out = []
    i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            c = s[i + 1]
            out.append({'n': '\n', 't': '\t', 'r': '\r', '"': '"', "'": "'", '\\': '\\'}.get(c, '\\' + c))
            i += 2
        else:
            out.append(s[i])
            i += 1
    return ''.join(out)


def custom_ranges(text):
    out = []
    for m in TBLVAR.finditer(text):
        start = m.end() - 1
        depth = 0
        pos_end = None
        for k, s, e in lex(text):
            if e <= start or k != 'code':
                continue
            for i in range(max(s, start), e):
                if text[i] == '{':
                    depth += 1
                elif text[i] == '}':
                    depth -= 1
                    if depth == 0:
                        pos_end = i + 1
                        break
            if pos_end:
                break
        out.append((m.start(), pos_end or len(text)))
    return out


def site_context(text, s, e, cust):
    """Why the literal text[s:e] ("..." span) is coupled to code at this site, or None (free display text)."""
    ls = text.rfind('\n', 0, s) + 1
    prefix = text[ls:s]
    le = text.find('\n', e)
    suffix = text[e:le if le > 0 else len(text)]
    if re.search(r'(==|~=)\s*$', prefix) or re.match(r'\s*(==|~=)', suffix):
        return 'cmp'
    if re.search(r'\[\s*$', prefix) and re.match(r'\s*\]', suffix):
        return 'index'
    if STRFN.search(prefix):
        return 'strfn'
    if NAPI.search(prefix):
        return 'nameapi'
    if BVAR.search(prefix):
        return 'blackvar'
    if any(a <= s < b for a, b in cust):
        return 'custom'
    return None


def literals(text):
    """[(content, start, end, context)] for every double-quoted literal with Han outside tokens."""
    cust = custom_ranges(text) if ('g_Custom' in text or 'g_SignPost' in text) else []
    out = []
    for kind, s, e in lex(text):
        if kind != 'dstring' or e - s < 2 or text[e - 1] != '"':
            continue
        content = text[s + 1:e - 1]
        if not HAN.search(TOK.sub('', content)):
            continue
        out.append((content, s, e, site_context(text, s, e, cust)))
    return out


def decode_lua(data, unpack):
    """CY Lua bytes (packed or plain, GBK or UTF-8) -> str; unpack = cy_lua_unpack.unpack."""
    plain = unpack(data)
    if plain is not None:
        data = plain
    for enc in ('utf-8', 'gbk', 'gb18030'):
        try:
            return data.decode(enc)
        except UnicodeDecodeError:
            continue
    return data.decode('utf-8', 'replace')


def census(texts):
    """texts: iterable of Lua source str -> (free Counter{literal: sites}, coupled {literal: Counter{context: n}}).
    A literal coupled to code at any site is excluded everywhere (same string, same semantics)."""
    free = Counter()
    coupled = {}
    for text in texts:
        for content, _s, _e, ctx in literals(text):
            if ctx:
                coupled.setdefault(content, Counter())[ctx] += 1
            else:
                free[content] += 1
    return free, coupled


def translate(text, lookup, excluded=frozenset()):
    """Replace free display literals through lookup(content) -> vi | None. Returns (new_text, n, stats Counter).
    Raises ValueError when the token stream after the replacement is not the expected one."""
    stats = Counter()
    out = []
    last = 0
    pairs = []
    for content, s, e, ctx in literals(text):
        if ctx:
            stats[ctx] += 1
            continue
        if content in excluded or content.strip() in excluded:
            stats['excluded'] += 1
            continue
        vi = lookup(content)
        if vi is None or vi == content:
            stats['untranslated'] += 1
            continue
        if '\n' in vi or '\r' in vi:
            stats['rejected-newline'] += 1
            continue
        out.append(text[last:s + 1])
        out.append(escape_lua(vi))
        out.append('"')
        last = e
        pairs.append((content, vi))
        stats['translated'] += 1
    if not pairs:
        return text, 0, stats
    out.append(text[last:])
    new_text = ''.join(out)
    ok, err = verify_lex_equal(text, new_text, pairs)
    if not ok:
        raise ValueError(err)
    return new_text, len(pairs), stats


def verify_lex_equal(old_text, new_text, expect_pairs):
    ta = list(lex(old_text))
    tb = list(lex(new_text))
    if len(ta) != len(tb):
        return False, 'token count differs: %d != %d' % (len(ta), len(tb))
    want = Counter(expect_pairs)
    for (ka, sa, ea), (kb, sb, eb) in zip(ta, tb):
        if ka != kb:
            return False, 'token kind differs at %d: %s -> %s' % (sa, ka, kb)
        a = old_text[sa:ea]
        b = new_text[sb:eb]
        if ka != 'dstring':
            if a != b:
                return False, 'token %s at %d changed' % (ka, sa)
        else:
            ca = a[1:-1] if len(a) >= 2 else a
            cb = b[1:-1] if len(b) >= 2 else b
            if ca != cb:
                key = (ca, unescape_lua(cb))
                if want.get(key, 0) <= 0:
                    return False, 'unexpected dstring change at %d: %r' % (sa, ca[:30])
                want[key] -= 1
    if +want:
        return False, 'missing %d expected replacements' % sum(want.values())
    return True, ''
