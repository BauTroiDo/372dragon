"""N-way packet ID comparison by class name.

Usage: pkt_compare_n.py <out.json> <label>=<tsv>[+<tsv>...] ...
Each tsv has columns name, id. For every pair: common names, same id, and per label the id range.
"""
import csv
import itertools
import json
import sys


def load(spec):
    label, paths = spec.split('=', 1)
    d = {}
    for p in paths.split('+'):
        with open(p, encoding='utf-8') as f:
            for r in csv.DictReader(f, delimiter='\t'):
                if r['id'] != '':
                    d.setdefault(r['name'], int(r['id']))
    return label, d


def main():
    out = sys.argv[1]
    tabs = dict(load(s) for s in sys.argv[2:])
    res = {'tables': {k: {'packets': len(v), 'id_min': min(v.values()), 'id_max': max(v.values())}
                      for k, v in tabs.items()}, 'pairs': {}}
    for a, b in itertools.combinations(tabs, 2):
        A, B = tabs[a], tabs[b]
        common = set(A) & set(B)
        same = sum(1 for n in common if A[n] == B[n])
        res['pairs'][f'{a}~{b}'] = {'names_common': len(common), 'same_id': same,
                                    'same_id_pct_of_common': round(100.0 * same / len(common), 1) if common else 0}
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(res, f, indent=1)
    print(json.dumps(res, indent=1))


if __name__ == '__main__':
    main()
