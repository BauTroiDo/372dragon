"""Guard byte-preserving migration against comments, strings and reapplication."""
import unittest
from patch_gameplay_predicates import rewrite, rewrite_shimen_menu


class MigrationTests(unittest.TestCase):
    def test_opaque_lua_text_is_unchanged(self):
        source = (b'-- self:IsHaveMission(a,b) > 0\n'
                  b'--[=[ self:IsHaveMission(a,b) > 0 ]=]\n'
                  b'local a="self:IsHaveMission(a,b) > 0"\n'
                  b"local b='self:IsMissionHaveDone(a,b) == 0'\n"
                  b'local c=[==[ self:IsHaveMission(a,b) > 0 ]==]\n')
        self.assertEqual(rewrite(source), (source, []))

    def test_boolean_branches_keep_line_endings(self):
        source = b'if self:IsHaveMission(a,b) > 0 then\r\nelseif self:IsMissionHaveDone(a,b) == 0 then\r\nend\r\n'
        expected = b'if self:IsHaveMission(a,b) then\r\nelseif (not self:IsMissionHaveDone(a,b)) then\r\nend\r\n'
        result, edits = rewrite(source)
        self.assertEqual(result, expected)
        self.assertEqual(len(edits), 2)
        self.assertEqual(rewrite(result), (result, []))

    def test_other_numeric_apis_remain_numeric(self):
        source = b'if self:CheckAccept(a) > 0 or self:GetLevel(a) <= 0 then end\n'
        self.assertEqual(rewrite(source), (source, []))

    def test_unsupported_comparison_stops_migration(self):
        with self.assertRaises(ValueError):
            rewrite(b'if self:IsHaveMission(a,b) >= 0 then end')

    def test_menu_change_is_limited_to_enumeration(self):
        source = (b'function event_shimen_test:OnEnumerate(caller, a)\n'
                  b'self:AddNumText("first",3,-1)\nself:AddNumText("second",4,-1)\nend\n'
                  b'function event_shimen_test:OnDefaultEvent(a)\nself:AddNumText("own",3,-1)\nend\n')
        result, edits = rewrite_shimen_menu(source)
        self.assertEqual(len(edits), 2)
        self.assertEqual(result.count(b'caller:AddNumTextWithTarget(self.script_id,'), 2)
        self.assertIn(b'self:AddNumText("own",3,-1)', result)
        self.assertEqual(rewrite_shimen_menu(result), (result, []))


if __name__ == '__main__':
    unittest.main()
