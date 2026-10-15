-- UI-only packet contracts recovered from donor Serverhook/Server.
-- Never mutate learned skills or persistent MissionData to imitate UI swaps.
local M={}
function M.build_adapters(packet,options)
    assert(type(packet)=="table" and packet.GCMissionModify,"live packet classes required")
    options=options or {}
    local out={}
    function out:mission_param_changed(owner,field,seconds)
        assert(field==4514 or field==4515,"bounded171 UI field required")
        assert(math.tointeger(seconds),"integer seconds required")
        local msg=packet.GCMissionModify.new()
        msg.m_nFlag=1;msg.mission_id=field;msg.mission_index=seconds
        owner:get_scene():send2client(owner,msg)
        return true
    end
    -- Donor packet format is proved; GL subtype12 handler equivalence must be
    -- separately verified before enabling171. Omitting the method fails the
    -- engine's capability check instead of sending an unverified UI command.
    if options.client_stream12_verified==true then
        assert(packet.GCPacketStream,"live GCPacketStream required")
        function out:swap_skill(owner,from_skill,to_skill,flag,extra)
            assert(math.tointeger(from_skill) and math.tointeger(to_skill) and math.tointeger(flag) and math.tointeger(extra),"integer packet fields required")
            local msg=packet.GCPacketStream.new();msg.id=12
            msg.args=string.pack("<i4i4i4i4",flag,from_skill,to_skill,extra)
            owner:get_scene():send2client(owner,msg)
            return true
        end
    end
    return out
end
return M
