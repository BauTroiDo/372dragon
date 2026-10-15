"""Join the camera readbacks (cam-<tag>.json) of a run_cy_oracle.ps1 run with its shots (<tag>*.png) into cameras.tsv:
shot, eye xyz, orbit target xyz, fovy, pitch, yaw, distance, TlbbViewer --camera argument (render units, as
Tools/render/d3d9_trace_diff.py camera). A shot belongs to the camread whose tag is the prefix before '-' of its name.
Usage: cam_table.py RUNDIR
"""
import glob
import json
import os
import sys


def main():
    d = sys.argv[1]
    cams = {}
    for f in glob.glob(os.path.join(d, 'cam-*.json')):
        c = json.load(open(f, encoding='utf-8'))['candidates']
        if c:
            cams[os.path.basename(f)[4:-5]] = c[0]
    rows = ['shot\teye\ttarget\tfovy_deg\tpitch_down_deg\tyaw_deg\torbit_distance\ttlbbviewer']
    for png in sorted(glob.glob(os.path.join(d, '*.png'))):
        name = os.path.basename(png)[:-4]
        tag = name.split('-')[0]
        tag = tag[:-1] if tag not in cams and tag[:-1] in cams else tag
        c = cams.get(tag)
        if not c:
            continue
        rows.append('\t'.join([name, ','.join(map(str, c['eye'])), ','.join(map(str, c['orbit_target'])),
                               str(c.get('proj_fovy_deg')), str(c['pitch_down_deg']), str(c['yaw_deg']),
                               str(c['orbit_distance']), c['tlbbviewer']]))
    out = os.path.join(d, 'cameras.tsv')
    open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(rows) + '\n')
    print(out, len(rows) - 1, 'shots')


if __name__ == '__main__':
    main()
