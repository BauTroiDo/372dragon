#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""cys_uifix2_actionmethods.py  (CYS-UIFIX2)

LOP LOI THU SAU - khong bo quet nao dang co mo hinh hoa no.

CY tra ve doi tuong CActionItem qua metatable `ActionButtonMetaTable`
(GMScriptSystm.cpp, `CActionItem::s_pMetaTable->RegisterObjectFunctor(...)`).
Metatable ay co MOT SO HUU HAN phuong thuc.  Script CY lai goi tren CUNG loai
doi tuong ay nhieu ten phuong thuc KHAC.  Tren doi tuong THAT, ten khong co
trong metatable = `nil` => "attempt to call method (a nil value)" => chet ham.

Truoc day khong ai thay vi stub `CreateActionItemForShow` tra NULL-OBJECT, ma
`NullIndex` tra ve MOT HAM cho MOI ten => moi loi goi deu "chay" (khong lam gi).
Bo bat dau tra doi tuong THAT thi lop loi nay LO RA.  Vi vay phai do TRUOC,
khong phai sau.

Do cai gi:
  1. Tap phuong thuc CO trong metatable CActionItem (doc thang tu C++).
  2. Moi bien Lua duoc gan tu mot ham TAO ACTION, va moi ten phuong thuc goi
     tren bien do.
  3. Hieu hai tap = danh sach se NEM, kem file/dong/khung.

Doi chung am bat buoc: --self-test.  ASCII only trong ma nguon.
"""
import argparse
import io
import json
import os
import re

META_RE = re.compile(r'CActionItem::s_pMetaTable->RegisterObjectFunctor\(\s*"([A-Za-z_]\w*)"')
# Cac chuoi LOAI action ma CActionSystem::EnumAction co the khop
# (`_stricmp(it->second->GetType_String(), szFilter)`), khai o dau GMActionSystem.cpp.
NAMETYPE_RE = re.compile(r'NAMETYPE_[A-Z0-9_]+\s*=\s*"([^"]+)"')

# Cac ham TAO/LAY mot doi tuong action that (deu day CActionItem qua BoxPointer).
PRODUCERS = (
    "CreateActionItemForShow",
    "CreateBindActionItemForShow",
    "EnumAction",
    "GetActionItem",
)
ASSIGN_RE = re.compile(
    r'(?m)^[^\n]*?\b(?:local\s+)?([A-Za-z_]\w*)\s*=\s*[^\n]*?\b(%s)\s*\(([^)\n]*)' % "|".join(PRODUCERS))
# EnumAction(0, "fittingitemdress") -> doi so LOC la doi so thu hai, neu la chuoi tran.
FILTER_RE = re.compile(r'^\s*[^,]*,\s*"([^"]*)"\s*$')
# EnumAction(0, GOODS_CONTAINERTYPE[i]) / EnumAction(0, TEN_BIEN) -> lay TEN de tra bang.
FILTER_VAR_RE = re.compile(r'^\s*[^,]*,\s*([A-Za-z_]\w*)\s*(?:\[[^\]]*\])?\s*$')
# local GOODS_CONTAINERTYPE = { "fittingitemhairstyle", "fittingitemfacestyle", ... }
TABLE_RE = re.compile(
    r'(?m)^\s*(?:local\s+)?([A-Za-z_]\w*)\s*=\s*\{([^{}]*)\}', re.S)
STR_RE = re.compile(r'"([^"\n]*)"')
# local GOODS_CONTAINERTYPE_BY_STR = "fittingitemhuanling"
SCALAR_RE = re.compile(r'(?m)^\s*(?:local\s+)?([A-Za-z_]\w*)\s*=\s*"([^"\n]+)"\s*;?\s*$')


def string_tables(text):
    """{ten_bang: set(chuoi tran ben trong)} cho cac bang chi chua chuoi.

    Dung de tra `EnumAction(0, GOODS_CONTAINERTYPE[i])` ve tap 7 chuoi that su co the
    duoc truyen vao.  Neu KHONG chuoi nao trong tap la mot loai action co that thi
    loi goi ay KHONG BAO GIO cham toi mot doi tuong action that.
    """
    out = {}
    for m in TABLE_RE.finditer(text):
        body = m.group(2)
        vals = STR_RE.findall(body)
        # chi nhan bang THUAN chuoi: bo phan chu thich roi khong con gi ngoai chuoi/dau phay
        stripped = re.sub(r'--[^\n]*', '', body)
        stripped = STR_RE.sub('', stripped)
        if vals and not re.search(r'[A-Za-z0-9_]', stripped):
            out[m.group(1)] = set(vals)
    # ... va ca bien VO HUONG: local GOODS_CONTAINERTYPE_BY_STR = "fittingitemhuanling"
    for m in SCALAR_RE.finditer(text):
        out.setdefault(m.group(1), set()).add(m.group(2))
    return out


def read_text(path):
    with open(path, "rb") as fh:
        return fh.read().decode("utf-8", errors="replace")


def metatable_methods(cpp_path):
    text = read_text(cpp_path)
    start = text.find("CActionItem::s_pMetaTable = new")
    if start < 0:
        return set()
    return set(META_RE.findall(text[start:start + 6000]))


def scan_lua(text, span):
    """Tra ve [(var, producer, assign_line, method, use_line, dong, filter, co_phep_canh)].

    `filter`      : doi so loc cua EnumAction neu la CHUOI TRAN, nguoc lai None.
    `co_phep_canh`: co mot dong `<var>:GetID() ~= 0` nam GIUA cho gan va cho dung hay khong.
                    Cu nem chi xay ra khi doi tuong la THAT; neu loi goi nam SAU phep canh
                    `GetID() ~= 0` thi voi `s_InvalidAction` (GetID = 0) no KHONG BAO GIO chay.
    """
    lines = text.splitlines()
    tables = string_tables(text)
    out = []
    for m in ASSIGN_RE.finditer(text):
        var, producer = m.group(1), m.group(2)
        raw = m.group(3) or ""
        fm = FILTER_RE.match(raw)
        if fm:
            filt = frozenset([fm.group(1)])
        else:
            vm = FILTER_VAR_RE.match(raw)
            filt = frozenset(tables[vm.group(1)]) if (vm and vm.group(1) in tables) else None
        aline = text.count("\n", 0, m.start()) + 1
        guard_re = re.compile(r'\b%s\s*:\s*GetID\s*\(\s*\)\s*[~=]=\s*0' % re.escape(var))
        guard_line = None
        for j in range(aline, min(len(lines), aline + span)):
            if guard_re.search(lines[j]):
                guard_line = j + 1
                break
        # BAY DA SAP THAT (20/09): `\bvar:` khop CA `uidata.action:SetActionItem(...)`, trong do
        # receiver la mot WIDGET chu khong phai bien action. Phai chan ky tu `.` (va `:`) ngay
        # truoc ten bien, neu khong bo do bao oan dung 2 khung va ket luan nguoc han.
        call_re = re.compile(r'(?<![\w.:])%s\s*:\s*([A-Za-z_]\w*)\s*\(' % re.escape(var))
        for i in range(aline, min(len(lines), aline + span)):
            # gan lai bien tu mot nguon KHAC thi ngung theo doi
            if re.search(r'(?m)^\s*(?:local\s+)?%s\s*=' % re.escape(var), lines[i]) \
               and not re.search(r'\b(?:%s)\s*\(' % "|".join(PRODUCERS), lines[i]):
                break
            for mm in call_re.finditer(lines[i]):
                guarded = guard_line is not None and guard_line <= i + 1
                out.append((var, producer, aline, mm.group(1), i + 1,
                            lines[i].strip()[:160], filt, guarded))
    return out


def self_test():
    ok = True

    def check(name, cond, extra=""):
        nonlocal ok
        print(("PASS " if cond else "FAIL ") + name + ("  " + extra if extra else ""))
        if not cond:
            ok = False

    good = ('local theAction = DataPool:CreateActionItemForShow(id, 1)\n'
            'if theAction:GetID() ~= 0 then\n'
            '  x:SetText(theAction:GetItemIconInShop())\n'
            'end\n')
    hits = scan_lua(good, 40)
    names = sorted(set(h[3] for h in hits))
    check("bat_duoc_ca_hai_phuong_thuc", names == ["GetID", "GetItemIconInShop"], "names=%s" % names)
    check("ghi_dung_so_dong", any(h[3] == "GetItemIconInShop" and h[4] == 3 for h in hits))

    # doi chung am 1: bien KHONG den tu ham tao action -> khong duoc bat gi
    other = ('local theAction = SomethingElse:Make(1)\n'
             'theAction:GetItemIconInShop()\n')
    check("biet_TRUOT_khi_nguon_khac", scan_lua(other, 40) == [])

    # doi chung am 2: bien bi gan lai tu nguon khac -> ngung theo doi
    reassign = ('local a = DataPool:CreateActionItemForShow(1, 1)\n'
                'a = Other:Thing()\n'
                'a:GetItemIconInShop()\n')
    check("biet_TRUOT_sau_khi_gan_lai", [h[3] for h in scan_lua(reassign, 40)] == [])

    # doi chung am 3: ngoai cua so span -> khong bat
    far = 'local a = EnumAction(1, "x")\n' + "-- filler\n" * 10 + "a:GetEquipLevel()\n"
    check("biet_TRUOT_ngoai_cua_so", scan_lua(far, 3) == [])

    # doi chung am 4 (bay da sap that): `uidata.action:` la WIDGET, khong phai bien action
    field = ('local action = DataPool:CreateActionItemForShow(1, 1)\n'
             'uidata.action:SetActionItem( action:GetID() )\n')
    names4 = sorted(set(h[3] for h in scan_lua(field, 40)))
    check("khong_nham_truong_uidata_action_voi_bien_action", names4 == ["GetID"],
          "names=%s" % names4)

    # --- phep canh GetID() ~= 0 va doi so loc (them 20/09 sau khi tu bac mot ket luan) ---
    guarded = ('local theAction = EnumAction(0, "fittingitemdress")\n'
               'if theAction:GetID() ~= 0 then\n'
               '  x:SetText(theAction:GetItemColorInFittingRoom(0))\n'
               'end\n')
    g = [h for h in scan_lua(guarded, 40) if h[3] == "GetItemColorInFittingRoom"]
    check("doc_duoc_doi_so_loc_chuoi_tran", g and g[0][6] == frozenset(["fittingitemdress"]),
          "filter=%s" % (sorted(g[0][6]) if g and g[0][6] else None))
    check("nhan_ra_loi_goi_NAM_SAU_phep_canh", g and g[0][7] is True)

    unguarded = ('local theAction = EnumAction(0, "fittingitemdress")\n'
                 'local i = theAction:GetItemTableIndex()\n'
                 'if theAction:GetID() ~= 0 then end\n')
    u = [h for h in scan_lua(unguarded, 40) if h[3] == "GetItemTableIndex"]
    check("nhan_ra_loi_goi_NAM_TRUOC_phep_canh", u and u[0][7] is False)

    # doi chung am 5: bien la doi so loc -> KHONG duoc bia ra mot chuoi
    varfilter = 'local a = EnumAction(0, TYPES[i])\na:GetEquipDur()\n'
    v = scan_lua(varfilter, 40)
    check("biet_TRUOT_khi_doi_so_loc_la_bien", v and v[0][6] is None,
          "filter=%s" % (v[0][6] if v else "(khong co hit)"))

    # bang chuoi cuc bo phai tra duoc: EnumAction(0, T[i]) voi local T = {"a","b"}
    tbl = ('local T = { "fittingitemdress", "fittingitemhorse" }\n'
           'local a = EnumAction(0, T[i])\n'
           'if a:GetID() ~= 0 then x = a:GetItemColorInFittingRoom(0) end\n')
    tt = [h for h in scan_lua(tbl, 40) if h[3] == "GetItemColorInFittingRoom"]
    check("tra_duoc_bang_chuoi_cuc_bo",
          tt and tt[0][6] == frozenset(["fittingitemdress", "fittingitemhorse"]),
          "filter=%s" % (sorted(tt[0][6]) if tt and tt[0][6] else None))

    sc = ('local S = "fittingitemhuanling"\n'
          'local a = EnumAction(0, S)\n'
          'if a:GetID() ~= 0 then x = a:GetItemPriceInFittingRoom(0) end\n')
    s1 = [h for h in scan_lua(sc, 40) if h[3] == "GetItemPriceInFittingRoom"]
    check("tra_duoc_bien_VO_HUONG",
          s1 and s1[0][6] == frozenset(["fittingitemhuanling"]),
          "filter=%s" % (sorted(s1[0][6]) if s1 and s1[0][6] else None))
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--script-cpp", default="Src/Client/WXClient/Script/GMScriptSystm.cpp")
    ap.add_argument("--action-cpp", default="Src/Client/WXClient/Action/GMActionSystem.cpp")
    ap.add_argument("--interface-root", default="Assets/CanonicalCY/Data/InterfaceFolder")
    ap.add_argument("--span", type=int, default=60)
    ap.add_argument("--out")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        raise SystemExit(0 if self_test() else 1)

    meta = metatable_methods(args.script_cpp)
    types = set(NAMETYPE_RE.findall(read_text(args.action_cpp)))
    rows = []
    files = 0
    for base, _dirs, names in os.walk(args.interface_root):
        for name in names:
            if not name.endswith(".lua"):
                continue
            path = os.path.join(base, name)
            rel = os.path.relpath(path, args.interface_root).replace(os.sep, "/")
            frame = rel.split("/")[0]
            files += 1
            for (var, producer, aline, method, uline, text, filt,
                 guarded) in scan_lua(read_text(path), args.span):
                if method in meta:
                    continue
                # Loai action co ton tai trong ban dung nay khong?
                #   'khong-ro'    : doi so loc la mot bien, chua ket luan duoc
                #   'co'          : chuoi tran nam trong bang NAMETYPE_*
                #   'KHONG'       : chuoi tran KHONG co loai nao khop => EnumAction luon tra NULL
                #                   => Lua nhan s_InvalidAction (GetID = 0)
                if producer != "EnumAction" or filt is None:
                    reach = "khong-ro"
                elif filt & types:
                    reach = "co"
                else:
                    reach = "KHONG"
                # Cu nem CHI xay ra khi: (loai co that HOAC chua ro) HOAC loi goi nam TRUOC
                # phep canh GetID() ~= 0 (luc do s_InvalidAction van bi goi phuong thuc thieu).
                throws = (reach != "KHONG") or (not guarded)
                rows.append({"frame": frame, "file": rel, "var": var, "producer": producer,
                             "assign_line": aline, "method": method, "use_line": uline,
                             "filter": (sorted(filt) if filt else None), "loai_action_ton_tai": reach,
                             "sau_phep_canh_GetID": guarded, "se_nem": throws,
                             "text": text})
    by_method = {}
    for r in rows:
        by_method.setdefault(r["method"], 0)
        by_method[r["method"]] += 1
    by_producer = {}
    for r in rows:
        by_producer.setdefault(r["producer"], set()).add(r["frame"])
    live = [r for r in rows if r["se_nem"]]
    dead = [r for r in rows if not r["se_nem"]]
    doc = {
        "counting_definition": "1 site = 1 dong Lua goi mot phuong thuc KHONG co trong "
                               "ActionButtonMetaTable tren mot bien den tu ham tao action",
        "counting_definition_se_nem": "site SE NEM THAT = loai action ton tai (hoac chua ro), "
                                      "HOAC loi goi nam TRUOC phep canh GetID() ~= 0",
        "action_types_in_build": sorted(types),
        "action_types_count": len(types),
        "sites_SE_NEM": len(live),
        "frames_SE_NEM": sorted(set(r["frame"] for r in live)),
        "frames_SE_NEM_count": len(set(r["frame"] for r in live)),
        "sites_MA_CHET_loai_action_khong_ton_tai": len(dead),
        "frames_chi_co_ma_chet": sorted(set(r["frame"] for r in dead)
                                        - set(r["frame"] for r in live)),
        "metatable_methods": sorted(meta),
        "metatable_count": len(meta),
        "producers": list(PRODUCERS),
        "span": args.span,
        "lua_files_scanned": files,
        "sites": len(rows),
        "frames": sorted(set(r["frame"] for r in rows)),
        "frames_count": len(set(r["frame"] for r in rows)),
        "methods_missing": sorted(by_method),
        "methods_missing_count": len(by_method),
        "sites_by_method": dict(sorted(by_method.items(), key=lambda kv: -kv[1])),
        "frames_by_producer": {k: sorted(v) for k, v in sorted(by_producer.items())},
        "frames_count_by_producer": {k: len(v) for k, v in sorted(by_producer.items())},
        "hits": rows,
    }
    if args.out:
        json.dump(doc, io.open(args.out, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("metatable=%d phuong thuc | loai action trong ban dung=%d | file lua=%d"
          % (len(meta), len(types), files))
    print("site=%d  khung=%d  ten phuong thuc thieu=%d  (THO)"
          % (len(rows), doc["frames_count"], len(by_method)))
    print("SE NEM THAT      : site=%d  khung=%d" % (len(live), doc["frames_SE_NEM_count"]))
    print("MA CHET (loai action khong ton tai, nam sau phep canh GetID~=0): site=%d"
          % len(dead))
    print("  khung CHI co ma chet (bo do cu bao oan):", doc["frames_chi_co_ma_chet"])
    for k, v in doc["frames_count_by_producer"].items():
        print("  producer %-30s -> %d khung" % (k, v))
    print("  10 phuong thuc thieu nhieu site nhat:",
          list(doc["sites_by_method"].items())[:10])
    if args.out:
        print("->", args.out)


if __name__ == "__main__":
    main()
