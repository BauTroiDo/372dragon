"""Sinh bộ ca đối chứng (Docs/07 mục 2): ~43 model, 100 effect, 10 cảnh của MỘT thư mục dữ liệu.

Hồ sơ (--profile):
  cy (mặc định, từ ci-cy 14/09/2026): Assets/CanonicalCY/Data (CY 3.71) + chỉ mục Assets/Staging/index/models_S2.tsv
      (S2 = DataCY, cùng all.obj với CanonicalCY: 11.492/11.495 obj trùng) -> cases.json + cases.tsv (CI dùng).
  gl: C:/TLBB/085/client_GL/Data + models_S1.tsv -> cases_gl.json + cases_gl.tsv (bản cũ, KHÔNG dùng trong CI;
      ảnh baseline Tests/oracle/baseline chụp từ client_GL chỉ so được với bộ này).

Model được chọn phải: có trong all.obj của dữ liệu, mọi .mesh của nó có trên đĩa, chỉ mục ghi complete=ok và verts>0.
Ưu tiên nội dung 2026 > 2025 > có animation > texture lớn > nhiều đỉnh, rồi băm tên để ổn định (cùng dữ liệu -> cùng
kết quả; id M01.., E001.., S01.. ổn định theo thứ tự nhóm).
Chỉ đọc dữ liệu. Chạy:  python make_cases.py [--profile cy|gl] [--data DIR] [--index TSV] [--out DIR]
"""
import argparse
import csv
import hashlib
import json
import os
import re

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
OUT = os.path.dirname(os.path.abspath(__file__))

PROFILES = {
    'cy': dict(
        data=os.path.join(ROOT, r'Assets\CanonicalCY\Data'),
        index=os.path.join(ROOT, r'Assets\Staging\index\models_S2.tsv'),
        mojibake=False,      # tên trong chỉ mục là chữ Hán thật; trên đĩa là GBK hiển thị qua cp1252
        name='cases',
        buckets=[  # (tên nhóm, regex trên tên obj, số lượng) - theo cách đặt tên của CY 3.71
            ('player', r'^npc[男女]主角', 8),   # nhân vật đủ bộ phận (男主角.obj trần là khung ghép, 0 entity)
            ('pet', r'^pet_|宠物|珍兽', 10),
            ('mount', r'^ride|坐骑|zuoqi|骑乘', 6),
            ('costume', r'时装|w_cloth|cloth|^top_|^back_|套装', 8),
            ('weapon', r'武器|dweapon|dwepon|weapon|^psoul', 8),
            ('boss_npc', r'^(hj_)?boss|^npc|首领', 6),
        ],
        scenes=[r'^dali_new_320\.scene$', r'^luoyang_new\.scene$', r'^suzhou_new\.scene$', r'^tlbb3_login\.scene$',
                r'^tl3chuangjian\.scene$', r'^login_bianjing\.scene$', r'^fengming_new_320\.scene$',
                r'^FengYun_lingxiaocheng\.scene$', r'^wedding_new_1\.scene$', r'^RogueFB\.scene$'],
    ),
    'gl': dict(
        data=r'C:\TLBB\085\client_GL\Data',
        index=os.path.join(ROOT, r'Assets\Staging\index\models_S1.tsv'),
        mojibake=True,       # chỉ mục S1 ghi tên mesh đúng như trên đĩa (cp1252 của GBK)
        name='cases_gl',
        buckets=[
            ('player', r'主角', 8),
            ('pet', r'^pet_|宠物|珍兽', 10),
            ('mount', r'坐骑|zuoqi|骑乘', 6),
            ('costume', r'时装|w_cloth|cloth', 8),
            ('weapon', r'武器|dweapon|weapon', 8),
            ('boss_npc', r'^(hj_)?boss|^npc|首领', 6),
        ],
        scenes=[r'^suzhou', r'^luoyang', r'^dali', r'xuanren', r'chuangjian', r'login', r'rift|lol',
                r'cy4_guigu', r'fengyun_lingxiaocheng', r'cy4_tangmen'],
    ),
}
NEW_FX = ['NewRibbonTrail', 'UIParticle', 'RevoluMove', 'SequenceFrame', 'Dissolve', 'RotationCurve', 'PolarMove']
_C1_RAW = {0x81, 0x8D, 0x8F, 0x90, 0x9D}
_OBJ_RE = re.compile(rb'<Object\s+name="([^"]*)"')


def h(s):
    return int(hashlib.md5(s.encode('utf-8')).hexdigest()[:8], 16)


def gbk_to_disk(b):
    """GBK bytes -> tên trên đĩa (ACP 1252): từng byte hiển thị theo cp1252, 5 byte cp1252 bỏ trống giữ U+0081.."""
    return ''.join(chr(x) if x < 0x80 or x in _C1_RAW else bytes([x]).decode('cp1252') for x in b)


def score(row):
    n = row['obj']
    return (3 if '2026' in n else 2 if '2025' in n else 0) + (1 if int(row['anims'] or 0) > 0 else 0) \
        + min(int(row['max_tex_px'] or 0), 2048) / 2048.0 + min(int(row['verts'] or 0), 40000) / 40000.0


def obj_names(data):
    """Tên obj (chữ Hán) khai báo trong mọi all.obj của Model*Folder (GBK, đọc byte)."""
    names = set()
    for top in sorted(os.listdir(data)):
        if not re.match(r'^Model\d*Folder$', top, re.I):
            continue
        p = os.path.join(data, top, 'all.obj')
        if os.path.isfile(p):
            for m in _OBJ_RE.finditer(open(p, 'rb').read()):
                names.add(m.group(1).decode('gbk', errors='replace'))
    return names


def mesh_paths(data, relpaths, mojibake):
    """mesh_relpath của chỉ mục ('Model6\\a.mesh;Model\\b.mesh' hoặc 'ModelFolder\\a.mesh') -> đường dẫn trên đĩa."""
    out = []
    for rp in [x for x in relpaths.split(';') if x]:
        top, _, rest = rp.partition('\\')
        if not top.lower().endswith('folder'):
            top += 'Folder'
        if not mojibake and any(ord(c) > 0x2FF for c in rest):
            rest = gbk_to_disk(rest.encode('gbk'))
        out.append(os.path.join(data, top, rest))
    return out


def pick_models(prof, data, index):
    rows = list(csv.DictReader(open(index, encoding='utf-8-sig'), delimiter='\t'))
    declared = obj_names(data)
    rows = [r for r in rows if r.get('complete') == 'ok' and int(r.get('verts') or 0) > 0 and r['obj'] in declared
            and r.get('mesh_relpath') and all(os.path.isfile(p) for p in mesh_paths(data, r['mesh_relpath'], prof['mojibake']))]
    used, out = set(), []
    for name, pat, n in prof['buckets']:
        rx = re.compile(pat, re.I)
        cand = sorted((r for r in rows if rx.search(r['obj']) and r['obj'] not in used),
                      key=lambda r: (-score(r), h(r['obj'])))
        for r in cand[:n]:
            used.add(r['obj'])
            out.append({'id': 'M%02d' % (len(out) + 1), 'bucket': name, 'obj': r['obj'], 'anim': '',
                        'verts': int(r['verts']), 'anims': int(r['anims'] or 0),
                        'max_tex_px': int(r['max_tex_px'] or 0)})
    return out, len(rows)


def blocks(path):
    """Tách khối cấp 0: (tên-dòng-đầu, list dòng bên trong) theo đếm ngoặc, file GBK."""
    text = open(path, 'rb').read().decode('gbk', errors='replace')
    res, depth, head, body = [], 0, None, []
    pending = None
    for line in text.splitlines():
        s = line.strip()
        if depth == 0:
            if s == '{':
                head, body, depth = pending, [], 1
                continue
            if s.endswith('{'):
                head, body, depth = s[:-1].strip(), [], 1
                continue
            if s and not s.startswith('//'):
                pending = s
            continue
        depth += s.count('{') - s.count('}')
        if depth <= 0:
            res.append((head, body))
            depth, head, body = 0, None, []
        else:
            body.append(s)
    return res


def pick_effects(data):
    ps_types = {}
    for head, body in blocks(os.path.join(data, r'EffectFolder\all.particle')):
        if not head:
            continue
        name = head.split()[-1] if head.lower().startswith('particle_system') else head
        t = {w.split()[1] for w in body if w.startswith(('affector ', 'emitter ')) and len(w.split()) > 1}
        ps_types[name] = t
    effects = {}
    for head, body in blocks(os.path.join(data, r'EffectFolder\all.effect')):
        if not head or not head.lower().startswith('effect'):
            continue
        name = head.split(None, 1)[1].strip() if len(head.split()) > 1 else head
        t = set()
        for w in body:
            parts = w.split()
            if len(parts) > 1 and parts[0] == 'element':
                t.add(parts[1])
            if len(parts) > 1 and parts[0].lower() == 'particlesystem':
                t |= ps_types.get(parts[1], set())
        effects[name] = t
    out, used = [], set()
    for typ in NEW_FX:
        cand = sorted((n for n, t in effects.items() if typ in t and n not in used),
                      key=lambda n: (-(('2026' in n) * 2 + ('2025' in n)), h(n)))
        for n in cand[:12]:
            used.add(n)
            out.append({'id': 'E%03d' % (len(out) + 1), 'effect': n, 'new_type': typ,
                        'types': sorted(effects[n])})
    classic = sorted((n for n, t in effects.items() if n not in used and t and not (t & set(NEW_FX))), key=h)
    for n in classic[:max(0, 100 - len(out))]:
        out.append({'id': 'E%03d' % (len(out) + 1), 'effect': n, 'new_type': '', 'types': sorted(effects[n])})
    return out, len(effects)


def pick_scenes(prof, data):
    names = []
    for top in ('SceneFolder', 'Scene2Folder'):
        sdir = os.path.join(data, top)
        if not os.path.isdir(sdir):
            continue
        for dp, _, fs in os.walk(sdir):
            for f in fs:
                if f.lower().endswith('.scene'):
                    names.append(os.path.relpath(os.path.join(dp, f), data))
    out, used = [], set()
    for pat in prof['scenes']:
        rx = re.compile(pat, re.I)
        for n in sorted(names, key=len):
            base = os.path.basename(n)
            if rx.search(base) and n not in used:
                used.add(n)
                stem = os.path.splitext(n)[0]
                feats = [e for e in ('.enscene', '.skysphere', '.hfog', '.hdr', '.newhdrbloom')
                         if os.path.exists(os.path.join(data, stem + e)) or
                         os.path.exists(os.path.join(data, stem + e.upper()))]
                out.append({'id': 'S%02d' % (len(out) + 1), 'scene': n, 'pattern': pat, 'features': feats})
                break
        else:
            print('  scene pattern without match:', pat)
    return out, len(names)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--profile', choices=sorted(PROFILES), default='cy')
    ap.add_argument('--data', help='thư mục Data (mặc định theo hồ sơ)')
    ap.add_argument('--index', help='chỉ mục models_S*.tsv (mặc định theo hồ sơ)')
    ap.add_argument('--out', default=OUT, help='thư mục ghi cases*.json/tsv (mặc định: Tests/oracle)')
    ap.add_argument('--name', help='tên file ra không đuôi (mặc định theo hồ sơ: cases | cases_gl)')
    a = ap.parse_args()
    prof = PROFILES[a.profile]
    data = os.path.normpath(a.data or prof['data'])
    index = a.index or prof['index']
    name = a.name or prof['name']
    for p in (data, index):
        if not os.path.exists(p):
            raise SystemExit('không thấy: ' + p)
    models, n_models = pick_models(prof, data, index)
    effects, n_effects = pick_effects(data)
    scenes, n_scenes = pick_scenes(prof, data)
    cases = {'generated_by': 'Tests/oracle/make_cases.py', 'profile': a.profile, 'data': data,
             'index': os.path.relpath(index, ROOT) if index.startswith(ROOT) else index,
             'pool': {'models_eligible': n_models, 'effects': n_effects, 'scenes': n_scenes},
             'models': models, 'effects': effects, 'scenes': scenes}
    json.dump(cases, open(os.path.join(a.out, name + '.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    with open(os.path.join(a.out, name + '.tsv'), 'w', encoding='utf-8-sig', newline='') as f:
        w = csv.writer(f, delimiter='\t')
        w.writerow(['id', 'kind', 'name', 'group', 'info'])
        for m in cases['models']:
            w.writerow([m['id'], 'model', m['obj'], m['bucket'], 'verts=%d anims=%d tex=%d' % (m['verts'], m['anims'], m['max_tex_px'])])
        for e in cases['effects']:
            w.writerow([e['id'], 'effect', e['effect'], e['new_type'] or 'classic', ','.join(e['types'])])
        for s in cases['scenes']:
            w.writerow([s['id'], 'scene', s['scene'], s['pattern'], ','.join(s['features'])])
    print('profile', a.profile, 'data', data)
    print('pool: models eligible', n_models, 'effects', n_effects, 'scenes', n_scenes)
    print('models', len(cases['models']), 'effects', len(cases['effects']), 'scenes', len(cases['scenes']))
    for b, _, _ in prof['buckets']:
        sel = [m for m in cases['models'] if m['bucket'] == b]
        print(' ', b, len(sel), '2026:', sum('2026' in m['obj'] for m in sel), '2025:', sum('2025' in m['obj'] for m in sel))
    for t in NEW_FX:
        print(' ', t, sum(1 for e in cases['effects'] if e['new_type'] == t))
    for s in cases['scenes']:
        print(' ', s['id'], s['scene'], s['features'])


if __name__ == '__main__':
    main()
