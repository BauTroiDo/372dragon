"""Parse camera memory scans ('cam:<tag>' of run_cy_oracle.ps1, same dump as run_cy_capture.ps1 'aspect').

Each hit is a float == 16/9 with 64 bytes before and 400 after. A camera candidate needs a plausible FOV just before the
aspect (0.2..2.0 rad) and, within the dump, a 4x4 view matrix: orthonormal rotation rows, last row (0,0,0,1)
(color-calib found it at +336). Ogre view = [R t; 0 1] with row-major storage, camera looks along -Z:
eye = -R^T t, forward = -R[2], up = R[1].  Prints JSON: unique cameras (rounded) with fov in degrees.
Usage: cam_parse.py cam-<tag>.txt [...] [--out cams.json]
"""
import json
import math
import re
import sys


def parse(path):
    hits = []
    cur = None
    for line in open(path, encoding='utf-8', errors='replace'):
        if line.startswith('hit '):
            cur = {'addr': line.split()[1], 'v': {}}
            hits.append(cur)
            continue
        m = re.