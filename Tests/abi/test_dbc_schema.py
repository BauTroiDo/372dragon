#!/usr/bin/env python3
# CYS: binary/text schema regressions. Fixtures/logs stay in an explicit repo Build directory.
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import unittest
from datetime import datetime

import check_dbc_layout as dbc


ROOT = Path(dbc.ROOT)
MAGIC = 0xDDBBCC00
# CYS: the only rows of the table list that are deliberately not loaded (registered with a NULL schema). Short and
# auditable on purpose: adding a name here is a decision, not a refresh.
ABSENT_WHITELIST = ['HairStyle.txt', 'MissionDialog.txt', 'MissionList.txt', 'MissionPunish.txt',
                    'MissionReward.txt']


def registered_ok_counts(rows, registered):
    """(rows the report says loaded, rows the sources say must load) for a check_dbc_layout.py --out table.

    CYS dbc-id-dup 19/09: replaces the hard table count that had to be bumped by hand twice (63 -> 64 -> 65, each
    time for a table that was perfectly valid). `registered` is counted from the other side - the C++ table list of
    CDataBaseSystem::OpenAllDataBase plus the loaders outside it - so the two sides are independent and the equality
    is a real check, not a restatement of the asserts above it. Adding a valid table raises both sides and stays
    green; a row the report silently dropped, a row that did not load, or a sixth table registered with a NULL
    schema without being whitelisted, all lower the left side only and go red.
    """
    return (sum(1 for r in rows if r['x64'] in ('OK', 'PENDING')), registered - len(ABSENT_WHITELIST))


def binary(types, values=(), strings=b''):
    """Fixture file encoding from TLBB_DBC.h, never calls the schema reader."""
    assert len(values) % len(types) == 0
    return (struct.pack('<Iiii', MAGIC, len(types), len(values) // len(types), len(strings)) +
            struct.pack('<' + 'I' * len(types), *types) +
            struct.pack('<' + 'I' * len(values), *values) + strings)


class SchemaTests(unittest.TestCase):
    out_dir = None

    @classmethod
    def setUpClass(cls):
        defines, scanner, types, typedefs, _, _ = dbc.load_headers()
        cls.context = {'defines': defines, 'types': types, 'typedefs': typedefs, 'anon': scanner.anon}
        cls.types = types

    def setUp(self):
        self.directory = self.out_dir / 'fixtures' / self._testMethodName
        self.directory.mkdir(parents=True, exist_ok=True)

    def parse(self, data, name='fixture.txt'):
        path = self.directory / name
        path.write_bytes(data)
        before = hashlib.sha256(data).hexdigest()
        result = dbc.read_table_schema(path)
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), before, 'reader modified input')
        return result

    def invalid(self, data, phase):
        path = self.directory / 'invalid.txt'
        path.write_bytes(data)
        with self.assertRaisesRegex(dbc.SchemaError, phase):
            dbc.read_table_schema(path)
        self.assertEqual(path.read_bytes(), data)

    def cli(self, data, filename='WhiteEquipBase.txt'):
        source = self.directory / 'data'
        source.mkdir(exist_ok=True)
        (source / filename).write_bytes(data)
        output = self.directory / 'result.tsv'
        env = dict(os.environ, PYTHONUTF8='1', PYTHONDONTWRITEBYTECODE='1')
        env['TEMP'] = env['TMP'] = str(self.directory)
        completed = subprocess.run(
            [sys.executable, '-B', str(ROOT / 'Tests/abi/check_dbc_layout.py'), str(source), '--out', str(output)],
            cwd=ROOT, env=env, capture_output=True, text=True, encoding='utf-8', timeout=10,
            creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        lines = output.read_text(encoding='utf-8').splitlines()
        keys = lines[0].split('\t')
        rows = [dict(zip(keys, line.split('\t'))) for line in lines[1:]]
        return completed, next(row for row in rows if row['file'] == filename)

    def test_fixed_binary_vector_uses_file_types_not_text_or_pointer_width(self):
        # 3 fields, 1 record, 3 string bytes; values are INT7, offset1, float1.5.
        raw = bytes.fromhex('00ccbbdd030000000100000003000000'
                            '00000000020000000100000007000000010000000000c03f004100')
        schema = self.parse(raw)
        self.assertEqual(schema.columns, ['INT', 'STRING', 'FLOAT'])
        self.assertEqual(schema.file_format, 'binary')
        self.assertEqual(schema.warnings, [])
        offsets, size = dbc.record_layout(schema.columns, 8)
        self.assertEqual([slot[0] for slot in offsets], [0, 8, 16])
        self.assertEqual(size, 24)

    def test_equivalent_text_and_binary_schemas(self):
        text = self.parse(b'INT\tSTRING\tFLOAT\nID\tName\tValue\n7\tA\t1.5\n', 'text.data')
        packed = self.parse(binary([0, 2, 1], [7, 1, 0x3fc00000], b'\0A\0'), 'binary.data')
        self.assertEqual(text.columns, packed.columns)
        self.assertEqual(dbc.record_layout(text.columns, 8), dbc.record_layout(packed.columns, 8))

    def test_extension_does_not_select_parser(self):
        self.assertEqual(self.parse(binary([0]), 'table.txt').file_format, 'binary')
        self.assertEqual(self.parse(b'INT\nIndex\n', 'table.bin').file_format, 'text')

    def test_text_cr_lf_and_crlf_headers(self):
        for ending in (b'\r', b'\n', b'\r\n'):
            with self.subTest(ending=ending):
                self.assertEqual(self.parse(b'INT\tSTRING' + ending + b'Index\tName' + ending).columns,
                                 ['INT', 'STRING'])

    def test_text_empty_tab_fields_ignored_and_duplicate_types_preserved(self):
        schema = self.parse(b'\tINT\t\tINT\tSTRING\t\nID\tCount\tName\n')
        self.assertEqual(schema.columns, ['INT', 'INT', 'STRING'])

    def test_text_whitespace_and_lowercase_types_are_not_silently_trimmed(self):
        for header in (b' INT', b'INT ', b'INT\t STRING', b'int', b'INT\tFLOAT '):
            with self.subTest(header=header):
                self.invalid(header + b'\nIndex\n', 'text-header: unknown type')

    def test_text_bom_rejected_as_in_runtime_loader(self):
        for bom in (b'\xef\xbb\xbf', b'\xff\xfe', b'\xfe\xff'):
            with self.subTest(bom=bom):
                self.invalid(bom + b'INT\nIndex\n', 'text-header: BOM')

    def test_text_empty_header_or_embedded_nul_invalid(self):
        for raw in (b'', b'\nIndex\n', b'\t\t\nIndex\n'):
            with self.subTest(raw=raw):
                self.invalid(raw, 'text-header: empty')
        self.invalid(b'INT\0\tSTRING\nIndex\n', 'text-header: embedded NUL')

    def test_text_header_capacity_boundary(self):
        valid = b'INT\t' * 2559 + b'INT'
        self.assertEqual(len(valid), 10239)
        self.assertEqual(len(self.parse(valid + b'\nColumns\n').columns), 2560)
        self.invalid(valid + b'\tINT\nColumns\n', 'text-header: exceeds')

    def test_unknown_text_type_diagnostic_does_not_echo_payload(self):
        path = self.directory / 'invalid.txt'
        path.write_bytes(b'fixture-payload-not-for-log\nColumns\n')
        with self.assertRaises(dbc.SchemaError) as caught:
            dbc.read_table_schema(path)
        self.assertNotIn('fixture-payload', str(caught.exception))
        self.assertIn('column 0', str(caught.exception))

    def test_truncated_binary_header_detected_before_allocation(self):
        for size in (1, 2, 3, 4, 8, 15):
            with self.subTest(size=size):
                self.invalid(binary([0])[:size], 'binary-header: truncated')

    def test_binary_signed_counts_and_zero_fields_invalid(self):
        for counts in ((0, 0, 0), (-1, 0, 0), (1, -1, 0), (1, 0, -1)):
            with self.subTest(counts=counts):
                self.invalid(struct.pack('<Iiii', MAGIC, *counts), 'binary-header: invalid signed')

    def test_binary_huge_counts_rejected_before_type_or_record_reads(self):
        self.invalid(struct.pack('<Iiii', MAGIC, 0x7fffffff, 0x7fffffff, 0x7fffffff), 'binary-types:')
        self.invalid(struct.pack('<IiiiI', MAGIC, 1, 0x7fffffff, 0, 0), 'binary-records:')

    def test_binary_truncated_type_vector(self):
        self.invalid(struct.pack('<IiiiI', MAGIC, 2, 0, 0, 0), 'binary-types:')

    def test_binary_truncated_record_extent(self):
        self.invalid(struct.pack('<IiiiII', MAGIC, 1, 2, 0, 0, 7), 'binary-records:')

    def test_binary_truncated_string_extent(self):
        self.invalid(struct.pack('<IiiiII', MAGIC, 1, 1, 3, 2, 0) + b'\0A', 'binary-strings:')

    def test_binary_unknown_field_type(self):
        self.invalid(binary([0, 99]), 'binary-types: unknown type at column 1')

    def test_unknown_binary_magic_not_guessed_from_extension(self):
        raw = bytearray(binary([0]))
        raw[3] = 0xdc
        self.invalid(bytes(raw), 'text-header: embedded NUL')

    def test_binary_zero_records_and_zero_string_block(self):
        schema = self.parse(binary([0, 2]))
        self.assertEqual(schema.columns, ['INT', 'STRING'])
        self.assertEqual(schema.warnings, [])

    def test_binary_zero_offset_with_zero_string_block_is_safe(self):
        schema = self.parse(binary([0, 2], [9, 0]))
        self.assertEqual(schema.warnings, [])

    def test_binary_nonzero_offset_with_zero_block_is_normalized_not_dereferenced(self):
        schema = self.parse(binary([2], [0xffffffff]))
        self.assertEqual(len(schema.warnings), 1)
        self.assertIn('count=1 first-row:column=0:0', schema.warnings[0])

    def test_binary_offset_equal_to_or_above_string_size_warns_and_keeps_schema(self):
        schema = self.parse(binary([0, 2], [1, 2, 2, 0xffffffff], b'\0\0'))
        self.assertEqual(schema.columns, ['INT', 'STRING'])
        self.assertEqual(len(schema.warnings), 1)
        self.assertIn('count=2 first-row:column=0:1,1:1', schema.warnings[0])

    def test_binary_offset_warning_samples_are_bounded(self):
        schema = self.parse(binary([2], [17] * 20000))
        self.assertIn('count=20000', schema.warnings[0])
        self.assertIn('0:0,1:0,2:0,3:0', schema.warnings[0])
        self.assertNotIn('4:0', schema.warnings[0])

    def test_binary_unterminated_tail_matches_loader_normalization(self):
        schema = self.parse(binary([2], [1], b'\0AB'))
        self.assertEqual(schema.warnings, ['binary-terminator-normalization: final byte forced to NUL'])

    def test_binary_extra_tail_bytes_are_reported_without_changing_schema(self):
        schema = self.parse(binary([0], [7]) + b'extra')
        self.assertEqual(schema.columns, ['INT'])
        self.assertEqual(schema.warnings, ['binary-tail: 5 trailing bytes ignored by loader'])

    def test_cli_binary_schema_mismatch_stays_informational(self):
        process, row = self.cli(binary([0, 2]))
        self.assertEqual(process.returncode, 0, process.stderr)
        self.assertEqual(row['columns'], '2')
        self.assertEqual(row['x64'], 'BAD')
        self.assertIn('format=binary', row['detail'])
        self.assertNotEqual(row['columns'], '1', 'regressed to binary first-line parsing')

    def test_cli_valid_long_struct_mismatch_keeps_old_zero_exit(self):
        process, row = self.cli(b'INT\nIndex\n')
        self.assertEqual(process.returncode, 0, process.stderr)
        self.assertEqual(row['x64'], 'LONG')

    def test_cli_invalid_schema_is_explicit_and_nonzero(self):
        process, row = self.cli(struct.pack('<Iiii', MAGIC, 93, -1, 0))
        self.assertEqual(process.returncode, 1, process.stderr)
        self.assertEqual(row['x64'], 'INVALID')
        self.assertEqual(row['columns'], '0')
        self.assertIn('binary-header:', row['detail'])
        self.assertNotIn('struct has', row['detail'])

    def test_cli_normalization_remains_loadable_and_is_visible(self):
        process, row = self.cli(binary([2], [50]))
        self.assertEqual(process.returncode, 0, process.stderr)
        self.assertNotEqual(row['x64'], 'INVALID')
        self.assertIn('binary-offset-normalization: count=1', row['detail'])

    def test_canonical_cy_four_binary_tables_report_true_columns_and_layout_status(self):
        # CYS 13/09 (game-data): the structs follow the client_GL columns; b68e90d recorded bad/bad/bad/prefix.
        # CYS-CY 14/09 (cs1-tables): the same four tables have the same columns in CY 3.71 (Assets/CanonicalCY).
        cases = [('WhiteEquipBase.txt', '_DBC_ITEM_EQUIP_WHITE', 93, 'ok'),
                 ('GreenEquipBase.txt', '_DBC_ITEM_EQUIP_GREEN', 93, 'ok'),
                 ('BlueEquipBase.txt', '_DBC_ITEM_EQUIP_BLUE', 91, 'ok'),
                 ('StoreMapItem.txt', '_DBC_ITEM_STOREMAP', 15, 'ok')]
        for name, record, columns, status in cases:
            with self.subTest(table=name):
                path = ROOT / 'Assets/CanonicalCY/Data/ConfigFolder' / name
                before = hashlib.sha256(path.read_bytes()).hexdigest()
                schema = dbc.read_table_schema(path)
                self.assertEqual(schema.file_format, 'binary')
                self.assertEqual(len(schema.columns), columns)
                self.assertEqual(dbc.compare(self.types[record]['members'], schema.columns, 8, self.context)[0], status)
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), before)

    def test_canonical_cy_changed_tables_match_cy_structs(self):
        # CYS 13/09 (game-data): b68e90d recorded CommonItem/GemInfo bad and ItemRule prefix (rule column read as price).
        # CYS-CY 14/09 (cs1-tables): CY 3.71 columns (binary in CanonicalCY): 28/84/15/54 columns; GL was 27/81/14/48.
        cases = [('CommonItem.txt', '_DBC_ITEM_MEDIC', 28, 'ok'),
                 ('GemInfo.txt', '_DBC_ITEM_GEM', 84, 'ok'),
                 ('ItemRule.txt', '_DBC_ITEM_RULE', 15, 'ok'),
                 ('SkillData_V1.txt', '_DBC_SKILLDATA_V1_DEPLETE', 54, 'ok'),
                 ('MonsterAttrExTable.txt', '_DBC_CREATURE_ATT', 73, 'ok'),
                 ('EquipBase.txt', '_DBC_ITEM_EQUIP_BASE', 103, 'ok'),
                 ('SkillTemplate_V1.txt', '_DBC_SKILL_DATA', 102, 'ok'),
                 ('CharModelEx.txt', '_DBC_CHARACTER_MODEL', 21, 'ok'),
                 ('SceneDefineEx.txt', '_DBC_SCENE_DEFINE', 25, 'ok'),
                 ('ImpactDirectly.txt', '_DBC_DIRECT_IMPACT', 25, 'ok'),
                 ('SpecialObjData.txt', '_DBC_SPECIAL_OBJ_DATA', 63, 'ok')]
        for name, record, columns, status in cases:
            with self.subTest(table=name):
                schema = dbc.read_table_schema(ROOT / 'Assets/CanonicalCY/Data/ConfigFolder' / name)
                self.assertEqual(schema.file_format, 'binary')
                self.assertEqual(len(schema.columns), columns)
                for pointer in (4, 8):
                    self.assertEqual(dbc.compare(self.types[record]['members'], schema.columns, pointer,
                                                 self.context)[0], status)

    def test_nested_struct_tail_padding_is_reported(self):
        # CYS: {LPCSTR, INT, INT, INT} as a nested member pads to 24 bytes on x64; the record packs the next INT at +20.
        members = [('group', 'Group', 'public'), ('next', 'INT', 'public')]
        context = dict(self.context)
        context['anon'] = dict(self.context['anon'])
        context['anon']['Group'] = [('desc', 'LPCSTR', 'public'), ('a', 'INT', 'public'),
                                    ('b', 'INT', 'public'), ('c', 'INT', 'public')]
        columns = ['STRING', 'INT', 'INT', 'INT', 'INT']
        self.assertEqual(dbc.compare(members, columns, 4, context)[0], 'ok')
        self.assertEqual(dbc.compare(members, columns, 8, context)[0], 'bad')

    def test_canonical_cy_table_list_strict_gate(self):
        # CYS: every OpenAllDataBase row: struct layout OK on x86/x64 and schema string == data column types.
        # CYS-CY 14/09 (cs1-tables): default data set CanonicalCY; the five tables of other loaders (ActionSet x3,
        # BeHit, CityIdOfChina) are part of the gate. Since cs2-world no client_GL table is kept any more: the camp
        # relations come from the CY table ReputationTable.txt (DBC_CAMP_AND_STAND).
        output = self.directory / 'layout.tsv'
        env = dict(os.environ, PYTHONUTF8='1', PYTHONDONTWRITEBYTECODE='1')
        completed = subprocess.run(
            [sys.executable, '-B', str(ROOT / 'Tests/abi/check_dbc_layout.py'), '--strict', '--allow-pending', '--out', str(output)],
            cwd=ROOT, env=env, capture_output=True, text=True, encoding='utf-8', timeout=600,
            creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        self.assertEqual(completed.returncode, 0, completed.stdout[-2000:] + completed.stderr[-2000:])
        self.assertIn('strict gate: PASS', completed.stdout)
        lines = output.read_text(encoding='utf-8').splitlines()
        keys = lines[0].split('\t')
        rows = [dict(zip(keys, line.split('\t'))) for line in lines[1:]]
        self.assertGreaterEqual(len(rows), 60)
        self.assertEqual(sorted(r['file'] for r in rows if r['x64'] == 'ABSENT'), ABSENT_WHITELIST)
        self.assertEqual(sorted(r['file'] for r in rows if r['table'] == '-other-' and r['x64'] == 'OK'),
                         ['ActionSet/ActionSet.txt', 'ActionSet/ActionSetKV.txt', 'ActionSet/ActionSetLine.txt',
                          'BeHit.txt', 'CityIdOfChina.txt'])
        pending = sorted(r['file'] for r in rows if r['x64'] == 'PENDING')
        # CYS-CY: InterfaceEx is PENDING until agent cy-gui puts the CY 3.71 GUI table into CanonicalCY.
        self.assertIn(pending, ([], ['InterfaceEx.txt']))
        # CYS dbc-id-dup 19/09: this used to be a hard count (63 -> 64 for DBC 907 XinFaStudySpend_V1.txt,
        # ci-refresh 17/09; 64 -> 65 for DBC 309 EquipDress.txt, dbc-schema-red 19/09). Both bumps were for a
        # perfectly valid table, so the number only measured how often someone edited the table list. What is
        # checked now is that the report and the sources agree: `registered` is counted from GMDataBase.cpp and
        # OTHER_TABLES, not from `rows`, so a row the report silently skipped is a failure and not a new baseline.
        # The floor above (assertGreaterEqual(len(rows), 60)) still catches a table list that lost rows.
        registered = len(dbc.table_list()) + len(dbc.OTHER_TABLES)
        loaded, must_load = registered_ok_counts(rows, registered)
        self.assertEqual(loaded, must_load,
                         'report %d row(s), sources %d row(s); not loaded: %s' % (
                             len(rows), registered,
                             [r['file'] for r in rows if r['x64'] not in ('OK', 'PENDING')
                              and r['file'] not in ABSENT_WHITELIST]))
        self.assertEqual([r['x64'] for r in rows if r['file'] == 'XinFaStudySpend_V1.txt'], ['OK'])
        # Column count pinned as well: a DBC table read with the wrong width silently shifts every field.
        self.assertEqual([(r['x64'], r['columns']) for r in rows if r['file'] == 'EquipDress.txt'], [('OK', '7')])
        self.assertEqual([r for r in rows if r['file'] == 'CampAndStand.txt'], [])
        self.assertEqual([r['x64'] for r in rows if r['file'] == 'ReputationTable.txt'], ['OK'])
        for row in rows:
            self.assertIn(row['x64'], ('OK', 'ABSENT', 'PENDING'), row)
            self.assertIn(row['schema'], ('OK', 'ABSENT', 'PENDING'), row)

    def test_table_count_invariant_knows_how_to_fail(self):
        # CYS dbc-id-dup 19/09: proof that replacing the hard 65 did not turn the check into "anything passes".
        base = [{'x64': 'OK', 'file': 'T%d.txt' % i} for i in range(60)]
        base += [{'x64': 'ABSENT', 'file': name} for name in ABSENT_WHITELIST]
        self.assertEqual(*registered_ok_counts(base, len(base)))                   # today's shape: green
        for extra in ('OK', 'PENDING'):                                            # a new valid table: green
            more = base + [{'x64': extra, 'file': 'New.txt'}]
            self.assertEqual(*registered_ok_counts(more, len(more)), msg=extra)
        # a row that did not load, and a sixth NULL-schema row that nobody whitelisted: red
        for broken in ('MISSING', 'BAD', 'NOSTRUCT', 'PREFIX', 'INVALID', 'ABSENT'):
            more = base + [{'x64': broken, 'file': 'Broken.txt'}]
            self.assertNotEqual(*registered_ok_counts(more, len(more)), msg=broken)
        # a row the report silently skipped although the sources register it: red
        self.assertNotEqual(*registered_ok_counts(base[1:], len(base)))   # a loaded row missing from the report
        self.assertNotEqual(*registered_ok_counts(base, len(base) + 1))   # a row registered but never reported

    def test_dbc_ids_are_unique(self):
        # CYS dbc-id-dup 19/09: a DBC id is the key of CDataBaseSystem::m_mapDataBaseBuf. Two names on one number
        # means GetDataBase(<the loser>) hands back another table and the caller overlays the wrong record struct.
        # 0.85 shipped DBC_LIFEABILITY_DEFINE and DBC_XINFA_XINFADEFINE both on 902 and nothing noticed for years.
        script = str(ROOT / 'Tests/abi/check_dbc_layout.py')
        env = dict(os.environ, PYTHONUTF8='1', PYTHONDONTWRITEBYTECODE='1')

        def census(*paths):
            return subprocess.run([sys.executable, '-B', script, '--check-dbc-ids', *paths], cwd=ROOT, env=env,
                                  capture_output=True, text=True, encoding='utf-8', timeout=300,
                                  creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))

        green = census()
        self.assertEqual(green.returncode, 0, green.stdout[-2000:] + green.stderr[-2000:])
        self.assertIn('0 duplicate(s)', green.stdout)
        self.assertNotIn('DBC ID DUPLICATE', green.stdout)
        # The alias kept for the dead 0.85 name must stay an alias: it may not own a number again.
        self.assertIn('dbc id alias: DBC_XINFA_XINFADEFINE = DBC_SKILL_XINFA', green.stdout)

        # The census must go red for a header that reuses a number - otherwise it only ever says "OK".
        header = self.directory / 'duplicate_ids.h'
        header.write_text('#define DBC_FIXTURE_ONE\t(902)\n'
                          '#define DBC_FIXTURE_TWO\t( 902 )\t// same number, different table\n'
                          '#define DBC_FIXTURE_THREE\t(903)\n'
                          '#define DBC_FIXTURE_ALIAS\tDBC_FIXTURE_THREE\n'
                          '#define DBC_XINFA_STUDYSPEND_SLOTS\t(902)\n', encoding='utf-8', newline='\n')
        red = census(str(header))
        self.assertEqual(red.returncode, 1, red.stdout[-2000:] + red.stderr[-2000:])
        self.assertIn('DBC ID DUPLICATE: 902', red.stdout)
        self.assertIn('DBC_FIXTURE_ONE', red.stdout)
        self.assertIn('DBC_FIXTURE_TWO', red.stdout)
        self.assertIn('1 duplicate(s)', red.stdout)
        # An alias is not a duplicate, and a non-table constant is not an id: neither may raise a false alarm.
        self.assertIn('dbc id alias: DBC_FIXTURE_ALIAS = DBC_FIXTURE_THREE', red.stdout)
        self.assertNotIn('DBC_XINFA_STUDYSPEND_SLOTS', red.stdout)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out-dir', type=Path, default=ROOT / 'Build/Logs/2026-09-12-gpt-p1-2/action-items' /
                        ('schema-tests-' + datetime.now().strftime('%Y%m%d-%H%M%S-%f')))
    args = parser.parse_args()
    output = args.out_dir.resolve()
    build = (ROOT / 'Build').resolve()
    if output == build or build not in output.parents:
        parser.error('--out-dir must stay below this repository Build directory')
    output.mkdir(parents=True, exist_ok=True)
    SchemaTests.out_dir = output
    stream = io.StringIO()
    result = unittest.TextTestRunner(stream=stream, verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(SchemaTests))
    text = stream.getvalue()
    (output / 'tests.log').write_text(text, encoding='utf-8', newline='\n')
    summary = {'tests': result.testsRun, 'failures': len(result.failures), 'errors': len(result.errors),
               'passed': result.testsRun - len(result.failures) - len(result.errors),
               'returncode': 0 if result.wasSuccessful() else 1,
               'source_sha256': {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in
                                 ['Tests/abi/check_dbc_layout.py', 'Tests/abi/test_dbc_schema.py']}}
    (output / 'result.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8', newline='\n')
    sys.stdout.write(text)
    print('Evidence:', output / 'result.json')
    return summary['returncode']


if __name__ == '__main__':
    sys.exit(main())
