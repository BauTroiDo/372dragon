#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""fx-cy: deterministic CY 3.71 sample lists for the sheet harness (Docs/specs/render/07e-fx-cy_vi.md).

Reads Assets/CanonicalCY/Data/EffectFolder/all.skill + all.effect (GBK) and writes
  Tests/fx/audit/lists/cy.tsv            "id<TAB>kind<TAB>name" effects for Tools/fx/fx_sheet.py --set canonicalcy
                                          (skills of the 15 CY sects -> their AnimEffect templates, auras, buffs,
                                          weapon / deco-weapon effects, mounts, costumes, UI particles)
  Tests/fx/effects/cy_skill_cases.tsv    "kind<TAB>model.obj<TAB>skill<TAB><TAB>label" for render_fx_sheet.py
                                          --cases (one male + one female skill per sect on the CY creation models)
Selection is by sorted name and fixed stride: the same data gives the same lists.
"""
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
DATA = os.path.join(ROOT, "Assets", "CanonicalCY", "Data", "EffectFolder")

# sect code in skill names (m01_<code>_ = male, g01_<code>_ = female) -> creation-scene model (Tests/fx/effects/sect_cases.tsv)
SECTS = [
    ("sl", "少林", "男主角高模少林.obj", "女主角高模少林.obj"),
    ("mj", "明教", "男主角高模明教.obj", "女主角高模明教.obj"),
    ("gb", "丐帮", "男主角丐帮高模.obj", "女主角丐帮高模.obj"),
    ("wd", "武当", "男主角高模武当.obj", "女主角高模武当.obj"),
    ("em", "峨眉", "男主角高模峨眉.obj", "女主角高模峨眉.obj"),
    ("xx", "星宿", "男主角高模星宿.obj", "女主角高模星宿.obj"),
    ("dl", "天龙", "男主角大理高模.obj", "女主角大理高模.obj"),
    ("ts", "天山", "男主角高模天山.obj", "女主角高模天山.obj"),
    ("xy", "逍遥", "男主角高模逍遥.obj", "女主角高模逍遥.obj"),
    ("gs", "慕容", "男主角高模姑苏慕容.obj", "女主角高模姑苏慕容.obj"),
    ("TM", "唐门", "男主角高模唐门高级100.obj", "女主角高模唐门高级100.obj"),
    ("GG", "鬼谷", "男主角高模鬼谷高级100.obj", "女主角高模鬼谷高级100.obj"),
    ("thd", "桃花岛", "主角时装桃花岛高模男.obj", "主角时装桃花岛高模女.obj"),
    ("cr", "CR2021", "npcM_cloth_CR_2021gaoji.obj", "npcW_cloth_CR_2021gaoji.obj"),
    ("erg", "ERG2024", "M_cloth_ERG_2024高模.obj", "W_cloth_ERG_2024高模.obj"),
]
GROUPS = [  # (prefix id, effect-name regex, count)
    ("A", r"光环|aura", 15),
    ("B", r"^buff_", 15),
    ("W", r"^wq_", 10),
    ("D", r"dweapon", 5),
    ("H", r"^hj_", 5),
    ("R", r"^ride_|^qc_", 6),
    ("T", r"^ts_|时装", 6),
    ("U", r"^UI_", 7),
]


def dec(b):
    return b.decode("gbk", "replace")


def parse_skills(path):
    """skill name -> (Animation, [EffectTemplateName...])"""
    skills = collections.OrderedDict()
    cur = None
    anim = ""
    effs = []
    depth = 0
    for raw in open(path, "rb").read().split(b"\n"):
        ln = raw.strip(b" \t\r")
        if depth == 0 and ln.startswith(b"skill "):
            cur = dec(ln[6:].strip())
            anim = ""
            effs = []
        elif ln == b"{":
            depth += 1
        elif ln == b"}":
            depth -= 1
            if depth == 0 and cur:
                skills[cur] = (anim, effs)
                cur = None
        elif cur:
            kv = re.match(rb"([^\t ]+)[\t ]+(.*)$", ln)
            if not kv:
                continue
            k, v = kv.group(1), dec(kv.group(2).strip())
            if k == b"Animation" and depth == 1:
                anim = v
            elif k == b"EffectTemplateName":
                effs.append(v)
    return skills


def effect_names(path):
    out = []
    for raw in open(path, "rb").read().split(b"\n"):
        ln = raw.strip(b" \t\r")
        if ln.startswith(b"effect "):
            out.append(dec(ln[7:].strip()))
    return out


def stride_pick(items, n):
    items = sorted(set(items))
    if len(items) <= n:
        return items
    step = len(items) / float(n)
    return [items[int(i * step)] for i in range(n)]


def main():
    skills = parse_skills(os.path.join(DATA, "all.skill"))
    effects = set(effect_names(os.path.join(DATA, "all.effect")))
    rows = []
    cases = []
    for code, zh, male, female in SECTS:
        sect_effs = []
        for sex, prefix, model in (("m", "m01_%s_" % code, male), ("g", "g01_%s_" % code, female)):
            names = [s for s in skills if s.startswith(prefix) and "_zm_" not in s]
            picked = stride_pick(names, 1)
            for s in picked:
                cases.append(("skill", model, s, "", "K%s%s" % (code, sex)))
            for s in names:
                sect_effs.extend(e for e in skills[s][1] if e in effects and e != "NullEffect")
        for e in stride_pick(sect_effs, 5):
            rows.append(("S%s" % code, e))
    all_eff = sorted(effects)
    for pid, rx, n in GROUPS:
        cand = [e for e in all_eff if re.search(rx, e)]
        for e in stride_pick(cand, n):
            rows.append((pid, e))
    seen = set()
    out_rows = []
    counters = collections.Counter()
    for pid, e in rows:
        if e in seen:
            continue
        seen.add(e)
        counters[pid] += 1
        out_rows.append(("%s%02d" % (pid, counters[pid]), "effect", e))
    lst = os.path.join(ROOT, "Tests", "fx", "audit", "lists", "cy.tsv")
    with open(lst, "w", encoding="utf-8", newline="\n") as f:
        f.write("# id\tkind\tname\tanim\t(fx-cy: CY 3.71 sample list, generated by Tools/fx/fx_lists_cy.py)\n")
        for r in out_rows:
            f.write("\t".join(r) + "\n")
    cs = os.path.join(ROOT, "Tests", "fx", "effects", "cy_skill_cases.tsv")
    with open(cs, "w", encoding="utf-8", newline="\n") as f:
        f.write("# kind\targ1(model)\targ2(skill)\targ3\tlabel\t(fx-cy: one CY sect skill per sex, generated)\n")
        for r in cases:
            f.write("\t".join(r) + "\n")
    print("%s: %d effects (%s)" % (lst, len(out_rows), ", ".join("%s=%d" % kv for kv in sorted(counters.items()))))
    print("%s: %d skill cases" % (cs, len(cases)))


if __name__ == "__main__":
    main()
