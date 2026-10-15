"""Exact DATA CY creation material/program closure in the private Bootstrap ZIP.

Ogre parses Bootstrap before General/all.material, so parent materials must live
in this archive. The existing shader-cache stamp also tracks this ZIP's bytes.
No fixed-function replacement or source shader rewriting is performed.
"""
import hashlib
import io
from pathlib import Path, PurePosixPath
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tools/pipeline'))
import tlbbfmt


def digest(data):
    return hashlib.sha256(data).hexdigest()


def definitions(data, kinds):
    found = {}
    for header, block in tlbbfmt.iter_blocks(data)[0]:
        words = header.split()
        if len(words) >= 2 and words[0] in kinds:
            name = words[1]
            if name in found:
                raise ValueError('Duplicate definition: ' + name.decode('ascii'))
            found[name] = block
    return found


def build_plan(stage, source_root, appearance):
    source = source_root / 'MaterialTemplates'
    material_path = source / 'Mtl_Character.material'
    program_path = source / 'Character.program'
    materials = definitions(material_path.read_bytes(), {b'material'})
    programs = definitions(program_path.read_bytes(), {b'vertex_program', b'fragment_program'})
    source_all = tlbbfmt.material_defs((source_root / 'Material/all.material').read_bytes())[0]
    selected = {bytes.fromhex(value) for value in appearance['material_keys_hex']}
    parents = {source_all[key]['parent'] for key in selected if source_all[key]['parent'] not in selected}
    if parents != {b'Mtl_Character_Lit', b'AlphaBlend/ColourChangable/AlphaTemplate'}:
        raise ValueError('Creation material parents changed; inspect the shader closure')
    needed_programs = set()
    for name in parents:
        needed_programs.update(re.findall(rb'\b(?:fragment|vertex)_program_ref\s+(\S+)', materials[name]))
    if needed_programs != {b'Character_Skin_PS', b'Character_Skin_ColorAdd_PS', b'Depth_PS'}:
        raise ValueError('Creation parent programs changed')
    # CysMaterialSystem::pickVertexProgram selects these exact DATA CY templates
    # for the MODEL / DEPTH families (static, linear skin, quaternion depth skin).
    needed_programs.update({b'Model_VS', b'Model_Skin_VS', b'Depth_VS', b'Depth_Skin_VS', b'Depth_DQSkin_VS'})
    program_sources = set()
    auto_constants = set()
    for name in needed_programs:
        block = programs[name]
        program_sources.update(value.decode('ascii') for value in re.findall(rb'(?m)^\s*source\s+(\S+)', block))
        auto_constants.update(value.decode('ascii') for value in re.findall(rb'\bparam_named_auto\s+\S+\s+(\S+)', block))
    native_constants = (ROOT / 'Src/Engine/OGRE/OgreMain/src/OgreGpuProgram.cpp').read_bytes()
    for constant in auto_constants:
        if ('"' + constant + '"').encode('ascii') not in native_constants:
            raise ValueError('Unsupported native shader auto constant: ' + constant)

    files = {}
    pending = list(program_sources)
    while pending:
        name = pending.pop()
        path = PurePosixPath(name)
        if path.is_absolute() or '..' in path.parts or ':' in name or '\\' in name:
            raise ValueError('Unsafe shader include path')
        if name in files:
            continue
        raw = (source / name).read_bytes()
        files[name] = raw
        pending.extend(value.decode('ascii') for value in re.findall(rb'(?m)^\s*#\s*include\s*["<]([^">]+)[">]', raw))

    zip_path = stage / 'Data/MaterialTemplates.zip'
    archive_before = zip_path.read_bytes()
    entries, info = {}, {}
    with zipfile.ZipFile(io.BytesIO(archive_before)) as archive:
        for item in archive.infolist():
            if item.filename in entries:
                raise ValueError('Duplicate Bootstrap ZIP entry')
            info[item.filename] = item
            entries[item.filename] = archive.read(item.filename)
        zip_comment = archive.comment
    original_entries = dict(entries)
    edits = []

    def merge_blocks(kind, wanted, source_defs, new_name):
        extension = '.material' if kind == b'material' else '.program'
        index = {}
        for filename, raw in entries.items():
            if filename.endswith(extension):
                for name, block in definitions(raw, {kind} if kind == b'material' else {b'vertex_program', b'fragment_program'}).items():
                    if name in index:
                        raise ValueError('Duplicate staged shader/material name')
                    index[name] = (filename, block)
        added = []
        for name in sorted(wanted):
            block = source_defs[name]
            if name in index:
                filename, before = index[name]
                if before != block:
                    if entries[filename].count(before) != 1:
                        raise ValueError('Staged block is not unique')
                    entries[filename] = entries[filename].replace(before, block, 1)
                    action = 'replace exact block'
                else:
                    action = 'reuse identical block'
            else:
                filename = new_name
                added.append(block)
                action = 'add exact block'
            edits.append({'kind': kind.decode('ascii'), 'name': name.decode('ascii'), 'entry': filename,
                          'action': action, 'source_block_sha256': digest(block)})
        if added:
            if new_name in entries:
                raise ValueError('Creation Bootstrap entry already exists')
            entries[new_name] = b'\n'.join(added)

    merge_blocks(b'material', parents, materials, 'CysCreateRole.material')
    merge_blocks(b'program', needed_programs, programs, 'CysCreateRole.program')
    for name, raw in files.items():
        if name in entries and entries[name] != raw:
            # A shader include has one global resource name. Replacing only this
            # selected source is explicit and backed up with the complete ZIP.
            action = 'replace exact CY shader file'
        else:
            action = 'reuse identical file' if name in entries else 'add exact CY shader file'
        entries[name] = raw
        edits.append({'kind': 'shader source', 'name': name, 'entry': name, 'action': action,
                      'source_sha256': digest(raw)})

    # Check every named program reference after merging, and exact source blocks.
    final_materials, final_programs = {}, {}
    for name, raw in entries.items():
        if name.endswith('.material'):
            final_materials.update(definitions(raw, {b'material'}))
        elif name.endswith('.program'):
            final_programs.update(definitions(raw, {b'vertex_program', b'fragment_program'}))
    for name in parents:
        if final_materials[name] != materials[name]:
            raise ValueError('Parent source bytes changed while merging')
    for name in needed_programs:
        if final_programs[name] != programs[name]:
            raise ValueError('Program source bytes changed while merging')
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, 'w') as archive:
        archive.comment = zip_comment
        for name in sorted(entries):
            metadata = info.get(name)
            if metadata is None:
                metadata = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
                metadata.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(metadata, entries[name])
    after = buffer.getvalue()
    with zipfile.ZipFile(io.BytesIO(after)) as verify:
        if verify.testzip() is not None or any(verify.read(name) != raw for name, raw in entries.items()):
            raise ValueError('Bootstrap archive verification failed')
    sources = [material_path, program_path, *(source / name for name in sorted(files))]
    report = {'archive': 'Data/MaterialTemplates.zip', 'sha256_before': digest(archive_before),
              'sha256_after': digest(after), 'material_count': len(parents), 'program_count': len(needed_programs),
              'shader_file_count': len(files), 'edits': edits,
              'unchanged_entries': [{'name': name, 'sha256': digest(raw)} for name, raw in original_entries.items()
                                    if entries[name] == raw],
              'sources': [{'path': '../' + path.relative_to(ROOT.parent).as_posix(),
                           'sha256': digest(path.read_bytes()), 'bytes': path.stat().st_size} for path in sources],
              'auto_constants': sorted(auto_constants),
              'runtime_pairing': 'CysMaterialSystem MODEL/DEPTH family; original CY SM3 source, no shader rewrite'}
    return {'Data/MaterialTemplates.zip': after}, {'Data/MaterialTemplates.zip': 'exact DATA CY creation material and shader closure'}, report
