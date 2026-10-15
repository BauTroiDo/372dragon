-- Use the already supported mission-tip packet; no shared rage/MP field reuse.
local M={}
function M.snapshot(owner)
 local faction=owner:get_menpai()
 local id,base,label
 if faction==13 then id,base,label=328,10000,'Cong tinh'
 elseif faction==14 then id,base,label=331,10,'Dao y'
 else return end
 local value=owner:get_cy_four_resource(id)
 local cap,current=value//base,value%base
 if cap==0 then cap=faction==13 and 1000 or 3 end
 return label,current,cap
end
function M.notify(owner,force)
 if type(owner.notify_tips)~='function' then return end
 local label,current,cap=M.snapshot(owner);if not label then return end
 local bucket=owner:get_menpai()==13 and math.floor(current/250) or current
 local key=label..':'..bucket..':'..cap
 if force or owner._cy_four_resource_tip~=key then
  owner._cy_four_resource_tip=key
  owner:notify_tips(string.format('%s: %d/%d',label,current,cap))
 end
end
return M
