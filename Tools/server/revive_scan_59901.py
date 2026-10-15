#!/usr/bin/env python3
"""CYS-REVIVE — quet toan bo ban ghi `tlbb.character` tim impact 59901 地府束缚 (STD_IMPACT_014).

Chi doc. Chay trong WSL TLBB bang root; Mongo rieng 127.0.0.1:27018 phai dang chay.

  revive_scan_59901.py --out <json>
      In moi nhan vat: guid, ten, hp/hp_max, sceneid, so impact luu, va cac impact co
      CanAction1/CanAction2/CanMove = 0 (tuc la dang khoa hanh dong/di chuyen).
"""
import argparse
import importlib.util
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BLOCKERS = ('可否使用任何技能（CanAction1标记，-1为无效）',
            '可否使用任何技能（CanAction2标记,-1为无效）',
            '可否移动（CanMove标记,-1为无效）')


def provision():
    spec = importlib.util.spec_from_file_location('private_server', os.path.join(HERE, 'provision_test_wsl.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def impacts_of(doc):
    raw = doc.get('impact_list')
    if isinstance(raw, list):
        return raw
    if isinstance(raw, dict):
        return list(raw.values())
    return []


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    args = ap.parse_args()
    server = provision()
    rows = []
    with server.database() as client:
        col = client['tlbb']['character']
        for doc in col.find({}, {'_id': 0, 'attrib': 1, 'impact_list': 1}):
            attrib = doc.get('attrib') or {}
            entry = {'guid': attrib.get('guid'), 'name': attrib.get('name'),
                     'hp': attrib.get('hp'), 'hp_max': attrib.get('hp_max'),
                     'sceneid': attrib.get('sceneid'), 'impacts': len(impacts_of(doc)),
                     'blocking': [], 'ids': []}
            for imp in impacts_of(doc):
                if not isinstance(imp, dict):
                    continue
                idx = imp.get('data_index')
                entry['ids'].append(idx)
                params = imp.get('params') or {}
                blocked = [k.split('（')[0].split('(')[0] for k in BLOCKERS if params.get(k) == 0]
                if blocked:
                    entry['blocking'].append({'data_index': idx, 'logic_id': imp.get('logic_id'),
                                              'continuance': imp.get('continuance'),
                                              'can_be_cancled': imp.get('can_be_cancled'),
                                              'fade_out_when_unit_offline': imp.get('fade_out_when_unit_offline'),
                                              'blocked': blocked})
            rows.append(entry)
    rows.sort(key=lambda r: (r['guid'] is None, r['guid']))
    out = {'total_characters': len(rows),
           'dead_hp0': [r['guid'] for r in rows if r['hp'] == 0],
           'with_blocking_impact': [r['guid'] for r in rows if r['blocking']],
           'rows': rows}
    with open(args.out, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print('total=%d  hp0=%s  blocking=%s' % (out['total_characters'], out['dead_hp0'], out['with_blocking_impact']))
    for r in rows:
        if r['blocking'] or r['hp'] == 0:
            print(' guid=%s %-10s hp=%s/%s scene=%s impacts=%s ids=%s blocking=%s'
                  % (r['guid'], r['name'], r['hp'], r['hp_max'], r['sceneid'], r['impacts'], r['ids'],
                     json.dumps(r['blocking'], ensure_ascii=False)))


if __name__ == '__main__':
    main()
