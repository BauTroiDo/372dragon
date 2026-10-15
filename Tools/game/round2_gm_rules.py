"""Run the GL rule exporter against private server cfghelper methods, offline."""
from pathlib import Path
import json,re,subprocess,hashlib
from dbc_inventory import Table
ROOT=Path(__file__).resolve().parents[2]
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
def literal(x):
    if isinstance(x,str):return json.dumps(x,ensure_ascii=False)
    if isinstance(x,list):return '{'+','.join(literal(v) for v in x)+'}'
    if isinstance(x,dict):return '{'+','.join('['+literal(k)+']='+literal(v) for k,v in x.items())+'}'
    return str(x)
def generate_rules(out=None):
    out=out or ROOT/'Build/Logs/2026-09-23-round2/gm-rules';out.mkdir(exist_ok=True,parents=True)
    cfg=SERVER/'GameServer/lualib/cfghelper.lua';source=cfg.read_text(encoding='utf8')
    names=['equip_base','item_seg_value','item_seg_rate','ling_yu_base','ling_yu_attr_rule','ling_yu_attr_value']
    inputs=[cfg,ROOT.parent/'Tools/gmtool/gen_equip_rules.lua',Path(__file__)]
    for name in names:
        method=re.search(r'^function cfghelper:read_'+name+r'\(\)\n.*?^end',source,re.M|re.S).group()
        inputs.append(SERVER/'configs'/re.search(r'read:load\("([^"]+)"\)',method)[1])
    stamp={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
    cache=out/'inputs.json';rules=out/'rules.tsv'
    if cache.exists() and rules.exists():
        old=json.loads(cache.read_text())
        if old.get('inputs')==stamp and old.get('output')==hashlib.sha256(rules.read_bytes()).hexdigest():
            return rules.read_bytes()
    methods=[];tables={}
    for name in names:
        method=re.search(r'^function cfghelper:read_'+name+r'\(\)\n.*?^end',source,re.M|re.S).group()
        methods.append(method)
        filename=re.search(r'read:load\("([^"]+)"\)',method)[1]
        table=Table(SERVER/'configs'/filename)
        tables[filename]=[]
        for row in table.rows:
            record={}
            for k,v in zip(table.names,row):
                if not k:continue
                if k in record:
                    if not isinstance(record[k],list):record[k]=[record[k]]
                    record[k].append(v)
                else:record[k]=v
            tables[filename].append(record)
    (out/'tables.lua').write_text('return '+literal(tables),encoding='utf8')
    linux='/mnt/c/TLBB/085/CY-Source/'+out.relative_to(ROOT).as_posix()+'/'
    wrapper=f'''package.path="/home/ubuntu/cys-test-20260913/GameServer/lualib/?.lua;"..package.path
local tables=dofile("{linux}tables.lua")
local cfghelper={{}}
table.tostr=function()return "" end
local skynet={{error=function()end,logd=function()end}}
local define=dofile("/home/ubuntu/cys-test-20260913/GameServer/lualib/define.lua")
local modules={{define=define,txtreader={{new=function()return {{load=function(_,name)return assert(tables[name],name)end}}end}}}}
local require=function(name)return assert(modules[name],name)end
'''+ '\n'.join(methods)+'\n'
    for name in names:wrapper+=f'cfghelper:read_{name}()\n'
    wrapper+='modules.configenginer={getinstance=function()return {get_config=function(_,name)return cfghelper[name]end}end}\n'
    exporter=(ROOT.parent/'Tools/gmtool/gen_equip_rules.lua').read_text(encoding='utf8')
    exporter=re.sub(r'local OUT = "[^"]+"',f'local OUT = "{linux}rules.tsv"',exporter)
    (out/'export.lua').write_text(wrapper+exporter,encoding='utf8')
    result=subprocess.run(['wsl','-d','TLBB','-u','root','--','lua',linux+'export.lua'],capture_output=True)
    (out/'export.log').write_bytes(result.stdout+result.stderr)
    result.check_returncode()
    data=(out/'rules.tsv').read_bytes()
    assert len(data)>100000 and b'10106000\tequip\t' in data
    cache.write_text(json.dumps({'inputs':stamp,'output':hashlib.sha256(data).hexdigest()},indent=2))
    return data
if __name__=='__main__':generate_rules()
