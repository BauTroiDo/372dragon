# -*- coding: utf-8 -*-
"""mtl_catalog.py - catalog of B (client_GL) material templates / GPU programs / HLSL and a gap
analysis against the 0.85 OGRE 1.2.5 material + GPU-program system.

Read-only inputs
  B  templates : Assets/Staging/materialtemplates/B  (extracted from client_GL/Data/MaterialTemplates.zip)
  B  programs  : client_GL/Data/MaterialFolder/*.program, Schema/*.program
  B  all.material (GBK bytes)
  085 data templates : Assets/Staging/materialtemplates/A085 (Reference/.../Client/Data/MaterialTemplates.zip)
  085 source templates: Src/Engine/WXCore/MaterialTemplates + Src/Engine/WXCore/PostFilter/media
  085 parser tables  : OgreMaterialSerializer.cpp, OgreGpuProgram.cpp, OgreD3D9HLSLProgram.cpp, OgreCgProgram.cpp
  B binaries (string presence only): OgreMain.dll, RenderSystem_Direct3D9.dll
Outputs: Tools/re/out/mtl_*.tsv|txt|json
Usage:  set PYTHONUTF8=1 & python mtl_catalog.py
"""
import collections
import glob
import json
import os
import re

R = r'C:\TLBB\085'
CY = R + r'\CY-Source'
OUT = CY + r'\Tools\re\out'
STAGE_B = CY + r'\Assets\Staging\materialtemplates\B'
STAGE_A = CY + r'\Assets\Staging\materialtemplates\A085'
SRC_TPL = CY + r'\Src\Engine\WXCore\MaterialTemplates'
SRC_PF = CY + r'\Src\Engine\WXCore\PostFilter\media'
OGRE = CY + r'\Src\Engine\OGRE'
MATF = R + r'\client_GL\Data\MaterialFolder'
BIN = R + r'\client_GL\Bin64'

SECTIONS = {
    'root': {'material': 'material', 'vertex_program': 'program', 'fragment_program': 'program'},
    'material': {'technique': 'technique'},
    'technique': {'pass': 'pass'},
    'pass': {'texture_unit': 'texture_unit', 'vertex_program_ref': 'program_ref',
             'fragment_program_ref': 'program_ref', 'shadow_caster_vertex_program_ref': 'program_ref',
             'shadow_receiver_vertex_program_ref': 'program_ref',
             'shadow_receiver_fragment_program_ref': 'program_ref'},
    'program': {'default_params': 'default_params'},
    'texture_unit': {'texture_source': 'texture_source'},
}
ENUM_KW = {'scene_blend', 'separate_scene_blend', 'depth_func', 'cull_hardware', 'cull_software', 'filtering',
           'tex_address_mode', 'render_queue', 'content_type', 'alpha_rejection', 'iteration', 'polygon_mode',
           'fog_override', 'lighting', 'shading', 'colour_write', 'depth_check', 'depth_write', 'env_map',
           'colour_op', 'colour_op_ex', 'alpha_op_ex', 'use_type', 'shader_type', 'sampler_index',
           'max_anisotropy', 'tex_coord_set', 'texture', 'cubic_texture', 'anim_texture', 'scheme', 'lod_index',
           'receive_shadows', 'transparency_casts_shadows', 'point_sprites', 'depth_bias', 'max_lights', 'target',
           'profiles', 'column_major_matrices', 'includes_skeletal_animation', 'preprocessor_defines', 'syntax',
           'texture_alias', 'scale', 'scroll_anim', 'rotate_anim', 'wave_xform', 'colour_op_multipass_fallback',
           'tex_border_colour', 'point_size', 'set_texture_alias'}
KEEP_BLOCK = re.compile(r'(?i)postfilter|hdr|bloom|fxaa|dlaa|mlaa|antialias|ssao|godray|lut|fog|dof|depthoffield|'
                        r'blur|heat|flood|fade|final|scenerender|rain|split|lens|drunk|energy|transscene|colou?r|gray|'
                        r'invert|water|sky|star|enscene|grass|shadow|depth|copyframe|linear|gamma|lightmap|terrain')


def gbk(s):
    return s.encode('latin-1').decode('gbk', 'replace')


class DB:
    def __init__(self):
        self.kw = collections.defaultdict(collections.Counter)        # corpus -> (ctx,kw) -> n
        self.kwex = {}                                                 # (ctx,kw) -> first example
        self.vals = collections.defaultdict(collections.Counter)      # (ctx,kw) -> "corpus|value" -> n
        self.auto = collections.defaultdict(collections.Counter)      # corpus -> auto name -> n
        self.autoex = {}
        self.ptypes = collections.defaultdict(collections.Counter)    # corpus -> param_named type -> n
        self.programs = collections.defaultdict(dict)                 # corpus -> name -> prog
        self.materials = collections.defaultdict(list)                # corpus -> [mat] (detail corpora)
        self.matnames = collections.defaultdict(set)
        self.parents = collections.Counter()                          # all.material parent usage
        self.parent_alias = collections.defaultdict(collections.Counter)
        self.parent_override = collections.defaultdict(collections.Counter)
        self.progref = collections.defaultdict(collections.Counter)   # corpus -> (kind, prog) -> n
        self.issues = collections.defaultdict(collections.Counter)
        self.issueex = collections.defaultdict(list)
        self.blocks = []


def issue(db, corpus, name, where):
    db.issues[corpus][name] += 1
    if len(db.issueex[(corpus, name)]) < 5:
        db.issueex[(corpus, name)].append(where)


def flatten(raw, fname, corpus, db):
    text = raw.decode('latin-1')
    if text.startswith('\xef\xbb\xbf'):
        text = text[3:]
    flat = []
    inblock = False
    for ln, line in enumerate(text.replace('\r\n', '\n').replace('\r', '\n').split('\n'), 1):
        s = line.strip()
        if inblock:
            if '*/' in s:
                s = s.split('*/', 1)[1].strip()
                inblock = False
            else:
                continue
        if '/*' in s and not s.startswith('//'):
            issue(db, corpus, 'block_comment', '%s:%d' % (fname, ln))
            head, rest = s.split('/*', 1)
            if '*/' in rest:
                s = (head + ' ' + rest.split('*/', 1)[1]).strip()
            else:
                s = head.strip()
                inblock = True
        if not s or s.startswith('//'):
            continue
        if '//' in s:
            issue(db, corpus, 'trailing_comment(0.85 parser keeps it as params)', '%s:%d' % (fname, ln))
            s = s.split('//', 1)[0].strip()
            if not s:
                continue
        pieces = [p.strip() for p in re.split(r'([{}])', s) if p.strip()]
        if len(pieces) > 1:
            issue(db, corpus, 'brace_on_same_line(0.85 parser needs own line)', '%s:%d' % (fname, ln))
        for p in pieces:
            flat.append((ln, p))
    return flat


def parse(raw, fname, corpus, db, detail=True, keep_blocks=False):
    flat = flatten(raw, fname, corpus, db)
    lines = None
    if keep_blocks:
        lines = raw.decode('latin-1').replace('\r\n', '\n').replace('\r', '\n').split('\n')
    stack = [('root', None)]
    pending = None
    rootstart = None
    n = len(flat)
    i = 0
    while i < n:
        ln, p = flat[i]
        where = '%s:%d' % (fname, ln)
        if p == '{':
            if pending is not None:
                stack.append(pending)
                if len(stack) == 2:
                    rootstart = (ln, pending)
                pending = None
            else:
                issue(db, corpus, 'orphan_open_brace', where)
                stack.append(('?', None))
            i += 1
            continue
        if p == '}':
            if len(stack) > 1:
                stack.pop()
                if len(stack) == 1 and keep_blocks and rootstart is not None:
                    hdr_ln, (kind, obj) = rootstart
                    name = obj.get('name', '') if isinstance(obj, dict) else ''
                    if KEEP_BLOCK.search(name or ''):
                        a = obj.get('line', hdr_ln)
                        db.blocks.append((fname, a, gbk('\n'.join(lines[a - 1:ln]))))
            else:
                issue(db, corpus, 'extra_close_brace', where)
            i += 1
            continue
        if pending is not None:
            issue(db, corpus, 'section_header_without_brace', where)
            pending = None
        toks = p.split()
        kw = toks[0]
        ctx, obj = stack[-1]
        nxt = i + 1 < n and flat[i + 1][1] == '{'
        child = SECTIONS.get(ctx, {}).get(kw)
        db.kw[corpus][(ctx, kw)] += 1
        db.kwex.setdefault((ctx, kw), where)
        if child or nxt:
            if not child:
                issue(db, corpus, 'unknown_section:%s/%s' % (ctx, kw), where)
                pending = ('?' + kw, {})
            else:
                pending = (child, header(db, corpus, ctx, obj, kw, toks, p, fname, ln, detail))
        else:
            attribute(db, corpus, ctx, obj, kw, toks, where, detail)
        i += 1
    if len(stack) != 1:
        issue(db, corpus, 'unclosed_section_at_eof', fname)


def header(db, corpus, ctx, obj, kw, toks, line, fname, ln, detail):
    if kw == 'material':
        rest = line[len('material'):].strip()
        name, parent = (rest.split(':', 1) + [''])[:2] if ':' in rest else (rest, '')
        m = {'name': name.strip(), 'parent': parent.strip(), 'file': fname, 'line': ln, 'tech': [],
             'aliases': [], 'corpus': corpus}
        db.matnames[corpus].add(m['name'])
        if detail:
            db.materials[corpus].append(m)
        elif m['parent']:
            db.parents[m['parent']] += 1
        return m
    if kw in ('vertex_program', 'fragment_program'):
        pr = {'name': toks[1] if len(toks) > 1 else '', 'type': kw, 'lang': toks[2] if len(toks) > 2 else '',
              'file': fname, 'line': ln, 'attrs': {}, 'params': [], 'corpus': corpus}
        db.programs[corpus][pr['name']] = pr
        return pr
    if kw == 'technique':
        t = {'name': ' '.join(toks[1:]), 'attrs': collections.OrderedDict(), 'passes': []}
        if obj is not None:
            obj['tech'].append(t)
        return t
    if kw == 'pass':
        pa = {'name': ' '.join(toks[1:]), 'attrs': collections.OrderedDict(), 'tus': [], 'refs': []}
        if obj is not None:
            obj['passes'].append(pa)
        return pa
    if kw == 'texture_unit':
        tu = {'name': ' '.join(toks[1:]), 'attrs': collections.OrderedDict()}
        if obj is not None:
            obj['tus'].append(tu)
        return tu
    if ctx == 'pass':  # program refs
        ref = {'kind': kw, 'program': toks[1] if len(toks) > 1 else '', 'params': []}
        db.progref[corpus][(kw, ref['program'])] += 1
        if obj is not None:
            obj['refs'].append(ref)
        return ref
    if kw == 'default_params':
        return obj
    return {}


def attribute(db, corpus, ctx, obj, kw, toks, where, detail):
    val = ' '.join(toks[1:])
    if kw in ENUM_KW:
        if kw == 'texture':
            v = ('<alias>' if toks[1:2] and toks[1].startswith('<') else '<file>') + (' ' + ' '.join(toks[2:]) if len(toks) > 2 else '')
        elif kw == 'set_texture_alias':
            v = toks[1] if len(toks) > 1 else ''
        elif kw in ('preprocessor_defines',):
            v = val
        else:
            v = val[:80]
        db.vals[(ctx, kw)]['%s|%s' % (corpus, v)] += 1
    if ctx == 'program' and isinstance(obj, dict):
        obj['attrs'][kw] = val
    elif ctx in ('default_params', 'program_ref'):
        if kw in ('param_named_auto', 'param_indexed_auto') and len(toks) >= 3:
            a = toks[2].lower()
            db.auto[corpus][a] += 1
            db.autoex.setdefault(a, where)
            if isinstance(obj, dict):
                obj['params'].append((kw, toks[1], a, ' '.join(toks[3:])))
        elif kw in ('param_named', 'param_indexed') and len(toks) >= 3:
            db.ptypes[corpus][toks[2]] += 1
            if isinstance(obj, dict):
                obj['params'].append((kw, toks[1], toks[2], ' '.join(toks[3:])))
    elif ctx == 'material' and isinstance(obj, dict):
        if kw == 'set_texture_alias' and len(toks) >= 2:
            obj['aliases'].append(toks[1])
            if not detail and obj.get('parent'):
                db.parent_alias[obj['parent']][toks[1]] += 1
    elif isinstance(obj, dict) and 'attrs' in obj:
        obj['attrs'].setdefault(kw, val)
    if not detail and ctx in ('pass', 'texture_unit', 'technique') and False:
        pass


def load_085():
    ser = open(OGRE + r'\OgreMain\src\OgreMaterialSerializer.cpp', 'rb').read().decode('latin-1')
    tabs = collections.defaultdict(set)
    for t, k in re.findall(r'm(\w+)AttribParsers\.insert\(AttribParserList::value_type\("([^"]+)"', ser):
        tabs[t].add(k)
    cmap = {'Root': 'root', 'Material': 'material', 'Technique': 'technique', 'Pass': 'pass',
            'TextureUnit': 'texture_unit', 'ProgramRef': 'program_ref', 'Program': 'program',
            'ProgramDefaultParam': 'default_params'}
    sup = {cmap[t]: v for t, v in tabs.items() if t in cmap}
    gp = open(OGRE + r'\OgreMain\src\OgreGpuProgram.cpp', 'rb').read().decode('latin-1')
    hl = open(OGRE + r'\RenderSystems\Direct3D9\src\OgreD3D9HLSLProgram.cpp', 'rb').read().decode('latin-1')
    cg = open(OGRE + r'\PlugIns\CgProgramManager\src\OgreCgProgram.cpp', 'rb').read().decode('latin-1')
    pd = set(re.findall(r'ParameterDef\("([^"]+)"', gp))
    hd = set(re.findall(r'ParameterDef\("([^"]+)"', hl))
    cd = set(re.findall(r'ParameterDef\("([^"]+)"', cg))
    autos = re.findall(r'AutoConstantDefinition\((ACT_\w+),\s*"([^"]+)"', gp)
    lits = set(re.findall(r'"([a-z0-9_]+)"', ser))
    return sup, pd, hd, cd, autos, lits


def b_strings():
    d = {}
    for f in ('OgreMain.dll', 'RenderSystem_Direct3D9.dll', 'Plugin_CgProgramManager.dll'):
        d[f] = open(os.path.join(BIN, f), 'rb').read()
    om = d['OgreMain.dll']
    # strings are 8-byte aligned in .rdata: anchor on a unique entry, then walk the NUL-separated run
    k = om.find(b'inverse_world_matrix_3x4\x00')
    e = om.find(b'skydome_ambient_color\x00', k) + len('skydome_ambient_color')
    a = k - 128
    names = [x.decode('latin-1') for x in om[a:e].split(b'\x00') if re.match(rb'^[a-z0-9_]+$', x)]
    bauto = names[names.index('world_matrix'):]
    return d, bauto, om.find(b'world_matrix\x00', a)


def has(d, kw):
    k = b'\x00' + kw.encode() + b'\x00'
    return [f for f, b in d.items() if k in b]


def hlsl_inventory(folder):
    inv = {}
    for p in sorted(glob.glob(folder + r'\**\*', recursive=True)):
        if not re.search(r'\.(hlsl|inc|cg|fx)$', p, re.I):
            continue
        rel = os.path.relpath(p, folder).replace('\\', '/')
        t = open(p, 'rb').read().decode('latin-1')
        inc = re.findall(r'^\s*#\s*include\s*[<"]([^">]+)[">]', t, re.M)
        tested = set()
        for expr in re.findall(r'^\s*#\s*(?:if|elif|ifdef|ifndef)\b(.*)$', t, re.M):
            tested.update(x for x in re.findall(r'\b([A-Z_][A-Z0-9_]{2,})\b', expr) if x not in ('defined',))
        defined = set(re.findall(r'^\s*#\s*define\s+(\w+)', t, re.M))
        unif = re.findall(r'^\s*uniform\s+(?:row_major\s+|column_major\s+)?(\w+)\s+(\w+)\s*(\[[^\]]*\])?', t, re.M)
        samp = re.findall(r'\b(sampler(?:1D|2D|3D|CUBE)?|samplerCUBE)\s+(\w+)\s*(?::\s*register\s*\(\s*(s\d+)\s*\))?', t)
        funcs = set(re.findall(r'^[ \t]*[\w<>]+[ \t]+(\w+)[ \t]*\([^;{]*\)[ \t\r\n]*(?::[ \t]*\w+[ \t\r\n]*)?\{', t, re.M))
        inv[rel] = {'size': len(t), 'includes': inc, 'tested': sorted(tested - defined), 'defined': sorted(defined),
                    'uniforms': ['%s %s%s' % u for u in unif], 'samplers': ['%s %s%s' % (a, b, (':' + c) if c else '') for a, b, c in samp],
                    'funcs': sorted(funcs)}
    return inv


def main():
    os.makedirs(OUT, exist_ok=True)
    db = DB()
    corpora = []
    # B templates zip content
    for p in sorted(glob.glob(STAGE_B + r'\*.material') + glob.glob(STAGE_B + r'\*.program')):
        parse(open(p, 'rb').read(), 'MT.zip/' + os.path.basename(p), 'B_tpl', db)
    for p in sorted(glob.glob(MATF + r'\*.program') + glob.glob(MATF + r'\Schema\*.program')):
        parse(open(p, 'rb').read(), 'MaterialFolder/' + os.path.relpath(p, MATF).replace('\\', '/'), 'B_prog', db,
              keep_blocks=True)
    parse(open(MATF + r'\all.material', 'rb').read(), 'all.material', 'B_allmat', db, detail=False, keep_blocks=True)
    for p in sorted(glob.glob(STAGE_A + r'\*.material') + glob.glob(STAGE_A + r'\*.program')):
        parse(open(p, 'rb').read(), '085zip/' + os.path.basename(p), 'A085', db)
    for p in sorted(glob.glob(SRC_TPL + r'\*.material') + glob.glob(SRC_TPL + r'\*.program') +
                    glob.glob(SRC_PF + r'\*.material') + glob.glob(SRC_PF + r'\*.program')):
        parse(open(p, 'rb').read(), 'Src/' + os.path.basename(p), 'SRC085', db)
    CORP = ['B_tpl', 'B_prog', 'B_allmat', 'A085', 'SRC085']

    sup, pd, hd, cd, autos085, lits = load_085()
    bins, bauto, bauto_off = b_strings()
    auto085 = [n for _, n in autos085]
    inc = open(STAGE_B + r'\ShaderLib\ParamNamedAuto.inc', 'rb').read().decode('latin-1')
    actc = {}
    for nm, act in re.findall(r'uniform[^;]*?\b(\w+)(?:\[[^\]]*\])?\s*(?:=[^;]*)?;\s*//\s*(ACT_\w+)', inc):
        actc[nm] = act

    # ---------- keyword gap ----------
    allkeys = set()
    for c in CORP:
        allkeys.update(db.kw[c].keys())
    rows = []
    for ctx, kw in sorted(allkeys):
        if ctx == 'program':
            s085 = 'Y' if kw in sup.get('program', set()) else ('Y(hlsl)' if kw in hd else ('Y(cg)' if kw in cd else ('Y(gp)' if kw in pd else 'N')))
        elif ctx in sup:
            s085 = 'Y' if kw in sup[ctx] else 'N'
        elif ctx == 'root' and kw in ('material', 'vertex_program', 'fragment_program'):
            s085 = 'Y'
        else:
            s085 = 'n/a(%s)' % ctx
        inb = ','.join(has(bins, kw)) or '-'
        rows.append([ctx, kw] + [str(db.kw[c].get((ctx, kw), 0)) for c in CORP] + [s085, inb, db.kwex.get((ctx, kw), '')])
    with open(OUT + r'\mtl_keyword_gap.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('ctx\tkeyword\t' + '\t'.join(CORP) + '\tin_085_parser\tstring_in_B_bin\texample\n')
        for r in rows:
            f.write('\t'.join(r) + '\n')

    # ---------- value usage ----------
    with open(OUT + r'\mtl_value_usage.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('ctx\tkeyword\tvalue\t' + '\t'.join(CORP) + '\tvalue_tokens_in_085_serializer\n')
        for (ctx, kw), cnt in sorted(db.vals.items()):
            per = collections.defaultdict(collections.Counter)
            for k, v in cnt.items():
                c, val = k.split('|', 1)
                per[val][c] += v
            for val, cc in sorted(per.items(), key=lambda x: -sum(x[1].values()))[:60]:
                toks = [t for t in val.split() if re.match(r'^[a-z_]+$', t)]
                miss = [t for t in toks if t not in lits]
                f.write('%s\t%s\t%s\t%s\t%s\n' % (ctx, kw, gbk(val), '\t'.join(str(cc.get(c, 0)) for c in CORP),
                                                  'all' if not miss else 'missing:' + ','.join(miss)))

    # ---------- auto constants ----------
    used = set()
    for c in CORP:
        used.update(db.auto[c].keys())
    with open(OUT + r'\mtl_autoconst_gap.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('auto_name\t' + '\t'.join(CORP) + '\tin_085_dict\tin_B_dict(idx)\tParamNamedAuto.inc\texample\n')
        for a in sorted(used | set(bauto), key=lambda x: (x not in used, x)):
            f.write('%s\t%s\t%s\t%s\t%s\t%s\n' % (a, '\t'.join(str(db.auto[c].get(a, 0)) for c in CORP),
                                                  'Y' if a in auto085 else 'N',
                                                  str(bauto.index(a)) if a in bauto else 'N', actc.get(a, ''),
                                                  db.autoex.get(a, '')))
    with open(OUT + r'\mtl_autoconst_B_dict.txt', 'w', encoding='utf-8', newline='\n') as f:
        f.write('# B OgreMain.dll AutoConstantDictionary name strings in file order (file offset 0x%x)\n' % bauto_off)
        for i, a in enumerate(bauto):
            f.write('%d\t%s\t%s\n' % (i, a, 'in_0.85' if a in auto085 else 'NEW'))

    # ---------- programs ----------
    with open(OUT + r'\mtl_programs.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('corpus\tname\ttype\tlang\tsource\tentry_point\ttarget/profiles\tpreprocessor_defines\tcolumn_major\t'
                'skeletal\tother_attrs\tauto_params\tnamed_params\tfile:line\n')
        for c in CORP:
            for name, p in sorted(db.programs[c].items()):
                at = p['attrs']
                other = {k: v for k, v in at.items() if k not in ('source', 'entry_point', 'target', 'profiles',
                                                                  'preprocessor_defines', 'column_major_matrices',
                                                                  'includes_skeletal_animation')}
                ap = ['%s=%s%s' % (x[1], x[2], (' ' + x[3]) if x[3] else '') for x in p['params'] if x[0].endswith('_auto')]
                npar = ['%s:%s' % (x[1], x[2]) for x in p['params'] if not x[0].endswith('_auto')]
                f.write('\t'.join([c, gbk(name), p['type'], p['lang'], at.get('source', ''), at.get('entry_point', ''),
                                   at.get('target', at.get('profiles', '')), at.get('preprocessor_defines', ''),
                                   at.get('column_major_matrices', ''), at.get('includes_skeletal_animation', ''),
                                   json.dumps(other, ensure_ascii=False), ' '.join(ap), ' '.join(npar),
                                   '%s:%d' % (p['file'], p['line'])]) + '\n')

    # ---------- template materials ----------
    defined_in = {}
    for c in ('B_tpl', 'B_prog', 'A085', 'SRC085'):
        for m in db.materials[c]:
            defined_in.setdefault(m['name'], c)
    for nm in db.matnames['B_allmat']:
        defined_in.setdefault(nm, 'B_allmat')
    with open(OUT + r'\mtl_templates.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('corpus\tmaterial\tparent\tuses_as_parent_in_all.material\ttechniques(scheme)\tpasses\tprogram_refs\t'
                'texture_units(alias|content_type|sampler_index)\tpass_keywords\tfile:line\n')
        for c in ('B_tpl', 'B_prog', 'A085', 'SRC085'):
            for m in db.materials[c]:
                techs, passes, refs, tus, pk = [], 0, [], [], collections.Counter()
                for t in m['tech']:
                    techs.append((t['name'] or '-') + ('[%s]' % t['attrs']['scheme'] if 'scheme' in t['attrs'] else ''))
                    for pa in t['passes']:
                        passes += 1
                        for r in pa['refs']:
                            refs.append('%s:%s' % (r['kind'].replace('_program_ref', ''), r['program']))
                        for tu in pa['tus']:
                            a = tu['attrs']
                            tus.append('%s|%s|%s' % (a.get('texture_alias', a.get('texture', '')), a.get('content_type', ''),
                                                     a.get('sampler_index', '')))
                        for k in pa['attrs']:
                            pk[k] += 1
                f.write('\t'.join([c, gbk(m['name']), gbk(m['parent']), str(db.parents.get(m['name'], 0)),
                                   ';'.join(techs), str(passes), ' '.join(sorted(set(refs))), ' '.join(tus),
                                   ' '.join('%s' % k for k in sorted(pk)), '%s:%d' % (m['file'], m['line'])]) + '\n')
    with open(OUT + r'\mtl_template_usage.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('parent_template\tdefined_in\tmaterials_in_all.material\tset_texture_alias usage (alias=count)\n')
        for par, n in db.parents.most_common():
            al = db.parent_alias.get(par, {})
            f.write('%s\t%s\t%d\t%s\n' % (gbk(par), defined_in.get(par, 'UNDEFINED'), n,
                                          ' '.join('%s=%d' % (k, v) for k, v in sorted(al.items(), key=lambda x: -x[1]))))
    # program refs of materials in all.material (no-parent materials & overrides)
    with open(OUT + r'\mtl_allmat_progrefs.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('kind\tprogram\tuses_in_all.material\tdefined_in\n')
        pdef = {}
        for c in CORP:
            for nm in db.programs[c]:
                pdef.setdefault(nm, c)
        for (k, p), n in db.progref['B_allmat'].most_common():
            f.write('%s\t%s\t%d\t%s\n' % (k, gbk(p), n, pdef.get(p, 'UNDEFINED')))

    # ---------- HLSL inventory ----------
    inv = hlsl_inventory(STAGE_B)
    for p in glob.glob(MATF + r'\*.cg'):
        t = open(p, 'rb').read().decode('latin-1')
        inv['MaterialFolder/' + os.path.basename(p)] = {'size': len(t), 'includes': [], 'tested': [], 'defined': [],
                                                        'uniforms': [], 'samplers': [], 'funcs': []}
    entry = collections.defaultdict(list)
    for c in ('B_tpl', 'B_prog', 'B_allmat'):
        for nm, p in db.programs[c].items():
            entry[p['attrs'].get('source', '')].append((p['attrs'].get('entry_point', ''), nm, p['attrs'].get('target', p['attrs'].get('profiles', ''))))
    incl_graph = {k: v['includes'] for k, v in inv.items()}

    def closure(f, seen=None):
        seen = seen or []
        for i2 in incl_graph.get(f, []):
            if i2 not in seen:
                seen.append(i2)
                closure(i2, seen)
        return seen
    with open(OUT + r'\mtl_hlsl_inventory.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('file\tsize\tincludes(direct)\tincludes(transitive)\tmacros_tested\tsamplers\tn_uniforms\t'
                'programs_using(entry@target:program)\tmissing_entry_points\n')
        for k, v in sorted(inv.items()):
            base = k.split('/')[-1]
            users = entry.get(base, []) + (entry.get(k, []) if k != base else [])
            tr = closure(k)
            funcs = set(v['funcs'])
            for t2 in tr:
                funcs |= set(inv.get(t2, {}).get('funcs', []))
            miss = sorted(set(e for e, _, _ in users if e and e not in funcs and not re.search(r'\b%s\s*\(' % re.escape(e), open(os.path.join(STAGE_B, k.replace('/', os.sep)), 'rb').read().decode('latin-1') if os.path.exists(os.path.join(STAGE_B, k.replace('/', os.sep))) else '')))
            f.write('\t'.join([k, str(v['size']), ' '.join(v['includes']), ' '.join(tr), ' '.join(v['tested']),
                               ' '.join(v['samplers']), str(len(v['uniforms'])),
                               ' '.join(sorted(set('%s@%s:%s' % (e, t3, gbk(n)) for e, n, t3 in users)))[:3000],
                               ' '.join(miss)]) + '\n')
    # sources referenced by programs but missing from zip/MaterialFolder
    have = set(k.split('/')[-1] for k in inv) | set(os.path.basename(p) for p in glob.glob(MATF + r'\*'))
    missing_src = sorted(s for s in entry if s and s not in have)

    # ---------- issues / blocks ----------
    with open(OUT + r'\mtl_issues.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('corpus\tissue\tcount\texamples\n')
        for c in CORP:
            for k, n in db.issues[c].most_common():
                f.write('%s\t%s\t%d\t%s\n' % (c, k, n, ' '.join(db.issueex[(c, k)])))
    with open(OUT + r'\mtl_postfx_blocks.txt', 'w', encoding='utf-8', newline='\n') as f:
        for fn, a, t in db.blocks:
            f.write('///// %s:%d\n%s\n\n' % (fn, a, t))

    # ---------- summary ----------
    summ = {
        'programs': {c: len(db.programs[c]) for c in CORP},
        'program_targets': {c: dict(collections.Counter(p['attrs'].get('target', p['attrs'].get('profiles', '?')) for p in db.programs[c].values())) for c in CORP},
        'program_langs': {c: dict(collections.Counter(p['lang'] for p in db.programs[c].values())) for c in CORP},
        'materials_detail': {c: len(db.materials[c]) for c in CORP},
        'allmaterial_materials': len(db.matnames['B_allmat']),
        'allmaterial_with_parent': sum(db.parents.values()),
        'distinct_parents': len(db.parents),
        'auto_used': {c: len(db.auto[c]) for c in CORP},
        'auto_used_not_in_085': sorted(a for a in used if a not in auto085),
        'B_dict_size': len(bauto), 'B_dict_new_vs_085': [a for a in bauto if a not in auto085],
        'keywords_not_in_085': sorted('%s/%s' % k for k in allkeys if any(db.kw[c].get(k) for c in ('B_tpl', 'B_prog', 'B_allmat')) and ((k[0] in sup and k[1] not in sup[k[0]] and not (k[0] == 'program' and (k[1] in hd or k[1] in cd or k[1] in pd))))),
        'missing_program_sources': missing_src,
        'hlsl_files': len(inv),
        'param_named_types': {c: dict(db.ptypes[c]) for c in CORP},
        'issues': {c: dict(db.issues[c]) for c in CORP},
    }
    json.dump(summ, open(OUT + r'\mtl_catalog.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps(summ, ensure_ascii=False, indent=1)[:6000])


if __name__ == '__main__':
    main()
