-- PetSoulXiShuXing: decimal row locks and GL/CY quality guarantees.
-- Fees/items follow scripts/obj/suzhou/osuzhou_yunshenshen.lua.
local M={costs={[0]=1,2,2,3,3,4,5},colors={
    [38002633]={[2]=3,[3]=3},[38002634]={[2]=4,[3]=4},[38002635]={[2]=5,[3]=5},
    [38002636]={[1]=3},[38002637]={[1]=4},[38002638]={[1]=5}}}
local function int(v,lo,hi)return type(v)=='number' and v%1==0 and v>=lo and v<=hi end
-- GL LuaFnGetPetSoulData("TIPS") uses these six colors, indexed by the
-- value intervals from PetSoulExtension (not the item's overall quality).
M.text_colors={'#W','#G','#B','#cCC33CC','#cFF9900','#Y'}
function M.text_color(row,value)
    if type(row)=='table' and type(value)=='number' then
        for band=6,1,-1 do
            if row[band*2-1] and value>=row[band*2-1] then return M.text_colors[band] end
        end
    end
    return '#W'
end
function M.locks(value,quality,old)
    if not int(value,0,111111) or not int(quality,0,3) then return end
    local visible=quality==0 and 4 or quality==1 and 5 or 6
    local locks,count,seen={},0,{}
    for i=1,6 do
        local bit=math.floor(value/10^(6-i))%10
        if bit>1 then return end
        if bit==1 then
            local a=old and old[i]
            if i>visible or not a or not int(a.type,0,255) or seen[a.type] then return end
            seen[a.type]=true;locks[i]=a.type;count=count+1
        end
    end
    return locks,count,visible
end
function M.generate(quality,old,value,colorCount,types,extension,random)
    local locks,count,visible=M.locks(value,quality,old)
    if not locks or not int(colorCount,0,visible) or type(types)~='table' or type(extension)~='table' then return end
    random=random or math.random
    local available,valid,locked={}, {}, {}
    for _,t in pairs(locks)do locked[t]=true end
    for _,t in ipairs(types)do
        if not int(t,0,127) or valid[t] then return end
        valid[t]=true
        local row=extension[t]
        if type(row)~='table' then return end
        for band=1,quality+3 do
            if not int(row[band*2-1],0,4294967295) or not int(row[band*2],row[band*2-1],4294967295) then return end
        end
        if not locked[t] then available[#available+1]=t end
    end
    for t in pairs(locked)do if not valid[t] then return end end
    if #available<visible-count then return end
    local result={}
    -- Generate exactly the visible rows. Generating six and truncating AFTER
    -- sorting discarded locked high-numbered attributes on four/five-row souls.
    for i=1,visible do
        local t=locks[i] or table.remove(available,random(1,#available))
        local row=extension[t];local band=random(1,quality+3)
        result[i]={type=t,value=random(row[band*2-1],row[band*2])}
    end
    local positions={};for i=1,visible do positions[i]=i end
    for i=1,colorCount do
        local pos=table.remove(positions,random(1,#positions));local a=result[pos];local row=extension[a.type]
        local band=quality+3;a.value=random(row[band*2-1],row[band*2])
    end
    table.sort(result,function(a,b)return a.type<b.type end)
    for i=visible+1,6 do result[i]={type=-1,value=0} end
    return result,count
end
return M
