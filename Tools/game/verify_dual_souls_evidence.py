"""Validate actual combat recipients, independent skills and the tagged login appearance."""
from pathlib import Path
import argparse,json,re

def combat(folder):
    log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
    assert 'CYS-DUAL-SOULS: RESULT errors=0' in log and 'CYS-DUAL-SOULS: FAIL' not in log
    match=re.search(r'CYS-DUAL-SOULS: AOE begin owner=(\d+)(.*?)CYS-DUAL-SOULS: AOE end',log,re.S)
    assert match,'AoE observation window missing'
    owner=int(match[1]);victims={}
    for receiver,sender,hp in re.findall(r'GCDetailHealsAndDamages receiver=(\d+) sender=(-?\d+) hp=(-?\d+)',match[2]):
        if int(sender)==owner and int(receiver)!=owner and int(hp)<0:
            victims[int(receiver)]=victims.get(int(receiver),0)-int(hp)
    assert len(victims)>=2,('AoE must damage multiple distinct enemies',victims)
    for group in (700,701,702):assert f'GCCooldownUpdate group={group} ' in log
    # Coarse client log timestamps corroborate the exact millisecond timer unit tests.
    def seconds(line):
        h,m,s=map(int,re.search(r'\[\d+_(\d+):(\d+):(\d+)\]',line).groups());return h*3600+m*60+s
    delays={}
    for group in (701,702):
        start=next(i for i,line in enumerate(log.splitlines()) if f'GCCooldownUpdate group={group} ' in line)
        lines=log.splitlines();born=seconds(lines[start]);hit=None
        for line in lines[start+1:]:
            damage=re.search(r'GCDetailHealsAndDamages receiver=(\d+) sender=(-?\d+) hp=(-?\d+)',line)
            if damage and int(damage[2])==owner and int(damage[1])!=owner and int(damage[3])<0:hit=seconds(line);break
        assert hit is not None and (hit-born)%86400>=1,('Damage arrived before projectile release',group)
        delays[group]=(hit-born)%86400
    for marker in ('real skill drag onto F1','server rejects unequip during combat','unequip revokes assault skills','re-equip preserves cooldown','character still moves'):
        assert 'CYS-DUAL-SOULS: PASS '+marker in log
    return {'owner':owner,'aoe_victims':victims,'cooldown_groups':[700,701,702],'observed_hit_delay_seconds':delays}

def relogin(folder):
    log=(folder/'WXClient.log').read_text(encoding='utf8',errors='replace')
    assert 'CYS-DUAL-SOULS: RELOGIN errors=0' in log and 'CYS-DUAL-SOULS: FAIL' not in log
    assert 'CYS-DUAL-SOULS: selection item=10156902 visual=699' in log
    assert 'both independent items survived relogin' in log
    assert 'two soul items survive scene transfer' in log
    return {'selection_item':10156902,'selection_visual':699,'skills_and_items_restored':True,'scene_transfer':True}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('check',type=Path);p.add_argument('--relogin',type=Path);a=p.parse_args()
    result={'combat':combat(a.check)}
    if a.relogin:result['relogin']=relogin(a.relogin)
    print(json.dumps(result,indent=2))
