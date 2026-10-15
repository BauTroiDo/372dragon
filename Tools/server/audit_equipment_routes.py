"""Check both admission and script dispatch for equipment skill requests."""
from pathlib import Path
import argparse
import re

ROUTES = [(809270, 'RunHunShiCompound_New', 'scripts.event.equip.wuhun'),
          (332207, 'DarkSkillAdjustForBagItem', 'scripts.obj.commonitem.332207'),
          (332207, 'DoRefreshDarkSkill', 'scripts.obj.commonitem.332207'),
          (809273, 'Lw_Op_Do', 'scripts.event.equip.cy_longwen'),
          (880001, 'RL_QuerySkills', 'scripts.event.equip.cy_lingpai'),
          (880001, 'RL_SwitchSkill', 'scripts.event.equip.cy_lingpai')]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', type=Path)
    args = parser.parse_args()
    rows = [line.split('\t') for line in (args.root/'configs/AllowableScriptFunc.txt').read_text(encoding='gbk').splitlines()]
    allowed = {(int(r[1]),r[2].strip()) for r in rows if len(r)>2 and r[1].isdigit()}
    registry = (args.root/'Game_2/Script/scripts/scripts.lua').read_text(encoding='utf8')
    failed = 0
    for sid, function, module in ROUTES:
        source = args.root/'Game_2/Script'/Path(module.replace('.', '/')+'.lua')
        checks = {
            'admission': (sid,function) in allowed,
            'registry': re.search(r'\['+str(sid)+r'\]\s*=\s*["\']'+re.escape(module)+r'["\']',registry) is not None,
            'method': source.exists() and re.search(r'function\s+\w+:'+re.escape(function)+r'\(',source.read_text(encoding='utf8')) is not None,
        }
        good = all(checks.values())
        failed += not good
        print(('PASS' if good else 'FAIL'),sid,function,checks)
    print(f'SUMMARY routes={len(ROUTES)} failed={failed}')
    raise SystemExit(1 if failed else 0)

if __name__ == '__main__':
    main()
