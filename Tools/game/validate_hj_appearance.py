"""Validate imported geometry, stable table cells, native mappings and soul reuse."""
import collections,json,sys
from hj_appearance_data import ROOT,PACK,OUT,RawTable,HJSource,sha,json_write,C
from validators import v01_mesh
from wuhun_appearance_data import Source as GLSource

def main():
    manifest=json.loads((PACK/'resource-manifest.json').read_text(encoding='utf8'))
    source=HJSource();meshes=0
    for entry in manifest:
        if entry['kind']!='mesh':continue
        name=entry['source'].encode('gbk');raw,_,_=source.file_bytes(source.resolve(name))
        assert sha(raw)==entry['source_sha256']
        imported=(PACK/'ModelFolder'/entry['output']).read_bytes();assert sha(imported)==entry['sha256']
        before=v01_mesh.walk_mesh(raw);after=v01_mesh.walk_mesh(imported)
        assert not before['err'] and not after['err'] and len(before['subs'])==len(after['subs']),entry['source']
        reversed=imported
        if after['skel']!=before['skel']:reversed=C.mesh_set_skeleton(reversed,before['skel'])
        pairs=set()
        for a,b in zip(before['subs'],after['subs']):
            if (b['mat'],a['mat']) not in pairs and b['mat']!=a['mat']:
                reversed=C.mesh_set_submat(reversed,b['mat'],a['mat']);pairs.add((b['mat'],a['mat']))
        assert reversed==raw,('mesh geometry/bytes changed',entry['source'])
        meshes+=1
    print('PASS reversible geometry',meshes,flush=True)
    tables=json.loads((PACK/'tables-manifest.json').read_text(encoding='utf8'))
    for name,info in tables.items():
        base=RawTable(PACK/'baseline/ConfigFolder'/(name+'.txt'));out=RawTable(PACK/'ConfigFolder'/(name+'.txt'))
        assert sha(out.raw)==info['sha256'] and sha(base.raw)==info['baseline']
        assert list(out.byid)==sorted(out.byid)
        for row in base.rows:assert out.byid[row[0]]==row
    # Wuhun HJ has the same six native visual mappings as GL. Confirm the
    # dependency bytes independently; a matching numeric ID is not evidence.
    gl=GLSource();hj_by={(r['kind'],r['source']):r for r in manifest}
    prior=json.loads((ROOT/'Build/Logs/2026-09-25-wuhun-appearance/assets/manifest.json').read_text(encoding='utf8'))
    differing=[];same=0;overrides=[]
    for entry in prior:
        kind,name=entry['kind'],entry['source'].encode('gbk');hj=hj_by.get((kind,entry['source']))
        assert hj,('soul dependency absent in HJ closure',kind,entry['source'])
        if kind in C.FILE_KINDS:raw,_,_=gl.file_bytes(gl.resolve(name))
        elif kind=='obj':raw=gl.obj_block(name)[1]
        else:raw=gl.def_block(kind,name)
        if sha(raw)==hj['source_sha256']:same+=1
        else:
            differing.append({'kind':kind,'source':entry['source'],'gl_sha':sha(raw),'hj_sha':hj['source_sha256']})
            assert kind=='texture',('Wuhun requires a new variant mapping',entry['source'])
            # Same 36 meshes/materials/particles; three DDS files have HJ pixel
            # revisions. Ship those under the existing isolated soul names so
            # the six functional souls use the exact HJ textures.
            overrides.append({'source':entry['source'],'output':entry['output'],'hj_output':hj['output'],'sha256':hj['sha256']})
    json_write(PACK/'wuhun-overrides.json',overrides)
    from validate_hj_mounts import validate
    mounted=validate()
    report={'passed':True,'reversible_meshes':meshes,'preserved_tables':len(tables),
            'wuhun_dependencies_identical':same,'wuhun_differences':differing,'mounted':mounted}
    json_write(OUT/'static-validation.json',report)
    print(json.dumps(report,ensure_ascii=False))

if __name__=='__main__':sys.stdout.reconfigure(encoding='utf8');main()
