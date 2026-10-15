"""Read-only inventory of CY Pet UI calls versus declared hosts and server script IDs.
Static presence is NOT proof that a handler or gameplay operation works.
"""
import argparse,collections,json,re,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Tools/pipeline'))
from cy_lua_unpack import unpack
CY=Path('C:/TLBB/085/Tools/DATA NEW/DataCY31-08-26/Interface')
SERVER=Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
def read(path):
    raw=path.read_bytes();raw=unpack(raw) or raw
    try:return raw.decode('utf-8-sig')
    except UnicodeDecodeError:return raw.decode('gbk','replace')
def audit():
    stubs=set();declared=set();calls=collections.defaultdict(list);script_ids=collections.defaultdict(list)
    for path in (ROOT/'Src/Client/LuaApiGen').glob('LuaApiGen_*.cpp'):
        stubs.update(re.findall(r'Stub\((?:state|s),\s*"([^"]+)",\s*"([^"]+)"',read(path)))
    for folder in ['Src/Client/LuaApiGen','Src/Client/WXClient/Network','Src/Client/WXClient/Interface']:
        for path in (ROOT/folder).glob('*.cpp'):
            if path.name.startswith('LuaApiGen_'):continue
            source=read(path)
            declared.update(re.findall(r'\{\s*"(Pet|DataPool|PlayerPackage|Player)"\s*,\s*"([^"]+)"\s*,',source))
            declared.update(re.findall(r'SCRIPT_SANDBOX::(\w+)::s_pMetaTable\s*->\s*Register\w+\(\s*"([A-Za-z_]\w*)"',source))
    files=[]
    for path in CY.rglob('*.lua'):
        if not any(part.lower().startswith(('pet','otherpet','targetpet','bieyepet','bieyecutepet',
                    'neidan','yushou','otheryushou','newexterior_pet','ybmarketuppet'))
                   for part in path.relative_to(CY).parts[:-1]):continue
        source=read(path);files.append(str(path.relative_to(CY)))
        for no,line in enumerate(source.splitlines(),1):
            line=line.split('--',1)[0]
            for pair in re.findall(r'\b(Pet|DataPool|PlayerPackage|Player)\s*:\s*(\w+)\s*\(',line):
                calls[pair].append(f'{path.relative_to(CY)}:{no}')
            for id in re.findall(r'Set_XSCRIPT_ScriptID\(\s*(\d+)\s*\)',line):script_ids[int(id)].append(f'{path.relative_to(CY)}:{no}')
    registry=dict((int(a),b) for a,b in re.findall(r'\[(\d+)\]\s*=\s*"([^"]+)"',read(SERVER/'Game_2/Script/scripts/scripts.lua')))
    unresolved=[dict(receiver=p[0],method=p[1],calls=len(refs),references=refs)
                for p,refs in sorted(calls.items()) if p in stubs and p not in declared]
    return dict(note='Static catalog, not runtime certification; aliases/metatable registration require manual follow-up.',
                ui_files=files,distinct_calls=len(calls),unresolved_stub_candidates=unresolved,
                xscript_ids=[dict(id=id,path=registry.get(id),references=refs) for id,refs in sorted(script_ids.items())])
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    r=audit();a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf-8')
    print('UI files',len(r['ui_files']),'distinct calls',r['distinct_calls'],'stub candidates',len(r['unresolved_stub_candidates']))
    print('missing server script IDs',[x['id'] for x in r['xscript_ids'] if not x['path']])
