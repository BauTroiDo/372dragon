#!/usr/bin/env python3
"""Read-only before/after evidence for the live world run on the private clone.

collect: run in WSL python3 (pymongo) around ONE approved CysNetBot/Game run. Writes one JSON snapshot with the
         clone status, an allowlisted account/character projection (GUID, scene, saved position), anomaly counters
         (record_xy_rec idx gaps, log_CGEnterScene/log_CGAskChangeScene anomaly rows) and per-log byte/keyword counts.
review:  compares two snapshots (and optionally the CysNetBot result.json) with the live-run success criteria.
Never writes to Mongo or the clone, never starts/stops services, never prints credentials, raw log lines or bodies.
"""
import argparse
import datetime
import importlib.util
import json
import os
import re
import sys
import time
from pathlib import Path

CY = Path(__file__).resolve().parents[2]
ACCOUNT, GUID = 'test00', 200001
LOG_KEYS = ('traceback', 'error', 'record_xy_rec', 'test00', '200001')
DATABASES = ('tlbb', 'tlbb_log')
ANOMALY_COLLECTIONS = ('record_xy_rec', 'log_CGEnterScene', 'log_CGAskChangeScene')


def inside(relative, base):
    path = (CY / relative).resolve()
    root = (CY / base).resolve()
    if path != root and root not in path.parents:
        raise SystemExit('path must stay below CY-Source/' + base)
    for part in (path,) + tuple(path.parents):
        if os.path.islink(str(part)):
            raise SystemExit('path must not be a link')
    return path


def load_provision(relative):
    path = inside(relative, '')
    spec = importlib.util.spec_from_file_location('private_server', str(path))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def number(value):
    return float(value) if isinstance(value, (int, float)) and not isinstance(value, bool) else None


def collect(args):
    if not re.fullmatch(r'[a-z0-9][a-z0-9-]{0,63}', args.label):
        raise SystemExit('invalid label')
    directory = inside(args.out_dir, 'Build/Logs')
    directory.mkdir(parents=True, exist_ok=True)
    target = directory / (args.label + '.json')
    if target.exists():
        raise SystemExit('snapshot exists; choose a new label')
    server = load_provision(args.provision)
    started = time.time()
    report = {'label': args.label, 'status': server.status(), 'logs': {}}
    for path in sorted(Path(server.TEST, 'log').glob('*/*.log')):
        data = path.read_bytes().lower()
        report['logs'][str(path.relative_to(server.TEST))] = {
            'bytes': len(data), 'counts': {key: data.count(key.encode()) for key in LOG_KEYS}}
    with server.database() as client:
        account = client['tlbb']['account'].find_one({'uid': ACCOUNT}, {'_id': 0, 'uid': 1, 'status': 1,
                                                                        'right': 1, 'char_list': 1}) or {}
        guids = account.get('char_list') if isinstance(account.get('char_list'), list) else []
        report['account'] = {'uid': account.get('uid'), 'status': account.get('status'), 'right': account.get('right'),
                             'character_guids': sorted(int(g) for g in guids if isinstance(g, int))}
        document = client['tlbb']['character'].find_one(
            {'attrib.guid': GUID}, {'_id': 0, 'attrib.guid': 1, 'attrib.sceneid': 1, 'attrib.world_pos': 1}) or {}
        attrib = document.get('attrib') or {}
        position = attrib.get('world_pos') or {}
        report['character'] = {'guid': attrib.get('guid'), 'sceneid': attrib.get('sceneid'),
                               'x': number(position.get('x')), 'y': number(position.get('y'))}
        report['anomalies'] = {}
        for name in ANOMALY_COLLECTIONS:
            for database in DATABASES:
                collection = client[database][name]
                report['anomalies'][database + '.' + name] = {
                    'total': collection.count_documents({}), 'guid': collection.count_documents({'guid': GUID})}
        flags = {}
        for row in client['tlbb_log']['account_login_rec'].find({'account': ACCOUNT}, {'_id': 0, 'flag': 1}):
            flag = row.get('flag')
            key = str(flag) if isinstance(flag, int) and 0 <= flag <= 100 else 'other'
            flags[key] = flags.get(key, 0) + 1
        report['login_flags'] = flags
    finished = time.time()
    report['window'] = {'started_utc': datetime.datetime.fromtimestamp(started, datetime.timezone.utc).isoformat(),
                        'finished_utc': datetime.datetime.fromtimestamp(finished, datetime.timezone.utc).isoformat()}
    report['scope'] = 'read-only private clone snapshot; allowlisted fields; no credentials or raw logs'
    with target.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps({'snapshot': str(target.relative_to(CY)).replace('\\', '/'), 'read_only': True}))


def review(args):
    pre = json.loads(inside(args.pre, 'Build/Logs').read_text(encoding='utf-8'))
    post = json.loads(inside(args.post, 'Build/Logs').read_text(encoding='utf-8'))
    checks = []

    def check(name, passed, detail):
        checks.append({'check': name, 'passed': bool(passed), 'detail': detail})

    services = lambda snap: {s['name']: (tuple(s['owned_pids']), s['running']) for s in snap['status']['services']}
    check('services_unchanged', services(pre) == services(post) and all(r for _, r in services(post).values()),
          {'pre': len(services(pre)), 'post': len(services(post))})
    check('ports_unchanged', pre['status']['ports'] == post['status']['ports'] and
          post['status']['ports'].get('15733') and post['status']['ports'].get('15734'), post['status']['ports'])
    check('account_unchanged', pre['account'] == post['account'] and GUID in post['account']['character_guids'],
          {'characters': len(post['account']['character_guids'])})
    a, b = pre['character'], post['character']
    moved = None
    if None not in (a['x'], a['y'], b['x'], b['y']):
        moved = [round(b['x'] - a['x'], 4), round(b['y'] - a['y'], 4)]
    detail = {'scene_pre': a['sceneid'], 'scene_post': b['sceneid'], 'delta_xy': moved}
    if args.allow_move:
        # GUI sessions walk freely: the saved row must still exist with a position; the delta is only reported.
        check('position_saved', b['guid'] == GUID and moved is not None and b['sceneid'] is not None, detail)
    else:
        check('position_unchanged', b['guid'] == GUID and a['sceneid'] == b['sceneid'] and moved is not None and
              abs(moved[0]) <= args.tolerance and abs(moved[1]) <= args.tolerance, detail)
    deltas = {key: {'total': post['anomalies'][key]['total'] - value['total'],
                    'guid': post['anomalies'][key]['guid'] - value['guid']} for key, value in pre['anomalies'].items()}
    check('no_new_anomaly_rows', all(d['total'] == 0 and d['guid'] == 0 for d in deltas.values()), deltas)
    flags = {key: post['login_flags'].get(key, 0) - pre['login_flags'].get(key, 0)
             for key in set(pre['login_flags']) | set(post['login_flags'])}
    changed = {key: value for key, value in flags.items() if value}
    check('one_login_record', sum(changed.values()) == 1 and len(changed) == 1 and min(changed.values()) > 0, changed)
    growth = {}
    for name, value in post['logs'].items():
        before = pre['logs'].get(name, {'bytes': 0, 'counts': {key: 0 for key in LOG_KEYS}})
        growth[name] = {'bytes': value['bytes'] - before['bytes'],
                        'traceback': value['counts']['traceback'] - before['counts']['traceback'],
                        'error': value['counts']['error'] - before['counts']['error']}
    check('no_new_log_errors', all(g['traceback'] == 0 and g['error'] == 0 for g in growth.values()),
          {name: g for name, g in growth.items() if g['bytes'] or g['traceback'] or g['error']})
    if args.bot:
        result = json.loads(inside(args.bot, 'Build/Logs').read_text(encoding='utf-8'))
        wanted = {'exit_code': 0, 'terminal': 'quit_complete', 'quit_flag': 0, 'charlogin': 'granted',
                  'ticket_next_idx': '7f00', 'first_game_frame': 'CGConnect', 'decode_failures': 0,
                  'dropped_outbound': 0, 'transfers': 0, 'in_world': True, 'automatic_retries': 0}
        if args.walk:
            wanted['moves_sent'] = 2
        wrong = {key: result.get(key) for key, value in wanted.items() if result.get(key) != value}
        if result.get('heartbeats', 0) < args.min_heartbeats:
            wrong['heartbeats'] = result.get('heartbeats')
        check('bot_result', not wrong, wrong or {'heartbeats': result.get('heartbeats'), 'next_idx': result.get('next_idx')})
    passed = all(c['passed'] for c in checks)
    record = {'pre': args.pre, 'post': args.post, 'bot': args.bot, 'passed': passed, 'checks': checks}
    if args.out:
        target = inside(args.out, 'Build/Logs')
        with target.open('x', encoding='utf-8', newline='\n') as stream:
            json.dump(record, stream, ensure_ascii=False, indent=2)
            stream.write('\n')
    for item in checks:
        print(('PASS ' if item['passed'] else 'FAIL ') + item['check'])
    print('REVIEW', 'PASS' if passed else 'FAIL')
    return 0 if passed else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command')
    first = commands.add_parser('collect')
    first.add_argument('--label', required=True)
    first.add_argument('--out-dir', required=True)
    first.add_argument('--provision', default='Tools/server/provision_test_wsl.py')
    second = commands.add_parser('review')
    second.add_argument('--pre', required=True)
    second.add_argument('--post', required=True)
    second.add_argument('--bot', default='')
    second.add_argument('--out', default='')
    second.add_argument('--walk', type=int, choices=(0, 1), default=1)
    second.add_argument('--min-heartbeats', type=int, default=3)
    second.add_argument('--tolerance', type=float, default=0.05)
    second.add_argument('--allow-move', action='store_true',
                        help='GUI sessions: report the saved position delta instead of requiring no movement')
    args = parser.parse_args()
    if args.command == 'collect':
        collect(args)
        return 0
    if args.command == 'review':
        return review(args)
    parser.error('choose collect or review')


if __name__ == '__main__':
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except Exception as error:  # fixed text; never echo documents or configuration
        print('{"error":"sanitized world snapshot failure: %s"}' % type(error).__name__)
        sys.exit(1)
