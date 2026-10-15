"""Check actual live bag widget observations, including the two negative controls."""
import argparse
import json
import re
from pathlib import Path


def check(root: Path, mode: str) -> dict:
    run = json.loads((root / 'run.json').read_text(encoding='utf-8-sig'))
    log = (root / 'WXClient.log').read_text(encoding='utf-8', errors='replace')
    rows = re.findall(r'CYS-BAG-PROBE: SNAP phase=(\S+) tab=(\d+) capacity=(\d+) visible=(\d+) occupied=(\d+) empty=(\d+) backgrounds=(\d+) mismatch=(\d+)', log)
    snapshots = {}
    failures = []
    for phase, *numbers in rows:
        if phase in snapshots:
            failures.append('duplicate snapshot ' + phase)
        snapshots[phase] = dict(zip(('tab', 'capacity', 'visible', 'occupied', 'empty', 'backgrounds', 'mismatch'), map(int, numbers)))
    shop = mode.startswith('shop-')
    wanted = ('shop-before', 'bought-new', 'bought-stack', 'sold') if shop else ('open', 'material', 'quest', 'base', 'unequipped', 'equipped', 'reopened')
    if set(snapshots) != set(wanted):
        failures.append('snapshot phases incomplete/unexpected')
    for phase, row in snapshots.items():
        if not (row['capacity'] > 0 and row['capacity'] == row['visible'] == row['backgrounds'] == row['occupied'] + row['empty']):
            failures.append('grid/capacity mismatch ' + phase)
        should_fail = (mode == 'refresh-A' and phase == 'unequipped') or (mode == 'enum-A' and phase in ('material', 'quest')) or (mode == 'shop-A' and phase in ('bought-new', 'bought-stack'))
        if (row['mismatch'] > 0) != should_fail:
            failures.append('unexpected widget verdict ' + phase)
    money_rows = re.findall(r'CYS-BAG-PROBE: money phase=(\S+) match=(\d+) gold=(\d+) jiaozi=(\d+)', log)
    money = {phase: dict(match=int(match), gold=int(gold), jiaozi=int(jiaozi)) for phase, match, gold, jiaozi in money_rows}
    if len(money_rows) != len(wanted) or set(money) != set(wanted):
        failures.append('money observations incomplete/duplicated')
    for phase, values in money.items():
        stale = mode == 'shop-A' and phase != 'shop-before'
        if (values['match'] == 0) != stale:
            failures.append('unexpected money verdict ' + phase)
    results = re.findall(r'CYS-BAG-PROBE: RESULT errors=(\d+) restored_guid=(\d+) post_move_m=([\d.]+)', log)
    if len(results) != 1:
        failures.append('missing/duplicate final observation')
    else:
        errors, guid, moved = results[0]
        if float(moved) < .5 or (not shop and int(guid) == 0):
            failures.append('restore/movement not demonstrated')
        if (int(errors) == 0) != (mode in ('B', 'shop-B')):
            failures.append('final error count contradicts control')
    if mode == 'B' and 'negative-arm cleanup' in log:
        failures.append('positive arm bypassed actual bag click')
    if 'CYS-BAG-PROBE: INVALID' in log:
        failures.append('probe precondition failed')
    if shop and (not re.search(r'CYS-BAG-PROBE: bought item=\d+ quantity=1 replies=1', log) or not re.search(r'CYS-BAG-PROBE: sold item=\d+ quantity=0 replies=1', log)):
        failures.append('purchase/sale did not run')
    if run.get('exit_code') != 0 or run.get('terminated_after_timeout') or run.get('account') != 'test13':
        failures.append('run invalid/unclean')
    if not re.search(r'CYS-BAG-PROBE: BEGIN old_refresh=\d old_enum=\d', log):
        failures.append('probe did not start')
    return dict(mode=mode, run=str(root), started=run['started'], finished=run['finished'], game_sha256=run['game_sha256'], manifest_sha256=run['stage_manifest_sha256'], snapshots=snapshots, money=money, result=results, failures=failures, passed=not failures)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    parser.add_argument('--mode', choices=('B', 'refresh-A', 'enum-A', 'shop-A', 'shop-B'), required=True)
    parser.add_argument('--json', type=Path)
    args = parser.parse_args()
    result = check(args.run, args.mode)
    text = json.dumps(result, indent=2)
    if args.json:
        args.json.write_text(text + '\n', encoding='utf-8')
    print(text)
    raise SystemExit(0 if result['passed'] else 1)
