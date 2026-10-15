"""Run isolated social regressions with staged source and private runtime libraries."""
from pathlib import Path
import json, subprocess
ROOT=Path(__file__).resolve().parents[2]
LOG=ROOT/'Build/Logs/2026-09-28-social-completion'
WS='/mnt/c/TLBB/085/CY-Source'
STAGE=WS+'/Build/Logs/2026-09-28-social-completion/server'
LIVE='/home/ubuntu/cys-test-20260913'
tests=[('party_test',[LIVE+'/GameServer',LIVE+'/GameServer']),
       ('guild_test',[LIVE+'/GameServer',LIVE+'/GameServer']),
       ('raid_test',[STAGE+'/GameServer',LIVE+'/GameServer']),
       ('social_guild_test',[STAGE,LIVE]),('social_trade_test',[STAGE,LIVE]),
       ('social_exp_test',[STAGE+'/GameServer']),
       ('social_follow_test',[STAGE+'/Game_2/Script/scripts/event/team.lua']),
       ('social_city_test',[WS+'/Tools/server/social_lua/cys_social_city.lua'])]
def main():
    results=[]
    for name,args in tests:
        r=subprocess.run(['wsl','-d','TLBB','-u','root','--','lua',WS+'/Tools/server/'+name+'.lua',*args],capture_output=True)
        output=(r.stdout+r.stderr).decode('utf8',errors='replace')
        (LOG/(name+'.log')).write_text(output,encoding='utf8')
        results.append({'test':name,'exit':r.returncode})
        print(name,r.returncode,output.splitlines()[-1:])
    (LOG/'server-regressions.json').write_text(json.dumps(results,indent=2))
    assert all(r['exit']==0 for r in results),'See individual test logs'
if __name__=='__main__':main()
