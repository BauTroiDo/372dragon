"""Generate the CY shop's two-row footer without changing events, controls, data or shared looks.

The generator writes an explicit proposal, never the input or a stage. Apply under coordinator control.
"""
from pathlib import Path
import argparse, hashlib, json, re, xml.etree.ElementTree as ET

CHANGES = {
    'YuanbaoShop_Frame': {
        'UnifiedSize': ('{{0.000000,800.000000},{0.000000,490.000000}}', '{{0.000000,800.000000},{0.000000,518.000000}}'),
        'UnifiedPosition': ('{{0.500000,-400.000000},{0.500000,-245.000000}}', '{{0.500000,-400.000000},{0.500000,-259.000000}}'),
    },
    'YuanbaoShop_Repair_SaleBack': {
        'UnifiedPosition': ('{{0.000000,0.000000},{1.000000,-25.000000}}', '{{0.000000,0.000000},{1.000000,-53.000000}}'),
        'UnifiedSize': ('{{1.000000,0.000000},{0.000000,25.000000}}', '{{1.000000,0.000000},{0.000000,53.000000}}'),
    },
    'YuanbaoShop_Text2': {'AbsoluteSize': ('w:140.000000 h:17.000000', 'w:600.000000 h:22.000000')},
    'YuanbaoShop_Text2_Bind': {'AbsoluteSize': ('w:250.000000 h:17.000000', 'w:600.000000 h:22.000000')},
    'YuanbaoShop_Text1': {'AbsolutePosition': ('x:174.000000 y:3.000000', 'x:174.000000 y:31.000000')},
    'YuanbaoShop_SearchMode': {'AbsolutePosition': ('x:235.000000 y:2.000000', 'x:235.000000 y:30.000000')},
    'YuanbaoShop_SearchMode_Bind': {'AbsolutePosition': ('x:235.000000 y:2.000000', 'x:235.000000 y:30.000000')},
    'YuanbaoShop_Begin': {'AbsolutePosition': ('x:411.000000 y:2.000000', 'x:411.000000 y:30.000000')},
    'YuanbaoShop_Duihuan': {'UnifiedPosition': ('{{1.000000,-92.000000},{0.000000,2.000000}}', '{{1.000000,-92.000000},{0.000000,30.000000}}')},
}

def generate(data):
    text=data.decode('utf-8')
    before=ET.fromstring(data)
    for name, properties in CHANGES.items():
        pattern=r'(<Window\b[^>]*\bName="'+re.escape(name)+r'"[^>]*>)(.*?)(?=<Window\b|</Window>)'
        found=list(re.finditer(pattern,text,re.S))
        if len(found)!=1:raise ValueError('Expected one window: '+name)
        match=found[0];block=match.group(2)
        for prop,(old,new) in properties.items():
            pattern_prop=r'(<Property\b[^>]*\bName="'+re.escape(prop)+r'"[^>]*\bValue=")([^"]*)(")'
            values=re.findall(pattern_prop,block)
            if len(values)!=1 or values[0][1] not in (old,new):raise ValueError('Unreviewed geometry: '+name+'/'+prop)
            block=re.sub(pattern_prop,lambda m:m[1]+new+m[3],block,count=1)
        text=text[:match.start(2)]+block+text[match.end(2):]
    after=ET.fromstring(text)
    # Verify exactly the named geometry properties differ; preserve hierarchy and all event/functional data.
    old_nodes=list(before.iter());new_nodes=list(after.iter())
    assert len(old_nodes)==len(new_nodes)
    active_window=None
    changed=[]
    for old,new in zip(old_nodes,new_nodes):
        assert old.tag==new.tag
        if old.tag=='Window':active_window=old.get('Name')
        if old.attrib!=new.attrib:
            assert old.tag=='Property' and active_window in CHANGES
            prop=old.get('Name');assert prop in CHANGES[active_window]
            assert {k:v for k,v in old.attrib.items() if k!='Value'}=={k:v for k,v in new.attrib.items() if k!='Value'}
            changed.append(active_window+'/'+prop)
    # Money row (3..25) and search row (30..51) fit in the 53px footer. At 1280x720 the 800x518 frame fits.
    assert 12+600<=624 and 3+22<30 and 30+21<=53 and 800<=1280 and 518<=720
    result=text.encode('utf-8')
    assert generate_idempotent(result)==result
    return result,changed

def generate_idempotent(data):
    # Fast check of final values without recursively calling generate.
    root=ET.fromstring(data)
    nodes={n.get('Name'):n for n in root.iter('Window')}
    for name,props in CHANGES.items():
        current={p.get('Name'):p.get('Value') for p in nodes[name].findall('Property')}
        assert all(current[k]==v[1] for k,v in props.items())
    return data

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',type=Path,required=True);p.add_argument('--output',type=Path,required=True);args=p.parse_args()
    if args.input.resolve()==args.output.resolve():p.error('Output must be a proposal, not the live input.')
    if args.output.exists():p.error('Output already exists; preserve old evidence and use a new path.')
    raw=args.input.read_bytes();result,changes=generate(raw)
    args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_bytes(result)
    metadata={'input':str(args.input.resolve()),'before_sha256':hashlib.sha256(raw).hexdigest(),'after_sha256':hashlib.sha256(result).hexdigest(),'changed_geometry':changes,'preserved':'window names/types/hierarchy, events, functional properties, Lua and shared looks','runtime_required':'visible before/after balance, cancel/purchase, page/tab, movement; no UI claim from static geometry alone'}
    args.output.with_suffix(args.output.suffix+'.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(metadata,ensure_ascii=False))
