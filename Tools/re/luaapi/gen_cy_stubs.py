# -*- coding: utf-8 -*-
"""gen_cy_stubs.py - stubs for the host functions the CY 3.71 UI scripts call and the GL catalog does not have.

Input   Build/Logs/2026-09-14-cy-gui/cy-lua-host-calls.tsv (Build/re/cy-gui/scan_cy_lua.py: receiver, name, calls,
        files, kind, in_catalog, called_in_gl_scripts) and Registry/luaapi/catalog.tsv (known receivers).
Output  Src/Client/LuaApiGen/LuaApiGen_Cy.cpp (+ .h), registered by LuaApiGen::RegisterCyExtras() right after
        RegisterAll(): the stub is only added when the receiver does not already have that name, so every real
        implementation wins, and every call is counted by the same "missing host function" telemetry.

Selection: a (receiver, name) is stubbed when the name is missing from the GL catalog and the receiver is either
_G, a receiver of the GL catalog, or a receiver with at least --min-receiver-calls calls in the CY scripts (so that
local variables and CEGUI control objects of the scripts do not create globals). A receiver that is a window name
of the CY layouts (or `this`) is a CEGUI control: its names are stubbed once on MetaTable_Control_Window (every
control metatable of UILuaControl.cpp aliases that table), never as a global table.

Return values (CY binaries are not decompiled for these) come from how the CY scripts USE the call result
(--lua-root, default Assets/CanonicalCY/Data/InterfaceFolder): a call site compared with a number, used in
arithmetic or as a `for` bound -> number 0; concatenated with `..` or compared with a string -> ""; indexed
(`X().f`, `X()[i]`, `X():m()`) -> the neutral LuaApiGen null object (a table whose __index returns itself);
compared with true/false only -> boolean. Sites with no usable context fall back to the name: Is/Has/Can/... -> 0
(CY host predicates return numbers, e.g. `IsZbs2018SpeicalServer() >= 1`, `SystemSetup:IsClassic() == 1`;
replay-8 of cy-gui failed with "attempt to compare boolean with number" for the old `false` inference),
Get*Num/Count/ID/Level/... -> 0, everything else -> the null object.
"""
import argparse
import collections
import os
import re

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
CALLS = os.path.join(ROOT, 'Build', 'Logs', '2026-09-14-cy-gui', 'cy-lua-host-calls.tsv')
CATALOG = os.path.join(ROOT, 'Registry', 'luaapi', 'catalog.tsv')
OUT_DIR = os.path.join(ROOT, 'Src', 'Client', 'LuaApiGen')
IDENT = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')
BOOLISH = re.compile(r'^(Is|Has|Can|Check|Need|Should)[A-Z_]|^(Lua_?Fn)?(Is|Has|Can)[A-Z]')
NUMBERISH = re.compile(r'(Num|Count|Cnt|Index|ID|Id|Level|Lv|Time|Money|Price|Size|Value|Type|State|Star|Score|Total|Max|Min|Amount|Percent|Exp|Hp|Mp|Flag|Status|Pos|Page)$')


def rets_for(name):
    if BOOLISH.search(name):
        return 'n'          # CY host predicates return 0/1 numbers
    if NUMBERISH.search(name):
        return 'n'
    return 'o'          # neutral null object


# Return VALUES decided from the CY data, not inferred ('1' = number 1, 'N' = number -1):
#  IsClassic -> 1: the CY 3.71 layouts are the classic skin (MainMenuBar_BK, XianShiHuoDongTiShi1_Icon*BK and the other
#  windows of the `IsClassic() == 0` branches exist in no layout; replay-5 failed on them with 0).
#  BieYeFurniture:GetFurCreateInfo(i) -> -1: end of the furniture list (the enumeration loop stops on nId == -1).
VALUE_RETS = {('SystemSetup', 'IsClassic'): '1', ('_G', 'IsClassic'): '1',
              ('BieYeFurniture', 'GetFurCreateInfo'): 'N',
              # formatted into ScriptGlobal_Format / compared with numbers on the CY login screen (LogOn.lua 302)
              ('GameProduceLogin', 'GetSelectLoginServer'): 's', ('GameProduceLogin', 'GetZoneWorldid'): 'n'}
# CY window methods with a known return kind (the rest: 0 for Is/Get*Num..., null object otherwise)
CONTROL_RETS = {'GetText': 's', 'GetName': 's', 'GetType': 's', 'GetProperty': 's', 'IsVisible': 'b',
                'GetWindowSize': 'nn', 'GetPixelRect': 'nnnn', 'GetAlpha': 'n', 'GetItemCount': 'n',
                'GetSelectItem': 'n', 'GetCurrentSelect': 'n', 'GetCheck': 'n', 'GetPosition': 'n',
                'GetToolTip': 's', 'GetPageNum': 'n', 'GetCurPage': 'n', 'GetChildCount': 'n'}
LUA_ROOT_DEFAULT = os.path.join(ROOT, 'Assets', 'CanonicalCY', 'Data', 'InterfaceFolder')
LUA_ROOT_MAIN = r'C:\TLBB\085\CY-Source\Assets\CanonicalCY\Data\InterfaceFolder'
NUM_AFTER = re.compile(r'^\s*(?:>=|<=|>|<|(?:==|~=)\s*-?\d|[-+*/%^]\s*[\w(]|,\s*-?\d+\s+do)')
STR_AFTER = re.compile(r'^\s*(?:\.\.|(?:==|~=)\s*")')
OBJ_AFTER = re.compile(r'^\s*(?:\.[A-Za-z_]|\[|:[A-Za-z_])')
BOOL_AFTER = re.compile(r'^\s*(?:==|~=)\s*(?:true|false)\b')
NUM_BEFORE = re.compile(r'(?:[-+*/%^]|for\s+\w+\s*=\s*[^,\n]+,|(?:>=|<=|>|<)|\d\s*(?:>=|<=|>|<|==|~=))\s*$')
STR_BEFORE = re.compile(r'(?:\.\.|"\s*(?:==|~=))\s*$')


COMMENT_LONG = re.compile(r'--\[(=*)\[.*?\]\1\]', re.S)
COMMENT_LINE = re.compile(r'--[^\n]*')
# whole statement from the line start: the FIRST assigned variable decides (`nId, nName, ... = X:GetInfo(i)`)
ASSIGN_LINE = re.compile(r'^\s*(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*(?:,\s*[A-Za-z_][A-Za-z0-9_.\[\]]*\s*)*=\s*$')
ASSIGN_BEFORE = re.compile(r'(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*(?:,\s*[A-Za-z_][A-Za-z0-9_]*\s*)*=\s*$')


# end-of-list sentinel: `if nId == -1 then break`, `while x ~= -1`, `< 0` -> the stub answers -1 so enumeration loops
# (`while(true) ... X:GetInfo(index) ... if nId == -1 then break`) terminate (BieYeHuanZhuang.lua hung replay-9).
NEG_AFTER = re.compile(r'^\s*(?:(?:==|~=)\s*-\s*1(?![\d.])|<\s*0(?![\d.])|<=\s*-\s*1(?![\d.])|>=\s*0(?![\d.])|>\s*-\s*1(?![\d.]))')


def classify(after, before):
    if NEG_AFTER.search(after):
        return 'N'
    if NUM_AFTER.search(after) or NUM_BEFORE.search(before):
        return 'n'
    if STR_AFTER.search(after) or STR_BEFORE.search(before):
        return 's'
    if OBJ_AFTER.search(after):
        return 'o'
    if BOOL_AFTER.search(after):
        return 'b'
    return None


def skip_call(text, i):
    """i at '(' of the call: index just past the matching ')' (strings/comments are not parsed; good enough)."""
    depth = 0
    for j in range(i, min(len(text), i + 4000)):
        c = text[j]
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
            if depth == 0:
                return j + 1
    return None


def layout_window_names(lua_root):
    """Window names of every CY layout (ascii/utf-8/utf-16), so window receivers get control stubs."""
    names = set()
    pat = re.compile(r'<Window\s+Type="[^"]+"\s+Name="([^"]+)"')
    for dirpath, _dirs, files in os.walk(lua_root):
        for fn in files:
            if not fn.lower().endswith('.layout.xml'):
                continue
            with open(os.path.join(dirpath, fn), 'rb') as f:
                data = f.read()
            if data[:2] in (b'\xff\xfe', b'\xfe\xff'):
                text = data[2:].decode('utf-16-le' if data[:2] == b'\xff\xfe' else 'utf-16-be', 'replace')
            else:
                text = data.decode('utf-8', 'replace')
            names.update(pat.findall(text))
    return names


RUNTIME_CONTROL = re.compile(r'(?:local\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*[A-Za-z_][A-Za-z0-9_\[\]\.]*\s*:\s*'
                             r'(?:AddItemElement|AddChildElement|GetListItemAt|GetSubItem|AddChild|CreateChildWindow)\s*\(')


def runtime_control_vars(lua_root):
    """Variable names the CY scripts assign a run-time created control to."""
    names = set()
    for dirpath, _dirs, files in os.walk(lua_root):
        for fn in files:
            if fn.lower().endswith('.lua'):
                with open(os.path.join(dirpath, fn), 'rb') as f:
                    names.update(RUNTIME_CONTROL.findall(f.read().decode('utf-8', 'replace')))
    return names


def usage_rets(lua_root, wanted):
    """{(receiver, name): rets} from the call sites of the CY scripts (see the module doc)."""
    votes = collections.defaultdict(collections.Counter)
    by_name = collections.defaultdict(list)
    for recv, name in wanted:
        by_name[name].append(recv)
    pattern = re.compile(r'(?<![A-Za-z0-9_])(?:([A-Za-z_][A-Za-z0-9_]*)\s*[.:]\s*)?(' + '|'.join(
        sorted(map(re.escape, by_name), key=len, reverse=True)) + r')\s*\(')
    for dirpath, _dirs, files in os.walk(lua_root):
        for fn in files:
            if not fn.lower().endswith('.lua'):
                continue
            with open(os.path.join(dirpath, fn), 'rb') as f:
                text = f.read().decode('utf-8', 'replace')
            text = COMMENT_LONG.sub(' ', text)
            text = COMMENT_LINE.sub('', text)
            for m in pattern.finditer(text):
                recv, name = m.group(1) or '_G', m.group(2)
                if recv == 'self':
                    recv = 'this'
                if recv not in by_name[name]:
                    continue
                end = skip_call(text, m.end() - 1)
                if end is None:
                    continue
                after = text[end:end + 40]
                before = text[max(0, m.start() - 60):m.start()]
                key = (recv, name)
                kind = classify(after, before)
                if kind is None:
                    # `local v = X(...)` / `v = X(...)`: the first use of v in the following lines decides
                    line_start = text.rfind(chr(10), 0, m.start()) + 1
                    am = ASSIGN_LINE.match(text[line_start:m.start()])
                    if am:
                        var = am.group(1)
                        use = re.compile(r'(?<![A-Za-z0-9_.:])' + re.escape(var) + r'(?![A-Za-z0-9_])')
                        for um in use.finditer(text, end, min(len(text), end + 2500)):
                            kind = classify(text[um.end():um.end() + 40], text[max(0, um.start() - 60):um.start()])
                            if kind:
                                break
                if kind:
                    votes[key][kind] += 1
    out = {}
    for key, v in votes.items():
        for kind in ('N', 'n', 's', 'o', 'b'):
            if v[kind]:
                out[key] = kind
                break
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--calls', default=CALLS)
    ap.add_argument('--catalog', default=CATALOG)
    ap.add_argument('--out', default=OUT_DIR)
    ap.add_argument('--min-receiver-calls', type=int, default=10)
    ap.add_argument('--lua-root', default=LUA_ROOT_DEFAULT if os.path.isdir(LUA_ROOT_DEFAULT) else LUA_ROOT_MAIN,
                    help='CY UI scripts (UTF-8) whose call sites decide the stub return kinds')
    ap.add_argument('--usage-report', help='TSV of (receiver, name, kind, source) for the record')
    args = ap.parse_args()

    known = set()
    known_pairs = set()
    with open(args.catalog, encoding='utf-8') as f:
        for line in f:
            if line.startswith('#'):
                continue
            p = line.rstrip('\n').split('\t')
            if len(p) > 1 and p[0] != 'name':
                known.add(p[1])
                known_pairs.add((p[1], p[0]))

    rows = []
    catalog_named = []
    per_receiver = collections.Counter()
    with open(args.calls, encoding='utf-8') as f:
        next(f)
        for line in f:
            recv, name, calls, files, kind, in_catalog, in_gl = line.rstrip('\n').split('\t')
            if not IDENT.match(name) or not IDENT.match(recv.lstrip('_')):
                continue
            if in_catalog == 'yes':
                catalog_named.append((recv, name, int(calls), int(files)))
                continue
            rows.append((recv, name, int(calls), int(files)))
            per_receiver[recv] += int(calls)
    # The catalog flag of the scan is by NAME only: XBWJHS:IsInBattleScene was skipped because XRZPVP registers that
    # name (replay-5). Such a name still gets a stub on a receiver this generator already serves (a CY receiver that
    # passes the selection below, or a catalog receiver) when the catalog lacks that very pair.
    served = {r for r, c in per_receiver.items() if c >= args.min_receiver_calls} | known
    for recv, name, calls, files in catalog_named:
        if recv in ('_G', 'this') or (recv, name) in known_pairs or recv not in served:
            continue
        rows.append((recv, name, calls, files))

    windows = layout_window_names(args.lua_root) if os.path.isdir(args.lua_root) else set()
    # CYS-CYGUI2: controls created at run time (`local b = List:AddItemElement(...)`, AddChildElement, GetListItemAt,
    # GetSubItem) are CEGUI controls too; their methods (AddTextCatalogTextAndImage, SetAchievementBar*...) belong on
    # MetaTable_Control_Window (SelectServer.lua 2242, replay-6).
    if os.path.isdir(args.lua_root):
        windows |= runtime_control_vars(args.lua_root)
    picked = []
    control = collections.OrderedDict()      # name -> (calls, files) on MetaTable_Control_Window
    for r in rows:
        if r[0] == 'this' or r[0] in windows:
            if r[0] in known:
                continue                    # `this` and named receivers of the GL catalog: stubbed by LuaApiGen
            c = control.get(r[1], (0, 0))
            control[r[1]] = (c[0] + r[2], c[1] + r[3])
        elif r[0] == '_G' or r[0] in known or per_receiver[r[0]] >= args.min_receiver_calls:
            picked.append(r)
    picked += [('MetaTable_Control_Window', name, c[0], c[1]) for name, c in control.items()]
    picked.sort(key=lambda r: (r[0], r[1]))
    groups = collections.OrderedDict()
    for recv, name, calls, files in picked:
        groups.setdefault(recv, []).append((name, calls, files))

    usage = usage_rets(args.lua_root, [(r[0], r[1]) for r in picked if r[0] != 'MetaTable_Control_Window']) \
        if os.path.isdir(args.lua_root) else {}
    kinds = collections.Counter()
    report = []
    body = []
    table = []
    idx = 0
    for recv, items in groups.items():
        body.append('        // receiver %s (%d stubs, %d calls in the CY scripts)' %
                    (recv, len(items), sum(i[1] for i in items)))
        for name, calls, files in items:
            fn = 'LAG_CY_%d' % idx
            rets = VALUE_RETS.get((recv, name)) or usage.get((recv, name))
            if recv == 'MetaTable_Control_Window':
                rets = rets or CONTROL_RETS.get(name)
            source = 'usage' if rets else 'name'
            rets = rets or rets_for(name)
            kinds[source + ':' + rets] += 1
            report.append((recv, name, rets, source))
            body.append('        int %s(LuaPlus::LuaState* s) { return Stub(s, "%s", "%s", "%s"); } '
                        '// calls %d in %d file(s), rets by %s' % (fn, recv, name, rets, calls, files, source))
            table.append('        { "%s", "%s", &%s },' % (recv, name, fn))
            idx += 1

    header = '''// LuaApiGen_Cy.h - GENERATED by CY-Source/Tools/re/luaapi/gen_cy_stubs.py. Do not edit by hand.
#pragma once
#include "LuaPlus.h"

namespace LuaApiGen
{
    //! Stubs for host functions only the CY 3.71 UI scripts call (see the .cpp header comment). Never overrides an
    //! existing function; call right after RegisterAll().
    void RegisterCyExtras(LuaPlus::LuaState* pState);
}
'''
    cpp = '''// LuaApiGen_Cy.cpp - GENERATED by CY-Source/Tools/re/luaapi/gen_cy_stubs.py from
// Build/Logs/2026-09-14-cy-gui/cy-lua-host-calls.tsv (host calls of the %d CY 3.71 UI scripts) and
// Registry/luaapi/catalog.tsv. Do not edit by hand: re-run the generator.
//
// %d stubs on %d receivers: names the CY scripts call and the GL client does not register. Each stub logs
// "missing host function <Receiver>:<Name>" once per session and counts every call, exactly like the GL stubs.
// Return values come from the call sites of the CY scripts (number compare/arithmetic -> 0, concat -> "",
// indexed -> the neutral null object, true/false compare -> false) and otherwise from the name (Is/Has/Can and
// *Num/Count/ID/Level/... -> 0, else the null object); replace a stub with a real implementation as soon as the
// CY system behind it is ported.
#include "LuaApiGen_Cy.h"
#include "LuaApiGen.h"
#include <cstring>

namespace LuaApiGen
{
    namespace
    {
%s

        struct CyStub { const char* receiver; const char* name; int (*fn)(LuaPlus::LuaState*); };
        const CyStub kCyStubs[] = {
%s
        };

        //! Table the functions of \\a receiver live in: a global table, the __index table of a boxed object, or a
        //! new global table when the receiver does not exist yet (CY-only systems).
        bool ResolveReceiver(LuaPlus::LuaObject& globals, const char* receiver, LuaPlus::LuaObject& out)
        {
            if (std::strcmp(receiver, "_G") == 0)
            {
                out = globals;
                return true;
            }
            LuaPlus::LuaObject o = globals.GetByName(receiver);
            if (o.IsTable())
            {
                out = o;
                return true;
            }
            if (o.IsUserData())
            {
                LuaPlus::LuaObject meta = o.GetMetaTable();
                if (!meta.IsTable())
                    return false;
                LuaPlus::LuaObject index = meta.GetByName("__index");
                out = index.IsTable() ? index : meta;
                return true;
            }
            if (o.IsNil())
            {
                out = globals.CreateTable(receiver);
                return true;
            }
            return false;
        }
    }

    void CreateNullObject(LuaPlus::LuaObject& objGlobal);

    void RegisterCyExtras(LuaPlus::LuaState* pState)
    {
        LuaPlus::LuaObject globals = pState->GetGlobals();
        CreateNullObject(globals);   // CYS-CYGUI2: may run before RegisterAll (UI load-time scripts)
        const char* last = 0;
        bool usable = false;
        LuaPlus::LuaObject table;
        for (int i = 0; i < (int)(sizeof(kCyStubs) / sizeof(kCyStubs[0])); ++i)
        {
            const CyStub& s = kCyStubs[i];
            if (!last || std::strcmp(last, s.receiver) != 0)
            {
                usable = ResolveReceiver(globals, s.receiver, table);
                last = s.receiver;
            }
            if (usable && IsMissing(table, s.name))
                table.Register(s.name, s.fn);
        }
    }
}
''' % (2043, len(picked), len(groups), '\n'.join(body), '\n'.join(table))

    with open(os.path.join(args.out, 'LuaApiGen_Cy.h'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(header)
    with open(os.path.join(args.out, 'LuaApiGen_Cy.cpp'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(cpp)
    if args.usage_report:
        with open(args.usage_report, 'w', encoding='utf-8', newline='\n') as f:
            f.write('receiver\tname\trets\tsource\n')
            for r in report:
                f.write('\t'.join(r) + '\n')
    print('stubs', len(picked), 'receivers', len(groups), 'skipped', len(rows) - len(picked),
          'kinds', dict(sorted(kinds.items())))


if __name__ == '__main__':
    main()
