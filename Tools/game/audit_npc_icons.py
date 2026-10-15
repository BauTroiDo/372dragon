"""Check live option icons against the independent canonical look/imageset data."""
from pathlib import Path
import json, re, xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[2]
DATA=ROOT/'Assets/CanonicalCY/Data/InterfaceFolder'

def catalog():
    look=ET.parse(DATA/'Schema/TLBBLook_ComplexWindow.looknfeel.xml').getroot()
    result={}
    for p in look.find("WidgetLook[@name='TLBB_Look_ComplexWindow']").findall("Property[@name='QuestButtonImage']"):
        m=re.fullmatch(r'index:(\d+) set:(\S+) image:(\S+)',p.attrib['value']);assert m
        state,atlas,name=int(m[1]),m[2],m[3]
        root=ET.parse(DATA/f'Common/{atlas}.imageset.xml').getroot()
        cell=root.find(f"Image[@Name='{name}']");assert cell is not None
        texture=DATA/root.attrib['Imagefile'];assert texture.is_file()
        result[state]={'image':f'set:{atlas} image:{name}','size':[int(cell.attrib[k]) for k in ['Width','Height']],
            'atlas':str(texture),'rect':[int(cell.attrib[k]) for k in ['XPos','YPos','Width','Height']]}
    assert set(result)==set(range(32))
    return result

def verify_runtime(folder):
    expected=catalog()
    # CEGUI's logger writes to UISystem.log in this client.
    logs='\n'.join(p.read_text(encoding='utf8',errors='replace') for p in folder.glob('*.log'))
    rows=re.findall(r'CYS-NPC-ICON: catalog button=CysNpcIconCheck__option__\d+#-9173,(\d+) image=\[([^\]]+)\] size=(\d+),(\d+) source=(\d+),(\d+) mouse=(\d),(\d)',logs)
    seen=set()
    for state,image,w,h,sw,sh,mouse,hover in rows:
        state=int(state);row=expected[state]
        assert image==row['image'],(state,image,row)
        assert [int(w),int(h)]==[int(sw),int(sh)]==row['size'],(state,w,h,sw,sh)
        assert (mouse,hover)==('1','1')
        seen.add(state)
    assert seen==set(expected),(seen,'missing live states')
    assert 'CYS-NPC-ICON: server button=QuestGreeting_Desc__option__' in logs
    assert 'NPC option icon:' not in logs,'image lookup error'
    print('PASS: canonical mapping and source dimensions for all 32 runtime icon states')

if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser();p.add_argument('--check',type=Path);p.add_argument('--out',type=Path);a=p.parse_args()
    if a.out:a.out.write_text(json.dumps(catalog(),ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    if a.check:verify_runtime(a.check)
