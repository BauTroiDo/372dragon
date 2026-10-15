"""Grade the separate slot1 regression. This does not replace core slot0 A/B."""
from pathlib import Path
import argparse, json, re


def grade(blob, run):
    def one(pattern):
        rows = re.findall(pattern, blob)
        return rows[0] if len(rows) == 1 else None
    before = one(r'BEFORE item=(\d+) price=(\d+) balance=(\d+) quantity=(\d+)')
    target = one(r'TARGET slot=(\d+) item=(\d+) price=(\d+) quantity=(\d+)')
    after = one(r'BUY replies=(\d+) item=(\d+) price=(\d+) balance_before=(\d+) balance_after=(\d+) quantity_before=(\d+) quantity_after=(\d+)')
    cancel = one(r'CANCEL shown=(\d) buy_delta=(\d+) balance=(\d+) quantity=(\d+)')
    notify = one(r'GCNotifyEquip bag_index=(\d+) item=(\d+) same_guid=(\d)')
    requests = re.findall(r'CYS-NBSHOP: buy index=(\d+) count=(\d+) item=(\d+)', blob)
    replies = re.findall(r'GCShopBuy result=(\d+) item=(\d+) count=(\d+)', blob)
    return {
        'measurement': bool(run.get('passed') and run.get('account') == 'test13' and run.get('game_sha256') and run.get('stage_manifest_sha256') and 'PRECONDITION' not in blob),
        'separate slot1': 'exports=1111 slot=1' in blob and bool(target and before and target == ('1', before[0], before[1], '0')),
        'new item absent before': bool(before and before[3] == '0' and int(before[1]) > 0 and int(before[2]) >= int(before[1])),
        'default confirmation': one(r'CONFIRM shown=(\d) buy_delta=(\d+)') == ('1', '0'),
        'cancel unchanged': bool(before and cancel == ('0', '0', before[2], before[3])),
        'exactly one successful purchase': bool(before and requests == [('1', '1', before[0])] and replies == [('0', before[0], '1')]),
        'new object notification': bool(before and notify and notify[1:] == (before[0], '0')),
        'details applied to new object': bool(before and notify and re.search(r'GCItemInfo applied bag_index='+notify[0]+r' item='+before[0]+r' count=1 empty=0\b', blob)),
        'bag and balance': bool(before and after and (after[0],after[1],after[2],after[3],after[5],after[6]) == ('1',before[0],before[1],before[2],'0','1') and int(after[4]) == int(after[3])-int(after[2])),
        'rendered new balance': bool(after and re.search(r'text phase=after window=YuanbaoShop_Text2 bytes=[1-9]\d* text=[^\n]*?(?<!\d)'+after[4]+r'(?!\d)', blob)),
        'actual target clicks': len(re.findall(r'DOWN window=YuanbaoShop_Item2 accepted=1\b', blob)) == 2 and 'DOWN window=YuanbaoShop_Item1 ' not in blob,
        'cleanup': 'CLEANUP shop=0 confirm=0' in blob,
    }


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--run',type=Path,required=True);a=p.parse_args()
    run=json.loads((a.run/'run.json').read_text(encoding='utf-8-sig'))
    cells=grade((a.run/'WXClient.log').read_text(encoding='utf-8',errors='replace'),run)
    result={'scope':'slot1 new-slot regression only; core A/B and visual review remain separate','status':'PASS' if all(cells.values()) else 'FAIL','checks':cells,'game_sha256':run.get('game_sha256'),'stage_manifest_sha256':run.get('stage_manifest_sha256')}
    (a.run/'new-slot-verdict.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2));raise SystemExit(0 if all(cells.values()) else 1)
