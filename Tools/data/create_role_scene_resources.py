"""Byte-preserving DATA CY login scene closure for a private CY-Source stage.

This plans the real tl3chuangjian.Scene and its dependencies. Native scene
routing and camera evidence are recorded independently. No source or stage
writes occur in build_plan; base_updates composes with appearance in memory.
"""
import argparse
from collections import Counter, defaultdict
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import sys
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tools/pipeline'))
import tlbbfmt
from avatar.data import disk_key, skeleton_names, read_table
from avatar import objxml

SCENE = 'tl3chuangjian.Scene'
BUILTINS = {b'BaseWhite', b'BaseWhiteNoLighting'}
KINDS = {'Enviroment', 'Light', 'SceneConfig', 'SkySphere', 'StaticEntity',
         'ParticleSystem', 'TerrainLiquid', 'Model'}
PROGRAM = {b'vertex_program', b'fragment_program'}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def key_record(key):
    return {'key_hex': key.hex(), 'display_gbk': key.decode('gbk')}


def safe_name(value):
    value = value.replace('\\', '/')
    path = PurePosixPath(value)
    if not value or path.is_absolute() or '..' in path.parts or ':' in value or '\x00' in value:
        raise ValueError('Unsafe scene resource path')
    return path.as_posix()


def disk_path(key):
    """Preserve resource directories: Ogre does not flatten prefixed requests.

    Disk components retain the appearance helper's GBK-to-CP1252 convention.
    Split Unicode path separators before encoding so a GBK trail byte cannot
    accidentally become a path delimiter.
    """
    parts = safe_name(key.decode('gbk')).split('/')
    encoded = [part.encode('gbk') for part in parts]
    if any(b'\\' in part for part in encoded):
        raise ValueError('GBK filename contains an ACP path separator byte')
    return '/'.join(disk_key(part) for part in encoded)


def correlative_key(key, base):
    """WXResources::loadCorrelativeResource first tries the model directory."""
    return base.rsplit(b'/', 1)[0] + b'/' + key if b'/' not in key and b'/' in base else key


def script_blocks(data, kind, selected=None):
    result = {}
    for header, block in tlbbfmt.iter_blocks(data)[0]:
        words = header.split()
        if kind == 'particle':
            key = header.removeprefix(b'particle_system ').strip()
        elif kind == 'effect':
            if not words or words[0] != b'effect':
                continue
            key = header.split(None, 1)[1]
        elif not words or words[0] not in ({b'material'} if kind == 'material' else PROGRAM):
            continue
        else:
            key = words[1].split(b':', 1)[0]
        if selected is not None and key not in selected:
            continue
        if key in result:
            if selected is not None and result[key] != block:
                raise ValueError('Duplicate selected script definition: ' + key.hex())
            continue
        result[key] = block
    return result


def merge_script(before, replacements, kind):
    """Replace whole exact blocks; keep unrelated bytes, comments and encoding."""
    existing = script_blocks(before, kind, set(replacements))
    after = before
    for key, block in sorted(replacements.items()):
        if key in existing:
            old = existing[key]
            if after.count(old) != 1:
                raise ValueError('Nonunique staged block: ' + key.hex())
            trailing = old[len(old.rstrip(b'\r\n')):]
            replacement = block + (trailing if trailing and not block.endswith((b'\r', b'\n')) else b'')
            after = after.replace(old, replacement, 1)
        else:
            after += b'\n' + block
    final = script_blocks(after, kind, set(replacements))
    # A source block at EOF may have no final newline. Appending the next block
    # adds a separator outside that block; its original bytes must still occur.
    mismatched = [key.hex() for key, block in replacements.items()
                  if final.get(key, b'').rstrip(b'\r\n') != block.rstrip(b'\r\n') or block not in after]
    if mismatched:
        raise ValueError('Merged scene script failed byte verification: ' + ','.join(mismatched))
    return after


def texture_references(block):
    """Ogre texture, anim_texture and cubic_texture forms, including all frames."""
    refs, placeholders = set(), set()
    for line in block.split(b'\n'):
        words = line.split(b'//', 1)[0].split()
        if len(words) < 2:
            continue
        command, args = words[0], words[1:]
        values = []
        if command == b'set_texture_alias' and len(args) == 2:
            values = [args[1]]
        elif command == b'texture':
            values = [args[0]]
        elif command == b'anim_texture':
            if len(args) < 3:
                raise ValueError('Malformed animated texture')
            if len(args) == 3 and re.fullmatch(rb'[1-9][0-9]*', args[1]):
                stem, dot, ext = args[0].rpartition(b'.')
                count = int(args[1])
                if not dot or count > 4096:
                    raise ValueError('Invalid numbered animated texture')
                values = [stem + b'_' + str(i).encode('ascii') + dot + ext for i in range(count)]
            else:
                values = args[:-1]
        elif command == b'cubic_texture':
            if len(args) == 7:
                values = args[:-1]
            elif len(args) == 2:
                if args[1].lower() == b'combineduvw':
                    values = [args[0]]
                elif args[1].lower() == b'separateuv':
                    stem, dot, ext = args[0].rpartition(b'.')
                    if not dot:
                        raise ValueError('Cubic texture base has no extension')
                    values = [stem + suffix + dot + ext for suffix in
                              (b'_fr', b'_bk', b'_lf', b'_rt', b'_up', b'_dn')]
                else:
                    raise ValueError('Invalid cubic texture mode')
            else:
                raise ValueError('Malformed cubic texture')
        for value in values:
            (placeholders if b'<' in value else refs).add(value)
    return refs, placeholders


def build_plan(stage, source_root, base_updates=None):
    stage, source_root = Path(stage).resolve(), Path(source_root).resolve()
    if ROOT / 'Build' not in stage.parents:
        raise ValueError('Scene destination must be a private CY-Source/Build stage')
    source_label = '../' + source_root.relative_to(ROOT.parent).as_posix()
    base_updates = {} if base_updates is None else base_updates
    updates, origins, sources, resources = {}, {}, {}, {}
    missing, unsupported, ambiguities, template_bindings = [], [], [], []
    material_keys, particle_keys, program_keys = set(), set(), set()
    object_counts, mesh_reports, model_reports = Counter(), [], []

    def source_record(path):
        raw = path.read_bytes()
        label = source_label + '/' + path.relative_to(source_root).as_posix()
        sources[label] = {'path': label, 'sha256': digest(raw), 'bytes': len(raw)}
        return raw, label

    def current(name):
        return base_updates[name] if name in base_updates else (stage / name).read_bytes()

    def put(name, raw, origin):
        name = safe_name(name)
        target = (stage / name).resolve()
        if stage not in target.parents:
            raise ValueError('Scene target escaped private stage')
        if name in updates and updates[name] != raw:
            raise ValueError('Conflicting scene output: ' + name)
        updates[name], origins[name] = raw, origin

    # Keep actual source paths as well as basename aliases. Prefix-qualified
    # references take precedence over flattened aliases, avoiding a different
    # same-named mesh in another directory. Ambiguous bytes fail closed.
    index = defaultdict(list)
    for family in ('Model', 'Material', 'Effect', 'Scene', 'Brushes'):
        for number in range(1, 9):
            directory = source_root / (family + (str(number) if number > 1 else ''))
            if not directory.is_dir():
                continue
            for path in sorted(directory.rglob('*')):
                if path.is_file():
                    relative = path.relative_to(directory).as_posix().lower()
                    for name in {relative, path.name.lower()}:
                        index[(family, name)].append(path)

    def locate(key, family):
        display = safe_name(key.decode('gbk')).lower()
        candidates = index.get((family, display), [])
        if not candidates:
            candidates = index.get((family, display.rsplit('/', 1)[-1]), [])
        if not candidates:
            candidates = index.get((family, disk_key(key)), [])
        if not candidates and family == 'Material':
            bootstrap_texture = source_root / 'MaterialTemplates' / safe_name(key.decode('gbk'))
            if bootstrap_texture.is_file():
                candidates = [bootstrap_texture]
        if not candidates:
            missing.append(dict(kind=family, **key_record(key)))
            return None
        candidates = list(dict.fromkeys(candidates))
        if len(candidates) > 1:
            variants = {digest(path.read_bytes()) for path in candidates}
            if len(variants) != 1:
                ambiguities.append(dict(kind=family, candidates=[p.relative_to(source_root).as_posix()
                                                                for p in candidates], **key_record(key)))
                return None
        return candidates[-1]

    def resource(key, family):
        if not key:
            return None
        identity = (family, key)
        if identity in resources:
            return updates[resources[identity]['target']]
        path = locate(key, family)
        if path is None:
            return None
        raw, label = source_record(path)
        target = 'Data/' + family + '/' + disk_path(key)
        put(target, raw, label)
        resources[identity] = dict(target=target, source=label, bytes=len(raw), sha256=digest(raw),
                                   **key_record(key))
        return raw

    scene_blob = resource(SCENE.encode('ascii'), 'Scene')
    if scene_blob is None:
        raise ValueError('Required DATA CY scene is missing')
    scene = ET.fromstring(scene_blob)
    for item in scene.findall('Object'):
        kind = item.get('type')
        object_counts[kind] += 1
        if kind not in KINDS:
            unsupported.append({'kind': 'scene object', 'type': kind})
    for tag in scene:
        if tag.tag not in {'Author', 'Copyright', 'Description', 'Terrain', 'SkySphere', 'Object'}:
            unsupported.append({'kind': 'scene root tag', 'name': tag.tag})

    terrain = ET.fromstring(resource(scene.find('Terrain').get('filename').encode('gbk'), 'Scene'))
    for tag in terrain:
        if tag.tag not in {'scale', 'centre', 'heightmap', 'gridInfo', 'lightmap', 'textures', 'pixmaps', 'materials'}:
            unsupported.append({'kind': 'terrain tag', 'name': tag.tag})
    for tag in ('heightmap', 'gridInfo', 'lightmap'):
        resource(terrain.find(tag).get('filename').encode('gbk'), 'Scene')
    for item in terrain.findall('textures/texture'):
        resource(item.get('filename').encode('gbk'), 'Brushes')
    terrain_materials = {item.get('material').encode('gbk') for item in terrain.findall('materials/template')}
    material_keys.update(terrain_materials)
    for item in terrain.findall('materials/fog_replacement'):
        program_keys.update(value.encode('ascii') for value in item.attrib.values())
    sky = ET.fromstring(resource(scene.find('SkySphere').get('filename').encode('gbk'), 'Scene'))
    sky_textures = {value.encode('gbk') for item in sky.iter() for name, value in item.attrib.items()
                    if name == 'texture' or name.startswith('texture_') and name != 'texture_count'
                    or name.endswith('_texture')}
    for key in sorted(sky_textures):
        resource(key, 'Material')
    # Sidecars are engine-discovered by scene basename rather than XML links.
    for extension in ('.hdr', '.newhdrbloom', '.hfog', '.godrays'):
        path = source_root / 'Scene' / (Path(SCENE).stem + extension)
        if path.is_file():
            resource(path.name.encode('ascii'), 'Scene')

    seen_meshes, seen_models, seen_skeletons = set(), set(), set()
    skeleton_reports = []

    def skeleton(key):
        if key in seen_skeletons:
            return
        seen_skeletons.add(key)
        raw = resource(key, 'Model')
        if raw is not None:
            info = skeleton_names(raw)
            structure = tlbbfmt.skel_info(raw)
            tail = raw[structure['end']:]
            if info['err'] or structure['err'] or any(tail):
                unsupported.append(dict(kind='invalid skeleton/frame', **key_record(key)))
            if structure['links']:
                unsupported.append(dict(kind='external skeleton animation link requires closure',
                                        links=structure['links'], **key_record(key)))
            skeleton_reports.append(dict(bones=len(info['bones']), animations=[key_record(a) for a in info['anims']],
                                         external_links=structure['links'], trailing_zero_bytes=len(tail),
                                         **key_record(key)))
            # Fairy searches optional dynamics beside the skeleton. A missing
            # sidecar is normal; an existing one is copied byte-for-byte.
            stem = key.rsplit(b'.', 1)[0] + b'.dynbone'
            if ('Model', stem.decode('gbk').rsplit('/', 1)[-1].lower()) in index:
                resource(stem, 'Model')

    def mesh(key):
        if key in seen_meshes:
            return
        seen_meshes.add(key)
        raw = resource(key, 'Model')
        if raw is None:
            return
        info = tlbbfmt.mesh_info(raw)
        if info['err']:
            unsupported.append(dict(kind='invalid mesh', errors=info['err'], **key_record(key)))
            return
        material_keys.update(info['mats'])
        if info['skel']:
            skeleton(info['skel'])
        mesh_reports.append(dict(submeshes=info['subs'], vertices=info['verts'], triangles=info['tris'],
                                 skeleton_hex=info['skel'].hex(), **key_record(key)))

    def model(key):
        if key in seen_models:
            return
        seen_models.add(key)
        raw = resource(key, 'Model')
        if raw is None:
            return
        tree = ET.fromstring(raw)
        if tree.tag != 'model':
            unsupported.append(dict(kind='model XML root', root=tree.tag, **key_record(key)))
            return
        for item in tree.iter():
            if item.tag == 'frame':
                skeleton(correlative_key(item.get('name').encode('gbk'), key))
            elif item.tag == 'entity':
                mesh(correlative_key(item.get('mesh').encode('gbk'), key))
                if item.get('material'):
                    material_keys.add(item.get('material').encode('gbk'))
            elif item.tag != 'model':
                unsupported.append(dict(kind='model XML element', tag=item.tag, **key_record(key)))
        model_reports.append(dict(elements=dict(Counter(item.tag for item in tree.iter())), **key_record(key)))

    properties = defaultdict(set)
    for item in scene.findall('Object'):
        kind = item.get('type')
        for prop in item.findall('Property'):
            name, value = prop.get('name'), prop.get('value')
            properties[kind].add(name)
            key = value.encode('gbk')
            if kind == 'StaticEntity' and name == 'mesh name':
                mesh(key)
            elif kind == 'Model' and name == 'model name':
                model(key)
            elif kind == 'ParticleSystem' and name == 'particle system name':
                particle_keys.add(key)
            elif kind == 'TerrainLiquid' and name in {'material', 'replaceMaterial'}:
                material_keys.add(key)

    # S2's explicit high-detail creation rows: 15 female + 15 male. The GL
    # 2644+12*sex formula is a different table contract and is not used here.
    model_table_path = source_root / 'Config/CharModelEx.txt'
    source_record(model_table_path)
    model_table = read_table(model_table_path)
    obj_blob, obj_origin = source_record(source_root / 'Model/all.obj')
    obj_pattern = re.compile(rb'<Object\s+name="([^"]+)"\s*>.*?</Object>', re.S)
    object_blocks = {m.group(1): m.group(0) for m in obj_pattern.finditer(obj_blob)}
    wanted_objects = {}
    for model_id in range(4950, 4980):
        row = model_table.get(model_id)
        if row is None or not row[1]:
            missing.append({'kind': 'sect preview model table row', 'id': model_id})
        else:
            wanted_objects[row[1]] = model_id
    pending_objects = list(wanted_objects)
    selected_objects, object_reports, effect_keys = {}, [], set()
    while pending_objects:
        key = pending_objects.pop()
        if key in selected_objects:
            continue
        if key not in object_blocks:
            missing.append(dict(kind='sect preview object', **key_record(key)))
            continue
        block = selected_objects[key] = object_blocks[key]
        if sum(m.group(1) == key for m in obj_pattern.finditer(obj_blob)) != 1:
            raise ValueError('Duplicate selected source object: ' + key.hex())
        tree = objxml.parse_object(block)
        object_meshes = []
        for item in tree.findall('EntityList/Entity'):
            key_mesh = objxml.B(item.get('file', ''))
            if key_mesh:
                mesh(key_mesh)
                object_meshes.append(key_mesh)
            material_keys.update(value for value in objxml.B(item.get('material', '')).split(b';') if value)
        for item in tree.findall('MaterialList/Material'):
            value = objxml.B(item.get('material', ''))
            if value:
                material_keys.add(value)
        for item in tree.findall('Skeletons/Skeleton'):
            skeleton(objxml.B(item.get('skeleton', '')))
        for item in tree.findall('Locators/Locator/Slot'):
            value = objxml.B(item.get('object', ''))
            if value:
                pending_objects.append(value)
        for item in objxml.iter_attrs(tree):
            name, value, hint = (objxml.B(item.get(attribute, '')) for attribute in ('name', 'value', 'hints'))
            if not value:
                continue
            if name == b'DefaultSkeleton' or hint == b'SkeletonAdd':
                skeleton(value)
            elif hint == b'MeshCreate':
                mesh(value)
            elif hint == b'MaterialSet':
                material_keys.update(value.split(b';'))
            elif hint == b'SlotCreate':
                pending_objects.append(value)
        effect_keys.update(objxml.B(item.get('effect')) for item in tree.findall('Effects/Effect') if item.get('effect'))
        object_reports.append(dict(model_id=wanted_objects.get(key), entities=len(object_meshes),
                                   mesh_keys_hex=[value.hex() for value in object_meshes],
                                   block_sha256=digest(block), **key_record(key)))
    staged_objects = current('Data/Model/all.obj')
    for key, block in sorted(selected_objects.items()):
        pattern = re.compile(rb'<Object\s+name="' + re.escape(key) + rb'"\s*>.*?</Object>', re.S)
        count = len(pattern.findall(staged_objects))
        if count > 1:
            raise ValueError('Duplicate staged sect object')
        if count == 1:
            staged_objects = pattern.sub(lambda match: block, staged_objects)
        else:
            if staged_objects.count(b'</AllObjects>') != 1:
                raise ValueError('Expected one staged AllObjects root')
            staged_objects = staged_objects.replace(b'</AllObjects>', block + b'\n</AllObjects>')
    if any({m.group(1): m.group(0) for m in obj_pattern.finditer(staged_objects)}.get(key) != block
           for key, block in selected_objects.items()):
        raise ValueError('Sect object merge failed byte verification')
    put('Data/Model/all.obj', staged_objects, obj_origin + ' [exact 30 sect preview object closure]')

    effect_blob, effect_origin = source_record(source_root / 'Effect/all.effect')
    effects = script_blocks(effect_blob, 'effect')
    selected_effects, effect_types = {}, set()
    pending_effects = list(effect_keys)
    while pending_effects:
        key = pending_effects.pop()
        if key in selected_effects:
            continue
        if key not in effects:
            missing.append(dict(kind='effect template', **key_record(key)))
            continue
        block = selected_effects[key] = effects[key]
        kinds = set(re.findall(rb'(?m)^\s*element\s+(\S+)', block))
        effect_types.update(kinds)
        for kind in kinds - {b'Particle'}:
            unsupported.append(dict(kind='effect element', element=kind.decode('ascii'), **key_record(key)))
        particle_keys.update(re.findall(rb'(?m)^\s*ParticleSystem\s+(\S+)', block))
        pending_effects.extend(value for value in re.findall(rb'(?m)^\s*(?:ParEffectName|ColEffectName)\s+(\S+)', block)
                               if value != b'NullEffect')
    # Validate duplicates only for referenced definitions, preserving unrelated
    # baseline duplicate placeholder names in all.* without masking them.
    script_blocks(effect_blob, 'effect', set(selected_effects))
    put('Data/Effect/all.effect', merge_script(current('Data/Effect/all.effect'), selected_effects, 'effect'),
        effect_origin + ' [exact sect preview effect closure]')

    particle_blob, particle_origin = source_record(source_root / 'Effect/all.particle')
    particles = script_blocks(particle_blob, 'particle')
    selected_particles = {}
    particle_types = {'renderer': set(), 'emitter': set(), 'affector': set()}
    for key in sorted(particle_keys):
        if key not in particles:
            missing.append(dict(kind='particle template', **key_record(key)))
            continue
        block = selected_particles[key] = particles[key]
        material_keys.update(re.findall(rb'(?m)^\s*material\s+(\S+)', block))
        for category in particle_types:
            particle_types[category].update(value.decode('ascii') for value in
                                            re.findall(rb'(?m)^\s*' + category.encode('ascii') + rb'\s+(\S+)', block))
        for key_mesh in re.findall(rb'(?m)^\s*mesh_name\s+(\S+)', block):
            mesh(key_mesh)
    script_blocks(particle_blob, 'particle', particle_keys)
    put('Data/Effect/all.particle', merge_script(current('Data/Effect/all.particle'), selected_particles, 'particle'),
        particle_origin + ' [exact selected scene templates]')

    # One global material/program name must have one definition. General scene
    # materials are merged in all.material; existing Scene terrain scripts stay
    # in their own group; parent templates/programs are merged in Bootstrap ZIP.
    all_blob, all_origin = source_record(source_root / 'Material/all.material')
    all_materials = script_blocks(all_blob, 'material')
    material_defs = tlbbfmt.material_defs(all_blob)[0]
    templates, template_paths, programs, program_paths = {}, {}, {}, {}
    for family in ('MaterialTemplates', 'Scene'):
        for extension, kind, target, paths in (('.material', 'material', templates, template_paths),
                                              ('.program', 'program', programs, program_paths)):
            for path in sorted((source_root / family).glob('*' + extension)):
                blob = path.read_bytes()
                for key, block in script_blocks(blob, kind).items():
                    if key in target and target[key] != block:
                        raise ValueError('Conflicting DATA CY template/program: ' + key.hex())
                    target[key], paths[key] = block, path
                if kind == 'material':
                    for key, definition in tlbbfmt.material_defs(blob)[0].items():
                        if key not in material_defs:
                            material_defs[key] = definition
    pending, closed = list(material_keys), set()
    while pending:
        key = pending.pop()
        if key in closed or key in BUILTINS:
            continue
        closed.add(key)
        if key not in material_defs:
            missing.append(dict(kind='material', **key_record(key)))
            continue
        parent = material_defs[key]['parent']
        if parent:
            pending.append(parent)
        block = all_materials.get(key, templates.get(key))
        if block is None:
            raise ValueError('Parsed material has no exact source block')
        texture_keys, placeholders = texture_references(block)
        for texture in sorted(texture_keys):
            resource(texture, 'Material')
        if placeholders:
            template_bindings.append(dict(placeholders=[p.decode('ascii') for p in sorted(placeholders)],
                                          **key_record(key)))
        program_keys.update(re.findall(rb'\b(?:vertex|fragment)_program_ref\s+(\S+)', block))
    selected_all = {key: all_materials[key] for key in closed if key in all_materials}
    script_blocks(all_blob, 'material', set(selected_all))
    selected_material_counts = Counter(header.split()[1].split(b':', 1)[0]
                                      for header, _ in tlbbfmt.iter_blocks(all_blob)[0]
                                      if header.startswith(b'material ') and header.split()[1].split(b':', 1)[0] in selected_all)
    put('Data/Material/all.material', merge_script(current('Data/Material/all.material'), selected_all, 'material'),
        all_origin + ' [exact selected scene material blocks]')
    selected_templates = {key: templates[key] for key in closed if key not in all_materials and key in templates}
    # Native CysMaterialSystem::pickVertexProgram performs this documented pairing.
    program_keys.update({b'Model_VS', b'Model_Skin_VS', b'Particle_VS'})
    selected_programs = {}
    shader_files, auto_constants = {}, set()
    for key in sorted(program_keys):
        if key not in programs:
            missing.append(dict(kind='GPU program', **key_record(key)))
            continue
        block = selected_programs[key] = programs[key]
        source_record(program_paths[key])
        auto_constants.update(re.findall(rb'\bparam_named_auto\s+\S+\s+(\S+)', block))
        for name in re.findall(rb'(?m)^\s*source\s+(\S+)', block):
            shader_files[name.decode('ascii')] = None
    native_constants = (ROOT / 'Src/Engine/OGRE/OgreMain/src/OgreGpuProgram.cpp').read_bytes()
    for constant in sorted(auto_constants):
        if b'"' + constant + b'"' not in native_constants:
            unsupported.append({'kind': 'shader auto constant', 'name': constant.decode('ascii')})
    pending = [(name, source_root / 'MaterialTemplates') for name in shader_files]
    shader_files = {}
    while pending:
        name, directory = pending.pop()
        name = safe_name(name)
        if name in shader_files:
            continue
        path = directory / name
        if not path.is_file():
            path = source_root / 'MaterialTemplates' / name
        if not path.is_file():
            missing.append({'kind': 'shader source/include', 'name': name})
            continue
        raw, origin = source_record(path)
        shader_files[name] = (raw, origin)
        for include in re.findall(rb'(?m)^\s*#\s*include\s*["<]([^">]+)[">]', raw):
            pending.append((include.decode('ascii'), path.parent))

    archive_before = current('Data/MaterialTemplates.zip')
    zip_entries, zip_info = {}, {}
    with zipfile.ZipFile(io.BytesIO(archive_before)) as archive:
        comment = archive.comment
        for item in archive.infolist():
            if item.filename in zip_entries:
                raise ValueError('Duplicate Bootstrap archive entry')
            zip_entries[item.filename], zip_info[item.filename] = archive.read(item.filename), item
    zip_original = dict(zip_entries)
    edits = []
    for kind, selected, paths, suffix in (('material', selected_templates, template_paths, '.material'),
                                          ('program', selected_programs, program_paths, '.program')):
        owners = {}
        for name, blob in zip_entries.items():
            if name.endswith(suffix):
                for key in script_blocks(blob, kind):
                    owners[key] = ('zip', name)
        # Scene contains legacy terrain names. Replace those exact blocks in
        # place rather than adding duplicate declarations in Bootstrap.
        scene_files = {p.name: p.read_bytes() for p in (stage / 'Data/Scene').glob('*' + suffix)}
        for name in list(scene_files):
            scene_files[name] = base_updates.get('Data/Scene/' + name, scene_files[name])
            for key in script_blocks(scene_files[name], kind):
                if key in owners:
                    raise ValueError('Existing duplicate Scene/Bootstrap program or material: ' + key.hex())
                owners[key] = ('scene', name)
        groups = defaultdict(dict)
        for key, block in selected.items():
            location = owners.get(key)
            if location is None:
                location = ('scene', 'CysCreateScene' + suffix) if paths[key].parent.name == 'Scene' else ('zip', 'CysCreateScene' + suffix)
            groups[location][key] = block
            _, origin = source_record(paths[key])
            edits.append(dict(kind=kind, location=location[0], file=location[1], source=origin,
                              block_sha256=digest(block), **key_record(key)))
        for (location, name), selected_blocks in groups.items():
            if location == 'zip':
                zip_entries[name] = merge_script(zip_entries.get(name, b''), selected_blocks, kind)
            else:
                target = 'Data/Scene/' + name
                put(target, merge_script(scene_files.get(name, b''), selected_blocks, kind),
                    'exact DATA CY scene ' + kind + ' closure')
    for name, (raw, origin) in shader_files.items():
        zip_entries[name] = raw
        edits.append({'kind': 'shader source', 'location': 'zip', 'file': name, 'source': origin,
                      'sha256': digest(raw)})
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w') as archive:
        archive.comment = comment
        for name, blob in sorted(zip_entries.items()):
            metadata = zip_info.get(name)
            if metadata is None:
                metadata = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
                metadata.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(metadata, blob)
    archive_after = buffer.getvalue()
    with zipfile.ZipFile(io.BytesIO(archive_after)) as archive:
        if archive.testzip() is not None or any(archive.read(name) != blob for name, blob in zip_entries.items()):
            raise ValueError('Scene Bootstrap archive byte verification failed')
    put('Data/MaterialTemplates.zip', archive_after, 'exact DATA CY scene parent/program/source closure')
    report = {
        'valid': not (missing or unsupported or ambiguities),
        'source': source_label, 'scene': SCENE, 'scene_sha256': digest(scene_blob),
        'scope': 'Exact CY scene and 30 sect preview dependencies; native routing/camera evidence is recorded independently.',
        'object_counts': dict(sorted(object_counts.items())), 'object_count': sum(object_counts.values()),
        'properties': {key: sorted(values) for key, values in properties.items()},
        'meshes': mesh_reports, 'models': model_reports, 'skeleton_count': len(seen_skeletons),
        'skeletons': skeleton_reports, 'sect_objects': object_reports,
        'effect_keys_hex': [key.hex() for key in sorted(selected_effects)],
        'effect_types': [key.decode('ascii') for key in sorted(effect_types)],
        'particle_keys_hex': [key.hex() for key in sorted(particle_keys)],
        'particle_types': {key: sorted(value) for key, value in particle_types.items()},
        'material_keys_hex': [key.hex() for key in sorted(closed)],
        'identical_source_material_duplicates': [dict(count=count, **key_record(key))
                                                for key, count in selected_material_counts.items() if count > 1],
        'parent_templates': [key_record(key) for key in sorted(selected_templates)],
        'programs': [key_record(key) for key in sorted(selected_programs)],
        'template_bindings': template_bindings, 'auto_constants': [key.decode('ascii') for key in sorted(auto_constants)],
        'missing': missing, 'unsupported': unsupported, 'ambiguous_resources': ambiguities,
        'resources': list(resources.values()), 'sources': list(sources.values()),
        'bootstrap': {'sha256_before': digest(archive_before), 'sha256_after': digest(archive_after),
                      'edits': edits, 'shader_file_count': len(shader_files),
                      'unchanged_entries': [{'name': name, 'sha256': digest(blob)} for name, blob in zip_original.items()
                                            if zip_entries[name] == blob]},
        'updates': len(updates), 'update_bytes': sum(map(len, updates.values())),
        'files': [{'path': name, 'origin': origins[name], 'sha256': digest(blob), 'bytes': len(blob)}
                  for name, blob in sorted(updates.items())],
    }
    return updates, origins, report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stage', required=True, type=Path)
    parser.add_argument('--source', required=True, type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    if ROOT / 'Build' not in out.parents or out.exists():
        raise SystemExit('Choose a new evidence JSON inside CY-Source/Build')
    _, _, report = build_plan(args.stage, args.source)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: report[key] for key in ('valid', 'object_count', 'updates', 'update_bytes',
                                                'missing', 'unsupported', 'ambiguous_resources')}, ensure_ascii=False))
    raise SystemExit(0 if report['valid'] else 1)
