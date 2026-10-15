"""Read-only CY native flight evidence: PE functions, RIP references and literals."""
from pathlib import Path
import argparse,bisect,hashlib,json
import pefile,capstone
p=argparse.ArgumentParser();p.add_argument('mode',choices=['refs','functions']);p.add_argument('values',nargs='*');p.add_argument('--binary',type=Path);a=p.parse_args()
root=Path(__file__).resolve().parents[2]
binary=a.binary or root/'Build/re/wuliang-parity/CYGame/Bin64/Game.exe';pe=pefile.PE(str(binary));base=pe.OPTIONAL_HEADER.ImageBase
image=pe.get_memory_mapped_image();md=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_64);md.detail=True;md.skipdata=True
funcs=sorted((e.struct.BeginAddress+base,e.struct.EndAddress+base) for e in pe.DIRECTORY_ENTRY_EXCEPTION)
starts=[x[0] for x in funcs]
def owner(addr):
    n=bisect.bisect_right(starts,addr)-1
    return funcs[n] if n>=0 and funcs[n][0]<=addr<funcs[n][1] else None
def string(addr):
    off=addr-base
    if off<0 or off>=len(image):return ''
    raw=image[off:off+120].split(b'\0',1)[0]
    if not raw or any(b<32 or b>126 for b in raw):return ''
    return raw.decode()
print('SOURCE',binary,'SHA256',hashlib.sha256(binary.read_bytes()).hexdigest())
if a.mode=='refs':
    needles=a.values or ['FLY_101118','IsFlyChange']
    targets={};offset=0
    for needle in needles:
        if needle.startswith('0x'):
            targets[int(needle,16)]=needle;continue
        offset=0
        while True:
            offset=image.find(needle.encode(),offset)
            if offset<0:break
            start=offset-2 if image[offset-2:offset]==b'#{' else offset
            targets[base+start]=string(base+start);offset+=1
    print('LITERALS',json.dumps({hex(k):v for k,v in targets.items()}))
    cache=root/'Build/Logs/2026-09-24-mount-flight'/('refs-'+hashlib.sha256(binary.read_bytes()).hexdigest()[:12]+'.json')
    if cache.exists():references=json.loads(cache.read_text())
    else:
        references=[]
        for sec in pe.sections:
            if not sec.Characteristics&0x20000000:continue
            for ins in md.disasm(sec.get_data(),base+sec.VirtualAddress):
                if ins.id==0:continue
                for op in ins.operands:
                    target=None
                    if op.type==capstone.x86.X86_OP_MEM and op.mem.base==capstone.x86.X86_REG_RIP:target=ins.address+ins.size+op.mem.disp
                    elif op.type==capstone.x86.X86_OP_IMM and ins.mnemonic in ['call','jmp']:target=op.imm
                    if target is not None:references.append([ins.address,ins.mnemonic,ins.op_str,target])
        cache.write_text(json.dumps(references))
    for address,mnemonic,operands,target in references:
        if target in targets:
            f=owner(address)
            print(hex(address),mnemonic,operands,'FUNCTION',hex(f[0]) if f else '?',targets[target])
else:
    for value in a.values:
        if ':' in value:f=tuple(int(v,16) for v in value.split(':'));leaf=False
        else:
            address=int(value,16);f=owner(address);leaf=f is None
            if leaf:f=(address,address+128)
        print('\nFUNCTION',hex(f[0]),hex(f[1]))
        for ins in md.disasm(image[f[0]-base:f[1]-base],f[0]):
            if ins.id==0:continue
            notes=[]
            for op in ins.operands:
                if op.type==capstone.x86.X86_OP_MEM and op.mem.base==capstone.x86.X86_REG_RIP:
                    target=ins.address+ins.size+op.mem.disp;s=string(target)
                    notes.append(hex(target)+(' '+s if s else ''))
            print(hex(ins.address),ins.mnemonic,ins.op_str,'; '+' | '.join(notes) if notes else '')
            if leaf and ins.mnemonic=='ret':break
