-- Alternate GL transport. The original unsupported subtype12 stays disabled.
-- Deployment retains the explicit verification gate until native acceptance.
local M={ui_index=90160909}
function M.build(packet,config)
 assert(packet.GCUICommand and config.resolve.skill_templates)
 local mapped=config.resolve.skill_templates
 local allowed={}
 for _,p in ipairs({{3840,3842,1},{3842,3840,0},{3851,3846,1},
                    {3846,3847,1},{3846,3851,0},{3847,3851,0}})do
  local from,to=assert(mapped[p[1]]),assert(mapped[p[2]])
  allowed[from..':'..to..':'..p[3]]=true
 end
 local out={}
 if config.gl_ui_swap_verified~=true then return out end
 function out:swap_skill(owner,from,to,flag,extra)
  assert(extra==0 and allowed[from..':'..to..':'..flag],'unverified swap pair')
  if config.gameplay_enabled~=true or not owner or owner:get_obj_type()~='human' then return false end
  if owner:get_menpai()~=config.resolve.faction[14] or not owner:get_scene() then return false end
  -- Current on_study_xinfa learns all five templates in the two xinfa sets.
  -- Reject an incomplete character; never learn a skill to imitate a UI swap.
  if not owner:have_skill(from) or not owner:have_skill(to) then return false end
  local msg=packet.GCUICommand.new()
  msg.m_nUIIndex=M.ui_index;msg.unknow=0
  msg.m_Param.m_IntCount=4;msg.m_Param.m_StrCount=0
  msg.m_Param.m_aIntValue={from,to,flag,extra}
  owner:get_scene():send2client(owner,msg)
  return true
 end
 return out
end
return M
