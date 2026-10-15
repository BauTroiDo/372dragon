# -*- coding: utf-8 -*-
"""Garden quest return: g_Back_X 275 -> 276, g_Back_Z remains 50.
The live sibling portals use (276,50); (275,50) is blocked on dali_new_320.
Preserves all unrelated bytes; requires a reviewed hash. Undo is coordinate-only.
"""
import sys
from safe_coordinates import run
if __name__ == '__main__':
    run('quest', sys.argv[1] if len(sys.argv) > 1 else 'kiem')
