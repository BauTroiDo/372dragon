"""Reproducible, opt-in DATA CY creation/selection UI for a private GL stage.

The original CY Lua is encoded. These are explicitly CY-Source controllers,
using CY art and raw CY appearance tables, not a claim to recover that script.
All destination files and backups stay under CY-Source/Build.
"""
import argparse
import copy
import datetime
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

from prepare_login_profile import ROOT, checked
from prepare_gl_login_profile import digest, relative, xml, SCHEME, PAIRS

SOURCE = ROOT.parent / 'Tools/DATA NEW/DataCY31-08-26'
MARKER = 'Bin64/create_role_profile.json'
GL_MARKER = 'Bin64/gl_login_profile.json'
PREFIX = 'CysCR_'
FONT_HASH = 'd45f67f0a7c0ca3f256950777ce6a61cc7ce5f9696d02900cbbaac25f8aa7d16'
TABLES = {'Race': 'CharRace.txt', 'Model': 'CharModelEx.txt', 'Face': 'CharFaceGeo.txt',
          'Hair': 'CharHairGeo.txt', 'Portrait': 'CharacterFace.txt', 'Outfit': 'NewRoleEquipset.txt',
          'Visual': 'ItemVisualChar.txt'}
TEMPLATES = ROOT / 'Tools/ui/templates'

# IDs follow the original CY MenpaiModel callbacks. Names are the actual CY
# bitmap labels, not misleading atlas keys (Kunlun=Peach Island, Hongming=Jueqing).
PREVIEWS = [
    ('Shaolin', 3, 'Thiếu Lâm'), ('Mingjiao', 4, 'Minh Giáo'), ('Gaibang', 3, 'Cái Bang'),
    ('Wudang', 4, 'Võ Đang'), ('Emei', 4, 'Nga Mi'), ('Xingxiu', 3, 'Tinh Túc'),
    ('Tianlong', 4, 'Thiên Long'), ('Tianshan', 3, 'Thiên Sơn'), ('Xiaoyao', 4, 'Tiêu Dao'),
    ('Murong', 3, 'Mộ Dung'), ('Tangmen', 5, 'Đường Môn'), ('Guigu', 5, 'Quỷ Cốc'),
    ('Kunlun', 5, 'Đào Hoa Đảo'), ('Hongming', 5, 'Tuyệt Tình Cốc'), ('ERenGu', 5, 'Ác Nhân Cốc')]


def preview_rows():
    rows = []
    for index, (icon, atlas, label) in enumerate(PREVIEWS):
        image = 'set:' + PREFIX + 'CreateRole' + str(atlas) + ' image:Icon_' + icon
        description = label + '. Nam / Nữ. Hủy để quay lại.'
        rows.append(str(index) + '\t' + image + '\t' + description)
    return ('\n'.join(rows) + '\n').encode('utf-8')


def json_bytes(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode('utf-8')


def source_name(path):
    # Provenance may point outside CY-Source; only the fixed source is read there.
    return '../Tools/DATA NEW/DataCY31-08-26/' + path.relative_to(SOURCE).as_posix()


def table_rows(data, columns):
    lines = data.split(b'\n')
    if len(lines) < 3 or len(lines[0].rstrip(b'\r').split(b'\t')) != columns:
        raise ValueError('Unexpected DATA CY table schema')
    rows = []
    for line in lines[2:]:
        line = line.rstrip(b'\r')
        if not line or line.startswith(b'#'):
            continue
        row = line.split(b'\t')
        if len(row) != columns:
            raise ValueError('Malformed DATA CY table row')
        int(row[0])
        rows.append(row)
    return rows


def generated_names():
    values, records = [], []
    for sex in ('Female', 'Male'):
        parts = []
        for part in ('FirstName', 'LastName'):
            path = SOURCE / 'Config' / (sex + part + '.txt')
            raw = path.read_bytes()
            strings = [row[1].decode('gbk') for row in table_rows(raw, 2)]
            if not strings or any(not s or any(ord(c) < 32 for c in s) for s in strings):
                raise ValueError('Invalid DATA CY random name part')
            parts.append(strings)
            records.append({'path': source_name(path), 'sha256': digest(raw), 'rows': len(strings)})
        if max(len(s.encode('utf-8')) for s in parts[0]) + max(len(s.encode('utf-8')) for s in parts[1]) > 29:
            raise ValueError('DATA CY random names exceed the native name limit')
        values.append(parts)
    # JSON strings are also valid Lua strings for these data (no \u escapes).
    def lua(value):
        if isinstance(value, list):
            return '{' + ','.join(lua(v) for v in value) + '}'
        return json.dumps(value, ensure_ascii=False)
    return lua(values).encode('utf-8'), records


def serial(tree):
    ET.indent(tree, space='  ')
    return ET.tostring(tree, encoding='utf-8', xml_declaration=True) + b'\n'


def load_layout_module():
    spec = importlib.util.spec_from_file_location('cys_create_layout', ROOT / 'Tools/ui/create_role_layout.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_base(stage):
    marker = checked((stage / MARKER).relative_to(ROOT))
    if not (stage / 'Bin64/offline_stage.json').is_file():
        raise ValueError('Expected a private offline Game stage')
    if marker.exists():
        raise ValueError('Creation profile already exists; use a fresh stage')
    raw = (stage / GL_MARKER).read_bytes()
    manifest = json.loads(raw)
    if manifest.get('applied') is not True:
        raise ValueError('The GL login profile must already be applied')
    expected = {p + ext for p in PAIRS for ext in ('.lua', '.layout.xml')}
    if {p['path'] for p in manifest['pairs']} != expected:
        raise ValueError('Expected exactly six original GL login files')
    for record in manifest['pairs']:
        path = relative(record['path'])
        actual = (stage / 'Data/Interface' / path).read_bytes()
        canonical = (ROOT / 'Assets/Canonical/Data/InterfaceFolder' / path).read_bytes()
        if digest(actual) != record['sha256'] or actual != canonical:
            raise ValueError('Original GL login pair was changed: ' + path)
    for record in manifest['files']:
        path = relative(record['path'])
        checked((stage / path).relative_to(ROOT))
        if digest((stage / path).read_bytes()) != record['sha256']:
            raise ValueError('GL manifest hash mismatch: ' + path)
    font = stage / 'Data/Interface/Schema/NotoSansSC-Regular.ttf'
    if digest(font.read_bytes()) != FONT_HASH:
        raise ValueError('Expected the approved NotoSansSC-Regular.ttf')
    filter_data = (stage / 'Data/Config/StrFilter.txt').read_bytes()
    if any(line.strip() and not line.startswith(b'#') for line in filter_data.split(b'\n')[2:]):
        raise ValueError('StrFilter must remain empty')
    return raw, manifest


def make_plan(stage, include_appearance=True):
    original_gl, gl = verify_base(stage)
    iface = SOURCE / 'Interface'
    scheme_path = iface / SCHEME
    source_scheme = xml(scheme_path.read_bytes())
    stage_scheme = xml((stage / 'Data/Interface' / SCHEME).read_bytes())
    for node in stage_scheme:
        if any(value.startswith(PREFIX) for value in node.attrib.values()):
            raise ValueError('Creation namespace already exists in the base scheme')
    maps = {n.attrib['WindowType']: n for n in source_scheme.findall('FalagardMapping')}
    all_atlases_path = iface / 'Schema/all.imageset.xml'
    atlas_root = xml(all_atlases_path.read_bytes())
    atlases = {n.attrib['Name']: n for n in atlas_root.findall('Imageset')}
    if len(atlases) != len(atlas_root):
        raise ValueError('Duplicate DATA CY atlas definition')
    source_looks, look_origins = {}, {}
    for entry in source_scheme.findall('LookNFeel'):
        path = iface / relative(entry.attrib['Filename'])
        for look in xml(path.read_bytes()).findall('WidgetLook'):
            name = look.attrib['name']
            if name in source_looks:
                raise ValueError('Duplicate DATA CY look: ' + name)
            source_looks[name] = look
            look_origins[name] = path

    updates, origins, sources = {}, {}, {}
    def source(path):
        key = source_name(path)
        sources[key] = {'path': key, 'sha256': digest(path.read_bytes()), 'bytes': path.stat().st_size}
        return key
    def update(path, data, origin):
        path = relative(path)
        if path in updates and updates[path] != data:
            raise ValueError('Conflicting output: ' + path)
        checked((stage / path).relative_to(ROOT))
        updates[path], origins[path] = data, origin

    source(scheme_path)
    source(all_atlases_path)
    for name, filename in TABLES.items():
        path = SOURCE / 'Config' / filename
        update('Data/Config/CysCreate' + name + '.txt', path.read_bytes(), source(path))

    module = load_layout_module()
    types = {name: name for name in sorted(module.types())}
    for screen in module.COUNTS:
        source(iface / screen / (screen + ".layout.xml"))
        source(iface / screen / (screen + ".lua"))
    layouts = {name: xml(module.layout(name)) for name in ('CreateRole', 'SelectRole')}
    for name, tree in layouts.items():
        update('Data/Interface/' + name + '/' + name + '.layout.xml', serial(tree), 'Tools/ui/create_role_layout.py')
    update("Data/Config/CysCreatePreview.txt", preview_rows(),
           "CY art/callback ID mapping; authored Vietnamese preview instructions")
    random_names, random_sources = generated_names()
    for item in random_sources:
        path = SOURCE / item['path'].split('DataCY31-08-26/', 1)[1]
        source(path)
    for name in ('CreateRole', 'SelectRole'):
        path = TEMPLATES / ('Cys' + name + '.lua')
        raw = path.read_bytes()
        if name == 'CreateRole':
            if raw.count(b'__CYS_RANDOM_NAMES__') != 2:
                raise ValueError('Unexpected random name template')
            raw = raw.replace(b'local names = __CYS_RANDOM_NAMES__', b'local names = ' + random_names)
        update('Data/Interface/' + name + '/' + name + '.lua', raw, path.relative_to(ROOT).as_posix())

    # Only referenced sections of shared utility looks belong to this profile.
    # Copy mapped/inherited looks fully; preserve each selected section verbatim.
    full_looks = {maps[t].attrib['LookNFeel'] for t in types.values()}
    sections = {}
    pending = [(name, None) for name in full_looks]
    seen = set()
    while pending:
        name, section = pending.pop()
        if (name, section) in seen:
            continue
        seen.add((name, section))
        look = source_looks[name]
        nodes = [look] if section is None else [n for n in look if n.attrib.get('name') == section]
        if not nodes:
            raise ValueError('Missing shared look section: ' + name + '/' + str(section))
        for subtree in nodes:
            for node in subtree.iter():
                if 'inherits' in node.attrib:
                    other = node.attrib['inherits']
                    full_looks.add(other)
                    pending.append((other, None))
                if 'look' in node.attrib:
                    other, part = node.attrib['look'], node.attrib.get('section')
                    if part is None:
                        full_looks.add(other)
                    else:
                        sections.setdefault(other, set()).add(part)
                    pending.append((other, part))
                if node.tag == 'Child':
                    raise ValueError('Unexpected child widget in bounded creation looks')
    needed_looks = full_looks | set(sections)
    looks_tree = ET.Element('Falagard')
    for name in sorted(needed_looks):
        look = copy.deepcopy(source_looks[name])
        if name not in full_looks:
            for child in list(look):
                if child.attrib.get('name') not in sections[name]:
                    look.remove(child)
        source(look_origins[name])
        for node in look.iter():
            if node is look:
                node.set('name', PREFIX + name)
            for attr in ('look', 'inherits'):
                if attr in node.attrib:
                    node.set(attr, PREFIX + node.attrib[attr])
            if 'imageset' in node.attrib:
                node.set('imageset', PREFIX + node.attrib['imageset'])
            if node.tag == 'PropertyDefinition':
                node.set('layoutOnWrite', 'false')
            if node.tag == 'Property' and node.attrib.get('name') == 'BackgroundName':
                node.set('value', 'CysCreateRole/Common/MeshBack.dds')
        looks_tree.append(look)

    # Collect exact atlas/image pairs, including every selectable portrait.
    pairs = set()
    def scan(tree):
        for node in tree.iter():
            if 'imageset' in node.attrib:
                pairs.add((node.attrib['imageset'], node.attrib['image']))
            for value in node.attrib.values():
                pairs.update(re.findall(r'\bset:([^\s]+)\s+image:([^\s]+)', value))
    scan(looks_tree)
    for tree in layouts.values():
        scan(tree)
    portrait_rows = table_rows((SOURCE / 'Config/CharacterFace.txt').read_bytes(), 6)
    portrait_count = 0
    for row in portrait_rows:
        if int(row[1]) in (0, 1) and int(row[3]) in (1, 3):
            descriptor = row[2].decode('gbk')
            match = re.fullmatch(r'set:([^\s]+) image:([^\s]+)', descriptor)
            if not match:
                raise ValueError('Unexpected selectable portrait descriptor')
            pairs.add((PREFIX + match[1], match[2]))
            portrait_count += 1
    # Preview uses the original fifteen CY sect title images, returned by native.
    for atlas in ('CreateRole3', 'CreateRole4', 'CreateRole5'):
        pairs.update((PREFIX + atlas, n.attrib['Name']) for n in atlases[atlas].findall('Image')
                     if n.attrib['Name'].startswith('Icon_'))
    needed_atlases = {name.removeprefix(PREFIX) for name, _ in pairs}
    if any(not name.startswith(PREFIX) for name, _ in pairs):
        raise ValueError('A creation image escaped its namespace')

    def texture(filename):
        filename = relative(filename)
        candidates = [root / filename for root in [iface, *sorted(SOURCE.glob('Material*'))] if root.is_dir()]
        found = [p for p in candidates if p.is_file()]
        if not found or len({digest(p.read_bytes()) for p in found}) != 1:
            raise ValueError('Missing or ambiguous DATA CY texture: ' + filename)
        return found[0]

    atlas_records = []
    for name in sorted(needed_atlases):
        original = atlases[name]
        images = {n.attrib['Name'] for n in original.findall('Image')}
        wanted = {image for atlas, image in pairs if atlas == PREFIX + name}
        if not wanted <= images:
            raise ValueError('Missing exact image in DATA CY atlas ' + name)
        image_path = texture(original.attrib['Imagefile'])
        destination = 'CysCreateRole/' + relative(original.attrib['Imagefile'])
        update('Data/Material/' + destination, image_path.read_bytes(), source(image_path))
        atlas = copy.deepcopy(original)
        atlas.set('Name', PREFIX + name)
        atlas.set('Imagefile', destination)
        atlas_file = 'CysCreateRole/' + PREFIX + name + '.imageset.xml'
        atlas_origin = source_name(all_atlases_path) + '#' + name
        update('Data/Interface/' + atlas_file, serial(atlas), atlas_origin)
        ET.SubElement(stage_scheme, 'Imageset', Name=PREFIX + name, Filename=atlas_file)
        atlas_records.append({'name': PREFIX + name, 'images': sorted(wanted),
                              'source': name,
                              'texture': source_name(image_path)})
    background = texture('Common/MeshBack.dds')
    update('Data/Material/CysCreateRole/Common/MeshBack.dds', background.read_bytes(), source(background))
    for short, original_type in types.items():
        mapping = copy.deepcopy(maps[original_type])
        mapping.set('WindowType', PREFIX + short)
        mapping.set('LookNFeel', PREFIX + mapping.attrib['LookNFeel'])
        ET.SubElement(stage_scheme, 'FalagardMapping', mapping.attrib)
    look_file = 'CysCreateRole/CysCreateRole.looknfeel.xml'
    update('Data/Interface/' + look_file, serial(looks_tree), 'namespaced DATA CY look closure')
    ET.SubElement(stage_scheme, 'LookNFeel', Filename=look_file)
    for name, size in [('Control', 11)]:
        fonts = ET.Element('Fonts')
        ET.SubElement(fonts, 'Font', Name=PREFIX + name, Filename='Schema/NotoSansSC-Regular.ttf',
                      Size=str(size), TextureSize='512', CodePage='65001', Type='FreeType')
        filename = 'CysCreateRole/' + PREFIX + name + '.font'
        update('Data/Interface/' + filename, serial(fonts), 'approved NotoSansSC-Regular.ttf UTF-8 branch')
        ET.SubElement(stage_scheme, 'Font', Name=PREFIX + name, Filename=filename, Type='FreeType')
    update('Data/Interface/' + SCHEME, serial(stage_scheme), 'existing GL scheme plus namespaced DATA CY closure')

    appearance_report = None
    material_report = None
    scene_report = None
    showroom_report = None
    if include_appearance:
        path = ROOT / 'Tests/ui/create_role_appearance_resources.py'
        if not path.is_file():
            raise ValueError('Appearance resource closure helper is not ready')
        spec = importlib.util.spec_from_file_location('cys_appearance_resources', path)
        helper = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(helper)
        model_updates, model_origins, appearance_report = helper.build_plan(stage, SOURCE)
        for name, data in model_updates.items():
            update(name, data, model_origins[name])
        source(SOURCE / 'Model/all.obj')
        source(SOURCE / 'Material/all.material')
        import create_role_materials
        material_updates, material_origins, material_report = create_role_materials.build_plan(stage, SOURCE, appearance_report)
        for name, data in material_updates.items():
            update(name, data, material_origins[name])

        def compose(filename):
            path = ROOT / 'Tools/data' / filename
            if not path.is_file():
                raise ValueError('Full creation profile requires ' + filename)
            spec = importlib.util.spec_from_file_location('cys_' + path.stem, path)
            helper = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(helper)
            extra, extra_origins, detail = helper.build_plan(stage, SOURCE, base_updates=updates)
            if detail.get('valid') is not True:
                raise ValueError('Creation resource preflight failed: ' + filename)
            for name, data in extra.items():
                name = relative(name)
                # The child composes on the exact planned bytes, including prior
                # object/material/Bootstrap edits. Its output intentionally replaces
                # that intermediate value; update still enforces destination scope.
                updates.pop(name, None)
                update(name, data, extra_origins[name])
            return detail

        scene_report = compose('create_role_scene_resources.py')
        showroom_report = compose('create_role_showroom.py')

    # Update the inherited manifest only for files changed by this extension.
    # Six login pairs remain untouched and retain their original manifest hashes.
    gl_after = copy.deepcopy(gl)
    for record in gl_after['files']:
        name = record['path']
        if name in updates:
            record['sha256_before_creation'] = record['sha256']
            record['sha256'] = digest(updates[name])
            record['bytes'] = len(updates[name])
            record['creation_origin'] = origins[name]
    gl_after['creation_extension'] = {'manifest': MARKER, 'parent_manifest_sha256': digest(original_gl)}
    update(GL_MARKER, json_bytes(gl_after), 'GL manifest inheritance; original pairs unchanged')
    report = {'version': 1, 'stage': stage.relative_to(ROOT).as_posix(), 'applied': False,
              'source': '../Tools/DATA NEW/DataCY31-08-26', 'controller': 'CY-Source, original CY Lua is encoded',
              'gl_parent_sha256': digest(original_gl), 'login_pairs': gl['pairs'], 'namespace': PREFIX,
              'font_sha256': FONT_HASH, 'font_codepage': 65001, 'strfilter_rules': 0,
              'sources': [sources[k] for k in sorted(sources)], 'random_names': random_sources,
              'generator_sources': [{'path': path.relative_to(ROOT).as_posix(), 'sha256': digest(path.read_bytes())}
                                    for path in [Path(__file__), ROOT / 'Tools/ui/create_role_layout.py',
                                                 TEMPLATES / 'CysCreateRole.lua', TEMPLATES / 'CysSelectRole.lua',
                                                 ROOT / 'Tests/ui/create_role_appearance_resources.py',
                                                 ROOT / 'Tools/data/create_role_materials.py'] +
                                                ([ROOT / 'Tools/data/create_role_scene_resources.py',
                                                  ROOT / 'Tools/data/create_role_showroom.py'] if include_appearance else [])],
              'atlases': atlas_records, 'portrait_count': portrait_count, 'appearance': appearance_report,
              'materials': material_report, 'scene': scene_report, 'showroom': showroom_report,
              'layout_contract': {'CreateRole': 96, 'SelectRole': 50, 'original_geometry_art_events': True,
                                  'select_rendering': 'native main scene; no GUI RTT window added'},
              'preview_labels': [{'id': i, 'image': 'set:CysCR_CreateRole' + str(a) + ' image:Icon_' + k, 'label': label}
                                 for i, (k, a, label) in enumerate(PREVIEWS)],
              'workflow_reference': [{'path': 'Assets/Canonical/Data/InterfaceFolder/' + name + '/' + name + '.lua',
                                      'sha256': digest((ROOT / 'Assets/Canonical/Data/InterfaceFolder' / name / (name + '.lua')).read_bytes())}
                                     for name in ('CreateRole', 'SelectRole')],
              'controls': {name: [n.attrib['Name'] for n in tree.iter('Window')] for name, tree in layouts.items()},
              'files': [{'path': name, 'sha256': digest(data), 'bytes': len(data), 'origin': origins[name]}
                        for name, data in sorted(updates.items())]}
    return updates, report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stage', required=True, help='Existing GL stage, relative to CY-Source')
    parser.add_argument('--out', help='New evidence directory under Build')
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--ui-only-plan', action='store_true', help='Read-only UI plan while model closure is prepared')
    args = parser.parse_args()
    stage = checked(args.stage)
    if args.apply and args.ui_only_plan:
        raise ValueError('An incomplete UI-only profile must never be applied')
    updates, report = make_plan(stage, not args.ui_only_plan)
    out = checked(args.out or ('Build/Logs/2026-09-13-gpt-create-role/profile/' +
                              datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')))
    if out.is_relative_to(stage) or stage.is_relative_to(out):
        raise ValueError('Evidence and stage must be disjoint')
    out.mkdir(parents=True, exist_ok=False)
    (out / 'plan.json').write_bytes(json_bytes(report))
    if args.apply:
        # Validate and back up every pre-existing destination before the first mutation.
        for index, record in enumerate(report['files']):
            path = checked((stage / record['path']).relative_to(ROOT))
            if path.exists():
                before = path.read_bytes()
                backup = out / ('%04d.before.bin' % index)
                backup.write_bytes(before)
                if backup.read_bytes() != before:
                    raise RuntimeError('Backup verification failed')
                record.update(sha256_before=digest(before), backup=backup.relative_to(ROOT).as_posix())
        (out / 'backup-index.json').write_bytes(json_bytes(report))
        for record in report['files']:
            path = checked((stage / record['path']).relative_to(ROOT))
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(updates[record['path']])
            if digest(path.read_bytes()) != record['sha256']:
                raise RuntimeError('Output hash verification failed: ' + record['path'])
        for record in report['login_pairs']:
            if digest((stage / 'Data/Interface' / record['path']).read_bytes()) != record['sha256']:
                raise RuntimeError('Login pair changed during creation overlay')
        report['applied'] = True
        checked((stage / MARKER).relative_to(ROOT)).write_bytes(json_bytes(report))
    (out / 'result.json').write_bytes(json_bytes(report))
    print(json.dumps({'applied': report['applied'], 'files': len(report['files']),
                      'atlases': len(report['atlases']), 'portraits': report['portrait_count'],
                      'report': (out / 'result.json').relative_to(ROOT).as_posix()}))


if __name__ == '__main__':
    main()
