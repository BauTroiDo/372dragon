-- Store the base skill when a player drags a temporary Jue skill.
-- CGModifySetting slot encoding is recovered from GL1401e0a50. No changes to
-- title/chat settings, item slots, learned skills, or the packet argument.
local M={}
function M.setting(owner,modify,config)
 local original=modify.setting
 if config.gameplay_enabled~=true or config.gl_ui_swap_verified~=true then return original end
 if not owner or owner:get_menpai()~=config.resolve.faction[14] or original.type~=1 then return original end
 local key=modify.type
 if type(key)~='number' or key%1~=0 or not ((key>=2 and key<=50) or (key>=99 and key<=107) or (key>=83 and key<=92)) then return original end
 local m=config.resolve.skill_templates
 local base=({[m[3842]]=m[3840],[m[3846]]=m[3851],[m[3847]]=m[3851]})[original.data]
 if not base or not owner:have_skill(base) then return original end
 return {type=1,data=base}
end
return M
