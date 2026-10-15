"""Dependency-planner regressions: full animation frames and byte-safe composition."""
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tools/data'))
import create_role_scene_resources as scene


class SceneClosureTests(unittest.TestCase):
    def test_numbered_water_animation_uses_all_twenty_frames(self):
        self.assertEqual(scene.texture_references(b'anim_texture water.dds 20 2')[0],
                         {b'water_' + str(i).encode('ascii') + b'.dds' for i in range(20)})

    def test_explicit_animation_uses_every_texture_not_duration(self):
        self.assertEqual(scene.texture_references(b'anim_texture a.dds b.dds c.dds 1')[0],
                         {b'a.dds', b'b.dds', b'c.dds'})

    def test_separate_cube_uses_six_faces(self):
        self.assertEqual(scene.texture_references(b'cubic_texture sky.dds separateUV')[0],
                         {b'sky_' + face + b'.dds' for face in (b'fr', b'bk', b'lf', b'rt', b'up', b'dn')})

    def test_combined_cube_is_one_resource(self):
        self.assertEqual(scene.texture_references(b'cubic_texture cube.dds combinedUVW')[0], {b'cube.dds'})

    def test_explicit_cube_does_not_drop_five_faces(self):
        line = b'cubic_texture a.dds b.dds c.dds d.dds e.dds f.dds separateUV'
        self.assertEqual(len(scene.texture_references(line)[0]), 6)

    def test_invalid_animation_does_not_become_a_partial_plan(self):
        with self.assertRaises(ValueError):
            scene.texture_references(b'anim_texture water.dds 2')

    def test_oversized_animation_is_rejected(self):
        with self.assertRaises(ValueError):
            scene.texture_references(b'anim_texture water.dds 999999999 1')

    def test_alias_and_gbk_bytes_are_preserved(self):
        key = '湖水蓝.dds'.encode('gbk')
        self.assertEqual(scene.texture_references(b'set_texture_alias <baseTexture> ' + key)[0], {key})

    def test_placeholder_report_is_distinct_from_real_file(self):
        self.assertEqual(scene.texture_references(b'texture <baseTex>.jpg\ntexture actual.dds'),
                         ({b'actual.dds'}, {b'<baseTex>.jpg'}))

    def test_replace_preserves_unrelated_exact_bytes(self):
        before = b'// base\r\nmaterial A\r\n{\r\n texture old.dds\r\n}\r\n'
        untouched = b'\r\n// do not rewrite\r\nmaterial B\r\n{\r\n texture untouched.dds\r\n}\r\n'
        block = b'material A\n{\n texture new.dds\n}\n'
        self.assertIn(untouched, scene.merge_script(before + untouched, {b'A': block}, 'material'))

    def test_eof_source_block_does_not_join_next_header(self):
        before = b'material A\n{\n texture old.dds\n}\nmaterial B\n{\n texture b.dds\n}\n'
        block = b'material A\n{\n texture new.dds\n}'
        result = scene.merge_script(before, {b'A': block}, 'material')
        self.assertEqual(set(scene.script_blocks(result, 'material')), {b'A', b'B'})
        self.assertIn(block, result)

    def test_add_eof_block_preserves_original_source_bytes(self):
        a = b'fragment_program A hlsl\n{\n source a.hlsl\n}'
        b = b'vertex_program B hlsl\n{\n source b.hlsl\n}\n'
        result = scene.merge_script(b'', {b'A': a, b'B': b}, 'program')
        self.assertIn(a, result)
        self.assertIn(b, result)

    def test_conflicting_referenced_duplicates_fail(self):
        before = b'material A\n{\n texture a.dds\n}\nmaterial A\n{\n texture b.dds\n}\n'
        with self.assertRaises(ValueError):
            scene.script_blocks(before, 'material', {b'A'})

    def test_identical_source_duplicates_are_deterministic(self):
        block = b'material Bird\n{\n texture bird.dds\n}\n'
        self.assertEqual(scene.script_blocks(block + block, 'material', {b'Bird'}), {b'Bird': block})

    def test_destination_does_not_allow_parent_traversal(self):
        with self.assertRaises(ValueError):
            scene.safe_name('../client_GL/Bin64/Game.exe')

    def test_destination_does_not_allow_drive(self):
        with self.assertRaises(ValueError):
            scene.safe_name('C:/outside/file')

    def test_destination_does_not_allow_unc(self):
        with self.assertRaises(ValueError):
            scene.safe_name('\\\\wsl.localhost\\TLBB\\file')

    def test_scene_planner_rejects_nonprivate_stage_before_reading_source(self):
        with self.assertRaises(ValueError):
            scene.build_plan(ROOT / 'Assets/Canonical', ROOT / 'absent-source')

    def test_prefixed_mesh_request_keeps_directory(self):
        key = '水瀑布/pubu_4.mesh'.encode('gbk')
        self.assertEqual(scene.disk_path(key), scene.disk_key('水瀑布'.encode('gbk')) + '/pubu_4.mesh')

    def test_prefixed_texture_request_keeps_every_directory(self):
        key = 'a/小动物/鱼.dds'.encode('gbk')
        self.assertEqual(scene.disk_path(key).count('/'), 2)
        self.assertTrue(scene.disk_path(key).startswith('a/'))

    def test_bare_appearance_resource_keeps_existing_path_contract(self):
        key = '女少林脸.mesh'.encode('gbk')
        self.assertEqual(scene.disk_path(key), scene.disk_key(key))

    def test_model_frame_is_staged_at_first_correlative_request(self):
        key = '飞鸟.frame'.encode('gbk')
        base = '小动物/飞鸟.model'.encode('gbk')
        self.assertEqual(scene.correlative_key(key, base), '小动物/飞鸟.frame'.encode('gbk'))

    def test_explicit_child_prefix_does_not_get_double_directory(self):
        self.assertEqual(scene.correlative_key(b'other/mesh.mesh', b'base/model.model'), b'other/mesh.mesh')


if __name__ == '__main__':
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(SceneClosureTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if len(sys.argv) > 1:
        out = Path(sys.argv[1]).resolve()
        if ROOT / 'Build' not in out.parents or out.exists():
            raise SystemExit('Choose a new report JSON within CY-Source/Build')
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps({'tests': result.testsRun, 'failures': len(result.failures),
                                   'errors': len(result.errors), 'pass': result.wasSuccessful()}, indent=2) + '\n',
                       encoding='utf-8')
    raise SystemExit(0 if result.wasSuccessful() else 1)
