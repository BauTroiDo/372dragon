#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tests/fx/effects/census/fx_census.py - census of the effect data, joined with what WX parses and uses.

Read-only inputs (GBK files are read as bytes; nothing is ever written back):
  S1 = CY-Source/Assets/Canonical/Data        (built from client_GL = "B")
  S2 = Tools/DATA NEW/DataCY31-08-26          (CY data)
  S3 = CY-Source/Assets/CanonicalCY/Data      (CY 3.71.9609 staged, fx-cy 14/09)
  S0 = the 0.85-era data of the current game stage (info only; optional)
Files per source: all.effect, all.skill, all.obj, ItemVisualLocator.txt.

The effect/skill parser mirrors WX::EffectManager::parseEffectFile / parseSkillFile line by line: lines are trimmed
(OGRE DataStream::getLine), blank lines and '//' lines are skipped, '{' and '}' must be alone on a line, attributes
are "key value" split at the first blank. The 0.85 parser *aborts the rest of the file* on a bad top-level line and
*throws* on a duplicate template name, so both are reported as anomalies.

Outputs (--out, default Build/Logs/2026-09-13-fx-effects/census):
  types_<S>.tsv        block types (element types, skill sub-blocks) with block and template counts
  keys_<S>.tsv         every (scope, key): uses, templates using it, arity, numeric range per component, top values
  refs_<S>.tsv         effect references from all.skill / all.obj / ItemVisualLocator and how many resolve
  anomalies_<S>.txt    lines the 0.85 parser would abort on / skip, duplicate names
  gap.tsv              join of keys_S1/S2 with the WX tables: NOT_PARSED / PARSED_IGNORED / USED per key
  summary.json         headline numbers (before/after comparisons read this)

WX tables (optional; the join is skipped when missing):
  --wx-dicts  TSV "scope<TAB>key" of every key the engine's ParamDictionaries accept (dumped by CYSFxEffectsTest)
  --wx-usage  TSV "scope<TAB>key<TAB>status<TAB>evidence": status IGNORED (parsed, stored, never read at run time)
              or USED; keys not listed there but present in --wx-dicts count as USED.
"""
import argparse
import collections
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CYS = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))           # ...\CY-Source
ROOT = os.path.dirname(CYS)                                                  # C:\TLBB\085

SOURCES = {
    "S1": {
        "effect": os.path.join(CYS, "Assets", "Canonical", "Data", "EffectFolder", "all.effect"),
        "skill": os.path.join(CYS, "Assets", "Canonical", "Data", "EffectFolder", "all.skill"),
        "obj": os.path.join(CYS, "Assets", "Canonical", "Data", "ModelFolder", "all.obj"),
        "ivl": os.path.join(CYS, "Assets", "Canonical", "Data", "ConfigFolder", "ItemVisualLocator.txt"),
    },
    "S2": {
        "effect": os.path.join(ROOT, "Tools", "DATA NEW", "DataCY31-08-26", "Effect", "all.effect"),
        "skill": os.path.join(ROOT, "Tools", "DATA NEW", "DataCY31-08-26", "Effect", "all.skill"),
        "obj": os.path.join(ROOT, "Tools", "DATA NEW", "DataCY31-08-26", "Model", "all.obj"),
        "ivl": os.path.join(ROOT, "Tools", "DATA NEW", "DataCY31-08-26", "Config", "ItemVisualLocator.txt"),
    },
    "S3": {  # CYS-FX: CanonicalCY = CY 3.71.9609 data staged by build_canonical_cy.py (fx-cy, 14/09)
        "effect": os.path.join(CYS, "Assets", "CanonicalCY", "Data", "EffectFolder", "all.effect"),
        "skill": os.path.join(CYS, "Assets", "CanonicalCY", "Data", "EffectFolder", "all.skill"),
        "obj": os.path.join(CYS, "Assets", "CanonicalCY", "Data", "ModelFolder", "all.obj"),
        "ivl": os.path.join(CYS, "Assets", "CanonicalCY", "Data", "ConfigFolder", "ItemVisualLocator.txt"),
    },
    "S0": {
        "effect": os.path.join(CYS, "Build", "gpt-p1-1-20260913", "stage-91148e1", "Data", "Effect", "all.effect"),
        "skill": os.path.join(CYS, "Build", "gpt-p1-1-20260913", "stage-91148e1", "Data", "Effect", "all.skill"),
    },
}

SKILL_SUBBLOCKS = ("AnimEffect", "Ribbon", "Sound", "SceneLight", "CameraShake", "ComplexBlur")


def read_lines(path):
    """bytes lines as OGRE getLine() returns them: split at '\n', trimmed of ' \t\r'."""
    with open(path, "rb") as f:
        data = f.read()
    return [ln.strip(b" \t\r") for ln in data.split(b"\n")]


def dec(b):
    return b.decode("gbk", "replace")


def split_kv(line):
    """Ogre::StringUtil::split(line, "\\t ", 1)."""
    m = re.match(rb"([^\t ]+)[\t ]+(.*)$", line)
    if not m:
        return [line] if line else []
    return [m.group(1), m.group(2)]


class KeyStats(object):
    __slots__ = ("uses", "templates", "arity", "num_min", "num_max", "values", "numeric", "example")

    def __init__(self):
        self.uses = 0
        self.templates = set()
        self.arity = collections.Counter()
        self.num_min = {}
        self.num_max = {}
        self.values = collections.Counter()
        self.numeric = 0
        self.example = ""

    def add(self, template, value, where):
        self.uses += 1
        self.templates.add(template)
        toks = value.split()
        self.arity[len(toks)] += 1
        nums = []
        for t in toks:
            try:
                nums.append(float(t))
            except ValueError:
                nums = None
                break
        if nums is not None and nums:
            self.numeric += 1
            for i, v in enumerate(nums[:8]):
                if i not in self.num_min or v < self.num_min[i]:
                    self.num_min[i] = v
                if i not in self.num_max or v > self.num_max[i]:
                    self.num_max[i] = v
        if len(self.values) < 4000 or value in self.values:
            self.values[value] += 1
        if not self.example:
            self.example = where

    def row(self, blocks_total):
        ranges = " ".join("%d:%g..%g" % (i, self.num_min[i], self.num_max[i]) for i in sorted(self.num_min))
        top = "; ".join("%s=%d" % (v[:40], n) for v, n in self.values.most_common(6))
        ar = ",".join("%d:%d" % (k, v) for k, v in sorted(self.arity.items()))
        return [str(self.uses), "%d/%d" % (self.uses, blocks_total), str(len(self.templates)), ar, ranges, top,
                self.example]


class Census(object):
    def __init__(self, name):
        self.name = name
        self.keys = collections.defaultdict(KeyStats)            # (scope, key) -> stats
        self.blocks = collections.Counter()                       # scope -> blocks
        self.block_templates = collections.defaultdict(set)       # scope -> templates
        self.anomalies = []
        self.effect_names = set()
        self.skill_names = set()
        self.refs = collections.defaultdict(lambda: [0, 0, set()])  # ref kind -> [total, resolved, missing names]
        self.effects_elements = collections.Counter()             # effect -> number of elements
        self.skill_effects = []                                   # (skill, attach point, template, attach flag)

    # ---------------------------------------------------------------- all.effect
    def parse_effect(self, path):
        lines = read_lines(path)
        n = len(lines)
        i = 0
        effect = None
        cur_elements = 0

        def skip_to(tok, i):
            while i < n:
                ln = lines[i]
                i += 1
                if ln == tok:
                    return i, True
            return i, False

        while i < n:
            ln = lines[i]
            lineno = i + 1
            i += 1
            if not ln or ln.startswith(b"//"):
                continue
            if effect is None:
                parts = ln.split()
                if parts[0] != b"effect" or len(parts) != 2:
                    self.anomalies.append("ABORT line %d: bad effect name line %r -> the 0.85 parser drops the "
                                          "rest of the file (%d lines)" % (lineno, dec(ln)[:80], n - lineno))
                    return
                effect = dec(parts[1])
                if effect in self.effect_names:
                    self.anomalies.append("DUPLICATE effect '%s' line %d -> createEffectTemplate throws" %
                                          (effect, lineno))
                self.effect_names.add(effect)
                self.blocks["effect"] += 1
                self.block_templates["effect"].add(effect)
                cur_elements = 0
                j, ok = skip_to(b"{", i)
                if j != i + 1:
                    self.anomalies.append("SKIP line %d: %d line(s) skipped before '{' of effect '%s'" %
                                          (lineno, j - i - 1, effect))
                i = j
                continue
            if ln == b"}":
                self.effects_elements[effect] = cur_elements
                effect = None
                continue
            if ln[:7] == b"element":
                parts = ln.split()
                if len(parts) < 2:
                    self.anomalies.append("ABORT line %d: bad element line %r" % (lineno, dec(ln)))
                    return
                etype = dec(parts[1])
                scope = "element:" + etype
                self.blocks[scope] += 1
                self.block_templates[scope].add(effect)
                cur_elements += 1
                j, ok = skip_to(b"{", i)
                if j != i + 1:
                    self.anomalies.append("SKIP line %d: %d line(s) skipped before '{' of element %s in '%s'" %
                                          (lineno, j - i - 1, etype, effect))
                i = j
                while i < n:
                    a = lines[i]
                    i += 1
                    if not a or a.startswith(b"//"):
                        continue
                    if a == b"}":
                        break
                    kv = split_kv(a)
                    if len(kv) != 2:
                        self.keys[(scope, "<bad:" + dec(a)[:30] + ">")].add(effect, "", "%d" % i)
                        continue
                    self.keys[(scope, dec(kv[0]))].add(effect, dec(kv[1]), "all.effect:%d" % i)
                continue
            kv = split_kv(ln)
            if len(kv) == 2:
                self.keys[("effect", dec(kv[0]))].add(effect, dec(kv[1]), "all.effect:%d" % lineno)
            else:
                self.keys[("effect", "<bad:" + dec(ln)[:30] + ">")].add(effect, "", "all.effect:%d" % lineno)

    # ---------------------------------------------------------------- all.skill
    def parse_skill(self, path):
        lines = read_lines(path)
        n = len(lines)
        i = 0
        skill = None

        def skip_to(tok, i):
            while i < n:
                ln = lines[i]
                i += 1
                if ln == tok:
                    return i
            return i

        while i < n:
            ln = lines[i]
            lineno = i + 1
            i += 1
            if not ln or ln.startswith(b"//"):
                continue
            if skill is None:
                parts = ln.split()
                if parts[0] != b"skill" or len(parts) != 2:
                    self.anomalies.append("SKILL-SKIP line %d: bad skill name line %r (0.85 logs and continues)" %
                                          (lineno, dec(ln)[:80]))
                    continue
                skill = dec(parts[1])
                if skill in self.skill_names:
                    self.anomalies.append("DUPLICATE skill '%s' line %d -> createSkillTemplate throws" %
                                          (skill, lineno))
                self.skill_names.add(skill)
                self.blocks["skill"] += 1
                self.block_templates["skill"].add(skill)
                i = skip_to(b"{", i)
                continue
            if ln == b"}":
                skill = None
                continue
            sub = dec(ln)
            if sub in SKILL_SUBBLOCKS or (b" " not in ln and b"\t" not in ln):
                scope = "skill:" + sub
                self.blocks[scope] += 1
                self.block_templates[scope].add(skill)
                i = skip_to(b"{", i)
                info = {}
                while i < n:
                    a = lines[i]
                    i += 1
                    if not a or a.startswith(b"//"):
                        continue
                    if a == b"}":
                        break
                    kv = split_kv(a)
                    if len(kv) != 2:
                        continue
                    k, v = dec(kv[0]), dec(kv[1])
                    info[k] = v
                    self.keys[(scope, k)].add(skill, v, "all.skill:%d" % i)
                if sub == "AnimEffect":
                    self.skill_effects.append((skill, info.get("AttachPoint", ""), info.get("EffectTemplateName", ""),
                                               info.get("Attach", "")))
                continue
            kv = split_kv(ln)
            if len(kv) == 2:
                self.keys[("skill", dec(kv[0]))].add(skill, dec(kv[1]), "all.skill:%d" % lineno)

    # ---------------------------------------------------------------- all.obj <Effects>
    def parse_obj(self, path):
        with open(path, "rb") as f:
            data = f.read()
        text = data.decode("gbk", "replace")
        obj = None
        pos = 0
        obj_re = re.compile(r'<Object\s+name\s*=\s*"([^"]*)"')
        eff_re = re.compile(r"<Effect\s+([^>]*?)/?>")
        attr_re = re.compile(r'(\w+)\s*=\s*"([^"]*)"')
        objs = [(m.start(), m.group(1)) for m in obj_re.finditer(text)]
        oi = 0
        for m in eff_re.finditer(text):
            while oi + 1 < len(objs) and objs[oi + 1][0] < m.start():
                oi += 1
            owner = objs[oi][1] if objs and objs[oi][0] < m.start() else "?"
            attrs = dict(attr_re.findall(m.group(1)))
            self.blocks["obj:Effect"] += 1
            self.block_templates["obj:Effect"].add(owner)
            for k, v in attrs.items():
                self.keys[("obj:Effect", k)].add(owner, v, "all.obj:@%d" % m.start())
            name = attrs.get("effect", "")
            if name:
                self._ref("obj:Effect.effect", name)

    # ---------------------------------------------------------------- ItemVisualLocator effect columns
    def parse_ivl(self, path):
        with open(path, "rb") as f:
            rows = f.read().split(b"\r\n")
        data_rows = [r.split(b"\t") for r in rows[2:] if r.strip()]
        if not data_rows:
            return
        ncol = max(len(r) for r in data_rows)
        for c in range(1, ncol):
            vals = [dec(r[c]).strip() for r in data_rows if c < len(r) and r[c].strip()]
            if not vals:
                continue
            hit = sum(1 for v in vals if v in self.effect_names)
            if hit * 2 >= len(vals):          # an effect column: most values name an effect template
                for v in vals:
                    self._ref("ivl:col%02d" % c, v)

    def _ref(self, kind, name):
        r = self.refs[kind]
        r[0] += 1
        if name in self.effect_names:
            r[1] += 1
        else:
            r[2].add(name)

    def resolve_skill_refs(self):
        for skill, ap, tmpl, att in self.skill_effects:
            if not tmpl:
                continue
            if "<" in tmpl:
                self._ref("skill:AnimEffect.template(<terrain>)", tmpl)
            else:
                self._ref("skill:AnimEffect.EffectTemplateName", tmpl)

    # ---------------------------------------------------------------- output
    def write(self, out):
        s = self.name
        with open(os.path.join(out, "types_%s.tsv" % s), "w", encoding="utf-8") as f:
            f.write("scope\tblocks\ttemplates\n")
            for scope, nb in sorted(self.blocks.items(), key=lambda x: (-x[1], x[0])):
                f.write("%s\t%d\t%d\n" % (scope, nb, len(self.block_templates[scope])))
        with open(os.path.join(out, "keys_%s.tsv" % s), "w", encoding="utf-8") as f:
            f.write("scope\tkey\tuses\tuses/blocks\ttemplates\tarity(n:count)\tnumeric_range\ttop_values\texample\n")
            for (scope, key), st in sorted(self.keys.items(), key=lambda x: (x[0][0], -x[1].uses, x[0][1])):
                f.write("\t".join([scope, key] + st.row(self.blocks[scope])) + "\n")
        with open(os.path.join(out, "refs_%s.tsv" % s), "w", encoding="utf-8") as f:
            f.write("kind\trefs\tresolved\tmissing_distinct\tmissing_examples\n")
            for kind, (tot, ok, miss) in sorted(self.refs.items()):
                f.write("%s\t%d\t%d\t%d\t%s\n" % (kind, tot, ok, len(miss), "; ".join(sorted(miss)[:12])))
        with open(os.path.join(out, "anomalies_%s.txt" % s), "w", encoding="utf-8") as f:
            for a in self.anomalies:
                f.write(a + "\n")


def load_tsv_pairs(path, ncols):
    rows = []
    if not path or not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as f:
        for ln in f:
            ln = ln.rstrip("\n")
            if not ln or ln.startswith("#"):
                continue
            parts = ln.split("\t")
            if len(parts) < ncols:
                parts += [""] * (ncols - len(parts))
            rows.append(parts)
    return rows


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default=os.path.join(CYS, "Build", "Logs", "2026-09-13-fx-effects", "census"))
    ap.add_argument("--sources", default="S1,S2,S0")
    ap.add_argument("--wx-dicts", default="")
    ap.add_argument("--wx-usage", default=os.path.join(HERE, "wx_key_usage.tsv"))
    ap.add_argument("--threshold", type=int, default=10, help="min templates using a key for the gap gate")
    ap.add_argument("--label", default="", help="label stored in summary.json (e.g. before / after)")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    summary = {"label": args.label, "sources": {}}
    censuses = {}
    for s in args.sources.split(","):
        s = s.strip()
        files = SOURCES.get(s, {})
        if not files or not os.path.exists(files.get("effect", "")):
            continue
        c = Census(s)
        c.parse_effect(files["effect"])
        if os.path.exists(files.get("skill", "")):
            c.parse_skill(files["skill"])
            c.resolve_skill_refs()
        if os.path.exists(files.get("obj", "")):
            c.parse_obj(files["obj"])
        if os.path.exists(files.get("ivl", "")):
            c.parse_ivl(files["ivl"])
        c.write(args.out)
        censuses[s] = c
        summary["sources"][s] = {
            "files": {k: {"path": v, "bytes": os.path.getsize(v)} for k, v in files.items() if os.path.exists(v)},
            "effects": len(c.effect_names), "skills": len(c.skill_names),
            "blocks": dict(c.blocks), "anomalies": len(c.anomalies),
            "aborts": sum(1 for a in c.anomalies if a.startswith("ABORT")),
            "duplicates": sum(1 for a in c.anomalies if a.startswith("DUPLICATE")),
            "refs": {k: {"refs": v[0], "resolved": v[1], "missing_distinct": len(v[2])} for k, v in c.refs.items()},
        }
        print("%s: %d effects, %d skills, %d anomalies" % (s, len(c.effect_names), len(c.skill_names),
                                                           len(c.anomalies)))

    # ------------------------------------------------------------ gap join with the WX tables
    dicts = load_tsv_pairs(args.wx_dicts, 2)
    usage = load_tsv_pairs(args.wx_usage, 4) or []
    if dicts is not None:
        parsed = set((r[0], r[1]) for r in dicts)
        ignored = {(r[0], r[1]): (r[2], r[3]) for r in usage}
        gate = collections.Counter()
        with open(os.path.join(args.out, "gap.tsv"), "w", encoding="utf-8") as f:
            f.write("source\tscope\tkey\ttemplates\tuses\tstatus\tevidence\n")
            for s, c in censuses.items():
                if s == "S0":
                    continue
                for (scope, key), st in sorted(c.keys.items(), key=lambda x: (-len(x[1].templates), x[0])):
                    if scope.startswith("obj:") or key.startswith("<bad:"):
                        continue
                    if (scope, key) in ignored and ignored[(scope, key)][0] == "IGNORED":
                        status, ev = "PARSED_IGNORED", ignored[(scope, key)][1]
                    elif (scope, key) in parsed:
                        status, ev = "USED", ignored.get((scope, key), ("", ""))[1]
                    else:
                        status, ev = "NOT_PARSED", ""
                    f.write("%s\t%s\t%s\t%d\t%d\t%s\t%s\n" % (s, scope, key, len(st.templates), st.uses, status, ev))
                    if len(st.templates) >= args.threshold:
                        gate["%s:%s" % (s, status)] += 1
        summary["gap_gate_threshold"] = args.threshold
        summary["gap_gate"] = dict(gate)
        print("gap gate (>= %d templates): %s" % (args.threshold, dict(gate)))

    with open(os.path.join(args.out, "summary.json"), "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=1, sort_keys=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
