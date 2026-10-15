# -*- coding: utf-8 -*-
"""V06 effect_strict - strict parse of all.effect / all.particle blocks and their references
(Docs/05 muc 6.4 / 7, Docs/08 muc 4.1-4.4: the effect parser has no comment syntax and silently drops
everything after a stray depth-0 line).

check_effect(): the block is 'effect NAME' + '{' ... '}' with balanced braces and nothing after the final
brace; every nested block is 'element <Type>' with a Type of the S1 vocabulary (Particle, NewRibbonTrail,
Beam, Projector, PointLight, UIParticle, BillboardSet); no '//' text (error: the engine reads it as data);
ParticleSystem -> all.particle, ParEffectName / ColEffectName -> all.effect (or NullEffect), Material ->
all.material.
check_particle(): same brace rules; nested blocks are emitter/affector of the S1 vocabulary (read from
Docs/evidence/assetinv/fxkeys.json when present; unknown = warn); 'material' -> all.material,
'mesh_name' -> an existing file.
check_file(): the whole file has no more depth-0 stray lines than the base file.
"""
import json
import os

from .common import ERROR, WARN, INFO, BUILTIN_MATS, NULL_NAMES, Report, disp, kv_lines, script_spans

VID = 'V06'
ELEMENTS = {b'Particle', b'NewRibbonTrail', b'Beam', b'Projector', b'PointLight', b'UIParticle', b'BillboardSet'}
FXKEYS = r'C:\TLBB\085\CY-Source\Docs\evidence\assetinv\fxkeys.json'
_VOCAB = None


def particle_vocab():
    global _VOCAB
    if _VOCAB is None:
        _VOCAB = set()
        try:
            with open(FXKEYS, encoding='utf-8') as f:
                bt = json.load(f)['block_types']['S1']['particle']
            _VOCAB = {k.encode('ascii') for k in bt}
        except (OSError, KeyError, ValueError, UnicodeEncodeError):
            _VOCAB = set()
    return _VOCAB


def _structure(block, kind, subj, rep):
    """Brace structure of one block -> list of nested block headers. Adds errors to rep."""
    depth = 0
    headers = []
    pending = None
    lines = block.splitlines()
    closed_at = None
    for i, raw in enumerate(lines):
        s = raw.strip()
        if not s:
            continue
        if b'//' in s:
            rep.add(VID, ERROR if kind == 'effect' else WARN, subj, 'line %d contains "//" (no comment syntax): %s'
                    % (i + 1, disp(s[:60])))
        if closed_at is not None:
            rep.add(VID, ERROR, subj, 'text after the closing brace (line %d): %s' % (i + 1, disp(s[:60])))
            break
        opens, closes = s.count(b'{'), s.count(b'}')
        if s not in (b'{', b'}') and (opens or closes):
            rep.add(VID, WARN, subj, 'brace shares a line with text (line %d): %s' % (i + 1, disp(s[:60])))
        if s == b'{':
            if depth >= 1 and pending is not None:
                headers.append(pending)
            pending = None
        elif opens == 0 and closes == 0:
            if depth == 0 and i > 0:
                rep.add(VID, ERROR, subj, 'stray depth-0 line %d: %s' % (i + 1, disp(s[:60])))
            pending = s
        depth += opens - closes
        if depth < 0:
            rep.add(VID, ERROR, subj, 'unbalanced "}" at line %d' % (i + 1))
            break
        if depth == 0 and (opens or closes) and i > 0:
            closed_at = i
    if depth != 0:
        rep.add(VID, ERROR, subj, 'unbalanced braces (depth %d at the end)' % depth)
    return headers


def check_effect(root, name, report=None):
    rep = report if report is not None else Report()
    refs = {'particles': [], 'effects': [], 'materials': []}
    d = root.defs('effect')
    if name not in d['first']:
        rep.add(VID, ERROR, name, 'effect not defined in all.effect')
        return rep, refs
    if name in d['dup']:
        rep.add(VID, WARN, name, 'effect defined %d times' % d['dup'][name])
    block = root.def_block('effect', name)
    subj = b'effect ' + name
    for h in _structure(block, 'effect', subj, rep):
        t = h.split()
        if not t or t[0] != b'element' or len(t) < 2:
            rep.add(VID, ERROR, subj, 'nested block is not "element <Type>": ' + disp(h[:60]))
        elif t[1] not in ELEMENTS:
            rep.add(VID, ERROR, subj, 'unknown element type ' + disp(t[1]))
    parts = root.defs('particle')['first']
    effs = d['first']
    mats = root.defs('material')['first']
    for k, v in kv_lines(block):
        if k == b'ParticleSystem':
            if v not in parts:
                rep.add(VID, ERROR, subj, 'ParticleSystem undefined in all.particle: ' + disp(v))
            elif v not in refs['particles']:
                refs['particles'].append(v)
        elif k in (b'ParEffectName', b'ColEffectName'):
            if v in NULL_NAMES:
                continue
            if v not in effs:
                rep.add(VID, ERROR, subj, '%s undefined in all.effect: %s' % (disp(k), disp(v)))
            elif v not in refs['effects']:
                refs['effects'].append(v)
        elif k == b'Material':
            if v in NULL_NAMES:
                continue
            if v not in mats and v not in BUILTIN_MATS:
                rep.add(VID, ERROR, subj, 'Material undefined in all.material: ' + disp(v))
            elif v not in refs['materials']:
                refs['materials'].append(v)
    rep.add(VID, INFO, subj, '%d particle system(s), %d sub-effect(s), %d material(s)' % (
        len(refs['particles']), len(refs['effects']), len(refs['materials'])))
    return rep, refs


def check_particle(root, name, report=None):
    rep = report if report is not None else Report()
    refs = {'materials': [], 'files': []}
    d = root.defs('particle')
    if name not in d['first']:
        rep.add(VID, ERROR, name, 'particle system not defined in all.particle')
        return rep, refs
    if name in d['dup']:
        rep.add(VID, WARN, name, 'particle system defined %d times' % d['dup'][name])
    block = root.def_block('particle', name)
    subj = b'particle ' + name
    vocab = particle_vocab()
    for h in _structure(block, 'particle', subj, rep):
        t = h.split()
        if not t or t[0] not in (b'emitter', b'affector') or len(t) < 2:
            rep.add(VID, WARN, subj, 'nested block "%s" is not emitter/affector' % disp(h[:60]))
        elif vocab and (t[0] + b':' + t[1]) not in vocab:
            rep.add(VID, WARN, subj, '%s type %s not used anywhere in S1' % (disp(t[0]), disp(t[1])))
    mats = root.defs('material')['first']
    for k, v in kv_lines(block):
        if k == b'material':
            if v not in mats and v not in BUILTIN_MATS:
                rep.add(VID, ERROR, subj, 'material undefined in all.material: ' + disp(v))
            elif v not in refs['materials']:
                refs['materials'].append(v)
        elif k == b'mesh_name':
            rel = root.resolve(v)
            if not rel:
                rep.add(VID, ERROR, subj, 'mesh_name file missing: ' + disp(v))
            elif rel not in refs['files']:
                refs['files'].append(rel)
    rep.add(VID, INFO, subj, '%d material(s), %d mesh file(s)' % (len(refs['materials']), len(refs['files'])))
    return rep, refs


def check_file(root, kind, base_root=None, report=None):
    """Whole-file stray count (and duplicate names) against the base data root."""
    rep = report if report is not None else Report()
    _blocks, stray = script_spans(root.script(kind))
    subj = 'all.' + kind
    if base_root is not None:
        _b, base_stray = script_spans(base_root.script(kind))
        if stray > base_stray:
            rep.add(VID, ERROR, subj, '%d stray depth-0 line(s), base has %d' % (stray, base_stray))
        else:
            rep.add(VID, INFO, subj, '%d stray depth-0 line(s) (base %d)' % (stray, base_stray))
    elif stray:
        rep.add(VID, WARN, subj, '%d stray depth-0 line(s)' % stray)
    return rep
