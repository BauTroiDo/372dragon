"""Read-only CY appearance closure; build_plan returns bytes for the profile owner.

Only the appearance selection actually exposed by CysCreateRoleAppearance is included.
Resource key bytes are never transcoded; Unicode S2 disk names map to the engine's
CP1252 rendering of those GBK bytes when staged. No source file is modified.
"""
import hashlib
import json
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tools/pipeline'))
import tlbbfmt
from avatar import objxml
from avatar.data import read_table, disk_key, skeleton_names

FILES = {'Race': 'CharRace.txt', 'Model': 'CharModelEx.txt', 'Face': 'CharFaceGeo.txt',
         'Hair': 'CharHairGeo.txt', 'Portrait': 'CharacterFace.txt',
         'Outfit': 'NewRoleEquipset.txt', 'Visual': 'ItemVisualChar.txt'}
OBJECT = re.compile(rb'<Object\s+name="([^"]+)"\s*>.*?</Object>', re.S)
IDLE = '空手站立01'.encode('gbk')


def material_blocks(data, selected=None):
    result = {}
    for header, block in tlbbfmt.iter_blocks(data)[0]:
        words = header.split()
        if len(words) > 1 and words[0] == b'material':
            name = words[1].split(b':')[0]
            if selected is not None and name not in selected:
                continue
            if name in result:
                raise ValueError('Duplicate named material in input script')
            result[name] = block
    return result


def build_plan(stage: Path, source_root: Path):
    stage, source_root = Path(stage).resolve(), Path(source_root).resolve()
    tables = {kind: read_table(source_root / 'Config' / name) for kind, name in FILES.items()}
    updates, records, resources = {}, {}, {}
    selected = {'face': [], 'hair': [], 'outfit': [], 'portrait': []}
    source_label = source_root.relative_to(ROOT.parent).as_posix()

    def put(relative, data, origin):
        if relative in updates and updates[relative] != data:
            raise ValueError('Conflicting appearance target: ' + relative)
        updates[relative] = data
        records[relative] = origin

    for kind, name in FILES.items():
        put('Data/Config/CysCreate%s.txt' % kind, (source_root / 'Config' / name).read_bytes(),
            '../' + source_label + '/Config/' + name)

    # Camera_Main in CY base objects names a row, not the legacy height;distance.
    # Keep this creation-only resource independent of the seven catalog tables.
    camera_path = source_root / 'Config/Model_Parameter.txt'
    cameras = read_table(camera_path)
    if cameras.types != ['INT', 'STRING', 'FLOAT', 'FLOAT']:
        raise ValueError('CY Model_Parameter schema must be ISFF')
    if len(cameras.rows) != len(cameras.by_id):
        raise ValueError('Duplicate CY camera row ID')
    for row in cameras.rows:
        if (len(row) != 4 or row[0] < 0 or not all(math.isfinite(v) for v in row[2:])
                or not 0 <= row[2] <= 1000 or not 0 < row[3] <= 1000):
            raise ValueError('Invalid CY camera row')
    put('Data/Config/CysCreateCamera.txt', camera_path.read_bytes(),
        '../' + source_label + '/Config/Model_Parameter.txt')

    index = {}
    for family in ('Model', 'Material'):
        for number in range(1, 9):
            directory = source_root / (family + (str(number) if number > 1 else ''))
            if directory.exists():
                for path in sorted(directory.rglob('*')):
                    if path.is_file():
                        index[path.name.lower()] = path

    def source(key):
        path = index.get(key.decode('gbk').lower()) or index.get(disk_key(key))
        if path is None:
            raise ValueError('CY appearance resource absent: ' + key.hex())
        return path

    def resource(key):
        if not key:
            return
        path = source(key)
        family = 'Model' if path.suffix.lower() in ('.mesh', '.skeleton', '.dynbone') else 'Material'
        target = 'Data/' + family + '/' + disk_key(key)
        blob = path.read_bytes()
        put(target, blob, '../' + source_label + '/' + path.relative_to(source_root).as_posix())
        resources[key] = {'key_hex': key.hex(), 'source': path.relative_to(source_root).as_posix(),
                          'target': target, 'bytes': len(blob), 'sha256': hashlib.sha256(blob).hexdigest()}
        return blob

    meshes, materials, skeletons = set(), set(), set()
    for sex in (0, 1):
        for row in tables['Face'].rows:
            if row[1] == sex and row[7] in (1, 3):
                selected['face'].append([sex, row[0]])
                meshes.add(row[2])
        for row in tables['Hair'].rows:
            if row[1] == sex and row[9] in (1, 3):
                selected['hair'].append([sex, row[0]])
                meshes.add(row[2])
                if row[4]: meshes.add(row[4])
        for row in tables['Portrait'].rows:
            if row[1] == sex and row[3] in (1, 3):
                selected['portrait'].append([sex, row[0], row[2].decode('ascii')])
        for row in tables['Outfit'].rows:
            selected['outfit'].append([sex, row[0]])
            for visual_id in row[2:5]:
                visual = tables['Visual'].get(visual_id)
                if visual is None: raise ValueError('CY starter outfit visual missing')
                meshes.add(visual[1 + 11 * sex])
                materials.update(x for x in visual[2 + 11 * sex].split(b';') if x)

    obj_source = (source_root / 'Model/all.obj').read_bytes()
    objects = {m.group(1): m.group(0) for m in OBJECT.finditer(obj_source)}
    object_stage = (stage / 'Data/Model/all.obj').read_bytes()
    object_info = []
    for sex in (0, 1):
        race = tables['Race'].get(sex)
        model = tables['Model'].get(race[3])
        key = model[1]
        block = objects[key]
        element = objxml.parse_object(block)
        camera_ids = [objxml.B(a.get('value', '')) for a in objxml.iter_attrs(element)
                      if objxml.B(a.get('name', '')) == b'Camera_Main']
        if len(camera_ids) != 1 or not re.fullmatch(rb'[0-9]+', camera_ids[0]):
            raise ValueError('CY base Camera_Main must name one camera row')
        camera_id = int(camera_ids[0])
        camera = cameras.get(camera_id)
        if camera is None:
            raise ValueError('CY base Camera_Main row unavailable')
        default = [objxml.B(a.get('value', '')) for a in objxml.iter_attrs(element)
                   if objxml.B(a.get('name', '')) == b'DefaultSkeleton']
        skeletons.update(default)
        idle_links = [objxml.B(link.get('skeleton', '')) for link in element.findall('Skeletons/Skeleton')
                      if IDLE in objxml.B(link.get('animations', '')).split()]
        if len(idle_links) != 1: raise ValueError('CY idle animation link missing or ambiguous')
        skeletons.update(idle_links)
        pattern = re.compile(rb'<Object\s+name="' + re.escape(key) + rb'"\s*>.*?</Object>', re.S)
        if len(pattern.findall(object_stage)) != 1: raise ValueError('Expected one staged base object')
        object_stage = pattern.sub(lambda _: block, object_stage)
        object_info.append({'sex': sex, 'key_hex': key.hex(), 'block_sha256': hashlib.sha256(block).hexdigest(),
                            'camera_id': camera_id, 'camera_height': camera[2], 'camera_distance': camera[3],
                            'idle_hex': IDLE.hex(), 'idle_skeleton_hex': idle_links[0].hex(),
                            'declared_animation_links': len(element.findall('Skeletons/Skeleton'))})
    put('Data/Model/all.obj', object_stage, '../' + source_label + '/Model/all.obj [two exact base blocks]')

    mesh_reports = []
    for key in sorted(meshes):
        data = resource(key)
        info = tlbbfmt.mesh_info(data)
        if info['err']: raise ValueError('Invalid CY appearance mesh: ' + key.hex())
        if info['skel']: skeletons.add(info['skel'])
        materials.update(info['mats'])
        mesh_reports.append({'key_hex': key.hex(), 'skeleton_hex': info['skel'].hex(),
                             'submeshes': info['subs'], 'vertices': info['verts'], 'triangles': info['tris']})
    for key in sorted(skeletons):
        blob = resource(key)
        if skeleton_names(blob)['err']: raise ValueError('Invalid CY appearance skeleton')
    for info in object_info:
        blob = source(bytes.fromhex(info['idle_skeleton_hex'])).read_bytes()
        if IDLE not in skeleton_names(blob)['anims']: raise ValueError('CY idle animation absent from skeleton')

    mat_source = (source_root / 'Material/all.material').read_bytes()
    mat_definitions = tlbbfmt.material_defs(mat_source)[0]
    pending = list(materials)
    while pending:
        key = pending.pop()
        if key in (b'BaseWhite', b'BaseWhiteNoLighting'): continue
        if key not in mat_definitions: raise ValueError('CY material undefined: ' + key.hex())
        parent = mat_definitions[key]['parent']
        if parent in mat_definitions and parent not in materials:
            materials.add(parent); pending.append(parent)
    mat_blocks = material_blocks(mat_source, materials)
    textures = set()
    for key in materials:
        textures.update(tlbbfmt.material_textures(key, mat_definitions))
    for key in sorted(textures): resource(key)
    mat_stage = (stage / 'Data/Material/all.material').read_bytes()
    existing = material_blocks(mat_stage)
    for key in sorted(materials):
        if key in (b'BaseWhite', b'BaseWhiteNoLighting'): continue
        block = mat_blocks[key]
        if key in existing:
            if mat_stage.count(existing[key]) != 1: raise ValueError('Staged material block not unique')
            mat_stage = mat_stage.replace(existing[key], block, 1)
        else:
            mat_stage += b'\n' + block
    put('Data/Material/all.material', mat_stage,
        '../' + source_label + '/Material/all.material [selected appearance blocks]')
    report = {'source': '../' + source_label, 'selected': selected, 'objects': object_info,
              'meshes': mesh_reports, 'resources': list(resources.values()),
              'material_keys_hex': [x.hex() for x in sorted(materials)],
              'texture_count': len(textures), 'skeleton_count': len(skeletons),
              'updates': len(updates), 'update_bytes': sum(len(v) for v in updates.values()),
              'scope': 'Creation appearance and one standing animation; other lazy animation links are not staged.'}
    return updates, records, report


if __name__ == '__main__':
    if len(sys.argv) != 4: raise SystemExit('usage: script STAGE SOURCE_ROOT REPORT_JSON')
    updates, records, report = build_plan(Path(sys.argv[1]), Path(sys.argv[2]))
    out = Path(sys.argv[3]).resolve()
    if ROOT / 'Build' not in out.parents: raise SystemExit('Report must stay in CY-Source/Build')
    if out.exists(): raise SystemExit('Preserve prior evidence; choose a new report')
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding='utf-8')
    print(json.dumps({k: report[k] for k in ('updates', 'update_bytes', 'texture_count', 'skeleton_count')}))
