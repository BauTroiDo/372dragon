"""Read-only reference evidence for skill text and CY action-bar settings."""
from pathlib import Path
import argparse, hashlib, json, re, struct, sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'Tools/redteam'))
from rt_dbc import Dbc
sys.stdout.reconfigure(encoding='utf8')

def skills():
    cfg=ROOT/'Assets/CanonicalCY/Data/ConfigFolder'
    t=Dbc(cfg/'SkillTemplate_V1.txt');d=Dbc(cfg/'SkillData_V1.txt')
    byid={d.i(r,0):r for r in range(d.nR)}
    for r in range(t.nR):
        if t.i(r,0) in (34,35,374,946) or (t.i(r,1)==14 and t.i(r,20)==0):
            sid=t.i(r,48);row=byid.get(sid)
            print(json.dumps(dict(id=t.i(r,0),sect=t.i(r,1),name=t.s(r,2).decode('utf8'),
                skilldata=sid,tip=d.s(row,1).decode('utf8') if row is not None else None,
                old_pair11=d.s(row,46).decode('utf8') if row is not None else None),ensure_ascii=False))

def binary(a):
    import capstone, pefile
    path=ROOT/'Build/re/cy-oracle/CYGame/Bin64/Game.exe'
    pe=pefile.PE(str(path));base=pe.OPTIONAL_HEADER.ImageBase
    md=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_64);md.detail=True
    functions=[(base+x.struct.BeginAddress,base+x.struct.EndAddress) for x in pe.DIRECTORY_ENTRY_EXCEPTION]
    print('binary',path,'sha256',hashlib.sha256(path.read_bytes()).hexdigest())
    def dump(va):
        pair=next(((b,e) for b,e in functions if b<=va<e),None)
        if not pair: print('no unwind',hex(va));return
        b,e=pair
        print('FUNCTION',hex(b),hex(e))
        for ins in md.disasm(pe.get_data(b-base,e-b),b): print(f'{ins.address:x}: {ins.mnemonic} {ins.op_str}')
    if a.address:
        for va in a.address:dump(int(va,16))
    if a.string:
        data=path.read_bytes();off=data.find(a.string.encode())
        assert off>=0,a.string
        target=base+pe.get_rva_from_offset(off);print('STRING',hex(target))
        for sec in pe.sections:
            if not sec.Characteristics&0x20000000:continue
            blob=sec.get_data();va=base+sec.VirtualAddress
            for m in re.finditer(rb'[\x48\x4c]\x8d[\x05\x0d\x15\x1d\x25\x2d\x35\x3d]',blob):
                off=m.start()
                if va+off+7+struct.unpack_from('<i',blob,off+3)[0]==target:
                    if a.context:
                        for ins in md.disasm(blob[max(0,off-32):off+64],va+max(0,off-32)):print(f'{ins.address:x}: {ins.mnemonic} {ins.op_str}')
                    else:dump(va+off)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['skills','binary']);p.add_argument('--address',nargs='*');p.add_argument('--string');p.add_argument('--context',action='store_true');a=p.parse_args()
    if a.mode=='skills':skills()
    else:binary(a)
