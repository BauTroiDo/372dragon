"""Prove that the final ornament fix only adds resources to the tested pack.

The same executable and unchanged catalog retain earlier census evidence.
Affected back ornaments still require runtime coverage on the final manifest.
"""
import json
from hj_appearance_data import OUT,PACK,CY,sha,json_write,V

BASE=OUT/'back-skill-baseline'
AGGREGATES={
    'Overlay/Post/MaterialFolder/cys_hj.material':'material',
    'Overlay/Post/EffectFolder/cys_hj.particle':'particle',
    'Overlay/Post/EffectFolder/cys_hj.effect':'effect',
    'Overlay/Post/EffectFolder/cys_hj.skill':'skill',
    'Overlay/Post/ModelFolder/cys_hj.obj':'obj',
}

def blocks(raw,kind):
    if kind=='obj':spans=V.obj_spans(raw)
    else:spans=[(V.def_name(kind,h)[0],a,b) for h,a,b in V.script_spans(raw)[0]]
    result={n:raw[a:b] for n,a,b in spans}
    assert len(result)==len(spans),('duplicate definitions',kind)
    return result

def prove(stage):
    old_raw=(BASE/'stage.json').read_bytes();new_raw=(stage/'Bin64/game_data_stage.json').read_bytes()
    old=json.loads(old_raw);new=json.loads(new_raw)
    assert {k:v for k,v in old.items() if k!='overlay'}=={k:v for k,v in new.items() if k!='overlay'},'non-resource stage change'
    before=json.loads((BASE/'resources.json').read_text(encoding='utf8'))
    after=json.loads((PACK/'resource-manifest.json').read_text(encoding='utf8'))
    key=lambda r:(r['kind'],r['source'])
    a={key(r):r for r in before};b={key(r):r for r in after}
    assert len(a)==len(before) and len(b)==len(after)
    for k,r in a.items():assert b[k]==r,('changed old resource',k)
    added=[r for k,r in b.items() if k not in a]
    aliases={r['native_alias'].encode('gbk') for r in added if r.get('native_alias')}
    assert aliases=={s.encode('gbk') for s in ('back_2025阴阳如意葫芦01_休闲','back_2025阴阳如意葫芦_休闲')}
    base=V.DataRoot(str(CY))
    assert not aliases&set(blocks(base.script('skill'),'skill'))
    old_files={r['path']:r for r in old['overlay']};new_files={r['path']:r for r in new['overlay']}
    assert old_files.keys()<=new_files.keys()
    changed=[];new_definitions={}
    for path,row in old_files.items():
        current=new_files[path]
        if row==current:continue
        assert path in AGGREGATES,('changed non-aggregate file',path)
        assert {k:v for k,v in row.items() if k not in ('sha256','bytes')}=={k:v for k,v in current.items() if k not in ('sha256','bytes')}
        kind=AGGREGATES[path];p=(BASE/path).read_bytes();q=(stage/path).read_bytes()
        assert sha(p)==row['sha256'] and sha(q)==current['sha256']
        prior=blocks(p,kind);now=blocks(q,kind)
        for name,body in prior.items():assert now[name]==body,('modified prior definition',kind,name)
        extra=set(now)-set(prior)
        expected={r['output'].encode() for r in added if r['kind']==kind}
        if kind=='skill':expected|=aliases
        assert extra==expected,('unexpected new definitions',kind,extra^expected)
        changed.append(path);new_definitions[kind]=len(extra)
    new_paths=set(new_files)-set(old_files)
    added_files={r['output']:r for r in added if r['kind'] in ('texture','mesh','skeleton','dynbone','sound')}
    assert {p.rsplit('/',1)[1] for p in new_paths}==set(added_files)
    for path in new_paths:
        row=added_files[path.rsplit('/',1)[1]]
        assert path.startswith('Overlay/Post/') and row['output'].startswith('cys_hj_')
        assert sha((stage/path).read_bytes())==row['sha256']==new_files[path]['sha256']
    report={'passed':True,'old_manifest_sha256':sha(old_raw),'new_manifest_sha256':sha(new_raw),
            'game_sha256':sha((stage/'Bin64/Game.exe').read_bytes()),'unchanged_resources':len(a),
            'added_resources':len(added),'changed_aggregates':changed,'added_definitions':new_definitions,
            'added_files':sorted(new_paths),'native_aliases':[n.decode('gbk') for n in sorted(aliases)],
            'unchanged_binary_configs_catalog_tables':True,'requires_current_back_census_both_sexes':True}
    json_write(OUT/'asset-extension-proof.json',report)
    return report
