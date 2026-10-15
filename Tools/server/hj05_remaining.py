"""Continuation on top of the published HJ05 fixes; private CY clone only."""
from pathlib import Path
import argparse, datetime, hashlib, json, shutil
from inventory_integrity import function
import remaining_soul_patch

ROOT = Path(__file__).resolve().parents[2]
LIVE = Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
LOG = ROOT/'Build/Logs/2026-09-28-hj05-remaining'
OWN = Path(__file__).with_name('remaining_lua')
RELS = ['GameServer/lualib/playershop.lua', 'GameServer/services/scene/scenecore.lua', 'GameServer/lualib/playershopmanager.lua']+remaining_soul_patch.RELS

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
def replace(s,a,b):
    assert s.count(a)==1, (a,s.count(a))
    return s.replace(a,b)

def plan():
    files={}
    for rel in RELS:
        b=LOG/'baseline'/rel
        if not b.exists():
            b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LIVE/rel,b)
        s=b.read_text(encoding='utf8')
        if rel in remaining_soul_patch.RELS:
            s=remaining_soul_patch.patch(rel,s)
        elif rel.endswith('/scenecore.lua'):
            s=function(s,'scenecore:char_player_shop_acquire_shop_list',change=lambda b:replace(b,
                'local playershops = playershopmanager:get_player_shops()',
                'local playershops = playershopmanager:get_shop_infos()'))
            for method,handler in [('char_player_shop_buy_item','buy'),('char_player_shop_on_sale','on_sale'),('char_player_shop_money','money')]:
                s=function(s,'scenecore:'+method,f"function scenecore:{method}(who, request)\n    return require('cys_player_shop').{handler}(self, who, request)\nend")
            s=function(s,'scenecore:char_player_shop_acquire_item_list',change=lambda b:replace(b,
                '    local is_manager = psa.is_manager == 1',
                '    if not shop or not obj_me then return end\n    local is_manager = psa.is_manager == 1'))
            s=function(s,'scenecore:char_item_sync',change=lambda b: replace(b,
                'function scenecore:char_item_sync(who, cis)',
                "function scenecore:char_item_sync(who, cis)\n    if cis.from_type == 2 or cis.from_type == 5 then\n        return require('cys_player_shop').move_pet(self, who, cis)\n    end"))
        elif rel.endswith('/playershopmanager.lua'):
            s=replace(s,'function playershopmanager:load()', 'function playershopmanager:load(scene)')
            s=replace(s,'local sql = {collection = "shop", query = nil}',
                'local sql = {collection = "shop", query = {["guid.world"]=self.world,["guid.server"]=self.server,["guid.scene"]=scene:get_id()}}')
            s=replace(s,'    self.scene = scene','    self.scene = scene\n    self.player_shops = {}')
        else:
            s=replace(s,'local item_container = require "item_container"','local item_container = require "item_container"\nlocal pet_container = require "pet_container"')
            s=replace(s,'self.pet_container = item_container.new()','self.pet_container = pet_container.new()')
            s=replace(s,'            self.item_container:init(define.STALL_BOX_SIZE, data.item_list)',
                '            self.item_container = item_container.new()\n            self.item_container:init(define.STALL_BOX_SIZE, data.item_list, define.CONTAINER_INDEX.HUMAN_SHANGHUI_ITEM)')
            s=replace(s,'            self.pet_container:init(define.STALL_BOX_SIZE, data.item_list)',
                '            self.pet_container = pet_container.new()\n            self.pet_container:init(define.STALL_BOX_SIZE, data.item_list, define.CONTAINER_INDEX.HUMAN_SHANGHUI_PET)')
            s=replace(s,'self.item_is_on_sale[i] = data.item_is_on_sale[i] or 0',
                'self.item_is_on_sale[i] = (data.item_is_on_sale[i] == true or data.item_is_on_sale[i] == 1) and 1 or 0')
            s=replace(s,'self.item_is_on_sale[index] = can','self.item_is_on_sale[index] = (can == true or can == 1) and 1 or 0')
            s=replace(s,'        stall_box:load(stall_list_data[i])','        stall_box:load(stall_list_data and (stall_list_data[i] or stall_list_data[tostring(i)]))')
            s=replace(s,'    print("stall_list_data =", table.tostr(stall_list_data))\n','')
            for line in ['        print("playerstallbox data =", table.tostr(data))\n','        print("raw_data.item_list =", table.tostr(raw_data.item_list))\n']:
                s=s.replace(line,'')
            s=replace(s,'    self:set_partner_list(sp.partner_list)','    self:set_partner_list(sp.partner_list)\n    self.serial = sp.serial or 0')
            s=replace(s,'    raw_data.status = self.status','    raw_data.status = self.status\n    raw_data.serial = self:get_serial()')
            s=replace(s,'    return self.serial\nend','    self:set_data_changed()\n    return self.serial\nend')
            s=function(s,'playershop:heart_beat','''function playershop:heart_beat(utime, com_factor)
    if self.data_changed and not self._cys_saving then
        -- A db call yields. Clear BEFORE the call so concurrent edits remain dirty.
        self._cys_saving = true
        self.data_changed = false
        local ok, saved = pcall(self.db_update_shop, self)
        self._cys_saving = false
        if not ok or not saved then self.data_changed = true end
    end
end''')
            s=function(s,'playershop:db_update_shop',change=lambda b: replace(b,'"lua", "update", sql','"lua", "safe_update", sql')[:-3]+'    return ret == true and err == nil\nend')
            s=replace(s,'    local can_manager = is_mine or self:is_partner(human:get_guid())',
                '''    if not require('cys_inventory_guard').integer(stall_index, 1, self.STALL_BOX_COUNT) then return false end
    if self:get_type() == self.TYPE.PET then
        return require('cys_player_shop').send_pet_list(self, human, stall_index, sign, is_manager)
    end
    local can_manager = is_mine or self:is_partner(human:get_guid())''')
            s=function(s,'playershop:send_item_list',change=lambda b: b[:-3]+'''
    -- Native 188-byte list records omit several CY tooltip fields. Follow the
    -- list with full ItemInfo snapshots, using reserved display-only positions.
    require('cys_player_shop').send_item_details(self,human,stall_index,is_manager)
end''')
        files[rel]=s
    for p in sorted(OWN.glob('*.lua')):files['GameServer/lualib/'+p.name]=p.read_text(encoding='utf8')
    files['GameServer/lualib/cys_soul_reforge.lua']=Path(__file__).with_name('remaining_soul_reforge.lua').read_text(encoding='utf8')
    rows=[]
    for rel,s in files.items():
        p=LOG/'server'/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf8',newline='\n')
        b=LOG/'baseline'/rel
        rows.append(dict(path=rel,before=sha(b) if b.exists() else None,after=sha(p)))
    manifest=LOG/'server/manifest.json';manifest.write_text(json.dumps(rows,indent=2),encoding='utf8')
    return rows

def main():
    ap=argparse.ArgumentParser();ap.add_argument('action',choices=['plan','apply']);a=ap.parse_args()
    deployed=LOG/'deployed-manifest.json'
    if not deployed.exists() and (LOG/'server/manifest.json').exists():
        old=json.loads((LOG/'server/manifest.json').read_text())
        if all(sha(LIVE/r['path'])==r['after'] for r in old):
            deployed.write_text(json.dumps(old,indent=2))
    previous={r['path']:r['after'] for r in json.loads(deployed.read_text())} if deployed.exists() else {}
    rows=plan()
    if a.action=='apply':
        for row in rows:
            assert sha(LIVE/row['path']) in (row['before'],row['after'],previous.get(row['path'],row['before'])), 'Runtime changed: '+row['path']
        backup=ROOT/'Build/backups/hj05-remaining'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
        for row in rows:
            p=LIVE/row['path']
            if sha(p)==row['after']:continue
            if p.exists():
                b=backup/row['path'];b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,b)
            p.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(LOG/'server'/row['path'],p)
        deployed.write_text(json.dumps(rows,indent=2))
        print('Applied with backup',backup)
    print(json.dumps(rows,indent=2))
if __name__=='__main__':main()
