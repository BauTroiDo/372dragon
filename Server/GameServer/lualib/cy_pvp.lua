-- CY school identities -> the runtime's GL-indexed AttackTraits table.
local M = {}
local traits = {[0]=0,1,2,3,4,5,6,7,8,9,16,17,18,19,20,15}
function M.trait(menpai) return traits[menpai] or 9 end
function M.mode(mode) return type(mode)=='number' and mode%1==0 and mode>=0 and mode<=5 end

-- Invitations are scene-local, short-lived capabilities bound to both GUIDs.
-- Object IDs alone can be reused after a player disconnects.
local function human(obj) return obj and obj:get_obj_type()=='human' end
function M.ready(scene, a, b)
    if not human(a) or not human(b) or a==b or not a:is_alive() or not b:is_alive() then return false end
    if not scene.scriptenginer:call(806010,'HaveChallengeFlag',a:get_obj_id())
        or not scene.scriptenginer:call(806010,'HaveChallengeFlag',b:get_obj_id()) then return false end
    local flag=require('define').MD_ENUM.MD_TIAOZHAN_SCRIPT
    if a:get_mission_data_by_script_id(flag) ~= b:get_mission_data_by_script_id(flag) then return false end
    if (a:get_team_id()~=-1 and not a:get_is_team_leader())
        or (b:get_team_id()~=-1 and not b:get_is_team_leader()) then return false end
    if a:get_team_id()~=-1 and a:get_team_id()==b:get_team_id() then return false end
    return true
end
function M.challenge(scene, who, req)
    local a=scene.objs[who]
    local b=req and scene.objs[req.m_objID]
    if not human(a) or not human(b) or a==b then return false end
    local now=require('skynet').time()
    if req.type==0 then
        if b:get_team_id()~=-1 then b=scene:get_obj_by_guid(b:get_team_info():get_team_leader()) end
        if not M.ready(scene,a,b) then a:notify_tips('Hai bên phải ở cùng lôi đài, còn sống và do đội trưởng thách đấu.');return false end
        local pending=b.cys_challenge_pending
        if pending and pending.expires>now then a:notify_tips('Đối phương đang có lời mời thách đấu.');return false end
        b.cys_challenge_pending={from=a:get_guid(),to=b:get_guid(),object=who,expires=now+30}
        local packet=require('game.packet').GCChallenge.new()
        packet.type=1;packet.m_objID=who
        for _,v in ipairs(scene:get_team_challenge_members(a)) do
            if #packet.member_list<6 then packet.member_list[#packet.member_list+1]=scene:make_challenge_member(v) end
        end
        scene:send2client(b,packet)
        return true
    elseif req.type==1 or req.type==2 then
        local pending=a.cys_challenge_pending
        if not pending or pending.from~=b:get_guid() or pending.to~=a:get_guid()
            or pending.object~=req.m_objID then return false end
        a.cys_challenge_pending=nil
        if pending.expires<=now then a:notify_tips('Lời mời thách đấu đã hết hạn.');return false end
        if req.type==2 then b:notify_tips('Đối phương đã từ chối thách đấu.');return true end
        if not M.ready(scene,a,b) then a:notify_tips('Điều kiện lôi đài đã thay đổi.');return false end
        -- Consume before calling the instance allocator, which may yield.
        scene.scriptenginer:call(806010,'ProcChallenge',b:get_obj_id(),a:get_obj_id())
        return true
    end
    return false
end
return M
