#!/usr/bin/env python3
"""Offline tests for collect_world_snapshot.py: a mock provision module stands in for the clone (no WSL, no Mongo).

Checks the allowlist (sensitive fake fields never reach a snapshot), a clean before/after pair (PASS) and a bad run
(idx gap row, moved character, traceback, extra login failure, bad bot result) that must FAIL the named checks.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

CY = Path(__file__).resolve().parents[2]
TOOL = Path(__file__).with_name('collect_world_snapshot.py')

MOCK = r'''
import contextlib, json
from pathlib import Path
TEST = Path(__file__).resolve().parent / 'clone'
STATE = json.loads((TEST / 'state.json').read_text())

class Collection:
    def __init__(self, rows): self.rows = rows
    def _match(self, row, query):
        for key, want in query.items():
            value = row
            for part in key.split('.'):
                value = value.get(part) if isinstance(value, dict) else None
            if value != want: return False
        return True
    def find_one(self, query, projection=None):
        return next((dict(r) for r in self.rows if self._match(r, query)), None)
    def find(self, query, projection=None):
        return [dict(r) for r in self.rows if self._match(r, query)]
    def count_documents(self, query):
        return len(self.find(query))

class Database:
    def __init__(self, name): self.name = name
    def __getitem__(self, collection): return Collection(STATE.get(self.name + '.' + collection, []))

class Client:
    def __getitem__(self, name): return Database(name)

def status():
    return STATE['status']

@contextlib.contextmanager
def database():
    yield Client()
'''


def state(position=(162.0, 156.0), gap=0, login=(0,), extra_error=0, pids=(11, 12)):
    return {
        'status': {'root': 'mock', 'services': [{'name': 'Game', 'owned_pids': [pids[0]], 'running': True},
                                                {'name': 'Tool', 'owned_pids': [pids[1]], 'running': True}],
                   'ports': {'15733': True, '15734': True}},
        'tlbb.account': [{'uid': 'test00', 'status': 1, 'right': 0, 'char_list': [200001],
                          'password': 'mock-secret-value', 'uuid': 'mock-uuid-value'}],
        'tlbb.character': [{'attrib': {'guid': 200001, 'sceneid': 2, 'name': 'mock-name-value',
                                       'world_pos': {'x': position[0], 'y': position[1]}}, 'bag': 'mock-bag'}],
        'tlbb_log.record_xy_rec': [{'guid': 200001, 'request': 'mock-request-value'}] * gap,
        'tlbb_log.account_login_rec': [{'account': 'test00', 'flag': f, 'ip': 'mock-ip'} for f in login],
        'log_text': 'login test00 ok\n' + 'ERROR x\n' * extra_error,
    }


def write_clone(root, data):
    clone = root / 'clone'
    (clone / 'log' / 'game').mkdir(parents=True, exist_ok=True)
    (clone / 'state.json').write_text(json.dumps(data))
    (clone / 'log' / 'game' / 'game.log').write_text(data['log_text'])


def run(*arguments):
    process = subprocess.run([sys.executable, '-B', str(TOOL), *arguments], cwd=CY, capture_output=True, text=True,
                             timeout=60)
    return process.returncode, process.stdout + process.stderr


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True)
    args = parser.parse_args()
    root = (CY / args.out).resolve()
    assert (CY / 'Build' / 'Logs') in root.parents and not root.exists(), 'choose a new Build/Logs output'
    root.mkdir(parents=True)
    (root / 'mock_provision.py').write_text(MOCK)
    rel = root.relative_to(CY).as_posix()
    provision = rel + '/mock_provision.py'
    results = []

    def snapshot(label, data):
        write_clone(root, data)
        rc, text = run('collect', '--label', label, '--out-dir', rel, '--provision', provision)
        assert rc == 0, 'collect failed: ' + text
        body = (root / (label + '.json')).read_text()
        for secret in ('mock-secret-value', 'mock-uuid-value', 'mock-name-value', 'mock-bag', 'mock-request-value',
                       'mock-ip', 'login test00 ok'):
            assert secret not in body, 'allowlist leak: ' + secret
        return body

    snapshot('pre', state())
    snapshot('post-good', state(login=(0, 0)))
    bot = root / 'bot-good.json'
    bot.write_text(json.dumps({'exit_code': 0, 'terminal': 'quit_complete', 'quit_flag': 0, 'charlogin': 'granted',
                               'ticket_next_idx': '7f00', 'first_game_frame': 'CGConnect', 'decode_failures': 0,
                               'dropped_outbound': 0, 'transfers': 0, 'in_world': True, 'automatic_retries': 0,
                               'moves_sent': 2, 'heartbeats': 4, 'next_idx': '8a00'}))
    rc, text = run('review', '--pre', rel + '/pre.json', '--post', rel + '/post-good.json', '--bot', rel + '/bot-good.json',
                   '--out', rel + '/review-good.json')
    assert rc == 0 and 'REVIEW PASS' in text, 'clean run must pass: ' + text
    results.append('PASS clean run')
    snapshot('post-bad', state(position=(163.0, 156.0), gap=1, login=(0, 0, 1), extra_error=1, pids=(11, 99)))
    bad = json.loads(bot.read_text())
    bad.update({'terminal': 'error', 'moves_sent': 1})
    (root / 'bot-bad.json').write_text(json.dumps(bad))
    rc, text = run('review', '--pre', rel + '/pre.json', '--post', rel + '/post-bad.json', '--bot', rel + '/bot-bad.json',
                   '--out', rel + '/review-bad.json')
    failed = {c['check'] for c in json.loads((root / 'review-bad.json').read_text())['checks'] if not c['passed']}
    expected = {'services_unchanged', 'position_unchanged', 'no_new_anomaly_rows', 'one_login_record',
                'no_new_log_errors', 'bot_result'}
    assert rc == 1 and failed == expected, 'bad run must fail exactly %s, got %s' % (sorted(expected), sorted(failed))
    results.append('PASS bad run fails ' + ','.join(sorted(failed)))
    snapshot('post-moved', state(position=(170.0, 150.0), login=(0, 0)))
    rc, text = run('review', '--pre', rel + '/pre.json', '--post', rel + '/post-moved.json', '--allow-move',
                   '--out', rel + '/review-gui.json')
    checks = {c['check']: c['passed'] for c in json.loads((root / 'review-gui.json').read_text())['checks']}
    assert rc == 0 and checks.get('position_saved') is True and 'position_unchanged' not in checks, \
        'GUI review with --allow-move must pass and only report the walk: ' + text
    rc, text = run('review', '--pre', rel + '/pre.json', '--post', rel + '/post-moved.json', '--out',
                   rel + '/review-moved-strict.json')
    failed = {c['check'] for c in json.loads((root / 'review-moved-strict.json').read_text())['checks'] if not c['passed']}
    assert rc == 1 and failed == {'position_unchanged'}, 'strict review must flag only the walk: %s' % sorted(failed)
    results.append('PASS gui review (--allow-move reports the walk; strict mode flags only position_unchanged)')
    rc, text = run('collect', '--label', 'pre', '--out-dir', rel, '--provision', provision)
    assert rc != 0, 'existing snapshot must not be overwritten'
    rc, text = run('collect', '--label', 'x', '--out-dir', '../outside', '--provision', provision)
    assert rc != 0, 'output outside Build/Logs must be refused'
    results.append('PASS guards (no overwrite, output confined)')
    (root / 'summary.json').write_text(json.dumps({'results': results}, indent=2) + '\n')
    print('\n'.join(results))
    print('RESULT collector tests passed; no WSL or database access')


if __name__ == '__main__':
    main()
