"""Offline helper guards; run after the read-only --out plan generated fixtures."""
import importlib.util
from pathlib import Path
import sys
import unittest

CY = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(CY / 'Tools/server'))
import repair_test_cluster_routes as repair


class Guards(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original = (CY / 'Build/Logs/2026-09-13-gpt-create-role/net/'
                        'cluster-route-plan-1/cluster_mgr.before.lua').read_bytes()

    def test_exact_patch_preserves_other_bytes(self):
        after = repair.patched(self.original)
        self.assertEqual(after.replace(repair.NEW, repair.OLD, 1), self.original)
        self.assertEqual(after.count(repair.NEW), 1)

    def test_mutated_source_refused(self):
        with self.assertRaises(RuntimeError):
            repair.patched(self.original + b'\n')

    def test_double_apply_refused(self):
        with self.assertRaises(RuntimeError):
            repair.patched(repair.patched(self.original))

    def test_duplicate_target_refused(self):
        with self.assertRaises(RuntimeError):
            repair.patched(self.original + repair.OLD)

    def test_absolute_output_refused(self):
        with self.assertRaises(RuntimeError):
            repair.output_path('/tmp/cys-out')

    def test_parent_output_refused(self):
        with self.assertRaises(RuntimeError):
            repair.output_path('Build/../cys-out')

    def test_nonbuild_output_refused(self):
        with self.assertRaises(RuntimeError):
            repair.output_path('Tools/cys-out')

    def test_existing_output_preserved(self):
        with self.assertRaises(RuntimeError):
            repair.output_path('Build/Logs/2026-09-13-gpt-create-role/net/cluster-route-plan-1')

    def test_formatter_failure_keeps_action_unknown(self):
        result = repair.console_result(b"debug_console.lua:291: attempt to call a nil value (field 'tostr')\n<CMD Error>")
        self.assertFalse(result['ok'])
        self.assertEqual(result['activation_status'], 'unknown')
        self.assertEqual(result['format_status'], 'error')
        self.assertEqual(result['console_line'], 291)

    def test_control_failure_separate_from_console(self):
        result = repair.console_result(b'CYS_ROUTE_FAIL phase=activation code=replay_refused line=39\n<CMD OK>')
        self.assertFalse(result['ok'])
        self.assertEqual(result['console_status'], 'ok')
        self.assertEqual(result['activation_status'], 'failure')
        self.assertEqual(result['format_status'], 'ok')

    def test_success_requires_console_completion(self):
        marker = b'CYS_ROUTE_OK had_tool=0 has_tool=1 public_count=23 filter_equal=1'
        self.assertFalse(repair.console_result(marker)['ok'])
        self.assertTrue(repair.console_result(marker + b'\n<CMD OK>')['ok'])

    def test_unknown_error_does_not_escape(self):
        result = repair.console_result(b'private_fixture_secret\n<CMD Error>')
        self.assertNotIn('private_fixture', str(result))
        self.assertEqual(result['activation_status'], 'unknown')

    def test_unapproved_code_does_not_escape(self):
        result = repair.console_result(b'CYS_ROUTE_FAIL phase=activation code=private_fixture_secret line=1\n<CMD OK>')
        self.assertNotIn('private_fixture', str(result))
        self.assertEqual(result['activation_status'], 'unknown')

    def test_rpc_diagnostic_allowlist(self):
        result = repair.console_result(b'CYS_ROUTE_FAIL phase=activation code=call_failed line=604 step=filter_local source=skynet.lua trace=49,52\n<CMD OK>')
        self.assertEqual(result['failure_step'], 'filter_local')
        self.assertEqual(result['failure_source'], 'skynet.lua')
        self.assertEqual(result['activation_trace_lines'], [49, 52])
        self.assertFalse(result['ok'])

    def test_unapproved_step_source_do_not_escape(self):
        result = repair.console_result(b'CYS_ROUTE_FAIL phase=activation code=call_failed line=604 step=private_fixture source=secret_fixture.lua trace=49\n<CMD OK>')
        self.assertIsNone(result['failure_step'])
        self.assertIsNone(result['failure_source'])
        self.assertNotIn('fixture', str(result))


if __name__ == '__main__':
    unittest.main()
