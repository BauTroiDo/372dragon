# -*- coding: utf-8 -*-
"""fx-audit static walker: all.particle / all.effect / all.skill (GBK) walked exactly like the runtime parsers,
plus the reference graph used for usage weights.

Mirrors (CY-Source Src, 13/09/2026):
  * Ogre ParticleSystemManager::parseScript (OgreMain/src/OgreParticleSystemManager.cpp:99-230): lines trimmed
    (DataStream::getLine), '//' comments, template name line, skipToNextOpenBrace, 'emitter <T>' / 'affector <T>'
    blocks whose lines are lower-cased as a whole (parseNewEmitter/parseNewAffector), other lines = system/renderer
    attributes (not lower-cased).
  * WX EffectManager::parseEffectFile (WXCore/EffectSystem/WXEffectManager.cpp:595-660): 'effect <name>' header
    (anything else at brace level 0 ABORTS the rest of the file), 'element <T>' blocks, effect attributes.
    createEffectTemplate throws on a duplicate name (WXEffectManager.cpp:275) - not caught by parseEffectFile.
  * WX EffectManager::parseSkillFile (WXEffectManager.cpp:673-778): 'skill <name>', AnimEffect / Ribbon / Sound /
    SceneLight / CameraShake / ComplexBlur sub-blocks, bare unknown token = skipped sub-block, skill attributes.

Every record keeps file, 1-based line, template, scope, type, key, value, so runtime messages (file:line) and runtime
dictionaries can be joined per occurrence. Data files are only read.
"""
from __future__ import annotations

import collections
import os
import re
from dataclasses import dataclass, field

WS = b" \t\r\n"


def read_lines(path):
    with open(path, "rb") as f:
        data = f.read()
    # DataStream::getLine splits on '\n' and trims; keep the 1-based numbering of the physical lines.
    return [l.strip(WS) for l in data.split(b"\n")]


def split_ws(line, maxsplit=-1):
    """StringUtil::split(line, "\t ", maxsplit) - runs of delimiters collapse."""
    parts = re.split(rb"[\t ]+", line.strip(WS), maxsplit=maxsplit) if maxsplit >= 0 else re.split(rb"[\t ]+", line.strip(WS))
    return [p for p in parts if p != b""] if maxsplit < 0 else parts


def key_value(line):
    """StringUtil::split(line, "\t ", 1): key and the rest (value keeps inner spaces)."""
    m = re.match(rb"([^\t ]+)[\t ]+(.*)$", line)
    if not m:
        return line, None
    return m.group(1), m.group(2).strip(WS)


@dataclass
class Rec:
    file: str
    line: int
    template: bytes
    scope: str          # system | emitter | affector | effect | element | skill | <subblock> | header | toplevel
    type: bytes         # emitter/affector/element/sub-block type, b'' for system/effect/skill attributes
    key: bytes
    value: bytes | None
    ordinal: int = 0    # n-th block of the same type inside the template (emitters/affectors/elements)


@dataclass
class Walk:
    path: str
    records: list = field(default_factory=list)
    templates: list = field(default_factory=list)       # (name, first line)
    duplicates: list = field(default_factory=list)      # (name, line, first line)
    aborted_at: int | None = None                       # line where the runtime stops reading the file
    abort_reason: str = ""
    blocks: list = field(default_factory=list)          # (template, scope, type, ordinal, line)


# --------------------------------------------------------------------------------------------------- particles
def walk_particle(path, known_emitters=None, known_affectors=None):
    lines = read_lines(path)
    w = Walk(path)
    fname = os.path.basename(path)
    seen = {}
    i = 0
    n = len(lines)
    cur = None
    ordinal = collections.Counter()

    def skip_to_open(i):
        while i < n:
            l = lines[i]
            i += 1
            if l == b"{":
                break
        return i

    def skip_to_close(i):
        while i < n:
            l = lines[i]
            i += 1
            if l == b"}":
                break
        return i

    while i < n:
        line = lines[i]
        ln = i + 1
        i += 1
        if not line or line.startswith(b"//"):
            continue
        if cur is None:
            name = line
            if name in seen:
                w.duplicates.append((name, ln, seen[name]))
                # CYS parseScript: duplicate -> block skipped (cysSkipBlock counts braces)
                depth = 0
                while i < n:
                    l = lines[i]
                    i += 1
                    if l == b"{":
                        depth += 1
                    elif l == b"}":
                        depth -= 1
                        if depth <= 0:
                            break
                continue
            seen[name] = ln
            cur = name
            ordinal = collections.Counter()
            w.templates.append((name, ln))
            w.records.append(Rec(fname, ln, name, "header", b"", b"#template", None))
            i = skip_to_open(i)
            continue
        if line == b"}":
            cur = None
            continue
        if line.startswith(b"emitter") or line.startswith(b"affector"):
            scope = "emitter" if line.startswith(b"emitter") else "affector"
            parts = split_ws(line)
            if len(parts) < 2:
                w.records.append(Rec(fname, ln, cur, scope, b"", b"#bad-block-line", line))
                i = skip_to_close(i)
                continue
            btype = parts[1]
            known = known_emitters if scope == "emitter" else known_affectors
            ordn = ordinal[(scope, btype)]
            ordinal[(scope, btype)] += 1
            w.blocks.append((cur, scope, btype, ordn, ln))
            w.records.append(Rec(fname, ln, cur, scope, btype, b"#block", None, ordn))
            if known is not None and btype not in known:
                # 'doesn't exists' -> skipToNextCloseBrace
                j = i
                while j < n and lines[j] != b"}":
                    l = lines[j]
                    if l and not l.startswith(b"//") and l != b"{":
                        k, v = key_value(l.lower())
                        w.records.append(Rec(fname, j + 1, cur, scope, btype, k, v, ordn))
                    j += 1
                i = min(j + 1, n)
                continue
            i = skip_to_open(i)
            while i < n:
                l = lines[i]
                lnn = i + 1
                i += 1
                if not l or l.startswith(b"//"):
                    continue
                if l == b"}":
                    break
                k, v = key_value(l.lower())
                w.records.append(Rec(fname, lnn, cur, scope, btype, k, v, ordn))
            continue
        k, v = key_value(line)
        w.records.append(Rec(fname, ln, cur, "system", b"", k, v))
    return w


# --------------------------------------------------------------------------------------------------- effects
def walk_effect(path, known_elements=None):
    lines = read_lines(path)
    w = Walk(path)
    fname = os.path.basename(path)
    seen = {}
    n = len(lines)
    i = 0
    cur = None
    ordinal = collections.Counter()

    def skip_to_open(i):
        while i < n:
            l = lines[i]
            i += 1
            if l == b"{":
                break
        return i

    while i < n:
        line = lines[i]
        ln = i + 1
        i += 1
        if not line or line.startswith(b"//"):
            continue
        if cur is None:
            parts = split_ws(line)
            if not parts or parts[0] != b"effect" or len(parts) != 2:
                w.aborted_at = ln
                w.abort_reason = "Bad effect system name line (parseEffectFile returns)"
                break
            name = parts[1]
            if name in seen:
                w.duplicates.append((name, ln, seen[name]))
                w.aborted_at = ln
                w.abort_reason = "duplicate effect template -> createEffectTemplate throws (rest of file lost)"
                break
            seen[name] = ln
            cur = name
            ordinal = collections.Counter()
            w.templates.append((name, ln))
            w.records.append(Rec(fname, ln, name, "header", b"", b"#template", None))
            i = skip_to_open(i)
            continue
        if line == b"}":
            cur = None
            continue
        if line.startswith(b"element"):
            parts = split_ws(line)
            if len(parts) < 2:
                w.aborted_at = ln
                w.abort_reason = "Bad effect system element line (parseEffectFile returns)"
                break
            etype = parts[1]
            i = skip_to_open(i)
            ordn = sum(ordinal.values())
            ordinal[etype] += 1
            w.blocks.append((cur, "element", etype, ordn, ln))
            w.records.append(Rec(fname, ln, cur, "element", etype, b"#block", None, ordn))
            # parseNewElement: unknown type -> skipToNextCloseBrace; known -> attributes until '}'
            while i < n:
                l = lines[i]
                lnn = i + 1
                i += 1
                if not l or l.startswith(b"//"):
                    continue
                if l == b"}":
                    break
                k, v = key_value(l)
                w.records.append(Rec(fname, lnn, cur, "element", etype, k, v, ordn))
            continue
        k, v = key_value(line)
        w.records.append(Rec(fname, ln, cur, "effect", b"", k, v))
    return w


# --------------------------------------------------------------------------------------------------- skills
SKILL_BLOCKS = (b"AnimEffect", b"Ribbon", b"Sound", b"SceneLight", b"CameraShake", b"ComplexBlur")


def walk_skill(path):
    lines = read_lines(path)
    w = Walk(path)
    fname = os.path.basename(path)
    seen = {}
    n = len(lines)
    i = 0
    cur = None
    ordinal = collections.Counter()

    def skip_to_open(i):
        while i < n:
            l = lines[i]
            i += 1
            if l == b"{":
                break
        return i

    def skip_to_close(i):
        while i < n:
            l = lines[i]
            i += 1
            if l == b"}":
                break
        return i

    while i < n:
        line = lines[i]
        ln = i + 1
        i += 1
        if not line or line.startswith(b"//"):
            continue
        if cur is None:
            parts = split_ws(line)
            if not parts or parts[0] != b"skill" or len(parts) != 2:
                w.records.append(Rec(fname, ln, b"", "toplevel", b"", b"#wrong-skill-name-line", line))
                continue
            name = parts[1]
            if name in seen:
                w.duplicates.append((name, ln, seen[name]))
                w.aborted_at = ln
                w.abort_reason = "duplicate skill template -> createSkillTemplate throws (rest of file lost)"
                break
            seen[name] = ln
            cur = name
            ordinal = collections.Counter()
            w.templates.append((name, ln))
            w.records.append(Rec(fname, ln, name, "header", b"", b"#template", None))
            i = skip_to_open(i)
            continue
        if line == b"}":
            cur = None
            continue
        if line in SKILL_BLOCKS:
            i = skip_to_open(i)
            ordn = ordinal[line]
            ordinal[line] += 1
            w.blocks.append((cur, "skill", line, ordn, ln))
            w.records.append(Rec(fname, ln, cur, "skillblock", line, b"#block", None, ordn))
            while i < n:
                l = lines[i]
                lnn = i + 1
                i += 1
                if not l or l.startswith(b"//"):
                    continue
                if l == b"}":
                    break
                k, v = key_value(l)
                w.records.append(Rec(fname, lnn, cur, "skillblock", line, k, v, ordn))
            continue
        if b" " not in line and b"\t" not in line:
            # CYS: bare token = unknown sub-block, skipped as a whole
            w.records.append(Rec(fname, ln, cur, "skillblock", line, b"#unknown-block", None))
            i = skip_to_open(i)
            i = skip_to_close(i)
            continue
        k, v = key_value(line)
        w.records.append(Rec(fname, ln, cur, "skill", b"", k, v))
    return w


# --------------------------------------------------------------------------------------------------- references
OBJ_EFFECT_RE = re.compile(rb'<Effect\b[^>]*?\beffect="([^"]*)"')
OBJ_NAME_RE = re.compile(rb'<Object\s+name="([^"]*)"')
SCENE_OBJ_RE = re.compile(rb'<Object\s+type="([^"]*)"[^>]*>(.*?)</Object>', re.S)
SCENE_PROP_RE = re.compile(rb'<Property\s+name="([^"]*)"\s+value="([^"]*)"')


def obj_effect_refs(all_obj_path):
    """all.obj: object name -> list of effect names from <Effects><Effect effect=.../>"""
    out = {}
    if not os.path.exists(all_obj_path):
        return out
    data = open(all_obj_path, "rb").read()
    starts = [(m.start(), m.group(1)) for m in OBJ_NAME_RE.finditer(data)]
    for idx, (pos, name) in enumerate(starts):
        end = starts[idx + 1][0] if idx + 1 < len(starts) else len(data)
        effs = OBJ_EFFECT_RE.findall(data, pos, end)
        if effs:
            out.setdefault(name, []).extend(effs)
    return out


def scene_refs(scene_path):
    """.Scene: particle systems, effects, models placed in the scene (+ their properties)."""
    data = open(scene_path, "rb").read()
    out = []
    for m in SCENE_OBJ_RE.finditer(data):
        props = dict(SCENE_PROP_RE.findall(m.group(2)))
        out.append((m.group(1), props))
    return out


def table_tokens(config_dir, max_bytes=64 << 20):
    """Tokens of every table in Config (text or 00CCBBDD binary): usage weight from DBC/tables."""
    c = collections.Counter()
    if not config_dir or not os.path.isdir(config_dir):
        return c
    for root, _dirs, files in os.walk(config_dir):
        for fn in files:
            p = os.path.join(root, fn)
            try:
                if os.path.getsize(p) > max_bytes:
                    continue
                data = open(p, "rb").read()
            except OSError:
                continue
            for tok in re.split(rb"[\x00\t\r\n]+", data):
                tok = tok.strip(b" ")
                if 2 <= len(tok) <= 200:
                    c[tok] += 1
    return c


def locate_data(data_dir):
    """client_GL layout (EffectFolder, ...) or CY / 0.85 layout (Effect, ...)."""
    gl = os.path.isdir(os.path.join(data_dir, "EffectFolder"))
    eff = os.path.join(data_dir, "EffectFolder" if gl else "Effect")
    model = os.path.join(data_dir, "ModelFolder" if gl else "Model")
    cfg = os.path.join(data_dir, "ConfigFolder" if gl else "Config")
    scene = os.path.join(data_dir, "SceneFolder" if gl else "Scene")
    return {
        "layout": "gl" if gl else "cy",
        "particle": os.path.join(eff, "all.particle"),
        "effect": os.path.join(eff, "all.effect"),
        "skill": os.path.join(eff, "all.skill"),
        "obj": os.path.join(model, "all.obj"),
        "config": cfg,
        "scene": scene,
        "effect_dir": eff,
    }


def gbk(b):
    if b is None:
        return ""
    return b.decode("gbk", "replace")
