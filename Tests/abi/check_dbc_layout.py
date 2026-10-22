#!/usr/bin/env python3

























import os
import re
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_abi_types as g  # noqa: E402

ROOT = g.ROOT
SRC = os.path.join(ROOT, 'Src')
DEF_DATA = os.path.join(ROOT, 'Assets', 'CanonicalCY', 'Data')
DEF_GL_DATA = os.path.join(ROOT, 'Assets', 'Canonical', 'Data')
# CYS-CY: client_GL tables kept on the CY data set (not in CY 3.71; stage_game.py stages them from Canonical).
# Empty since cs2-world 14/09 (CampAndStand -> ReputationTable.txt, the CY 3.71 camp relation table).
KEEP_GL = {}
# CYS-CY 14/09 ("Mọi thứ như CY"): GUI tables whose struct follows CY 3.71 while Assets/CanonicalCY may still hold the
# client_GL copy (agent cy-gui replaces the GUI layer). Reference = the CY 3.71 text table of S2 (DataCY). When the data
# set still has other columns but the struct matches the reference, the row is PENDING: reported, and a strict failure
# unless --allow-pending is given.
S2_CONFIG = os.path.normpath(os.path.join(ROOT, '..', 'Tools', 'DATA NEW', 'DataCY31-08-26', 'Config'))
if not os.path.isdir(S2_CONFIG):
    S2_CONFIG = r'C:\TLBB\085\Tools\DATA NEW\DataCY31-08-26\Config'
PENDING_CY = {'InterfaceEx.txt': 'CY 3.71 GUI table; agent cy-gui replaces the client_GL copy in CanonicalCY'}
# CYS-CY: tables opened outside OpenAllDataBase: (file, column types the parser requires, parser).
OTHER_TABLES = [
    ('ActionSet/ActionSet.txt', 'IIII', 'Client/WXClient/Action/CysActionSetTable.cpp LoadActionSet'),
    ('ActionSet/ActionSetLine.txt', 'I' * 20, 'CysActionSetTable.cpp LoadActionSetLine (CY: 16 slots + 3 extras)'),
    ('ActionSet/ActionSetKV.txt', 'IS', 'CysActionSetTable.cpp LoadActionSetKV'),
    ('BeHit.txt', 'ISIIIIIIIISSSSFFFFII', 'Client/CEGUISystem/CysBeHitConfig.h BeHitTable::load'),
    ('CityIdOfChina.txt', 'IISSI', 'Client/LuaApiGen/CysProvinceList.cpp Parse'),
]
HEADERS = [
    os.path.join(SRC, 'Shared', 'Common', 'BaseType.h'),
    os.path.join(SRC, 'Shared', 'Common', 'Type.h'),
    os.path.join(SRC, 'Engine', 'Interface', 'TDBasicType.h'),
    os.path.join(SRC, 'Shared', 'Common', 'GameDefine.h'),
    os.path.join(SRC, 'Shared', 'Common', 'GameDefine2.h'),
    os.path.join(SRC, 'Shared', 'Common', 'GameStruct_Skill.h'),
    os.path.join(SRC, 'Shared', 'Common', 'GameStruct_Camp.h'),
    os.path.join(SRC, 'Engine', 'Interface', 'TDDBC_Struct.h'),
]
TABLE_LIST = os.path.join(SRC, 'Client', 'WXClient', 'DBC', 'GMDataBase.cpp')
# { DBC_ID, "file" [, <record size expression>, "SCHEMA" | NULL ] }
TABLE_ROW = re.compile(r'^\s*\{\s*(DBC_\w+)\s*,\s*"([^"]+)"\s*(?:,\s*([^,{}]+?)\s*,\s*(?:"([A-Z]*)"|(NULL))\s*)?\}', re.M)
TYPE_LETTER = {'INT': 'I', 'FLOAT': 'F', 'STRING': 'S'}
# CYS dbc-id-dup 19/09: a DBC id is the key of CDataBaseSystem::m_mapDataBaseBuf, so two tables may never share one.
# Two names on one number is a latent bug even while only one of them is registered: GetDataBase(<the other name>)
# then silently hands back the wrong table and the caller overlays it with the wrong record struct. 0.85 shipped
# exactly that (DBC_LIFEABILITY_DEFINE / DBC_XINFA_XINFADEFINE both 902) and no check saw it.
DBC_DEFINE = re.compile(r'^\s*#\s*define\s+(DBC_\w+)\s+\(?\s*(\d+)\s*\)?\s*$')
DBC_ALIAS = re.compile(r'^\s*#\s*define\s+(DBC_\w+)\s+(DBC_\w+)\s*$')
# DBC_* names that are plain constants, not table ids (no table row, no record struct). Keep this list short and
# auditable: anything else spelled '#define DBC_<NAME> <number>' is treated as a table id.
NON_TABLE_DEFINES = {
    'DBC_XINFA_STUDYSPEND_SLOTS',  # (121) array bound of _DBC_XINFA_STUDYSPEND::StudySpend, not a table
}

BASE = {  # size, kind
    'char': (1, 'num'), 'CHAR': (1, 'num'), 'UCHAR': (1, 'num'), 'BYTE': (1, 'num'), 'bool': (1, 'num'),
    'short': (2, 'num'), 'SHORT': (2, 'num'), 'USHORT': (2, 'num'), 'WORD': (2, 'num'), 'wchar_t': (2, 'num'),
    'int': (4, 'num'), 'INT': (4, 'num'), 'UINT': (4, 'num'), 'unsigned': (4, 'num'), 'long': (4, 'num'),
    'LONG': (4, 'num'), 'ULONG': (4, 'num'), 'DWORD': (4, 'num'), 'BOOL': (4, 'num'), 'float': (4, 'num'),
    'FLOAT': (4, 'num'), 'double': (8, 'num'), '__int64': (8, 'num'),
    'LPCSTR': (0, 'ptr'), 'LPSTR': (0, 'ptr'), 'LPCTSTR': (0, 'ptr'), 'LPTSTR': (0, 'ptr'), 'PCHAR': (0, 'ptr'),
}


class SchemaError(ValueError):
    """Invalid header/types or binary extent; never contains table string payloads."""


class TableSchema:
    def __init__(self, columns, file_format, warnings=None, names=None):
        self.columns = columns
        self.file_format = file_format
        self.warnings = warnings or []
        self.names = names


def _binary_schema(stream, file_size):
    # TLBB_DBC.h FILE_HEAD: four little-endian 32-bit fields, not native pointers.
    stream.seek(0)
    header = stream.read(16)
    if len(header) != 16:
        raise SchemaError('binary-header: truncated 16-byte FILE_HEAD')
    magic, fields, records, string_bytes = struct.unpack('<Iiii', header)
    if magic != 0xDDBBCC00:
        raise SchemaError('binary-header: invalid magic')
    if fields <= 0 or records < 0 or string_bytes < 0:
        raise SchemaError('binary-header: invalid signed field/record/string counts')
    # Python integers cannot wrap. Check every declared extent against the actual
    # file before reading/allocating its type vector; huge corrupt counts stay cheap.
    type_end = 16 + 4 * fields
    record_bytes = 4 * fields * records
    string_start = type_end + record_bytes
    required = string_start + string_bytes
    if type_end > file_size:
        raise SchemaError('binary-types: declared vector exceeds file bounds')
    if string_start > file_size:
        raise SchemaError('binary-records: declared records exceed file bounds')
    if required > file_size:
        raise SchemaError('binary-strings: declared block exceeds file bounds')

    raw_types = stream.read(4 * fields)
    if len(raw_types) != 4 * fields:
        raise SchemaError('binary-types: file changed or vector was truncated')
    names = ('INT', 'FLOAT', 'STRING')
    columns = []
    for index, (kind,) in enumerate(struct.iter_unpack('<I', raw_types)):
        if kind >= len(names):
            raise SchemaError('binary-types: unknown type at column %d' % index)
        columns.append(names[kind])

    warnings = []
    # Inspect offset integers in bounded chunks. No pointer/offset is dereferenced.
    # The runtime clamps out-of-range offsets to zero and forces the last string
    # byte to NUL; report those normalizations without calling them invalid schemas.
    string_columns = {i for i, kind in enumerate(columns) if kind == 'STRING'}
    if string_columns:
        remaining = record_bytes
        cell = 0
        normalized = 0
        first_cells = []
        while remaining:
            block = stream.read(min(65536, remaining))
            if not block or len(block) % 4:
                raise SchemaError('binary-records: file changed or records were truncated')
            for (offset,) in struct.iter_unpack('<I', block):
                if cell % fields in string_columns and offset != 0 and offset >= string_bytes:
                    normalized += 1
                    if len(first_cells) < 4:
                        first_cells.append('%d:%d' % (cell // fields, cell % fields))
                cell += 1
            remaining -= len(block)
        if normalized:
            warnings.append('binary-offset-normalization: count=%d first-row:column=%s (zero-based)' %
                            (normalized, ','.join(first_cells)))
    if string_bytes:
        stream.seek(required - 1)
        last = stream.read(1)
        if not last:
            raise SchemaError('binary-strings: file changed or block was truncated')
        if last != b'\0':
            warnings.append('binary-terminator-normalization: final byte forced to NUL')
    if file_size > required:
        warnings.append('binary-tail: %d trailing bytes ignored by loader' % (file_size - required))
    return TableSchema(columns, 'binary', warnings)


def read_table_schema(path):
    """Read schema without C++ overlays; text rows/INT semantics are not validated.

    Follow TLBB_DBC.cpp:116/267: CR/LF terminates the header; empty tab
    fields are ignored, repeated types remain, whitespace and BOM are not stripped.
    Binary identification uses magic, never the filename extension.
    """
    with open(path, 'rb') as stream:
        file_size = os.fstat(stream.fileno()).st_size
        prefix = stream.read(4)
        magic = b'\x00\xcc\xbb\xdd'
        if prefix == magic or (prefix and magic.startswith(prefix)):
            return _binary_schema(stream, file_size)
        stream.seek(0)
        # The runtime's 10 KiB line buffer has space for at most 10239 bytes + NUL.
        raw = stream.read(10240 * 2)
        ends = [i for i in (raw.find(b'\r'), raw.find(b'\n')) if i >= 0]
        first = raw[:min(ends)] if ends else raw
        if len(first) >= 10240:
            raise SchemaError('text-header: exceeds the loader 10239-byte line capacity')
        if first.startswith((b'\xef\xbb\xbf', b'\xff\xfe', b'\xfe\xff')):
            raise SchemaError('text-header: BOM is not accepted by the runtime loader')
        if b'\0' in first:
            raise SchemaError('text-header: embedded NUL or unrecognized binary magic')
        cells = [cell for cell in first.split(b'\t') if cell]
        if not cells:
            raise SchemaError('text-header: empty column type list')
        names = {b'INT': 'INT', b'FLOAT': 'FLOAT', b'STRING': 'STRING'}
        columns = []
        for index, cell in enumerate(cells):
            if cell not in names:
                raise SchemaError('text-header: unknown type at column %d (no whitespace trimming)' % index)
            columns.append(names[cell])
        # Second header line: column names in B's named tables, a repeat of the types elsewhere (evidence only).
        header_names = None
        rest = raw[len(first):].lstrip(b'\r\n')
        second = rest.split(b'\n', 1)[0].rstrip(b'\r') if rest else b''
        if second:
            parts = second.split(b'\t')
            decoded = []
            for part in parts:
                try:
                    decoded.append(part.decode('gbk'))
                except UnicodeDecodeError:
                    decoded.append(part.decode('utf-8', 'replace'))
            if [p for p in decoded if p] != columns:
                header_names = (decoded + [''] * len(columns))[:len(columns)]
        return TableSchema(columns, 'text', names=header_names)


def load_headers():
    defines = dict(g.PREDEF)
    scanner = g.Scanner()
    typedefs, dbc_ids, dbc_lines = {}, {}, {}
    for path in HEADERS:
        raw = open(path, 'rb').read().decode('utf-8-sig', errors='replace')
        text = g.preprocess(g.join_continuations(g.strip_comments(raw)), defines)
        # CYS: array bounds may be class constants ("static const int MAX_LEVEL = 5;").
        for m in re.finditer(r'\b(?:static\s+const|const\s+static)\s+(?:int|INT)\s+(\w+)\s*=\s*(\d+)\s*;', text):
            defines.setdefault(m.group(1), m.group(2))
        rel = os.path.relpath(path, SRC).replace('\\', '/')
        for i, ln in enumerate(g.strip_comments(raw).split('\n'), 1):
            m = re.match(r'\s*#\s*define\s+(DBC_\w+)\s+\(?\s*(\d+)\s*\)?', ln)
            if m:
                dbc_ids[m.group(1)] = int(m.group(2))
                dbc_lines[m.group(1)] = (rel, i)
        for m in re.finditer(r'\btypedef\s+([\w\s\*]+?)\s*\b(\w+)\s*;', text):
            typedefs[m.group(2)] = m.group(1).strip()
        scanner.scan(g.tokenize(text), rel)
    types = {}
    for t in scanner.types:
        types.setdefault(t['name'].split('::')[-1], t)
    return defines, scanner, types, typedefs, dbc_ids, dbc_lines


def eval_dim(expr, defines):
    e = expr
    for _ in range(8):
        e2 = re.sub(r'\b[A-Za-z_]\w*\b', lambda m: '(%s)' % defines.get(m.group(0), '0'), e)
        if e2 == e:
            break
        e = e2
    e = re.sub(r'\b(0[xX][0-9a-fA-F]+|\d+)[uUlL]+\b', r'\1', e)
    try:
        return int(eval(e, {'__builtins__': {}}, {}))
    except Exception:
        return None


class Layout:
    def __init__(self, ptr):
        self.ptr = ptr
        self.slots = []      # (offset, size, kind, member)
        self.size = 0
        self.align = 1
        self.errors = []


def scalar(tname, typedefs, depth=0):
    tname = tname.strip()
    if tname in BASE:
        return BASE[tname]
    if tname in typedefs and depth < 10:
        base = typedefs[tname]
        if '*' in base:
            return (0, 'ptr')
        words = [w for w in base.split() if w not in ('const', 'volatile', 'signed', 'struct')]
        if words == ['unsigned', 'char']:
            return (1, 'num')
        if words == ['unsigned', 'short']:
            return (2, 'num')
        if words in (['unsigned', 'int'], ['unsigned', 'long'], ['unsigned']):
            return (4, 'num')
        if words:
            return scalar(words[-1], typedefs, depth + 1)
    return None


def layout_of(members, ptr, ctx, member_prefix=''):
    lay = Layout(ptr)
    off = 0
    for (mn, mt, _acc) in members:
        dims = [d for d in re.findall(r'\[([^\]]*)\]', mt)]
        base = re.sub(r'\[[^\]]*\]', '', mt)
        words = [w for w in base.replace('*', ' * ').split() if w not in ('const', 'volatile', 'struct', 'mutable')]
        count = 1
        for d in dims:
            n = eval_dim(d, ctx['defines'])
            if n is None:
                lay.errors.append('%s: cannot evaluate [%s]' % (mn, d))
                n = 1
            count *= n
        if '*' in words:
            elems = [(0, ptr, 'ptr', member_prefix + mn)]
            esize, ealign = ptr, ptr
        else:
            tname = ' '.join(words)
            if words[:1] == ['unsigned'] and len(words) > 1:
                tname = 'unsigned ' + words[-1]
            sc = scalar(words[-1] if words else '', ctx['typedefs']) if tname not in ('unsigned char', 'unsigned short') \
                else ((1, 'num') if tname == 'unsigned char' else (2, 'num'))
            if sc:
                size = sc[0] or ptr
                kind = sc[1]
                elems = [(0, size, kind, member_prefix + mn)]
                esize, ealign = size, size
            else:
                sub_members = ctx['anon'].get(words[-1] if words else '')
                if sub_members is None and words and words[-1] in ctx['types']:
                    sub_members = ctx['types'][words[-1]]['members']
                if sub_members is None:
                    lay.errors.append('%s: unknown type %s' % (mn, mt))
                    continue
                sub = layout_of(sub_members, ptr, ctx, member_prefix + mn + '.')
                lay.errors.extend(sub.errors)
                elems = sub.slots
                esize, ealign = sub.size, sub.align
        off = (off + ealign - 1) // ealign * ealign
        for k in range(count):
            for (o, s, kd, nm) in elems:
                lay.slots.append((off + k * esize + o, s, kd, nm if count == 1 else '%s[%d]' % (nm, k)))
        off += esize * count
        lay.align = max(lay.align, ealign)
    lay.size = (off + lay.align - 1) // lay.align * lay.align if off else 0
    return lay


def record_layout(cols, ptr):
    slots, off, align = [], 0, 4
    for i, c in enumerate(cols):
        size = ptr if c == 'STRING' else 4
        off = (off + size - 1) // size * size
        slots.append((off, size, 'ptr' if c == 'STRING' else 'num', '#%d:%s' % (i, c)))
        off += size
        align = max(align, size)
    return slots, (off + align - 1) // align * align


def compare(struct_members, cols, ptr, ctx):
    lay = layout_of(struct_members, ptr, ctx)
    rec, rec_size = record_layout(cols, ptr)
    for i, (s, r) in enumerate(zip(lay.slots, rec)):
        if s[0] != r[0] or s[1] != r[1] or s[2] != r[2]:
            return ('bad', i, s, r, lay)
    if len(lay.slots) > len(rec):
        return ('long', len(rec), lay.slots[len(rec)], None, lay)
    if len(lay.slots) < len(rec):
        return ('prefix', len(lay.slots), None, None, lay)
    if lay.size != rec_size:
        # CYS: same slots but a different sizeof (tail padding) breaks GetRecordSize() == sizeof(struct)
        return ('bad', len(rec), ('<sizeof>', lay.size, 'size', 'sizeof'), (rec_size, rec_size, 'size', 'record'), lay)
    return ('ok', None, None, None, lay)


def table_list(path=TABLE_LIST):
    """(dbc id, file, record size expression or None, schema string or None, absent flag) per OpenAllDataBase row."""
    src = open(path, encoding='utf-8-sig', errors='replace').read()
    rows = []
    for m in TABLE_ROW.finditer(src):
        rows.append((m.group(1), m.group(2), m.group(3), m.group(4), m.group(5) is not None))
    return rows


def rel_gl(path):
    return os.path.relpath(path, ROOT).replace(os.sep, '/')


def scan_dbc_ids(paths):
    """({number: [(name, file, line)]}, [(alias, target, file, line)]) for the '#define DBC_*' of paths."""
    ids, aliases = {}, []
    for path in paths:
        raw = open(path, 'rb').read().decode('utf-8-sig', errors='replace')
        rel = rel_gl(path)
        for i, ln in enumerate(g.strip_comments(raw).split('\n'), 1):
            m = DBC_DEFINE.match(ln)
            if m and m.group(1) not in NON_TABLE_DEFINES:
                ids.setdefault(int(m.group(2)), []).append((m.group(1), rel, i))
                continue
            m = DBC_ALIAS.match(ln)
            if m:
                aliases.append((m.group(1), m.group(2), rel, i))
    return ids, aliases


def dbc_id_report(paths):
    """Prints the DBC id census of paths; returns the list of numbers claimed by more than one name."""
    ids, aliases = scan_dbc_ids(paths)
    duplicates = sorted(n for n, owners in ids.items() if len(owners) > 1)
    for number in duplicates:
        print('DBC ID DUPLICATE: %d claimed by %s' % (number, ', '.join(
            '%s (%s:%d)' % owner for owner in ids[number])))
    for alias, target, rel, line in aliases:
        print('dbc id alias: %s = %s (%s:%d)' % (alias, target, rel, line))
    print('dbc ids: %d number(s), %d name(s), %d alias(es), %d duplicate(s)' % (
        len(ids), sum(len(o) for o in ids.values()), len(aliases), len(duplicates)))
    return duplicates


def main():
    argv = sys.argv[1:]
    options = {}
    for key in ('--out', '--columns', '--data', '--gl-data'):
        if key in argv:
            i = argv.index(key)
            options[key] = argv[i + 1]
            del argv[i:i + 2]
    strict = '--strict' in argv
    allow_pending = '--allow-pending' in argv
    args = [a for a in argv if not a.startswith('--')]
    # CYS dbc-id-dup 19/09: id census on its own. Positional args replace HEADERS, so the test can point it at a
    # header that deliberately reuses a number and prove this gate really goes red (nonzero exit) for it.
    if '--check-dbc-ids' in argv:
        return 1 if dbc_id_report(args or HEADERS) else 0
    data = options.get('--data') or (args[0] if args else DEF_DATA)
    gl_data = options.get('--gl-data') or DEF_GL_DATA
    defines, scanner, types, typedefs, dbc_ids, dbc_lines = load_headers()
    ctx = {'defines': defines, 'types': types, 'typedefs': typedefs, 'anon': scanner.anon}

    # struct per DBC id: _DBC_<suffix> by name, else the first struct defined after the #define in the same file
    by_line = sorted([(t['file'], t['line'], t['name'].split('::')[-1]) for t in scanner.types])
    define_seq = sorted([(f, l, n) for n, (f, l) in dbc_lines.items()])

    aliases = {'DBC_DIRECTLY_IMPACT': '_DBC_DIRECT_IMPACT',  # typedef _DBC_DIRECT_IMPACT SDirectImpact
               # CYS: _DBC_CHARACTER_ACTION_SET is the 13-column per-model action-set file record (CActionSetMgr);
               # CYS: the CharActionSet.txt table itself has 10 columns.
               'DBC_CHARACTER_ACTION_SET': '_DBC_CHAR_ACTION_SET_TABLE'}

    def struct_for(dbc):
        cand = aliases.get(dbc, '_' + dbc)
        if cand in types:
            return cand
        if dbc not in dbc_lines:
            return None
        f, l = dbc_lines[dbc]
        nxt = min([dl for (df, dl, dn) in define_seq if df == f and dl > l] or [10 ** 9])
        for (tf, tl, tn) in by_line:
            if tf == f and l < tl < nxt:
                return tn
        return None

    def index(root):
        found = {}
        config = os.path.join(root, 'ConfigFolder')
        base = config if os.path.isdir(config) else root
        for dirpath, _dirs, fnames in os.walk(base):
            for fn in fnames:
                full = os.path.join(dirpath, fn)
                found.setdefault(fn.lower(), full)
                found.setdefault(os.path.relpath(full, base).replace(os.sep, '/').lower(), full)
        return found

    files = index(data)
    gl_files = index(gl_data) if os.path.isdir(gl_data) else {}

    rows = ['table\tfile\tstruct\tcolumns\tx86\tx64\tschema\tdetail']
    column_rows = ['table\tfile\tstruct\tcolumn\ttype\tx64_offset\tmember\tdata_name']
    counts = {}
    schema_counts = {}
    gate_failures = []
    invalid_schemas = 0
    for dbc, fname, size_expr, schema_text, absent in table_list():
        # CYS: the table list names its record struct (sizeof(...)); older lists fall back to the _DBC_<id> name rule
        named = re.match(r'sizeof\s*\(\s*(\w+)\s*\)$', size_expr or '')
        st = named.group(1) if named and named.group(1) in types else struct_for(dbc)
        path = files.get(fname.lower())
        kept = None
        if not path and fname in KEEP_GL and gl_files.get(fname.lower()):
            path = kept = gl_files[fname.lower()]
        alt = None
        if not path and not absent:
            base, ext = os.path.splitext(fname)
            alt = files.get((base + 'Ex' + ext).lower())
        use = path or alt
        schema = None
        schema_state = '-'
        if not use:
            status86 = status64 = 'ABSENT' if absent else 'MISSING'
            schema_state = 'ABSENT' if absent else '-'
            detail = ('absent from the data set' if absent else 'file not in data set')
            ncols = 0
        else:
            try:
                schema = read_table_schema(use)
            except (SchemaError, OSError) as error:
                status86 = status64 = 'INVALID'
                invalid_schemas += 1
                ncols = 0
                detail = str(error) if isinstance(error, SchemaError) else 'schema-read: file unavailable'
            cols = schema.columns if schema else []
            if schema:
                ncols = len(cols)
            if schema and not st:
                status86 = status64 = 'NOSTRUCT'
                detail = 'no record struct found (table read column by column?)'
            elif schema:
                r86 = compare(types[st]['members'], cols, 4, ctx)
                r64 = compare(types[st]['members'], cols, 8, ctx)
                status86, status64 = r86[0].upper(), r64[0].upper()
                d = []
                for arch, r in (('x86', r86), ('x64', r64)):
                    if r[0] == 'bad':
                        d.append('%s slot %d: struct %s %s@%d vs column %s@%d' % (
                            arch, r[1], r[2][3], r[2][2], r[2][0], r[3][3], r[3][0]))
                    elif r[0] == 'long':
                        d.append('%s: struct has %d slots, table %d columns' % (arch, len(r[4].slots), ncols))
                    if r[4].errors:
                        d.append('%s: %s' % (arch, '; '.join(r[4].errors[:3])))
                data_schema = ''.join(TYPE_LETTER[c] for c in cols)
                if absent:
                    schema_state = 'UNEXPECTED'
                    d.append('table list marks it absent but the file exists')
                elif schema_text is not None:
                    schema_state = 'OK' if schema_text == data_schema else 'DIFF'
                    if schema_state == 'DIFF':
                        d.append('table list schema %s != data %s' % (schema_text, data_schema))
                    ref = os.path.join(S2_CONFIG, fname)
                    if schema_state == 'DIFF' and fname in PENDING_CY and os.path.isfile(ref):
                        ref_cols = read_table_schema(ref).columns
                        ref_schema = ''.join(TYPE_LETTER[c] for c in ref_cols)
                        ok86 = compare(types[st]['members'], ref_cols, 4, ctx)[0]
                        ok64 = compare(types[st]['members'], ref_cols, 8, ctx)[0]
                        if ref_schema == schema_text and ok86 == 'ok' and ok64 == 'ok':
                            status86 = status64 = schema_state = 'PENDING'
                            d.append('struct OK against the CY 3.71 reference %s (%s)' % (
                                rel_gl(ref), PENDING_CY[fname]))
                detail = ' | '.join(d)
                slots = r64[4].slots
                offsets = record_layout(cols, 8)[0]
                for index, column in enumerate(cols):
                    member = slots[index][3] if index < len(slots) else '-'
                    name = (schema.names[index] if schema.names and index < len(schema.names) else '')
                    column_rows.append('\t'.join([dbc, fname, st, str(index), column, str(offsets[index][0]), member,
                                                  name.replace('\t', ' ')]))
            if schema and (schema.file_format == 'binary' or schema.warnings):
                detail = ' | '.join([part for part in
                                    [detail, 'format=' + schema.file_format] + schema.warnings if part])
            if kept:
                detail = ('client_GL table kept (%s): %s; ' % (KEEP_GL[fname], rel_gl(kept))) + detail
            if alt and not path:
                detail = ('0.85 name missing, using %s; ' % os.path.basename(alt)) + detail
                status86 = 'ALT-' + status86
                status64 = 'ALT-' + status64
        counts[status64] = counts.get(status64, 0) + 1
        schema_counts[schema_state] = schema_counts.get(schema_state, 0) + 1
        passing = ('OK', 'ABSENT', 'PENDING') if allow_pending else ('OK', 'ABSENT')
        if status86 not in passing or status64 not in passing or schema_state not in passing:
            gate_failures.append(fname)
        rows.append('\t'.join([dbc, fname, st or '-', str(ncols), status86, status64, schema_state, detail]))
    other_ok = 0
    for fname, expected, parser in OTHER_TABLES:
        path = files.get(fname.lower())
        got = ''
        if not path:
            state, detail = 'MISSING', 'file not in data set'
        else:
            try:
                schema = read_table_schema(path)
                got = ''.join(TYPE_LETTER[c] for c in schema.columns)
                state = 'OK' if got == expected else 'DIFF'
                detail = 'parser %s | format=%s' % (parser, schema.file_format)
                if state == 'DIFF':
                    detail = 'parser expects %s, data %s | ' % (expected, got) + detail
            except (SchemaError, OSError) as error:
                state, detail = 'INVALID', str(error)
        if state == 'OK':
            other_ok += 1
        else:
            gate_failures.append(fname)
        counts['other-' + state] = counts.get('other-' + state, 0) + 1
        rows.append('\t'.join(['-other-', fname, '-', str(len(got)), state, state, state, detail]))
    present = sum(1 for r in rows[1:] if r.split('\t')[5] == 'OK')
    pending = [r.split('\t')[1] for r in rows[1:] if r.split('\t')[5] == 'PENDING']
    kept_ok = sum(1 for r in rows[1:] if r.split('\t')[5] == 'OK' and 'client_GL table kept' in r)
    text = '\n'.join(rows) + '\n'
    if options.get('--out'):
        with open(options['--out'], 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
    if options.get('--columns'):
        with open(options['--columns'], 'w', encoding='utf-8', newline='\n') as f:
            f.write('\n'.join(column_rows) + '\n')
    sys.stdout.write(text)
    print('x64 status counts:', ', '.join('%s=%d' % kv for kv in sorted(counts.items())))
    print('schema counts:', ', '.join('%s=%d' % kv for kv in sorted(schema_counts.items())))
    print('tables OK: %d = OpenAllDataBase %d (CY %d + client_GL kept %d) + other loaders %d/%d; data %s' % (
        present, present - other_ok, present - other_ok - kept_ok, kept_ok, other_ok, len(OTHER_TABLES), data))
    if pending:
        print('pending CY data (struct matches the CY 3.71 reference, data set not yet CY): ' + ' '.join(pending))
    # CYS dbc-id-dup 19/09: the table rows above compare struct vs data; they can never see two #defines sharing one
    # id (the second name is simply never registered). That census is this one, and --strict fails on it.
    dbc_duplicates = dbc_id_report(HEADERS)
    if invalid_schemas:
        return 1
    if strict:
        print('strict gate: %s (%d table(s) not OK/ABSENT%s%s)' % (
            'FAIL' if (gate_failures or dbc_duplicates) else 'PASS', len(gate_failures),
            (': ' + ' '.join(gate_failures)) if gate_failures else '',
            (('; duplicate DBC id: ' + ' '.join(str(n) for n in dbc_duplicates)) if dbc_duplicates else '')))
        return 1 if (gate_failures or dbc_duplicates) else 0
    return 0


if __name__ == '__main__':
    sys.exit(main())
