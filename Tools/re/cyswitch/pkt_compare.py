"""Compare packet ID tables: client_GL Game.exe, CY 3.71 Game.exe (from pkt_ids.py) and the skynet spec.

Usage: pkt_compare.py <pkt_ids_gl.tsv> <pkt_ids_cy.tsv> <Registry/protocol/packets_summary.tsv> <outdir>
Writes <outdir>/pkt_compare.tsv (one row per name in any table) and <outdir>/pkt_compare_summary.json.
"""
import csv
import json
import os
import sys


def load(path, idcol='id', namecol='name'):
    with open(path, encoding='utf-8') as f:
        rows = list(csv.DictReader(f, delimiter='\t'))
    return {r[namecol]: int(r[idcol]) for r in rows if r[idcol] != ''}, rows


def main():
    gl, _ = load(sys.argv[1])
    cy, _ = load(sys.argv[2])
    sk, skrows = load(sys.argv[3])
    skdir = {r['name']: r['dir'] for r in skrows}
    skproto = {r['name']: r['proto'] for r in skrows}
    out = sys.argv[4]
    os.makedirs(out, exist_ok=True)

    def cmp(a, b):
        common = set(a) & set(b)
        same = {n for n in common if a[n] == b[n]}
        ida = {v: k for k, v in a.items()}
        idb = {v: k for k, v in b.items()}
        id_common = set(ida) & set(idb)
        id_same_name = {i for i in id_common if ida[i] == idb[i]}
        return {'a': len(a), 'b': len(b), 'names_common': len(common), 'names_common_same_id': len(same),
                'names_common_diff_id': len(common) - len(same), 'only_a': len(set(a) - set(b)),
                'only_b': len(set(b) - set(a)), 'ids_common': len(id_common),
                'ids_common_same_name': len(id_same_name), 'ids_common_other_name': len(id_common) - len(id_same_name)}

    summary = {
        'gl_vs_skynet': cmp(gl, sk),
        'cy_vs_skynet': cmp(cy, sk),
        'cy_vs_gl': cmp(cy, gl),
    }
    # skynet packets by protocol (login / game) seen from CY
    by = {}
    for n, i in sk.items():
        p = skproto.get(n, '?')
        d = by.setdefault(p, {'skynet': 0, 'cy_has_name': 0, 'cy_same_id': 0, 'gl_has_name': 0, 'gl_same_id': 0})
        d['skynet'] += 1
        if n in cy:
            d['cy_has_name'] += 1
            d['cy_same_id'] += cy[n] == i
        if n in gl:
            d['gl_has_name'] += 1
            d['gl_same_id'] += gl[n] == i
    summary['skynet_by_proto'] = by
    ids_cy = {v: k for k, v in cy.items()}
    # skynet game packets whose id in CY means another packet (collision risk if CY talked to skynet)
    coll = [(n, i, ids_cy[i]) for n, i in sk.items() if i in ids_cy and ids_cy[i] != n]
    summary['skynet_ids_that_cy_maps_to_other_packet'] = len(coll)
    summary['id_range'] = {'gl': [min(gl.values()), max(gl.values())], 'cy': [min(cy.values()), max(cy.values())],
                           'skynet': [min(sk.values()), max(sk.values())]}
    names = sorted(set(gl) | set(cy) | set(sk))
    with open(os.path.join(out, 'pkt_compare.tsv'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('name\tskynet_id\tskynet_dir\tskynet_proto\tgl_id\tcy_id\tgl_eq_skynet\tcy_eq_skynet\tcy_eq_gl\t'
                'cy_id_in_skynet_is\n')
        for n in names:
            s, g, c = sk.get(n), gl.get(n), cy.get(n)
            other = ''
            if c is not None:
                sk_by_id = {v: k for k, v in sk.items()}
                other = sk_by_id.get(c, '')
            f.write(f'{n}\t{"" if s is None else s}\t{skdir.get(n, "")}\t{skproto.get(n, "")}\t'
                    f'{"" if g is None else g}\t{"" if c is None else c}\t'
                    f'{int(s == g) if s is not None and g is not None else ""}\t'
                    f'{int(s == c) if s is not None and c is not None else ""}\t'
                    f'{int(g == c) if g is not None and c is not None else ""}\t{other}\n')
    with open(os.path.join(out, 'pkt_compare_summary.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(summary, f, ensure_ascii=False, indent=1)
    print(json.dumps(summary, indent=1))


if __name__ == '__main__':
    main()
