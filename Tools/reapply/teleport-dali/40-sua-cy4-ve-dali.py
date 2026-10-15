# -*- coding: utf-8 -*-
"""Four CY4 return portals: (241,141) -> (253,121).
See coordinate-manifest.json for reviewed original and faction-corrected states.
Preserves all unrelated bytes, including CY faction IDs. Undo is coordinate-only.
"""
import sys
from safe_coordinates import run
if __name__ == '__main__':
    run('cy4', sys.argv[1] if len(sys.argv) > 1 else 'kiem')
