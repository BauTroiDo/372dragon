"""Preserve saved reshuffle count when equipment is loaded on the private server."""
from pathlib import Path
import argparse, datetime, hashlib, json, re, shutil, subprocess
from give_item import connected

ROOT = Path('/home/ubuntu/cys-test-20260913')
REL = Path('GameServer/lualib/item.lua')
MARK = '    self:set_reshuffle_count(data.reshuffle_count or 0)'

def patched(text):
    if MARK in text:
        return text
    anchor = '    self:set_enhancement_level(data.enhancement_level)'
    assert text.count(anchor) == 1
    return text.replace(anchor, anchor + '\n' + MARK, 1)

def regression(text, folder):
    # Execute the actual loader and setter; unrelated setters are no-ops here.
    def method(name):
        match = re.search(r'^function equip_data:' + name + r'\([^\n]*\n.*?^end', text, re.M | re.S)
        assert match, name
        return match.group()
    code = '''local equip_data={}
table.clone=function(t) local r={} for k,v in pairs(t) do r[k]=v end return r end
'''
    code += '\n'.join(method(n) for n in ['init_from_data', 'set_reshuffle_count', 'copy_raw_data'])
    code += '''
local function fresh()
 return setmetatable({reshuffle_count=0,attr_count=0}, {__index=function(_,k)
  return equip_data[k] or function() end
 end})
end
for _,n in ipairs({0,7,255}) do
 local a=fresh();a:init_from_data({reshuffle_count=n});assert(a.reshuffle_count==n)
 local b=fresh();b:init_from_data(a:copy_raw_data());assert(b.reshuffle_count==n)
end
local a=fresh();a:init_from_data({});assert(a.reshuffle_count==0)
for _,n in ipairs({-1,256}) do a:init_from_data({reshuffle_count=n});assert(a.reshuffle_count==0) end
print('PASS actual equipment loader: reshuffles 0/7/255, save-load roundtrip, old records and invalid bounds')
'''
    folder.mkdir(parents=True, exist_ok=True)
    script = folder/'reshuffle-roundtrip.lua';script.write_text(code, encoding='utf8')
    subprocess.run(['lua', str(script)], check=True)

def main():
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['check','apply']);a=p.parse_args()
    dest=ROOT/REL;old=dest.read_bytes();new=patched(old.decode('utf8')).encode('utf8')
    folder=ROOT/'backups/equipment-tooltip-check';regression(new.decode(),folder)
    candidate=folder/'item.lua';candidate.write_bytes(new)
    subprocess.run(['luac','-p',str(candidate)],check=True)
    if a.mode=='apply' and old!=new:
        assert not connected(),'Close private clients before applying'
        backup=ROOT/'backups'/('equipment-tooltip-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
        saved=backup/REL;saved.parent.mkdir(parents=True);shutil.copy2(dest,saved)
        assert dest.read_bytes()==old
        dest.write_bytes(new)
        record={'path':str(REL),'before':hashlib.sha256(old).hexdigest(),'after':hashlib.sha256(new).hexdigest()}
        (backup/'manifest.json').write_text(json.dumps(record,indent=2)+'\n')
        print('Backup:',backup)
    print('PASS syntax; changed:',old!=new,'mode:',a.mode)

if __name__=='__main__':main()
