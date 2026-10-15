"""Plan/apply inventory invariants to the PRIVATE clone only, preserving other patches.

Run tests against --out/GameServer before --apply. Every changed runtime file is
backed up, hashed and rechecked before writing. Does not touch character data.
"""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import re

ROOT = Path('//wsl.localhost/TLBB/home/ubuntu/cys-test-20260913')
HERE = Path(__file__).resolve().parent


def function(text, name, replacement=None, change=None):
    pattern = r'^function ' + re.escape(name) + r'\([^\n]*\)[^\n]*\n.*?^end'
    hits = list(re.finditer(pattern, text, re.M | re.S))
    assert len(hits) == 1, (name, len(hits))
    hit = hits[0]
    body = replacement if replacement is not None else change(hit.group())
    return text[:hit.start()] + body.rstrip() + text[hit.end():]


def add_guard(body, code, tag):
    if '-- CYS-INV ' + tag in body:
        return body
    at = body.index('\n') + 1
    return body[:at] + '    -- CYS-INV ' + tag + '\n' + code.rstrip() + '\n' + body[at:]


MOVE = '''function item_operator:move_item(source_container, source_index, dest_container, dest_index, flag)
    local fail = define.ITEM_OPERATOR_ERROR.ITEMOE_UNKNOW
    if not inventory_guard.accepts(source_container, source_index) then return fail end
    local source = source_container:get_item(source_index)
    if not source or source:is_lock() then return fail end
    if source_container == dest_container and source_index == dest_index then return fail end
    local before = source:get_lay_count()
    local function unchanged(pos, dest, count)
        return source_container:get_item(source_index) == source and not source:is_lock()
            and source:get_lay_count() == before and dest_container:get_item(pos) == dest
            and (not dest or (not dest:is_lock() and dest:get_lay_count() == count))
            and inventory_guard.accepts(source_container, source_index, source)
            and inventory_guard.accepts(dest_container, pos, source)
    end
    if dest_index == define.INVAILD_ID then
        -- Search all candidates with full bind/metadata checks, never the first
        -- same-ID stack (which may have different binding or expiration).
        local size = dest_container:get_size()
        local last = type(size) == 'table' and 219 or size - 1
        for i = 0, last do
            local dest = dest_container:get_item(i)
            local count = dest and dest:get_lay_count() or 0
            if inventory_guard.accepts(dest_container, i, source)
                and inventory_guard.stackable(source, dest)
                and source:get_lay_count() + dest:get_lay_count() <= dest:get_max_tile_count() then
                if not unchanged(i, dest, count) then return fail end
                dest:set_lay_count(count + before)
                source_container:erase_item(source_index)
                return i
            end
        end
        dest_index = dest_container:get_empty_item_index(source:get_place_bag())
    end
    if not inventory_guard.accepts(dest_container, dest_index, source) then return fail end
    local dest = dest_container:get_item(dest_index)
    local count = dest and dest:get_lay_count() or 0
    if dest then
        if not inventory_guard.stackable(source, dest) then return fail end
        local add = math.min(source:get_lay_count(), dest:get_max_tile_count() - dest:get_lay_count())
        if add <= 0 or not unchanged(dest_index, dest, count) then return fail end
        dest:set_lay_count(count + add)
        local left = before - add
        if left == 0 then source_container:erase_item(source_index) else source:set_lay_count(left) end
    else
        if not unchanged(dest_index, nil, 0) then return fail end
        dest_container:set_item(dest_index, source)
        source_container:erase_item(source_index)
    end
    return dest_index
end'''

SPLIT = '''function item_operator:split_item(logparam, src_container, src_index, count, dest_container, dest_index)
    local fail = define.ITEM_OPERATOR_ERROR.ITEMOE_UNKNOW
    if not inventory_guard.accepts(src_container, src_index) then return fail end
    local item = src_container:get_item(src_index)
    if not item or item:is_empty() or item:is_lock() or not item:can_lay()
        or not inventory_guard.integer(count, 1, item:get_lay_count() - 1) then return fail end
    if dest_index == define.INVAILD_ID then dest_index = dest_container:get_empty_item_index(item:get_place_bag()) end
    if not inventory_guard.accepts(dest_container, dest_index, item)
        or dest_container:get_item(dest_index) then return fail end
    local before = item:get_lay_count()
    local copy = table.clone(item)
    local guid = self:gen_item_guid() -- may yield; nothing has been changed yet
    if not guid or src_container:get_item(src_index) ~= item or item:is_lock()
        or item:get_lay_count() ~= before or dest_container:get_item(dest_index)
        or not inventory_guard.accepts(dest_container, dest_index, item) then return fail end
    copy:set_guid(guid)
    copy:set_lay_count(count)
    dest_container:set_item(dest_index, copy)
    item:set_lay_count(before - count)
    return define.ITEM_OPERATOR_ERROR.ITEMOE_SUCCESS
end'''

MULTI = '''function human_item_logic:create_multi_item_to_bag(logparam, human, item_index, item_count, is_bind, shop_type, quality, extra, precommit)
    if not inventory_guard.integer(item_count, 1, 65535) then return false, define.INVAILD_ID end
    is_bind = is_bind ~= nil and is_bind ~= false and is_bind ~= 0
    if not self:calc_item_space(human, item_index, item_count, is_bind) then return false, define.INVAILD_ID end
    -- GUID allocation yields. Prepare every new object BEFORE changing the bag;
    -- then plan against its current state and commit without any yields.
    local prepared = {}
    local sample = item_operator:gen_item(logparam, item_index, shop_type or 1, quality, extra)
    if not sample then return false, define.INVAILD_ID end
    sample:set_is_bind(is_bind)
    local maximum = sample:get_max_tile_count()
    if not inventory_guard.integer(maximum, 1, 65535) then return false, define.INVAILD_ID end
    prepared[1] = sample
    for i = 2, math.ceil(item_count / maximum) do
        local item = item_operator:gen_item(logparam, item_index, shop_type or 1, quality, extra)
        if not item then return false, define.INVAILD_ID end
        item:set_is_bind(is_bind)
        prepared[i] = item
    end
    local bag, left, changes = human:get_prop_bag_container(), item_count, {}
    local kind = sample:get_place_bag()
    for pos, item in bag:ipairs(kind) do
        if left > 0 and inventory_guard.stackable(sample, item) then
            local add = math.min(left, maximum - item:get_lay_count())
            if add > 0 then
                changes[#changes+1] = {pos=pos, item=item, count=item:get_lay_count()+add}
                left = left - add
            end
        end
    end
    local next_new = 1
    for pos, item in bag:ipairs(kind) do
        if left > 0 and not item then
            local add = math.min(left, maximum)
            changes[#changes+1] = {pos=pos, item=prepared[next_new], count=add}
            next_new, left = next_new + 1, left - add
        end
    end
    if left > 0 or (precommit and not precommit()) then return false, define.INVAILD_ID end
    for _, change in ipairs(changes) do
        change.item:set_lay_count(change.count)
        bag:set_item(change.pos, change.item)
    end
    for _, change in ipairs(changes) do
        -- Same two-stage contract as the live create_multi_item_to_bag:
        -- create/replace slot identity first, then apply detail/count.
        local notice = packet_def.GCNotifyEquip.new()
        notice.bag_index, notice.item = change.pos, change.item:copy_raw_data()
        human:get_scene():send2client(human, notice)
        local msg = packet_def.GCItemInfo.new()
        msg.bagIndex, msg.item = change.pos, change.item:copy_raw_data()
        human:get_scene():send2client(human, msg)
    end
    skynet.send(".logdb", "lua", "insert", {collection="create_item_to_bag_rec",doc={
        name=human:get_name(),guid=human:get_guid(),param=logparam,item_index=item_index,
        item_count=item_count,is_bind=is_bind,date_time=utils.get_day_time()}})
    return true, changes[#changes].pos
end'''

PACK = '''function scenecore:char_pack_up_packet(who, request)
    local human = self.objs[who]
    if not human then return end
    local bag = human:get_prop_bag_container()
    if inventory_guard.pack(bag, request.unknow) then
        local first = request.unknow * 100
        local kind = ({"prop", "material", "task"})[request.unknow + 1]
        -- Explicit empty-slot updates clear old actions as well as moved items.
        for i = first, first + bag:get_size()[kind] - 1 do
            local item = bag:get_item(i)
            if item then
                local notice = packet_def.GCNotifyEquip.new()
                notice.bag_index, notice.item = i, item:copy_raw_data()
                self:send2client(human, notice)
            end
            local msg = packet_def.GCItemInfo.new()
            msg.bagIndex = i
            msg.unknow_1 = item and 0 or 1
            msg.item = item and item:copy_raw_data() or item_cls.new():copy_raw_data()
            self:send2client(human, msg)
        end
    else
        human:notify_tips("Tui co vat pham bi khoa hoac yeu cau khong hop le.")
    end
    local ret = packet_def.GCPackUpPacket.new()
    ret.unknow = request.unknow
    self:send2client(human, ret)
end'''


def transform(rel, raw):
    text = raw.decode('utf-8').replace('\r\n', '\n')
    if rel.endswith('cys_inventory_guard.lua'):
        return (HERE / 'inventory_guard.lua').read_bytes()
    if 'local inventory_guard = require "cys_inventory_guard"' not in text and not rel.endswith('msgagent.lua'):
        text = 'local inventory_guard = require "cys_inventory_guard"\n' + text
    if rel.endswith('human_bag_container.lua'):
        text = function(text, 'human_bag_container:get_no_full_item_index', change=lambda b: b.replace(
            'if not item:is_full() then', 'if not item:is_full() and not item:is_lock() then'))
        text = function(text, 'human_bag_container:set_size', '''function human_bag_container:set_size(size)
    if not inventory_guard.resize_ok(self, size) then return nil end
    self.size = {prop=size.prop, material=size.material, task=size.task}
    return {}
end''')
        if 'function human_bag_container:init(' not in text:
            text = text.replace('return human_bag_container', '''-- CYS-INV load all persisted CY slots before applying equipment capacity.
-- Overflow stays in the saved record, inaccessible until the proper bag is worn.
function human_bag_container:init(size, data, flag)
    self._cys_loading = true
    item_container.init(self, {prop=100, material=100, task=20}, data, flag)
    self._cys_loading = nil
    self.size = size
end

return human_bag_container''')
        text = function(text, 'human_bag_container:set_item', '''function human_bag_container:set_item(index, item)
    local checked_item = item
    if self._cys_loading then checked_item = nil end
    if not inventory_guard.accepts(self, index, checked_item) then return false end
    self.item_list[index] = item
    return true
end''')
    elif rel.endswith('item_operator.lua'):
        text = function(text, 'item_operator:move_item', MOVE)
        text = function(text, 'item_operator:split_item', SPLIT)
        text = function(text, 'item_operator:exchange_item', change=lambda b: add_guard(b, '''    if not inventory_guard.accepts(source_container, source_index)
        or not inventory_guard.accepts(dest_container, dest_index) then
        return define.ITEM_OPERATOR_ERROR.ITEMOE_UNKNOW
    end
    local si, di = source_container:get_item(source_index), dest_container:get_item(dest_index)
    if (si and si:is_lock()) or (di and di:is_lock())
        or not inventory_guard.accepts(dest_container, dest_index, si)
        or not inventory_guard.accepts(source_container, source_index, di) then
        return define.ITEM_OPERATOR_ERROR.ITEMOE_UNKNOW
    end''', 'exchange destinations'))
        text = function(text, 'item_operator:create_item', change=lambda b: add_guard(b, '''    if dest_index ~= define.INVAILD_ID and not inventory_guard.accepts(dest_container, dest_index, template) then
        return define.ITEM_OPERATOR_ERROR.ITEMOE_UNKNOW
    end''', 'create destination'))
    elif rel.endswith('scenecore.lua'):
        def pick_contract(b):
            if '-- CYS-INV whole loot stack' in b:
                return b
            b = add_guard(b, '', 'whole loot stack')
            b = b.replace('if not obj_box then return end',
                          'if not obj_box or obj_box:get_obj_type() ~= "itembox" then return end')
            b = b.replace('local no_full_index = bag_container:get_no_full_item_index(item:get_index())',
                          'local no_full_index = inventory_guard.pick_stack_index(bag_container, item)')
            b = b.replace('local no_full_index = bag_container:get_no_full_item_index(item:get_index(), item:is_bind())',
                          'local no_full_index = inventory_guard.pick_stack_index(bag_container, item)')
            b = b.replace('if guid == pick.item_guid then', 'if guid == pick.item_guid then\n                    if item:is_lock() then return end')
            b = b.replace('local item_list = obj_box:get_container():get_item_data()',
                          'local item_list = obj_box:get_container():get_item_data()\n        local chage_item = false')
            b = re.sub(r'self:pick_notify\(obj_box, obj_me, item\)\s*item_operator:inc_item_lay_count\(bag_container, bag_index\)\s*obj_box:erase_item\(index\)',
                       '''if item_operator:move_item(obj_box:get_container(), index, bag_container, bag_index) < 0 then return end
                            self:pick_notify(obj_box, obj_me, item)''', b)
            b = re.sub(r'self:pick_notify\(obj_box, obj_me, item\)\s*item_operator:move_item\(obj_box:get_container\(\), index, bag_container, bag_index\)',
                       '''if item_operator:move_item(obj_box:get_container(), index, bag_container, bag_index) < 0 then return end
                                self:pick_notify(obj_box, obj_me, item)''', b)
            b = b.replace('msg.item_guid = raw_data.guid', '-- Keep the source GUID so the client clears the right loot row.')
            b = b.replace('set_open_flag(flase)', 'set_open_flag(false)')
            assert b.count('inventory_guard.pick_stack_index') == 2
            assert 'inc_item_lay_count' not in b and 'msg.item_guid = raw_data.guid' not in b
            return b
        text = function(text, 'scenecore:char_pick_box_item', change=pick_contract)
        text = function(text, 'scenecore:char_open_box_item', change=lambda b: add_guard(b, '''    local box = self.objs[box_item.m_objID]
    if not self.objs[me] or not box or box:get_obj_type() ~= "itembox" then return end''', 'loot object type'))
        text = function(text, 'scenecore:package_swap_item', change=lambda b: add_guard(b, '''    local human = self.objs[whos]
    if not human or not inventory_guard.swap_ok(human:get_prop_bag_container(), swap.index_from, swap.index_to) then return end''', 'swap boundaries').replace(
                'or item_from_bind ~= item_to:is_bind() then',
                'or item_from_bind ~= item_to:is_bind()\n                        or not inventory_guard.stackable(item_from, item_to) then'))
        if 'function scenecore:char_pack_up_packet(' in text:
            text = function(text, 'scenecore:char_pack_up_packet', PACK)
        else:
            text = text.replace('function scenecore:package_swap_item', PACK + '\n\nfunction scenecore:package_swap_item', 1)
        # Old -1 rejected legitimate swaps with the last retained slot occupied.
        text = text.replace('local subsize = usesize - cursize - 1', 'local subsize = usesize - cursize')
        text = function(text, 'scenecore:char_use_bag_equip', change=lambda b: b.replace(
            'if not bag:test_can_change_size("prop", subsize) then',
            'if not bag:test_can_change_size("prop", subsize) or bag_index >= bag:get_size().prop + subsize then'))
        text = function(text, 'scenecore:char_un_equip', change=lambda b: b.replace(
            'if not dest_container:test_can_change_size("prop", -size - 1) then',
            'if not dest_container:test_can_change_size("prop", -size) or empty_index >= dest_container:get_size().prop - size then'))
    elif rel.endswith('obj/human.lua'):
        text = function(text, 'human:on_bag_size_changed', change=lambda b: b.replace(
            'local updates = self.prop_bag_container:set_size(size)',
            'local updates = self.prop_bag_container:set_size(size)').replace(
            '    self:send_bag_size(size)', '    self:send_bag_size(self.prop_bag_container:get_size())'))
        text = function(text, 'human:do_shop', change=lambda b: add_guard(b, '''    if not self.shop or not inventory_guard.integer(index, 1, 200)
        or not inventory_guard.integer(buy_num, 1, 65535) then return end
    local goods = self.shop:get_merchadise_by_index(index)
    if not goods or not inventory_guard.integer(goods.pnum, 1, 65535)
        or not inventory_guard.integer(goods.price, 0, 2147483647)
        or goods.pnum * buy_num > 65535 or goods.price * buy_num > 2147483647 then return end
    local opening_shop = self.shop''', 'shop quantities').replace(
            'human_item_logic:create_multi_item_to_bag(logparam, self, itemid, item_count, is_bind, shop_type)',
            '''human_item_logic:create_multi_item_to_bag(logparam, self, itemid, item_count, is_bind, shop_type, nil, nil, function()
            return self.shop == opening_shop and self.shop_cfg_version == shopenginer:get_shop_cfg_version()
                and self:check_cost_money_by_shop_type(shop_type, cost_money)
        end)'''))
        text = function(text, 'human:shop_sell', change=lambda b: add_guard(b, '''    local bag = self:get_prop_bag_container()
    local source = inventory_guard.accepts(bag, sell_bag_index) and bag:get_item(sell_bag_index)
    if not source or source:is_lock() then return end''', 'sell lock'))
    elif rel.endswith('human_item_logic.lua'):
        for name, signature in [('move_item_from_bag_to_container_with_index', 'destcontainer'), ('move_item_from_container_to_bag_with_index', 'human:get_prop_bag_container()')]:
            source = 'human:get_prop_bag_container()' if name.startswith('move_item_from_bag') else 'fromcontainer'
            code = f'''    local src, dst = {source}, {signature}
    local item = inventory_guard.accepts(src, from_index) and src:get_item(from_index)
    if not item or item:is_lock() or not inventory_guard.accepts(dst, dest_index, item)
        or dst:get_item(dest_index) then return false end'''
            text = function(text, 'human_item_logic:' + name, change=lambda b, code=code: add_guard(b, code, 'transfer boundaries'))
        text = function(text, 'human_item_logic:calc_item_space', change=lambda b: add_guard(b, '''    if not inventory_guard.integer(need_count, 1, 2147483647) then return false end
    is_bind = is_bind ~= nil and is_bind ~= false and is_bind ~= 0''', 'space quantity').replace(
                'if item:get_index() == item_index and item:is_bind() == is_bind then',
                'if item:get_index() == item_index and item:is_bind() == is_bind and not item:is_lock() then'))
        text = function(text, 'human_item_logic:create_multi_item_to_bag', MULTI)
    elif rel.endswith('msgagent.lua'):
        text = function(text, 'request:CGPackUpPacket', '''function request:CGPackUpPacket()
    skynet.send(my_scene, "lua", "char_pack_up_packet", my_obj_id, self)
end''')
    return text.encode('utf-8')


RELS = ['GameServer/' + r for r in [
    'lualib/human_bag_container.lua','lualib/item_operator.lua','lualib/human_item_logic.lua',
    'services/scene/scenecore.lua','services/scene/obj/human.lua','services/msgagent.lua',
    'lualib/cys_inventory_guard.lua']]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--out',type=Path,required=True)
    p.add_argument('--apply',action='store_true')
    a=p.parse_args()
    assert ROOT.name=='cys-test-20260913' and ROOT.is_dir()
    a.out.mkdir(parents=True,exist_ok=True)
    rows=[];changes=[];sha=lambda b:hashlib.sha256(b).hexdigest()
    for rel in RELS:
        path=ROOT/rel; raw=path.read_bytes() if path.exists() else b''
        new=transform(rel,raw)
        assert transform(rel,new)==new, 'not idempotent '+rel
        dest=a.out/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(new)
        rows.append(dict(path=rel,before=sha(raw) if path.exists() else None,after=sha(new)))
        if new!=raw: changes.append((rel,raw,new,path.exists()))
    # Unchanged dependency for executable container tests, never deployed.
    dep=a.out/'GameServer/lualib/item_container.lua'
    dep.parent.mkdir(parents=True,exist_ok=True)
    dep.write_bytes((ROOT/'GameServer/lualib/item_container.lua').read_bytes())
    manifest=dict(root=str(ROOT),files=rows,utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
    if a.apply and changes:
        backup=ROOT/'backups'/('inventory-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
        backup.mkdir(parents=True,exist_ok=False)
        for rel,raw,new,existed in changes:
            assert ((ROOT/rel).read_bytes() if (ROOT/rel).exists() else b'')==raw
            if existed:
                dst=backup/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(raw)
        for rel,raw,new,existed in changes:(ROOT/rel).write_bytes(new)
        manifest['backup']=str(backup)
        (backup/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8',newline='\n')
        print('backup',backup)
    (a.out/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8',newline='\n')
    print('APPLIED' if a.apply else 'PLAN',len(changes),'changed files')


if __name__=='__main__':main()
