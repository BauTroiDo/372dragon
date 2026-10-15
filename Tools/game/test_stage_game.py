#!/usr/bin/env python3
"""Regression tests of Tools/game/stage_game.py helpers (no stage, no Canonical access, no writes).

Engine names (D1), the OgreResourceGroupManager index rules the stage layout relies on, WXResources.cfg ordering,
script block extraction and the per-string UTF-8 -> CP936 conversion of XML resource names.
Run: python -B Tools/game/test_stage_game.py
"""
from pathlib import Path
import os
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import stage_game as sg  # noqa: E402


def location(group, files, recursive=True, spec=None):
    loc = sg.Location(group, 'FileSystem', Path('.'), recursive, spec or ('loc%d' % id(files)))
    loc._files = list(files)
    loc._lower = {n.lower(): n for n in files}
    return loc


class DataProfiles(unittest.TestCase):
    # CYS-CY (cs1-tables): --data CanonicalCY points the junction and the resource layout at the CY data set.
    def tearDown(self):
        sg.set_data_profile('Canonical')

    def test_canonical_cy_profile_has_the_cy_folders_in_reach_order(self):
        sg.set_data_profile('CanonicalCY')
        self.assertTrue(str(sg.CANON).replace(os.sep, '/').endswith('Assets/CanonicalCY/Data'))
        folders = [p for g, p, t in sg.CANON_LAYOUT]
        for name in ('Model8Folder', 'Material8Folder', 'Scene2Folder'):
            self.assertIn(name, folders)
        self.assertLess(folders.index('ModelFolder'), folders.index('Model8Folder'))
        self.assertEqual([g for g, p, t in sg.CANON_LAYOUT if p == 'Scene2Folder'], ['Scene'])

    def test_canonical_profile_keeps_the_client_gl_layout(self):
        sg.set_data_profile('Canonical')
        self.assertTrue(str(sg.CANON).replace(os.sep, '/').endswith('Assets/Canonical/Data'))
        self.assertEqual(sg.CANON_LAYOUT, sg.CANON_LAYOUT_GL)
        self.assertNotIn('Scene2Folder', [p for g, p, t in sg.CANON_LAYOUT])

    def test_keep_gl_tables_only_for_canonical_cy(self):
        class Recorder:
            def __init__(self):
                self.added = []

            def add(self, where, folder, relpath, **kw):
                self.added.append((where, folder, relpath))
        sg.set_data_profile('Canonical')
        ov, report = Recorder(), {}
        self.assertEqual(sg.keep_gl_overlay(ov, report), [])
        self.assertEqual(ov.added, [])

    def test_unknown_profile_is_rejected(self):
        with self.assertRaises(SystemExit):
            sg.set_data_profile('client_GL')


class EngineNames(unittest.TestCase):
    def test_cjk_name_becomes_its_gbk_bytes_read_as_cp1252(self):
        # fx-audit D1: the three CY files the profile stage lacked, as the ANSI file layer opens them
        self.assertEqual(sg.engine_name('女少林脸.mesh'), 'Å®ÉÙÁÖÁ³.mesh')
        self.assertEqual(sg.engine_name('女少林脸.mesh').encode('cp1252'), '女少林脸.mesh'.encode('gbk'))

    def test_engine_form_and_ascii_names_are_unchanged(self):
        for name in ('Å®ÉÙÁÖÁ³.mesh', 'jpg_huo_2.dds', 'CysCreateRole/Common/Button05.tga'):
            with self.subTest(name=name):
                self.assertEqual(sg.engine_name(name), name)

    def test_cp1252_holes_map_like_windows(self):
        # 0x81 0x8D 0x8F 0x90 0x9D are undefined in cp1252; Windows maps them to U+0081.. (identity)
        self.assertEqual(sg.view(b'\x81\x40'), '\x81@')
        self.assertTrue(sg.is_engine_form('\x81@'))
        self.assertEqual(sg.engine_name('丂'), '\x81@')

    def test_non_gbk_names_are_rejected(self):
        with self.assertRaises(UnicodeEncodeError):
            sg.engine_name('\U0001F600.dds')


class ResourceIndex(unittest.TestCase):
    def index(self, *locations):
        group = sg.GroupIndex('General')
        for loc in locations:
            group.add(loc)
        return group

    def test_full_relative_name_last_location_wins(self):
        a, b = location('General', ['sub/x.dds'], spec='A'), location('General', ['sub/x.dds'], spec='B')
        self.assertIs(self.index(a, b).lookup('sub/x.dds'), b)

    def test_base_name_first_recursive_location_wins(self):
        a, b = location('General', ['one/x.dds'], spec='A'), location('General', ['two/x.dds'], spec='B')
        self.assertIs(self.index(a, b).lookup('x.dds'), a)

    def test_root_file_of_a_later_location_takes_the_base_name(self):
        a, b = location('General', ['one/x.dds'], spec='A'), location('General', ['x.dds'], spec='B')
        self.assertIs(self.index(a, b).lookup('x.dds'), b)

    def test_backslash_paths_fall_back_to_location_order(self):
        a, b = location('General', ['sub/x.dds'], spec='A'), location('General', ['sub/x.dds'], spec='B')
        self.assertIs(self.index(a, b).lookup('sub\\x.dds'), a)

    def test_lookup_is_case_insensitive(self):
        a = location('General', ['Sub/X.dds'], spec='A')
        self.assertIs(self.index(a).lookup('sub/x.DDS'), a)
        self.assertIs(self.index(a).lookup('x.DDS'), a)

    def test_pre_and_post_overlay_win_every_lookup_form(self):
        # stage layout: Pre (before Canonical) + Post (after) copies of a file that must replace Canonical
        pre = location('General', ['CreateRole/CreateRole.layout.xml'], spec='Pre')
        canon = location('General', ['CreateRole/CreateRole.layout.xml'], spec='Canonical')
        post = location('General', ['CreateRole/CreateRole.layout.xml'], spec='Post')
        group = self.index(pre, canon, post)
        self.assertIs(group.lookup('CreateRole/CreateRole.layout.xml'), post)
        self.assertIs(group.lookup('CreateRole.layout.xml'), pre)
        self.assertIs(group.lookup('CreateRole\\CreateRole.layout.xml'), pre)

    def test_non_recursive_locations_do_not_index_base_names(self):
        a = location('General', ['sub/x.dds'], recursive=False, spec='A')
        self.assertIsNone(self.index(a).lookup('x.dds'))


class ResourcesCfg(unittest.TestCase):
    def test_sections_keys_sorted_equal_keys_in_file_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            Path(tmp, 'WXResources.cfg').write_text(
                '[Bootstrap]\nZip=../a.zip\nZip=../b.zip\n\n[General]\nZip=../c.zip\nFileSystem=*../d\n'
                'FileSystem=../e\n', encoding='ascii')
            locations = sg.parse_resources_cfg(tmp)
        self.assertEqual([(l.group, l.kind, l.spec, l.recursive) for l in locations],
                         [('Bootstrap', 'Zip', '../a.zip', False), ('Bootstrap', 'Zip', '../b.zip', False),
                          ('General', 'FileSystem', '../d', True), ('General', 'FileSystem', '../e', False),
                          ('General', 'Zip', '../c.zip', False)])


class Scripts(unittest.TestCase):
    def test_material_names_drop_the_parent(self):
        data = b'material A\r\n{\r\n}\r\nmaterial B : A\r\n{\r\n\ttechnique\r\n\t{\r\n\t}\r\n}\r\n'
        self.assertEqual([n for n, _ in sg.script_blocks(data, 'material')], [b'A', b'B'])

    def test_particle_names_with_and_without_keyword(self):
        data = b'PS/One\r\n{\r\n}\r\nparticle_system PS/Two\r\n{\r\n}\r\n'
        self.assertEqual([n for n, _ in sg.script_blocks(data, 'particle')], [b'PS/One', b'PS/Two'])

    def test_obj_blocks_and_first_definition_wins(self):
        data = (b'<AllObjects>\n<Object name="a.obj">1</Object>\n<Object name="b.obj">2</Object>\n'
                b'<Object name="a.obj">3</Object>\n</AllObjects>\n')
        blocks = sg.script_blocks(data, 'obj')
        self.assertEqual([n for n, _ in blocks], [b'a.obj', b'b.obj'])
        self.assertIn(b'>1<', blocks[0][1])

    def test_gbk_bytes_are_never_decoded(self):
        name = '雁门'.encode('gbk')
        data = b'material ' + name + b'\r\n{\r\n}\r\n'
        self.assertEqual(sg.script_blocks(data, 'material')[0][0], name)


class Tokens(unittest.TestCase):
    def test_utf8_scene_names_convert_per_string_like_wxexpatparser(self):
        data = ('<?xml version="1.0" encoding="UTF-8"?>\n<Scene><Object mesh="0树木/女少林脸.mesh"/>'
                '<Object mesh="a.mesh"/></Scene>').encode('utf-8') + b'<!-- \xff stray byte -->'
        self.assertEqual(sg.tokens_of(data, 'x.Scene'), ['0树木/女少林脸.mesh'.encode('gbk'), b'a.mesh'])

    def test_utf8_scene_with_bom_is_detected(self):
        # Canonical scenes such as "海口 1.Scene" start with a UTF-8 BOM before the declaration
        data = b'\xef\xbb\xbf<?xml version="1.0" encoding="UTF-8" standalone="no" ?>\n' + \
            '<Scene><Object mesh="0树木/松树3.mesh"/></Scene>'.encode('utf-8')
        self.assertEqual(sg.tokens_of(data, 'x.Scene'), ['0树木/松树3.mesh'.encode('gbk')])

    def test_gbk_scripts_keep_their_bytes(self):
        data = b'texture ' + '女少林脸.dds'.encode('gbk') + b'\r\n'
        self.assertEqual(sg.tokens_of(data, 'all.material'), ['女少林脸.dds'.encode('gbk')])

    def test_mesh_files_only_name_skeletons(self):
        self.assertEqual(sg.tokens_of(b'\x00\x01abc.skeleton\x00tex.dds\x00', 'x.mesh'), [b'abc.skeleton'])


class CameraKeys(unittest.TestCase):
    # camera3d: the stage WXSystem.cfg carries the CY 3.71 Bin/System.cfg camera block once
    def test_template_values_replaced_and_missing_keys_appended(self):
        text = sg.apply_cy_camera_keys('[Variable]\nA=1\nCamera_MaxDistance=17.5\nCamera_FOV=35.0\n')
        lines = text.split('\n')
        self.assertIn('Camera_MaxDistance=27.5', lines)
        self.assertIn('Camera_Pitch_Min=-40.0', lines)
        self.assertIn('View_DefaultCamera=1', lines)
        self.assertIn('View_UseSkyCamera=1', lines)  # CO Y KHAC CY 17/09: camera tu do trong ban choi
        for key, _ in sg.CY_CAMERA_KEYS:
            self.assertEqual(sum(1 for line in lines if line.split('=', 1)[0] == key), 1, key)
        self.assertEqual(lines[1], 'A=1')

    def test_repeated_key_is_rejected(self):
        with self.assertRaises(SystemExit):
            sg.apply_cy_camera_keys('Camera_FOV=35\nCamera_FOV=45\n')


if __name__ == '__main__':
    unittest.main(verbosity=2)
