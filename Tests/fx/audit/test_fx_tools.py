# -*- coding: utf-8 -*-
"""fx-audit tool tests (no engine needed): the static walker mirrors the runtime parsers, value comparison and
SSIM behave. Run: py -3 Tests/fx/audit/test_fx_tools.py  (exit code 0 = all passed)."""
from __future__ import annotations

import os
import sys
import tempfile

import numpy as np

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "Tools", "fx"))
import fx_census as C  # noqa: E402
import fx_sheet as F  # noqa: E402
import fx_static as S  # noqa: E402

FAILED = []


def check(name, cond):
    print(("PASS " if cond else "FAIL ") + name)
    if not cond:
        FAILED.append(name)


def tmp(text):
    fd, path = tempfile.mkstemp(suffix=os.path.splitext(text[0])[1])
    with os.fdopen(fd, "wb") as f:
        f.write(text[1].encode("gbk"))
    return path


def test_particle():
    p = tmp(("x.particle", "测试_a\n{\n\tquota 20\n\tmaterial 材质A\n\temitter Box\n\t{\n\t\tEmission_Rate 5\n\t}\n"
                           "\taffector Nope\n\t{\n\t\tfoo 1\n\t}\n}\n测试_a\n{\n\tquota 1\n}\n测试_b\n{\n}\n"))
    w = S.walk_particle(p, known_emitters={b"Box"}, known_affectors=set())
    names = [n.decode("gbk") for n, _ in w.templates]
    check("particle: templates in order, duplicate skipped", names == ["测试_a", "测试_b"])
    check("particle: duplicate recorded with first line", len(w.duplicates) == 1 and w.duplicates[0][2] == 1)
    rec = [r for r in w.records if r.scope == "emitter" and not r.key.startswith(b"#")]
    check("particle: emitter line lower-cased like parseNewEmitter", rec and rec[0].key == b"emission_rate")
    sysrec = [r for r in w.records if r.scope == "system"]
    check("particle: system line keeps case and GBK value", sysrec[1].value.decode("gbk") == "材质A")
    aff = [r for r in w.records if r.scope == "affector" and r.key == b"foo"]
    check("particle: unknown affector block still attributed", len(aff) == 1)
    os.remove(p)


def test_effect_abort():
    p = tmp(("x.effect", "effect e1\n{\n\telement Particle\n\t{\n\t\tParticleSystem ps1\n\t}\n}\n"
                         "stray line\neffect e2\n{\n}\n"))
    w = S.walk_effect(p)
    check("effect: stray level-0 line aborts the rest (parseEffectFile)", [n for n, _ in w.templates] == [b"e1"]
          and w.aborted_at == 8)
    os.remove(p)
    p = tmp(("x.effect", "effect e1\n{\n}\neffect e1\n{\n}\neffect e3\n{\n}\n"))
    w = S.walk_effect(p)
    check("effect: duplicate template aborts (createEffectTemplate throws)", w.aborted_at == 4)
    os.remove(p)


def test_skill_subblock():
    p = tmp(("x.skill", "skill s1\n{\n\tAnimation a\n\tMystery\n\t{\n\t\tx 1\n\t}\n\tAnimEffect\n\t{\n"
                        "\t\tEffectTemplateName e1\n\t}\n}\n"))
    w = S.walk_skill(p)
    kinds = [(r.scope, r.type, r.key) for r in w.records]
    check("skill: bare token = skipped sub-block", ("skillblock", b"Mystery", b"#unknown-block") in kinds)
    check("skill: AnimEffect after the unknown block still parsed",
          ("skillblock", b"AnimEffect", b"EffectTemplateName") in kinds)
    os.remove(p)


def test_values():
    check("value: numeric tolerance", C.same_value(b"0.5 1", b"0.500001 1.0"))
    check("value: booleans", C.same_value(b"true", b"1") and not C.same_value(b"true", b"0"))
    check("value: Ring inner 0 vs runtime 1 differs", not C.same_value(b"0", b"1"))


def test_ssim():
    rng = np.random.default_rng(1)
    a = rng.integers(0, 255, (64, 64, 3)).astype(np.float64)
    b = a.copy()
    check("ssim: identical = 1", F.ssim(a, b) == 1.0)
    b[10:20, 10:20] = 0
    check("ssim: different < 1", F.ssim(a, b) < 0.99)


def test_ignored():
    # CYS ci-refresh 17/09: the probe key moved Particle -> UIParticle. fx-effects (13/09) made the Particle
    # sub-effect keys USED (WXParticleElement::_updateParticleEffects), and fx-cy (e216cddd, 14/09) therefore
    # dropped every "element particle <sub-effect>" row from Tools/fx/ignored_keys.tsv; only UIParticle still
    # has no sub-effect system, in B/C too. The test now checks that registry state instead of the old one.
    ig = C.load_ignored()
    k = ("element", "uiparticle", "pareffectname")
    check("ignored: ParEffectName listed", bool(ig.get(k)))
    check("ignored: NullEffect is a no-op", ig.is_noop(k, b"NullEffect") and not ig.is_noop(k, b"yanhua_x"))
    check("ignored: Particle ParEffectName no longer ignored", not ig.get(("element", "particle", "pareffectname")))


if __name__ == "__main__":
    test_particle()
    test_effect_abort()
    test_skill_subblock()
    test_values()
    test_ssim()
    test_ignored()
    print("%d failed" % len(FAILED))
    sys.exit(1 if FAILED else 0)
