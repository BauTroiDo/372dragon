"""Atomic bag swap/merge, private server only; preserve authoritative identities."""
from pathlib import Path
import datetime,json,hashlib,argparse
from inventory_integrity import ROOT,function,MOVE

SWAP='''function scenecore:package_swap_item(who, request)
    -- CYS-INV swap boundaries; revalidate after config lookup yields.
    local human = self.objs[who]
    if not human then return end
    local bag = human:get_prop_bag_container()
    local source_pos, dest_pos = request.index_from, request.index_to
    if not inventory_guard.swap_ok(bag, source_pos, dest_pos) then return end
    local source, dest = bag:get_item(source_pos), bag:get_item(dest_pos)
    local source_count, dest_count = source:get_lay_count(), dest and dest:get_lay_count() or 0
    -- get_max_tile_count/can_lay can yield while .CfgDB is first loading. A
    -- second packet may finish first; never resurrect its consumed source.
    local stackable = inventory_guard.stackable(source, dest)
    local limit = stackable and dest:get_max_tile_count() or 1
    if bag:get_item(source_pos) ~= source or bag:get_item(dest_pos) ~= dest
        or source:get_lay_count() ~= source_count or (dest and dest:get_lay_count() ~= dest_count)
        or not inventory_guard.swap_ok(bag, source_pos, dest_pos) then return end
    if stackable and dest_count < limit then
        local moved = math.min(source_count, limit - dest_count)
        if moved <= 0 then return end
        local remaining = source_count - moved
        dest:set_lay_count(dest_count + moved)
        if remaining == 0 then bag:set_item(source_pos, nil) else source:set_lay_count(remaining) end
    else
        bag:set_item(source_pos, dest)
        bag:set_item(dest_pos, source)
    end
    -- Notify identity before full instance data. GCItemInfo alone can update an
    -- old object in a now-empty cell; never rely on a client-side blind swap.
    for _, pos in ipairs({source_pos, dest_pos}) do
        local item = bag:get_item(pos)
        if item then
            local identity = packet_def.GCNotifyEquip.new()
            identity.bag_index = pos
            identity.item = item:copy_raw_data()
            self:send2client(human, identity)
        end
        local detail = packet_def.GCItemInfo.new()
        detail.bagIndex = pos
        detail.unknow_1 = item and 0 or 1
        detail.item = item and item:copy_raw_data() or item_cls.new():copy_raw_data()
        self:send2client(human, detail)
    end
end'''

def main():
    p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
    rel='GameServer/services/scene/scenecore.lua';path=ROOT/rel;old=path.read_bytes();new=function(old.decode(), 'scenecore:package_swap_item', SWAP).encode()
    out=a.out/rel;out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(new)
    report={'path':rel,'before':hashlib.sha256(old).hexdigest(),'after':hashlib.sha256(new).hexdigest()}
    if a.apply and new!=old:
        backup=ROOT/'backups'/('round2-swap-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))/rel
        backup.parent.mkdir(parents=True,exist_ok=True);backup.write_bytes(old);assert path.read_bytes()==old;path.write_bytes(new);report['backup']=str(backup)
    (a.out/'manifest.json').write_text(json.dumps(report,indent=2));print('APPLIED' if a.apply else 'PLAN',report)
    rel='GameServer/lualib/item_operator.lua';path=ROOT/rel;old=path.read_bytes();new=function(old.decode(),'item_operator:move_item',MOVE).encode()
    out=a.out/rel;out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(new)
    report={'path':rel,'before':hashlib.sha256(old).hexdigest(),'after':hashlib.sha256(new).hexdigest()}
    if a.apply and new!=old:
        backup=ROOT/'backups'/('round2-move-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))/rel
        backup.parent.mkdir(parents=True,exist_ok=True);backup.write_bytes(old);assert path.read_bytes()==old;path.write_bytes(new);report['backup']=str(backup)
    (a.out/'move-manifest.json').write_text(json.dumps(report,indent=2));print('APPLIED' if a.apply else 'PLAN',report)
if __name__=='__main__':main()
