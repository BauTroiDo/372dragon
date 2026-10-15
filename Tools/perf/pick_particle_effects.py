#!/usr/bin/env python3
"""CYS-PERF: ranks effects by particle load (static estimate from the data, no rendering).

  pick_particle_effects.py [--data Assets/Canonical/Data] [--top 5] [--json OUT]

For every particle system template of EffectFolder/all.particle: quota and, per emitter, emission_rate x mean
time_to_live (steady-state particles of the emitter). For every effect of all.effect: the templates of its
"element Particle" blocks. Estimated live particles of an effect = sum over its systems of
min(quota, sum of emitter steady states). The ranking is restricted to the effect cases of
Tests/oracle/cases.json (known-loadable in TlbbViewer) and also printed for the whole data set.
Both files are GBK; names are compared as decoded text.
"""
import argparse
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))


def tokens(line):
    return line.strip().split(None, 1)


def parse_particles(path):
    """name -> {"quota": int, "emitters": [(rate, ttl)], "est": float}"""
    text = open(path, "rb").read().decode("gbk", "replace")
    systems = {}
    name, depth, current, emitter = None, 0, None, None
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("//"):
            continue
        if line == "{":
            depth += 1
            continue
        if line == "}":
            if depth == 2 and emitter is not None:
                current["emitters"].append(emitter)
                emitter = None
            depth -= 1
            if depth == 0 and current is not None:
                systems[name] = current
                current = None
            continue
        if depth == 0:
            name, current = line, {"quota": 10, "emitters": []}
            continue
        parts = tokens(line)
        key = parts[0].lower()
        value = parts[1] if len(parts) > 1 else ""
        if depth == 1:
            if key == "quota":
                try:
                    current["quota"] = int(float(value.split()[0]))
                except ValueError:
                    pass
            elif key == "emitter":
                emitter = {"rate": 10.0, "ttl_min": 5.0, "ttl_max": 5.0}
        elif depth == 2 and emitter is not None:
            try:
                number = float(value.split()[0]) if value else 0.0
            except ValueError:
                continue
            if key == "emission_rate":
                emitter["rate"] = number
            elif key == "time_to_live":
                emitter["ttl_min"] = emitter["ttl_max"] = number
            elif key == "time_to_live_min":
                emitter["ttl_min"] = number
            elif key == "time_to_live_max":
                emitter["ttl_max"] = number
    for s in systems.values():
        steady = sum(e["rate"] * 0.5 * (e["ttl_min"] + e["ttl_max"]) for e in s["emitters"])
        s["est"] = min(float(s["quota"]), steady)
    return systems


def parse_effects(path):
    """effect name -> [particle system template names]"""
    text = open(path, "rb").read().decode("gbk", "replace")
    effects, name, depth, in_particle = {}, None, 0, False
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        if line == "{":
            depth += 1
            continue
        if line == "}":
            depth -= 1
            if depth <= 1:
                in_particle = False
            continue
        parts = tokens(line)
        if depth == 0 and parts[0] == "effect" and len(parts) > 1:
            name = parts[1].strip()
            effects[name] = []
        elif depth == 1 and parts[0] == "element":
            in_particle = len(parts) > 1 and parts[1].strip() == "Particle"
        elif depth == 2 and in_particle and parts[0] == "ParticleSystem" and len(parts) > 1 and name is not None:
            effects[name].append(parts[1].strip())
    return effects


def rank(effects, systems, names):
    rows = []
    for name in names:
        templates = effects.get(name, [])
        found = [systems[t] for t in templates if t in systems]
        rows.append({
            "effect": name,
            "systems": len(templates),
            "missing_templates": len(templates) - len(found),
            "quota_sum": sum(s["quota"] for s in found),
            "est_particles": round(sum(s["est"] for s in found), 1),
            "emitters": sum(len(s["emitters"]) for s in found),
        })
    rows.sort(key=lambda r: (r["est_particles"], r["quota_sum"]), reverse=True)
    return rows


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--data", default=os.path.join(ROOT, "Assets", "Canonical", "Data"))
    parser.add_argument("--top", type=int, default=5)
    parser.add_argument("--json")
    args = parser.parse_args(argv)
    systems = parse_particles(os.path.join(args.data, "EffectFolder", "all.particle"))
    effects = parse_effects(os.path.join(args.data, "EffectFolder", "all.effect"))
    with open(os.path.join(ROOT, "Tests", "oracle", "cases.json"), encoding="utf-8") as handle:
        cases = json.load(handle)["effects"]
    case_ids = {c["effect"]: c["id"] for c in cases}
    oracle = rank(effects, systems, list(case_ids))
    for row in oracle:
        row["case"] = case_ids[row["effect"]]
    overall = rank(effects, systems, list(effects))[:25]
    result = {"particle_systems": len(systems), "effects": len(effects),
              "oracle_top": oracle[:args.top], "oracle_all": oracle, "overall_top25": overall}
    print("particle system templates: %d, effects: %d" % (len(systems), len(effects)))
    print("oracle effect cases by estimated live particles:")
    for row in oracle[: max(args.top, 10)]:
        print("  %s %-60s systems=%d quota=%d est=%.0f emitters=%d missing=%d" % (
            row["case"], row["effect"], row["systems"], row["quota_sum"], row["est_particles"], row["emitters"],
            row["missing_templates"]))
    print("whole data set, top 10:")
    for row in overall[:10]:
        print("  %-60s systems=%d quota=%d est=%.0f" % (row["effect"], row["systems"], row["quota_sum"], row["est_particles"]))
    if args.json:
        with open(args.json, "w", encoding="utf-8") as handle:
            json.dump(result, handle, ensure_ascii=False, indent=1)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
