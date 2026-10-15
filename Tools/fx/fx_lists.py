# -*- coding: utf-8 -*-
"""fx-audit: builds the render lists of the sheet harness (UTF-8 TSV "id<TAB>kind<TAB>name[<TAB>anim]").

  a) oracle   - the 100 effects of Tests/oracle/cases.json
  b) frontend - everything the game shows before the world: particle systems / models of the login, character-select
                and character-creation scenes (tl3chuangjian / xuanren / chuangjian .Scene of the game stage), the 30
                sect preview models 4950..4979 (Build/Logs/2026-09-13-gpt-create-role/original-reference/
                s2-sect-preview-rows.json) with their weapons, and every effect those models attach (<Effects> of
                all.obj)
  c) skills   - the 40 effect templates most referenced by all.skill AnimEffect blocks of the game stage data

Names are written as Unicode (GBK decoded); the viewer converts them back to GBK. Items absent from a data set are
reported by the viewer as 'absent' in items.tsv, so one list serves every data set.

Usage: py -3 Tools/fx/fx_lists.py [--out Tests/fx/audit/lists]
"""
from __future__ import annotations

import argparse
import collections
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fx_static as S  # noqa: E402

ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
STAGE = os.path.join(ROOT, r"Build\gpt-p1-1-20260913\stage-91148e1\Data")
ORACLE = os.path.join(ROOT, r"Tests\oracle\cases.json")
SECTS = os.path.join(ROOT, r"Build\Logs\2026-09-13-gpt-create-role\original-reference\s2-sect-preview-rows.json")
FRONTEND_SCENES = ["tl3chuangjian.scene", "xuanren.Scene", "chuangjian.Scene"]


def write(path, items):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("# id\tkind\tname\tanim\n")
        for it in items:
            f.write("\t".join(it) + "\n")
    print("%-60s %d items" % (path, len(items)))


def oracle_list():
    d = json.load(open(ORACLE, encoding="utf-8"))
    return [(e["id"], "effect", e["effect"]) for e in d["effects"]]


def frontend_list(data=STAGE):
    paths = S.locate_data(data)
    items, seen = [], set()

    def add(kind, name, prefix):
        key = (kind, name)
        if key in seen or not name:
            return
        seen.add(key)
        items.append(("%s%03d" % (prefix, len([i for i in items if i[0].startswith(prefix)]) + 1), kind, name))

    obj_effects = S.obj_effect_refs(paths["obj"])
    scene_dir = paths["scene"]
    files = {fn.lower(): fn for fn in os.listdir(scene_dir)}
    for sc in FRONTEND_SCENES:
        fn = files.get(sc.lower())
        if not fn:
            continue
        path = os.path.join(scene_dir, fn)
        with open(path, "rb") as f:
            head = f.read(200)
        # tl3chuangjian.Scene declares encoding="UTF-8" and stores CJK names as UTF-8 (all.particle names are GBK):
        # decode as the file declares, the viewer converts the Unicode name to GBK.
        utf8 = b'encoding="utf-8"' in head.lower()

        def txt(b):
            if b is None:
                return ""
            if utf8:
                try:
                    return b.decode("utf-8")
                except UnicodeDecodeError:
                    pass
            return S.gbk(b)

        for otype, props in S.scene_refs(path):
            if otype == b"ParticleSystem":
                add("particle", txt(props.get(b"particle system name")), "P")
            elif otype == b"Effect":
                add("effect", txt(props.get(b"effect name") or props.get(b"effect")), "E")
            # Scene 'Model' objects are scenery .model files (tl3chuangjian: birds, trees, boats), not all.obj
            # LogicModel templates; the stage file stores their names as UTF-8 bytes, which the GBK list cannot
            # carry. They hold no effect templates, so they are not rendered here.
    if os.path.exists(SECTS):
        rows = json.load(open(SECTS, encoding="utf-8"))["rows"]
        for r in rows:
            actor = r["actor_name"]
            add("model", actor, "S")
            for e in obj_effects.get(actor.encode("gbk"), []):
                add("effect", S.gbk(e), "E")
    return items


def skills_list(data=STAGE, top=40):
    """Top effect templates by all.skill AnimEffect references. Names that are not effect templates of the data
    (placeholders such as '<template>', 'aaaaaaaaaa' filled in by code, or missing effects) are counted separately
    in skills-counts.tsv but not rendered."""
    paths = S.locate_data(data)
    w = S.walk_skill(paths["skill"])
    effects = set(n for n, _ in S.walk_effect(paths["effect"]).templates)
    c = collections.Counter()
    for r in w.records:
        if r.scope == "skillblock" and r.type == b"AnimEffect" and r.key == b"EffectTemplateName" and r.value:
            c[r.value] += 1
    ranked = [n for n, _ in c.most_common() if n in effects and not n.startswith(b"<")]
    return [("K%02d" % (i + 1), "effect", S.gbk(n)) for i, n in enumerate(ranked[:top])], c, effects


CANONICAL = os.path.join(ROOT, r"Assets\Canonical\Data")


def evidence_list(data=CANONICAL, pairs=8, scaled=6):
    """Evidence for two 'parsed but ignored' defects:
    * particle sub-effects: effects whose Particle element names a ParEffectName/ColEffectName (never spawned by
      WXParticleElement) rendered next to that sub-effect template (what should appear per particle);
    * effect use_scale (rejected by the Effect dictionary): the first effects that set it."""
    paths = S.locate_data(data)
    w = S.walk_effect(paths["effect"])
    effects = set(n for n, _ in w.templates)
    items, seen = [], set()
    by_tpl = {}
    for r in w.records:
        if r.scope == "element" and r.key in (b"ParEffectName", b"ColEffectName") and r.value and \
                r.value != b"NullEffect" and r.value in effects:
            by_tpl.setdefault(r.template, set()).add(r.value)
    for tpl in list(by_tpl)[:pairs]:
        for name in [tpl] + sorted(by_tpl[tpl])[:2]:
            if name not in seen:
                seen.add(name)
                items.append(("V%02d" % (len(items) + 1), "effect", S.gbk(name)))
    n = 0
    for r in w.records:
        if r.scope == "effect" and r.key == b"use_scale" and r.template not in seen and n < scaled:
            seen.add(r.template)
            items.append(("U%02d" % (n + 1), "effect", S.gbk(r.template)))
            n += 1
    return items


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default=os.path.join(ROOT, r"Tests\fx\audit\lists"))
    ap.add_argument("--evidence-only", action="store_true")
    a = ap.parse_args()
    write(os.path.join(a.out, "evidence.tsv"), evidence_list())
    if a.evidence_only:
        return
    write(os.path.join(a.out, "oracle.tsv"), oracle_list())
    fe = frontend_list()
    write(os.path.join(a.out, "frontend.tsv"), fe)
    sk, counts, effects = skills_list()
    write(os.path.join(a.out, "skills.tsv"), sk)
    with open(os.path.join(a.out, "skills-counts.tsv"), "w", encoding="utf-8", newline="\n") as f:
        f.write("effect\tanimeffect_refs\tis_effect_template\n")
        for n, k in counts.most_common(300):
            f.write("%s\t%d\t%d\n" % (S.gbk(n), k, 1 if n in effects else 0))


if __name__ == "__main__":
    main()
