"""Build a dependency-checked GL login overlay in a private CY-Source stage.

The three layout/Lua pairs are copied byte-for-byte from Canonical. Only their
transitive looks, mappings, imagesets and fonts are merged into the stage. A
manifest and byte backups retain every change; original clients are read-only.
"""
import argparse
import datetime
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import xml.etree.ElementTree as ET

from prepare_login_profile import ROOT, checked

INTERFACE = ROOT / 'Assets/Canonical/Data/InterfaceFolder'
MATERIAL_ROOTS = tuple(sorted((ROOT / 'Assets/Canonical/Data').glob('Material*Folder')))
PAIRS = ('Logon/LogOn', 'SelectServer/SelectServer', 'SoftKeyBoard/SoftKeyBoard')
SCHEME = 'Schema/WoWLookSkin.scheme.xml'
LOOK_BLOCK = re.compile(rb'<WidgetLook\b[^>]*\bname="([^"]+)"[^>]*>.*?</WidgetLook>', re.S)
NATIVE_TYPES = {'DefaultWindow', 'DefaultGUISheet', 'DragContainer', 'ScrolledContainer'}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def relative(value):
    path = PurePosixPath(value.replace('\\', '/'))
    if path.is_absolute() or '..' in path.parts or ':' in str(path):
        raise ValueError('Unsafe resource path: ' + value)
    return str(path)


def xml(data):
    # XML must decode strictly. Never repair resource names with replacement text.
    return ET.fromstring(data)


def exact_setting(data, name, expected):
    values = re.findall(rb'(?m)^[ \t]*' + re.escape(name) + rb'[ \t]*=[ \t]*([^\r\n]*)', data)
    if [value.strip() for value in values] != [expected]:
        raise ValueError('Unexpected or duplicate setting: ' + name.decode('ascii'))


def test_port(data, name):
    exact_setting(data, name, b'14400')
    pattern = rb'(?m)^([ \t]*' + re.escape(name) + rb'[ \t]*=[ \t]*)14400([ \t]*\r?$)'
    after, count = re.subn(pattern, rb'\g<1>15733\g<2>', data)
    if count != 1:
        raise ValueError('Could not replace the isolated endpoint')
    return after


def make_plan(stage, wsl_test=False):
    iface = stage / 'Data/Interface'
    scheme_bytes = (iface / SCHEME).read_bytes()
    old_scheme = xml(scheme_bytes)
    source_scheme = xml((INTERFACE / SCHEME).read_bytes())
    maps = {n.attrib['WindowType']: n for n in source_scheme.findall('FalagardMapping')}
    images = {n.attrib['Name']: n for n in source_scheme.findall('Imageset')}
    fonts = {n.attrib['Name']: n for n in source_scheme.findall('Font')}
    looks = {}
    for entry in source_scheme.findall('LookNFeel'):
        name = relative(entry.attrib['Filename'])
        data = (INTERFACE / name).read_bytes()
        parsed = {n.attrib['name'] for n in xml(data).findall('WidgetLook')}
        for match in LOOK_BLOCK.finditer(data):
            key = match[1].decode('utf-8')
            if key not in parsed:
                continue
            if key in looks:
                raise ValueError('Duplicate source look: ' + key)
            looks[key] = (name, match[0], xml(match[0]))
        if not parsed.issubset(looks):
            raise ValueError('Unparsed WidgetLook: ' + name)

    updates = {}
    origins = {}
    types, needed_looks, needed_images, needed_fonts = set(), set(), set(), set()
    def update(path, data, origin):
        key = str(path.relative_to(stage)).replace('\\', '/')
        if key in updates and updates[key] != data:
            raise ValueError('Conflicting destination: ' + key)
        updates[key] = data
        origins[key] = origin

    def scan(tree):
        for node in tree.iter():
            attrs = node.attrib
            if node.tag == 'Window':
                types.add(attrs['Type'])
            if node.tag == 'Child':
                types.add(attrs['type'])
            if 'look' in attrs:
                needed_looks.add(attrs['look'])
            if 'inherits' in attrs:
                needed_looks.add(attrs['inherits'])
            if 'imageset' in attrs:
                needed_images.add(attrs['imageset'])
            if node.tag in ('Property', 'PropertyDefinition'):
                name = attrs.get('Name', attrs.get('name', ''))
                value = attrs.get('Value', attrs.get('initialValue', ''))
                if name == 'Font' and value:
                    needed_fonts.add(value)
                needed_images.update(re.findall(r'\bset:([^\s]+)', value))
            if 'font' in attrs and attrs['font']:
                needed_fonts.add(attrs['font'])

    pair_records = []
    needed_sounds = set()
    for pair in PAIRS:
        for extension in ('.layout.xml', '.lua'):
            name = pair + extension
            data = (INTERFACE / name).read_bytes()
            update(iface / name, data, 'Assets/Canonical/Data/InterfaceFolder/' + name)
            pair_records.append({'path': name, 'sha256': digest(data)})
            if extension == '.layout.xml':
                scan(xml(data))
            else:
                needed_sounds.update(int(x) for x in re.findall(rb'Sound:PlaySound\(\s*(\d+)\s*[,)]', data))
                # Image strings used by Lua belong to this dependency closure too.
                needed_images.update(x.decode('ascii') for x in re.findall(rb'\bset:([A-Za-z0-9_]+)', data))

    # Preserve the legacy sound table byte-for-byte and add only exact GL rows
    # required by these scripts. Keys/comments remain GBK bytes, never recoded.
    if needed_sounds:
        sound_table = stage / 'Data/Config/SoundInfo.txt'
        before = sound_table.read_bytes()
        canonical = (INTERFACE.parent / 'ConfigFolder/SoundInfo.txt').read_bytes()
        schema = b'INT\tSTRING\tSTRING'
        if before.splitlines()[:2] != [schema, schema] or canonical.splitlines()[:2] != [schema, schema]:
            raise ValueError('Unsupported SoundInfo schema')
        def sound_rows(raw):
            rows = {}
            for line in raw.splitlines(keepends=True)[2:]:
                fields = line.rstrip(b'\r\n').split(b'\t')
                if not fields[0].isdigit():
                    continue
                key = int(fields[0])
                if len(fields) not in (2, 3) or key in rows:  # trailing description is optional
                    raise ValueError('Invalid or duplicate SoundInfo row')
                rows[key] = (line, fields[1])
            return rows
        current, source = sound_rows(before), sound_rows(canonical)
        added = []
        for key in sorted(needed_sounds):
            if key not in source:
                raise ValueError('Missing Canonical login sound: ' + str(key))
            line, resource = source[key]
            if key in current:
                if current[key][0].rstrip(b'\r\n') != line.rstrip(b'\r\n'):
                    raise ValueError('Conflicting login sound ID: ' + str(key))
            else:
                # This profile appends new IDs only; do not break ordered DBC keys.
                if key <= max(current, default=-1):
                    raise ValueError('Login sound insertion needs an ordered merge')
                added.append(line)
            name = relative(resource.decode('ascii'))
            update(stage / 'Data/Sound' / name,
                   (INTERFACE.parent / 'SoundFolder' / name).read_bytes(),
                   'Assets/Canonical/Data/SoundFolder/' + name)
        if added:
            if not before.endswith(b'\r\n') or any(not line.endswith(b'\r\n') for line in added):
                raise ValueError('SoundInfo line endings differ')
            update(sound_table, before + b''.join(added), 'generated: retain legacy bytes and append exact Canonical login sounds')

    done_types, done_looks = set(), set()
    while types - done_types or needed_looks - done_looks:
        for name in sorted(types - done_types):
            done_types.add(name)
            if name in NATIVE_TYPES or name.startswith('Falagard/'):
                continue
            if name not in maps:
                raise ValueError('Missing GL type mapping: ' + name)
            needed_looks.add(maps[name].attrib['LookNFeel'])
        for name in sorted(needed_looks - done_looks):
            done_looks.add(name)
            if name not in looks:
                raise ValueError('Missing GL look: ' + name)
            scan(looks[name][2])

    # Remove only selected old look definitions; every other legacy definition
    # remains byte-identical. The new file contains exact Canonical look blocks.
    for entry in old_scheme.findall('LookNFeel'):
        name = relative(entry.attrib['Filename'])
        path = iface / name
        before = path.read_bytes()
        after = LOOK_BLOCK.sub(lambda m: b'' if m[1].decode('utf-8') in done_looks else m[0], before)
        if after != before:
            update(path, after, 'generated: remove selected definitions now in CysGLLogin')
    combined = b'<?xml version="1.0" encoding="utf-8"?>\n<Falagard>\n'
    combined += b'\n'.join(looks[n][1] for n in sorted(done_looks)) + b'\n</Falagard>\n'
    update(iface / 'Schema/CysGLLogin.looknfeel.xml', combined,
           'generated: exact Canonical WidgetLook blocks, dependency closure')

    # Keep the legacy scheme byte form, replace selected registrations in place.
    scheme = scheme_bytes
    additions = [b'<LookNFeel Filename="Schema/CysGLLogin.looknfeel.xml" />']
    def register(tag, key, value, node):
        nonlocal scheme
        pattern = rb'<' + tag.encode() + rb'\b[^>]*\b' + key.encode() + rb'="' + re.escape(value.encode()) + rb'"[^>]*/>'
        serialized = ET.tostring(node, encoding='utf-8')
        masked = re.sub(rb'<!--.*?-->', lambda m: b' ' * len(m[0]), scheme, flags=re.S)
        found = list(re.finditer(pattern, masked))
        if len(found) > 1 and any(xml(scheme[m.start():m.end()]).attrib !=
                                  xml(scheme[found[0].start():found[0].end()]).attrib for m in found[1:]):
            raise ValueError('Conflicting stage registrations: ' + value)
        if found:
            # The original schemes repeat several identical Imageset entries.
            # Preserve those entries rather than changing unrelated load order.
            for match in reversed(found):
                scheme = scheme[:match.start()] + serialized + scheme[match.end():]
        else:
            additions.append(serialized)
    for name in sorted(done_types & maps.keys()):
        register('FalagardMapping', 'WindowType', name, maps[name])
    for name in sorted(needed_images):
        if name not in images:
            raise ValueError('Missing GL imageset: ' + name)
        entry = images[name]
        filename = relative(entry.attrib['Filename'])
        data = (INTERFACE / filename).read_bytes()
        image_root = xml(data)
        if image_root.attrib['Name'] != name:
            raise ValueError('Imageset name mismatch: ' + name)
        texture = relative(image_root.attrib['Imagefile'])
        candidates = [p / texture for p in (*MATERIAL_ROOTS, INTERFACE) if (p / texture).is_file()]
        if not candidates:
            raise ValueError('Missing texture: ' + texture)
        texture_data = candidates[0].read_bytes()
        if any(p.read_bytes() != texture_data for p in candidates[1:]):
            raise ValueError('Ambiguous texture: ' + texture)
        update(iface / filename, data, str((INTERFACE / filename).relative_to(ROOT)))
        update(stage / 'Data/Material' / texture, texture_data, str(candidates[0].relative_to(ROOT)))
        register('Imageset', 'Name', name, entry)
    for name in sorted(needed_fonts):
        if name not in fonts:
            raise ValueError('Missing GL font registration: ' + name)
        entry = fonts[name]
        filename = relative(entry.attrib['Filename'])
        data = (INTERFACE / filename).read_bytes()
        font_root = xml(data)
        branches = list(font_root) if font_root.tag == 'Fonts' else [font_root]
        selected = [f for f in branches if f.attrib.get('CodePage') == '65001']
        if len(selected) != 1 or selected[0].attrib['Filename'] != 'Schema/NotoSansSC-Regular.ttf':
            raise ValueError('Expected exact Noto UTF-8 font branch: ' + name)
        update(iface / filename, data, str((INTERFACE / filename).relative_to(ROOT)))
        register('Font', 'Name', name, entry)

    # The modern CommonStaticImage atlas removed two legacy menu blocks. Keep
    # their original texture/coordinates in a distinct set instead of borrowing
    # unrelated GL artwork or deleting the old controls. GL pairs stay intact.
    legacy_menu = iface / 'MainMenuBar/MainMenuBar.layout.xml'
    menu_data = legacy_menu.read_bytes()
    old_sets = {n.attrib['Name']: n for n in old_scheme.findall('Imageset')}
    old_entry = old_sets['CommonStaticImage']
    old_set = xml((iface / relative(old_entry.attrib['Filename'])).read_bytes())
    old_texture = relative(old_set.attrib['Imagefile'])
    texture_data = (stage / 'Data/Material' / old_texture).read_bytes()
    old_set.attrib['Name'] = 'CysLegacy_CommonStaticImage'
    old_set.attrib['Imagefile'] = 'CysGLCompat/' + old_texture
    for image_name in ('MainMenuBar_LeftBlock', 'MainMenuBar_RightBlock'):
        descriptor = ('set:CommonStaticImage image:' + image_name).encode('ascii')
        if menu_data.count(descriptor) != 1:
            raise ValueError('Unexpected legacy menu descriptor: ' + image_name)
        menu_data = menu_data.replace(descriptor, descriptor.replace(b'set:CommonStaticImage', b'set:CysLegacy_CommonStaticImage'))
    update(legacy_menu, menu_data, 'generated: isolate two legacy menu image references')
    update(iface / 'Schema/CysLegacy_CommonStaticImage.imageset.xml', ET.tostring(old_set, encoding='utf-8', xml_declaration=True),
           'generated: preserve original legacy CommonStaticImage atlas')
    update(stage / 'Data/Material/CysGLCompat' / old_texture, texture_data, 'stage baseline legacy texture')
    additions.append(b'<Imageset Name="CysLegacy_CommonStaticImage" Filename="Schema/CysLegacy_CommonStaticImage.imageset.xml" />')
    noto = INTERFACE / 'Schema/NotoSansSC-Regular.ttf'
    update(iface / 'Schema/NotoSansSC-Regular.ttf', noto.read_bytes(), str(noto.relative_to(ROOT)))
    if scheme.count(b'</GUIScheme>') != 1:
        raise ValueError('Invalid scheme root')
    scheme = scheme.replace(b'</GUIScheme>', b'\n'.join(additions) + b'\n</GUIScheme>')
    xml(scheme)
    update(iface / SCHEME, scheme, 'generated: bounded GL login registrations')
    if wsl_test:
        # Only the explicitly authorized independent clone; no host discovery,
        # server writes, credentials, fallback endpoint or live-client changes.
        cfg = (stage / 'Bin64/WXSystem.cfg').read_bytes()
        exact_setting(cfg, b'GameServer_Address', b'127.0.0.1')
        exact_setting(cfg, b'GameServer_ConnectDirect', b'0')
        exact_setting(cfg, b'System_CodePage', b'65001')
        update(stage / 'Bin64/WXSystem.cfg', test_port(cfg, b'GameServer_Port'),
               'generated: authorized independent WSL clone login endpoint')
        fixture = (ROOT / 'Tests/ui/fixtures/login-server-utf8.txt').read_bytes()
        modern = (stage / 'Patch/LoginServer.txt').read_bytes()
        if modern != fixture:
            raise ValueError('Expected the exact offline login fixture')
        modern = modern.replace(b'127.0.0.1:14400', b'127.0.0.1:15733')
        modern = modern.replace(b'CYS offline', b'CYS WSL Test').replace(b'offline (no server)', b'Independent WSL test')
        update(stage / 'Patch/LoginServer.txt', modern, 'generated: one independent WSL test server')
        legacy = (stage / 'Patch/WXLoginServer.txt').read_bytes()
        if len(re.findall(rb'(?m)^[ \t]*\[LOGIN[^\]\r\n]*\]', legacy)) != 1:
            raise ValueError('Expected one legacy dummy server')
        exact_setting(legacy, b'IP', b'127.0.0.1')
        update(stage / 'Patch/WXLoginServer.txt', test_port(legacy, b'PORT'),
               'generated: matching independent WSL test fallback list')
    report = {'pairs': pair_records, 'types': sorted(done_types), 'looks': sorted(done_looks),
              'imagesets': sorted(needed_images), 'fonts': sorted(needed_fonts),
              'look_sources': {n: looks[n][0] for n in sorted(done_looks)},
              'files': [{'path': n, 'origin': origins[n], 'bytes': len(b), 'sha256': digest(b)}
                        for n, b in sorted(updates.items())],
              'sound_ids': sorted(needed_sounds),
              'endpoint': '127.0.0.1:15733' if wsl_test else '127.0.0.1:14400',
              'note': 'Private login profile; GL pairs unchanged; no GLResponsive; native hosts are required.'}
    return updates, report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('stage', help='Existing private offline stage, relative to CY-Source')
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--wsl-test', action='store_true', help='Use the authorized independent WSL test clone on loopback port 15733')
    parser.add_argument('--out', required=True, help='New Build/Logs directory for manifest and backups')
    args = parser.parse_args()
    stage = checked(args.stage)
    out = checked(args.out)
    marker = checked((stage / 'Bin64/gl_login_profile.json').relative_to(ROOT))
    checked((stage / 'Bin64/offline_stage.json').relative_to(ROOT))
    if not out.is_relative_to(ROOT / 'Build/Logs') or out.exists():
        raise ValueError('Use a new directory under Build/Logs')
    if not (stage / 'Bin64/offline_stage.json').is_file():
        raise ValueError('Existing offline stage marker required')
    if marker.exists():
        raise ValueError('Preserve applied profile; use a new private stage')
    updates, report = make_plan(stage, args.wsl_test)
    for name in updates:
        checked((stage / name).relative_to(ROOT))
    report.update(stage=str(stage.relative_to(ROOT)), applied=False,
                  created=datetime.datetime.now().astimezone().isoformat())
    out.mkdir(parents=True, exist_ok=False)
    def save_report():
        text = json.dumps(report, ensure_ascii=False, indent=2)
        (out / 'manifest.json').write_text(text, encoding='utf-8')
        return text
    save_report()
    if args.apply:
        # Complete every backup and persist its mapping before touching the stage.
        for index, (name, data) in enumerate(sorted(updates.items())):
            path = stage / name
            if path.exists():
                before = path.read_bytes()
                (out / (str(index) + '.before')).write_bytes(before)
                report['files'][index]['sha256_before'] = digest(before)
                report['files'][index]['backup'] = str(index) + '.before'
        save_report()
        for name, data in sorted(updates.items()):
            path = stage / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            if path.read_bytes() != data:
                raise RuntimeError('Write verification failed: ' + name)
        report['applied'] = True
    text = save_report()
    if args.apply:
        marker.write_text(text, encoding='utf-8')
    print(json.dumps({k: len(report[k]) for k in ('pairs', 'types', 'looks', 'imagesets', 'fonts', 'files')}))


if __name__ == '__main__':
    main()
