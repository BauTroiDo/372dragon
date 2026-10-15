# -*- coding: utf-8 -*-
"""fx-audit census: what the REAL runtime rejects or ignores in the effect data, per occurrence, with examples and
usage weight.

Inputs per data set
  * runtime dump of TlbbViewer --fx-census (OgreMain particle factories + Plugin_ParticleFX2 + WXCore effect/skill
    parsers + CYS affectors/elements): dict.tsv, ptemplates.tsv, pparams.tsv, effects.tsv, skills.tsv, passes.tsv,
    textures.tsv, resources.tsv and census.log (LML_NORMAL: every rejected particle line with file:line);
  * the data files, walked like the runtime parsers (fx_static.py) to attribute each runtime message to its template
    and to count all.effect / all.skill keys against the runtime dictionaries (EffectManager logs a bad element
    attribute only once per key - WXEffectManager.cpp:1260 _logErrorInfoOnce - so the log cannot give counts).

Output: Registry/fx/census-<set>.tsv (one row per issue group) and census-<set>-summary.json.

Usage
  py -3 Tools/fx/fx_census.py --set stage [--run]           # --run: (re)dump with the viewer first
  py -3 Tools/fx/fx_census.py --set all --run
"""
from __future__ import annotations

import argparse
import collections
import json
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fx_static as S  # noqa: E402

ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
VIEWER = os.path.join(ROOT, r"Build\cmake\fxaudit-x64\bin\TlbbViewer.exe")
RAW = os.path.join(ROOT, r"Build\Logs\2026-09-13-fx-audit\census-raw")
REGISTRY = os.path.join(ROOT, r"Registry\fx")
SETS = {
    "stage": os.path.join(ROOT, r"Build\gpt-p1-1-20260913\stage-91148e1\Data"),
    "canonical": os.path.join(ROOT, r"Assets\Canonical\Data"),
    "s2": os.path.normpath(os.path.join(ROOT, r"..\Tools\DATA NEW\DataCY31-08-26")),
    "canonicalcy": os.path.join(ROOT, r"Assets\CanonicalCY\Data"),   # CYS-FX: CY 3.71.9609 staged (fx-cy 14/09)
}
QUOTA_OUTLIER = 2000          # particles per system
IGNORED_KEYS = os.path.join(HERE, "ignored_keys.tsv")


# --------------------------------------------------------------------------------------------------- runtime dump
def read_tsv(path):
    rows = []
    if not os.path.exists(path):
        return rows
    with open(path, "rb") as f:
        header = f.readline().rstrip(b"\r\n").split(b"\t")
        for line in f:
            cols = line.rstrip(b"\r\n").split(b"\t")
            if len(cols) < len(header):
                cols += [b""] * (len(header) - len(cols))
            rows.append(dict(zip([h.decode() for h in header], cols)))
    return rows


def run_viewer(viewer, data, rawdir, cache):
    os.makedirs(rawdir, exist_ok=True)
    cmd = [viewer, "--data", data, "--fx-census", rawdir, "--shader-cache", cache, "--size", "320x240",
           "--fsaa", "0"]
    t0 = time.time()
    p = subprocess.run(cmd, cwd=os.path.dirname(viewer), capture_output=True)
    with open(os.path.join(rawdir, "viewer-output.txt"), "wb") as f:
        f.write(b"cmd: " + " ".join(cmd).encode("utf-8", "replace") + b"\n")
        f.write(b"exit: %d\nseconds: %.1f\n--- stdout\n" % (p.returncode, time.time() - t0))
        f.write(p.stdout + b"\n--- stderr\n" + p.stderr)
    return p.returncode, time.time() - t0


class Runtime:
    def __init__(self, rawdir, dict_path=None):
        self.dir = rawdir
        self.dict = collections.defaultdict(set)          # (scope, type) -> params
        self.defaults = {}                                # (scope, type, param) -> default value
        # dict_path: judge keys against another runtime's dictionaries (e.g. the frozen baseline run-b3), the
        # dictionaries do not depend on the data set
        self.dict_source = dict_path or os.path.join(rawdir, "dict.tsv")
        for r in read_tsv(self.dict_source):
            k = (r["scope"].decode(), r["type"])
            p = r["param"]
            if p.startswith(b"#"):
                self.dict.setdefault(k, set())
                continue
            self.dict[k].add(p)
            if "default" in r:
                self.defaults[(k[0], k[1], p)] = r["default"]
        self.ptemplates = {r["template"]: r for r in read_tsv(os.path.join(rawdir, "ptemplates.tsv"))}
        self.pparams = {}
        for r in read_tsv(os.path.join(rawdir, "pparams.tsv")):
            self.pparams[(r["template"], r["scope"].decode(), r["type"], int(r["ordinal"] or 0), r["param"])] = r["value"]
        self.effects = collections.defaultdict(list)
        self.effect_params = collections.defaultdict(dict)
        for r in read_tsv(os.path.join(rawdir, "effects.tsv")):
            if r["param"] == b"#element":
                self.effects[r["effect"]].append(r["type"])
            elif r["param"] == b"#effect":
                self.effects.setdefault(r["effect"], [])
            else:
                self.effect_params[r["effect"]][(r["element"], r["param"])] = r["value"]
        self.skills = set(r["skill"] for r in read_tsv(os.path.join(rawdir, "skills.tsv")))
        self.passes = collections.defaultdict(list)
        for r in read_tsv(os.path.join(rawdir, "passes.tsv")):
            self.passes[r["material"]].append(r)
        self.textures = collections.defaultdict(list)
        for r in read_tsv(os.path.join(rawdir, "textures.tsv")):
            self.textures[r["material"]].append(r)
        self.resources = set()
        for r in read_tsv(os.path.join(rawdir, "resources.tsv")):
            self.resources.add(r["name"].lower())
        self.log = os.path.join(rawdir, "census.log")

    def types(self, scope):
        return set(t for (s, t) in self.dict if s == scope)


# --------------------------------------------------------------------------------------------------- runtime log
RX = [
    ("emitter-attr", re.compile(rb"^Bad particle emitter attribute line: '(.*)' for emitter (\S+) \((.*):(\d+)\)$")),
    ("affector-attr", re.compile(rb"^Bad particle affector attribute line: '(.*)' for affector (\S+) \((.*):(\d+)\)$")),
    ("system-attr", re.compile(rb"^Bad particle system attribute line: '(.*)' in (.*) \((?:tried renderer|no renderer), (.*):(\d+)\)$")),
    ("emitter-type", re.compile(rb"^Particle system emitter doesn't exists at line: '(.*)' in (.*) \((.*):(\d+)\)$")),
    ("affector-type", re.compile(rb"^Particle system affector doesn't exists at line: '(.*)' in (.*) \((.*):(\d+)\)$")),
    ("bad-block", re.compile(rb"^Bad particle system (?:emitter|affector) line: '(.*)' in (.*) \((.*):(\d+)\)$")),
    ("exception", re.compile(rb"^CYS: particle script (.*):(\d+): '(.*)': (.*)$")),
]
RX_ONCE = re.compile(rb"^CYS FX \(reported once\): (\S+) : (.*?)(?: \[(.*)\])?$")
RX_SCRIPT_ERROR = re.compile(rb"^TlbbViewer: SCRIPT ERROR in (\S+)(.*)$")
RX_MATERIAL = re.compile(rb"^Error in material (.*) at line (\d+) of (.*): (.*)$")
RX_TS = re.compile(rb"^\d\d:\d\d:\d\d: (.*)$")


def parse_log(path):
    """-> dict (file, line) -> list of (kind, detail), plus once-messages, script errors, material errors, other."""
    by_line = collections.defaultdict(list)
    once = []
    script_errors = []
    material_errors = []
    renderer_msgs = collections.Counter()
    if not os.path.exists(path):
        return by_line, once, script_errors, material_errors, renderer_msgs
    with open(path, "rb") as f:
        for raw in f:
            m = RX_TS.match(raw.rstrip(b"\r\n"))
            if not m:
                continue
            msg = m.group(1)
            hit = False
            for kind, rx in RX:
                mm = rx.match(msg)
                if not mm:
                    continue
                hit = True
                if kind == "exception":
                    fname, ln, line, what = mm.groups()
                    by_line[(os.path.basename(fname.decode("gbk", "replace")), int(ln))].append((kind, line, what))
                else:
                    groups = mm.groups()
                    fname, ln = groups[-2], groups[-1]
                    by_line[(os.path.basename(fname.decode("gbk", "replace")), int(ln))].append((kind, groups[0], groups[1]))
                break
            if hit:
                continue
            mm = RX_ONCE.match(msg)
            if mm:
                once.append(mm.groups())
                continue
            mm = RX_SCRIPT_ERROR.match(msg)
            if mm:
                script_errors.append(msg)
                continue
            mm = RX_MATERIAL.match(msg)
            if mm:
                material_errors.append(mm.groups())
                continue
            if b"Renderer" in msg and (b"unknown" in msg or b"not supported" in msg or b"ignored" in msg):
                renderer_msgs[msg] += 1
    return by_line, once, script_errors, material_errors, renderer_msgs


# --------------------------------------------------------------------------------------------------- weights
def usage_weights(paths, walks, log=print):
    """effect weight = skill AnimEffect refs + all.obj <Effect> refs + scene Effect objects + table tokens;
    particle weight = sum over referencing effect elements of max(1, effect weight) + scene ParticleSystem objects
    + table tokens."""
    eff_w = collections.Counter()
    eff_src = collections.defaultdict(collections.Counter)
    par_w = collections.Counter()
    par_src = collections.defaultdict(collections.Counter)
    for r in walks["skill"].records:
        if r.scope == "skillblock" and r.type == b"AnimEffect" and r.key == b"EffectTemplateName" and r.value:
            eff_w[r.value] += 1
            eff_src[r.value]["skill"] += 1
    for obj, effs in S.obj_effect_refs(paths["obj"]).items():
        for e in effs:
            eff_w[e] += 1
            eff_src[e]["obj"] += 1
    scenes = 0
    if os.path.isdir(paths["scene"]):
        for fn in os.listdir(paths["scene"]):
            if not fn.lower().endswith(".scene"):
                continue
            scenes += 1
            try:
                objs = S.scene_refs(os.path.join(paths["scene"], fn))
            except OSError:
                continue
            for otype, props in objs:
                if otype == b"ParticleSystem":
                    n = props.get(b"particle system name")
                    if n:
                        par_w[n] += 1
                        par_src[n]["scene"] += 1
                elif otype == b"Effect":
                    n = props.get(b"effect name") or props.get(b"effect")
                    if n:
                        eff_w[n] += 1
                        eff_src[n]["scene"] += 1
    tokens = S.table_tokens(paths["config"])
    for name in list(walks["effect_names"]):
        t = tokens.get(name, 0)
        if t:
            eff_w[name] += t
            eff_src[name]["table"] += t
    elem_refs = collections.Counter()
    for r in walks["effect"].records:
        if r.scope == "element" and r.key == b"ParticleSystem" and r.value:
            elem_refs[r.value] += 1
            par_w[r.value] += max(1, eff_w.get(r.template, 0))
            par_src[r.value]["effect"] += 1
    for name in list(walks["particle_names"]):
        t = tokens.get(name, 0)
        if t:
            par_w[name] += t
            par_src[name]["table"] += t
    log("  weights: %d scenes, %d table tokens, %d effects referenced, %d particle templates referenced"
        % (scenes, len(tokens), len(eff_w), len(par_w)))
    return eff_w, eff_src, par_w, par_src


# --------------------------------------------------------------------------------------------------- value compare
NUM = re.compile(rb"^[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?$")


def same_value(a, b):
    if a is None or b is None:
        return a == b
    ta, tb = a.split(), b.split()
    if len(ta) != len(tb):
        return False
    for x, y in zip(ta, tb):
        if x == y:
            continue
        xl, yl = x.lower(), y.lower()
        if {xl, yl} <= {b"true", b"1", b"yes", b"on"} or {xl, yl} <= {b"false", b"0", b"no", b"off"}:
            continue
        if NUM.match(x) and NUM.match(y):
            fx, fy = float(x), float(y)
            if abs(fx - fy) <= 1e-3 * max(1.0, abs(fx), abs(fy)):
                continue
        return False
    return True


# --------------------------------------------------------------------------------------------------- census
def census(set_name, data, rawdir, out_dir, log=print, dict_path=None):
    paths = S.locate_data(data)
    rt = Runtime(rawdir, dict_path)
    t0 = time.time()
    emit_types = set(rt.types("emitter"))
    aff_types = set(rt.types("affector"))
    elem_types = set(rt.types("element"))
    walks = {
        "particle": S.walk_particle(paths["particle"], emit_types or None, aff_types or None),
        "effect": S.walk_effect(paths["effect"], elem_types or None),
        "skill": S.walk_skill(paths["skill"]),
    }
    walks["effect_names"] = [n for n, _ in walks["effect"].templates]
    walks["particle_names"] = [n for n, _ in walks["particle"].templates]
    log("  static walk %.1f s: %d particle templates, %d effects, %d skills"
        % (time.time() - t0, len(walks["particle"].templates), len(walks["effect"].templates),
           len(walks["skill"].templates)))
    eff_w, eff_src, par_w, par_src = usage_weights(paths, walks, log)
    by_line, once, script_errors, material_errors, renderer_msgs = parse_log(rt.log)
    ignored = load_ignored()

    groups = collections.OrderedDict()

    def add(category, status, scope, btype, key, value, template, where, weight, group_value=False):
        gk = (category, status, scope, btype, key, value if group_value else b"")
        g = groups.get(gk)
        if g is None:
            g = groups[gk] = {"occ": 0, "templates": collections.Counter(), "values": collections.Counter(),
                              "where": where, "weight": 0}
        g["occ"] += 1
        if template not in g["templates"]:
            g["weight"] += weight
        g["templates"][template] += 1
        if value is not None:
            g["values"][value] += 1

    # ---- particles: runtime messages joined per line
    pw = walks["particle"]
    pfile = os.path.basename(paths["particle"])
    line_rec = {}
    for r in pw.records:
        line_rec[r.line] = r
    counted_blocks = set()
    stats = collections.Counter()
    last_value = {}
    for r in pw.records:
        if r.key.startswith(b"#"):
            continue
        stats["particle lines"] += 1
        msgs = by_line.get((pfile, r.line))
        w = par_w.get(r.template, 0)
        where = "%s:%d" % (pfile, r.line)
        if msgs:
            for kind, a, b in msgs:
                if kind in ("emitter-attr", "affector-attr"):
                    add("particle", "rejected-key", r.scope, r.type, r.key, r.value, r.template, where, w)
                    stats["particle rejected"] += 1
                elif kind == "system-attr":
                    add("particle", "rejected-key", "system/renderer", b"", r.key, r.value, r.template, where, w)
                    stats["particle rejected"] += 1
                elif kind == "exception":
                    add("particle", "rejected-value(exception)", r.scope, r.type, r.key, r.value, r.template,
                        where + " " + b.decode("gbk", "replace")[:80], w, group_value=True)
                    stats["particle rejected"] += 1
            continue
        if r.scope in ("emitter", "affector") and ((r.scope == "emitter" and emit_types and r.type not in emit_types)
                                                   or (r.scope == "affector" and aff_types and r.type not in aff_types)):
            add("particle", "unknown-type(block skipped)", r.scope, r.type, b"*", None, r.template, where, w)
            stats["particle rejected"] += 1
            continue
        ik = (r.scope, r.type.decode("gbk", "replace").lower(), r.key.decode("gbk", "replace").lower())
        ig = ignored.get(ik)
        if ig and not ignored.is_noop(ik, r.value):
            add("particle", "accepted-but-ignored", r.scope, r.type, r.key, r.value, r.template, where + " " + ig, w)
            stats["particle ignored"] += 1
        last_value[(r.template, r.scope, r.type, r.ordinal, r.key)] = (r.value, where)

    # value check: data value (last occurrence in its block) vs runtime value (non-default dump or default)
    if rt.pparams or rt.defaults:
        for (tpl, scope, btype, ordn, key), (value, where) in last_value.items():
            dscope = "system" if scope == "system" else scope
            if scope == "system":
                rkey = (tpl, "system", b"ParticleSystem", 0, key)
                dkey = ("system", b"ParticleSystem", key)
                if rkey not in rt.pparams and dkey not in rt.defaults:
                    rtpl = rt.ptemplates.get(tpl)
                    rname = rtpl["renderer"] if rtpl else b""
                    rkey = (tpl, "renderer", rname, 0, key)
                    dkey = ("renderer", rname, key)
            else:
                rkey = (tpl, dscope, btype, ordn, key)
                dkey = (dscope, btype, key)
            if dkey not in rt.defaults and rkey not in rt.pparams:
                continue
            if tpl not in rt.ptemplates:
                continue
            runtime_value = rt.pparams.get(rkey, rt.defaults.get(dkey))
            if runtime_value is None or runtime_value.startswith(b"#get"):
                continue
            if not same_value(value, runtime_value):
                stats["particle value-mismatch"] += 1
                add("particle", "value-not-applied(review)", scope, btype, key, value, tpl,
                    where + " runtime=" + runtime_value.decode("gbk", "replace")[:40], par_w.get(tpl, 0))

    for name, ln, first in pw.duplicates:
        add("particle", "duplicate-template(block skipped)", "template", b"", b"", None, name,
            "%s:%d (first %d)" % (pfile, ln, first), par_w.get(name, 0))

    # ---- effects: keys against the runtime dictionaries (the log reports each key once)
    ew = walks["effect"]
    efile = os.path.basename(paths["effect"])
    effect_dict = rt.dict.get(("effect", b"Effect"), set())
    for r in ew.records:
        if r.key.startswith(b"#"):
            if r.key == b"#block" and elem_types and r.type not in elem_types:
                add("effect", "unknown-element(block skipped)", "element", r.type, b"*", None, r.template,
                    "%s:%d" % (efile, r.line), eff_w.get(r.template, 0))
            continue
        where = "%s:%d" % (efile, r.line)
        w = eff_w.get(r.template, 0)
        stats["effect lines"] += 1
        if r.value is None:
            add("effect", "bad-line(no value)", r.scope, r.type, r.key, None, r.template, where, w)
            continue
        if r.scope == "element":
            if elem_types and r.type not in elem_types:
                continue
            d = rt.dict.get(("element", r.type))
            if d is not None and r.key not in d:
                add("effect", "rejected-key", "element", r.type, r.key, r.value, r.template, where, w)
                stats["effect rejected"] += 1
                continue
        elif r.scope == "effect":
            if effect_dict and r.key not in effect_dict:
                add("effect", "rejected-key", "effect", b"", r.key, r.value, r.template, where, w)
                stats["effect rejected"] += 1
                continue
        ik = (r.scope, r.type.decode("gbk", "replace").lower(), r.key.decode("gbk", "replace").lower())
        ig = ignored.get(ik)
        if ig and not ignored.is_noop(ik, r.value):
            add("effect", "accepted-but-ignored", r.scope, r.type, r.key, r.value, r.template, where + " " + ig, w)
            stats["effect ignored"] += 1
    if ew.aborted_at:
        lost = sum(1 for n, l in ew.templates if l > ew.aborted_at)
        add("effect", "FILE-ABORT", "file", b"", b"", None, b"all.effect",
            "%s:%d %s" % (efile, ew.aborted_at, ew.abort_reason), 0)
        stats["effect templates lost by abort (static)"] = lost

    # ---- skills
    sw = walks["skill"]
    sfile = os.path.basename(paths["skill"])
    for r in sw.records:
        where = "%s:%d" % (sfile, r.line)
        if r.key == b"#unknown-block":
            add("skill", "unknown-subblock(skipped)", "skill", r.type, b"*", None, r.template, where, 1)
            continue
        if r.key.startswith(b"#"):
            continue
        stats["skill lines"] += 1
        if r.scope == "skill":
            d = rt.dict.get(("skill", b"Skill"))
        else:
            d = rt.dict.get(("skill", r.type))
        if d is not None and d and r.key not in d:
            add("skill", "rejected-key", r.scope, r.type, r.key, r.value, r.template, where, 1)
            stats["skill rejected"] += 1
    if sw.aborted_at:
        add("skill", "FILE-ABORT", "file", b"", b"", None, b"all.skill",
            "%s:%d %s" % (sfile, sw.aborted_at, sw.abort_reason), 0)

    # ---- references: effect -> particle template, particle -> material -> texture, mesh names, skill -> effect
    runtime_effects = set(rt.effects.keys())
    for r in ew.records:
        if r.scope != "element" or not r.value:
            continue
        where = "%s:%d" % (efile, r.line)
        if r.key == b"ParticleSystem" and r.type in (b"Particle", b"UIParticle"):
            if rt.ptemplates and r.value not in rt.ptemplates:
                add("reference", "missing-particle-template", "element", r.type, r.key, r.value, r.template, where,
                    eff_w.get(r.template, 0), group_value=True)
        elif r.key.lower() in (b"meshname", b"mesh") and rt.resources:
            if r.value.lower() not in rt.resources:
                add("reference", "missing-mesh", "element", r.type, r.key, r.value, r.template, where,
                    eff_w.get(r.template, 0), group_value=True)
    for r in sw.records:
        if r.scope == "skillblock" and r.type == b"AnimEffect" and r.key == b"EffectTemplateName" and r.value:
            if runtime_effects and r.value not in runtime_effects:
                add("reference", "missing-effect-template", "skill", b"AnimEffect", r.key, r.value, r.template,
                    "%s:%d" % (sfile, r.line), 1, group_value=True)
    used_materials = collections.Counter()
    for name, t in rt.ptemplates.items():
        mat = t["material"]
        if mat:
            used_materials[mat] += 1
        if t["material_exists"] == b"0" and mat:
            add("reference", "missing-material(particle)", "system", b"", b"material", mat, name,
                t["origin"].decode("gbk", "replace"), par_w.get(name, 0), group_value=True)
        try:
            q = int(t["quota"])
        except ValueError:
            q = 0
        if q >= QUOTA_OUTLIER:
            add("cost", "quota-outlier(>=%d)" % QUOTA_OUTLIER, "system", t["renderer"], b"quota", t["quota"], name,
                t["origin"].decode("gbk", "replace"), par_w.get(name, 0), group_value=True)
    # Texture existence: the runtime answer (textures.tsv) when the dump covers the material, else the static
    # fallback (material scripts + the file names the ANSI enumeration can see). A missing name that exists on disk
    # under a CJK name (not representable in cp1252) is reported as unreachable, not missing.
    static = {}

    def ensure_static():
        if not static:
            roots = data_roots(data, paths["layout"])
            static["tex"] = static_material_textures(roots)
            static["reachable"], static["unreachable"] = ansi_index(roots)
            log("  static texture fallback: %d materials, %d reachable / %d unreachable file names"
                % (len(static["tex"]), len(static["reachable"]), len(static["unreachable"])))
        return static

    covered = 0
    for mat in used_materials:
        rows = rt.textures.get(mat)
        if rows:
            covered += 1
            for tx in rows:
                if tx["exists"] == b"0":
                    st = ensure_static()
                    status = ("unreachable-texture(CJK file name)" if tx["texture"].lower() in st["unreachable"]
                              else "missing-texture(particle material)")
                    add("reference", status, "material", b"", mat, tx["texture"], mat,
                        "tech %s pass %s tu %s" % (tx["tech"].decode(), tx["pass"].decode(), tx["tu"].decode()),
                        used_materials[mat], group_value=True)
            continue
        st = ensure_static()
        for tex in st["tex"].get(mat, []):
            low = tex.lower()
            if low.startswith(b"<") or low in st["reachable"]:
                continue
            status = ("unreachable-texture(CJK file name, static)" if low in st["unreachable"]
                      else "missing-texture(particle material, static)")
            add("reference", status, "material", b"", mat, tex, mat, "material script (static fallback)",
                used_materials[mat], group_value=True)
    stats["particle materials covered by the runtime dump"] = covered
    stats["particle materials"] = len(used_materials)
    # Mesh particle renderer: mesh_name must resolve, else MeshParticleRenderer throws
    # ResourceGroupManager::findGroupContainingResource (OgreResourceGroupManager.cpp:1375) and the whole effect
    # fails to create (seen in the sheets: K31 g01_ts_梅花三弄 -> 梅花.mesh, E088 -> 冰晶.mesh).
    st = ensure_static()
    mesh_known = set(r.lower() for r in rt.resources) if rt.resources else None
    for (tpl, scope, rtype, _ordn, key), value in rt.pparams.items():
        if scope != "renderer" or key != b"mesh_name" or not value:
            continue
        low = value.lower()
        found = (low in mesh_known) if mesh_known is not None else (low in st["reachable"])
        if found:
            continue
        status = ("unreachable-mesh(CJK file name; effect creation throws)" if low in st["unreachable"]
                  else "missing-mesh(particle renderer; effect creation throws)")
        add("reference", status, "renderer", rtype, key, value, tpl, "pparams.tsv", par_w.get(tpl, 0),
            group_value=True)
    for mat in used_materials:
        for ps in rt.passes.get(mat, []):
            if ps["tech"] != b"0":
                continue
            if ps["src"] == b"one" and ps["dst"] == b"zero":
                add("material", "opaque-pass(particle material, no blending)", "material", b"", mat,
                    b"%s/%s depth_write=%s" % (ps["src"], ps["dst"], ps["depth_write"]), mat,
                    "pass %s" % ps["pass"].decode(), used_materials[mat])
    for msg in script_errors:
        add("script", "FILE-ABORT(runtime)", "file", b"", b"", msg[:200], b"", "census.log", 0)
    for name, ln, fname, what in material_errors:
        add("material", "material-script-error", "material", b"", what.split(b" ")[0][:60], what[:120], name,
            "%s:%s" % (fname.decode("gbk", "replace"), ln.decode()), used_materials.get(name, 0), group_value=True)
    for msg, n in renderer_msgs.items():
        add("particle", "renderer-message", "renderer", b"", b"", msg[:160], b"", "census.log x%d" % n, 0,
            group_value=True)
    for fn, desc, token in once:
        add("log-once", "reported-once", "log", fn, token or b"", desc[:160], b"", "census.log", 0, group_value=True)
    for key, params in rt.dict.items():
        scope, btype = key
        if scope in ("emitter", "affector"):
            for p in params:
                if p != p.lower():
                    add("runtime", "dictionary-key-not-lowercase(never matched)", scope, btype, p, None, b"",
                        "dict.tsv", 0)

    # ---- write
    os.makedirs(out_dir, exist_ok=True)
    rows = []
    for (category, status, scope, btype, key, value), g in groups.items():
        examples = [t for t, _ in g["templates"].most_common(3)]
        top_value = g["values"].most_common(1)[0][0] if g["values"] else (value or b"")
        rows.append({
            "set": set_name, "category": category, "status": status, "scope": scope,
            "type": S.gbk(btype), "key": S.gbk(key), "value": S.gbk(value if value else top_value)[:120],
            "occurrences": g["occ"], "templates": len(g["templates"]), "weight": g["weight"],
            "examples": " | ".join(S.gbk(e) for e in examples), "where": g["where"],
        })
    rows.sort(key=lambda r: (-(r["weight"] + r["occurrences"]), r["category"], r["status"]))
    cols = ["set", "category", "status", "scope", "type", "key", "value", "occurrences", "templates", "weight",
            "examples", "where"]
    tsv = os.path.join(out_dir, "census-%s.tsv" % set_name)
    with open(tsv, "w", encoding="utf-8", newline="\n") as f:
        f.write("\t".join(cols) + "\n")
        for r in rows:
            f.write("\t".join(str(r[c]).replace("\t", " ").replace("\n", " ") for c in cols) + "\n")
    by_status = collections.Counter()
    for r in rows:
        by_status[(r["category"], r["status"])] += r["occurrences"]
    summary = {
        "set": set_name, "data": data, "runtime_dump": rawdir, "layout": paths["layout"],
        "dictionaries": rt.dict_source,
        "static": {"particle_templates": len(pw.templates), "effects": len(ew.templates),
                   "skills": len(sw.templates), "particle_duplicates": len(pw.duplicates),
                   "effect_abort": [ew.aborted_at, ew.abort_reason], "skill_abort": [sw.aborted_at, sw.abort_reason]},
        "runtime": {"particle_templates": len(rt.ptemplates), "effects": len(rt.effects),
                    "skills": len(rt.skills), "materials": len(rt.passes), "dict_types": len(rt.dict),
                    "script_errors": len(script_errors)},
        "counts": {k: v for k, v in stats.items()},
        "by_status": {"%s/%s" % k: v for k, v in sorted(by_status.items(), key=lambda kv: -kv[1])},
        "top": rows[:40],
    }
    with open(os.path.join(out_dir, "census-%s-summary.json" % set_name), "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)
    log("  %s: %d issue groups -> %s" % (set_name, len(rows), tsv))
    return summary


GL_FOLDERS = ["EffectFolder", "ModelFolder"] + ["Model%dFolder" % i for i in range(2, 9)] + \
    ["InterfaceFolder", "MaterialFolder"] + ["Material%dFolder" % i for i in range(2, 9)] + \
    ["SoundFolder", "ConfigFolder", "BrushesFolder", "SceneFolder", "Scene2Folder", "MaterialTemplates", "OgreCore"]
CY_FOLDERS = ["Effect", "Model"] + ["Model%d" % i for i in range(2, 9)] + ["Interface", "Material"] + \
    ["Material%d" % i for i in range(2, 9)] + ["Sound", "Config", "Brushes", "Scene", "Scene2", "MaterialTemplates",
                                                "OgreCore"]


def data_roots(data, layout):
    """The folders TlbbViewer registers as resource locations (ViewerApp::addResourceLocations)."""
    names = GL_FOLDERS if layout == "gl" else CY_FOLDERS
    return [os.path.join(data, n) for n in names if os.path.isdir(os.path.join(data, n))]


MAT_RE = re.compile(rb"^\s*material\s+([^:{]+?)\s*(?::\s*(\S+))?\s*$")
TEX_RE = re.compile(rb"^\s*(?:texture|anim_texture|cubic_texture)\s+(\S+)")


def static_material_textures(data_paths):
    """material -> texture names from the .material scripts of the data (fallback when the runtime dump of the
    materials is incomplete). Only 'texture' / 'anim_texture' / 'cubic_texture' first arguments."""
    out = collections.defaultdict(list)
    for root in data_paths:
        for r, _dirs, files in os.walk(root):
            for fn in files:
                if not fn.lower().endswith(".material"):
                    continue
                cur = None
                try:
                    data = open(os.path.join(r, fn), "rb").read()
                except OSError:
                    continue
                for line in data.split(b"\n"):
                    m = MAT_RE.match(line)
                    if m:
                        cur = m.group(1).strip()
                        continue
                    t = TEX_RE.match(line)
                    if t and cur is not None:
                        out[cur].append(t.group(1))
    return out


def ansi_index(data_paths):
    """Lower-case file names as the engine's ANSI enumeration (_findfirst under ACP 1252) sees them: names that
    cp1252 cannot represent are unreachable and are left out (FACT OgreFileSystem.cpp:318/374)."""
    reachable, unreachable = set(), set()
    for root in data_paths:
        for _r, _dirs, files in os.walk(root):
            for fn in files:
                try:
                    reachable.add(fn.encode("cp1252").lower())
                except UnicodeEncodeError:
                    try:
                        unreachable.add(fn.encode("gbk").lower())
                    except UnicodeEncodeError:
                        pass
    return reachable, unreachable


class IgnoredKeys(dict):
    """(scope, type lower, key lower) -> evidence; type '*' matches every type. Values listed as no-op in the
    5th column are not counted (e.g. ParEffectName NullEffect)."""

    def __init__(self):
        super().__init__()
        self.noop = {}

    def get(self, k, default=None):
        scope, btype, key = k
        for kk in ((scope, btype, key), (scope, "*", key)):
            if dict.__contains__(self, kk):
                return dict.__getitem__(self, kk)
        return default

    def is_noop(self, k, value):
        scope, btype, key = k
        for kk in ((scope, btype, key), (scope, "*", key)):
            if kk in self.noop:
                v = (value or b"").decode("gbk", "replace").strip().lower()
                return v in self.noop[kk]
        return False


def load_ignored():
    out = IgnoredKeys()
    if not os.path.exists(IGNORED_KEYS):
        return out
    with open(IGNORED_KEYS, encoding="utf-8") as f:
        for line in f:
            if not line.strip() or line.startswith("#"):
                continue
            cols = line.rstrip("\n").split("\t")
            if len(cols) >= 4:
                k = (cols[0], cols[1].lower(), cols[2].lower())
                dict.__setitem__(out, k, cols[3])
                if len(cols) >= 5:
                    out.noop[k] = set(v.strip().lower() for v in cols[4].split(","))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--set", default="all", help="stage | canonical | s2 | all")
    ap.add_argument("--data", help="data folder (default: the known folder of --set)")
    ap.add_argument("--run", action="store_true", help="run TlbbViewer --fx-census first")
    ap.add_argument("--viewer", default=VIEWER)
    ap.add_argument("--raw", default=RAW, help="runtime dump root (per set sub-folder)")
    ap.add_argument("--out", default=REGISTRY)
    ap.add_argument("--dict", help="dict.tsv of another runtime dump to judge keys with (baseline)")
    a = ap.parse_args()
    names = list(SETS) if a.set == "all" else [a.set]
    for name in names:
        data = a.data or SETS[name]
        rawdir = os.path.join(a.raw, name)
        print("[%s] %s" % (name, data), flush=True)
        if a.run:
            cache = os.path.join(os.path.dirname(a.viewer), "..", "ShaderCache-" + name)
            rc, sec = run_viewer(a.viewer, data, rawdir, os.path.normpath(cache))
            print("  viewer --fx-census exit %d in %.1f s" % (rc, sec), flush=True)
        census(name, data, rawdir, a.out, dict_path=a.dict)


if __name__ == "__main__":
    main()
