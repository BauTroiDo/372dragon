-- packet_domains/misc.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)
    --请求团队成员信息
    packet.CGAskRaidMemberInfo = {
        xy_id = packet.XYID_CGAskRaidMemberInfo,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAskRaidMemberInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.guid = stream:readint()
            self.sceneid = stream:readshort()
        end
    }


    --通知客户端团队成员位置调整
    packet.GCRetRaidModifyMemberPosition = {
        xy_id = packet.XYID_GCRetRaidModifyMemberPosition,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRetRaidModifyMemberPosition})
            o:ctor()
            return o
        end,
        ctor = function(self) 
    		self.m_yOk = 0
    		self.raid_id = -1
    		self.m_OperateGUID = -1		--操作GUID
    		self.m_sSquadIndex = -1		--源小队ID
    		self.m_sMemIndex = -1		--源小队内位置

    		self.m_dSquadIndex = -1
    		self.m_dMemIndex = -1
    	end,
        bis = function(self, buffer)
        end,
        bos = function(self)
    		local stream = bostream.new()
    		stream:writechar(self.m_yOk)
    		stream:writeint(self.m_OperateGUID)
    		stream:writeshort(self.raid_id)

    		stream:writeshort(self.m_sSquadIndex)
    		stream:writeint(self.m_sMemIndex)

    		stream:writeshort(self.m_dSquadIndex)
    		stream:writeint(self.m_dMemIndex)

            return stream:get()
        end
    }

    --请求团队信息
    packet.CGAskRaiInfo = {
        xy_id = packet.XYID_CGAskRaiInfo,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskRaiInfo})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end,
        bos = function(self)
        end
    }


    --请求排行榜内容
    packet.CGWNormalRankingList = {
    	xy_id = packet.XYID_CGW_NORMAL_RANKING_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGWNormalRankingList})
            o:ctor()
            return o
        end,
        ctor = function(self)

        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
    		--需要测试打印
    		-- local skynet = require "skynet"
    		local nDataCount = stream:readint()	--max=10
    		-- skynet.logi("data 1",nDataCount)
    		-- skynet.logi("data 2",stream:readint())
    		-- skynet.logi("data 3",stream:readint())
    		-- skynet.logi("data 4",stream:readint())
    		-- skynet.logi("data 5",stream:readint())
    		-- for i = 1,nDataCount do
    			-- skynet.logi("for data",stream:readint())
    		-- end
        end,
        bos = function(self)
        end
    }


    --雕纹纹刻效果显示
    packet.GCDiaowenFeatureSkill = {
        xy_id = packet.XYID_GC_DIAOWEN_FEATURESKILL,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDiaowenFeatureSkill})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.objId = -1
    		self.effect_id = -1	--对应DWJinJieTeXing.txt内的第一列
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
    		stream:writeuint(self.objId)
    		stream:writeuint(self.effect_id)
            return stream:get()
        end
    }


    packet.GCSecWeaponAddSkillList = {
        xy_id = packet.XYID_GC_SECWEAPON_ADDSKILLLIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCSecWeaponAddSkillList})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.selfId = 0
    		self.skillId = {-1,-1,-1,-1,-1,-1,-1}	--对应七情刃的7个技能
    		self.commonskillA = -1	--通法上卷技能
    		self.commonskillB = -1	--通法下卷技能
    		self.is_hide = 0		--进入副武器技能周期开写0，周期结束写1
    		self.is_update = 1		--一直保持为TRUE
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
    		stream:writeuint(self.selfId)
    		for i = 1,7 do
    			stream:writeint(self.skillId[i])
    		end
    		stream:writeshort(self.commonskillA)
    		stream:writeshort(self.commonskillB)
    		stream:writechar(self.is_hide)
    		stream:writechar(self.is_update)
            return stream:get()
        end
    }


    packet.KeyExchange = {
        xy_id = packet.XYID_KEY_EXCHANGE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.KeyExchange})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.len = 0
            self.data = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.len = stream:readushort()
            for i = 1, self.len do self.data[i] = stream:readuchar() end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(#self.data)
            for _, d in ipairs(self.data) do stream:writeuchar(d) end
            return stream:get()
        end
    }


    packet.GCUseGemResult = {
        xy_id = packet.XYID_GC_USEGEMRESULT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCUseGemResult})
            o:ctor()
            return o
        end,
        ctor = function(self) self.result = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.result)
            return stream:get()
        end
    }


    packet.GCRemoveGemResult = {
        xy_id = packet.XYID_GC_REMOVEGEMRESULT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRemoveGemResult})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.result = 0
            self.gem_index = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readuint()
            self.gem_index = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.result)
            stream:writeuint(self.gem_index)
            return stream:get()
        end
    }


    packet.CGCharMoodState = {
        xy_id = packet.XYID_CG_CHAR_MOOD_STATE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharMoodState})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.mode_state = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.mode_state = stream:readuchar()
        end
    }


    packet.CGChangePkModeReq = {
        xy_id = packet.XYID_CG_CHANGE_PK_MODE_REQ,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGChangePkModeReq})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.pk_mode = 0
            self.unknow_2 = ""
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.pk_mode = stream:readuchar()
            self.unknow_2 = stream:read(0x1F)
        end
    }


    packet.CGCharUseSkill = {
        xy_id = packet.XYID_CG_CHARUSESKILL,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharUseSkill})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.skillID = 0
            self.guidTarget = 0
            self.targetObjID = 0
            self.posTarget = {x = 0, y = 0}
            self.dir = 0.0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.dir = stream:readfloat()
            self.skillID = stream:readint()
            self.target = stream:readint()
            self.m_objID = stream:readuint()
            self.targetObjID = stream:readint()
            self.posTarget.x = stream:readfloat()
            self.posTarget.y = stream:readfloat()
        end
    }


    packet.CGCharDefaultEvent = {
        xy_id = packet.XYID_CG_CHARDEFAULTEVENT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharDefaultEvent})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.targetID = 0
        end,
        equal = function(self, other)
            return self.m_objID == other.m_objID and self.targetID == other.targetID
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.targetID = stream:readuint()
        end
    }


    packet.GCNewPlatform = {
        xy_id = packet.XYID_GC_NEW_PLATFORM,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCNewPlatform})
            o:ctor()
            return o
        end, 
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream    = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.world_pos = {}
            self.world_pos.x = stream:readfloat()
            self.world_pos.y = stream:readfloat()
            self.dir = stream:readfloat()
            self.class = stream:readuchar()
            local size = stream:readuchar()
            if size > 0 and size < 0x20 then
                self.desc = stream:read(size)
            end
            self.desc = gbk.toutf8(self.desc)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writefloat(self.dir)
            stream:writeuchar(self.class)
            -- FIX 2026-09-04: client GCNewPlatform::Read (Game.exe 0x14067b010) chi nhan
            -- desc dai 1..31 byte. inireader da chuyen Tip sang UTF-8 (ban che tao = 42 byte)
            -- => client bo doc chuoi => "Read Packet Size error[378]". Cat an toan <= 31 byte.
            local desc = gbk.fromutf8(self.desc or "")
            if #desc > 0x1f then
                desc = gbk.truncate_utf8_bytes(desc, 0x1f)
            end
            self.desc = desc
            local len = string.len(desc)
            stream:writeuchar(len)
            stream:write(desc, len)
            return stream:get()
        end
    }


    packet.GCNotifyMail = {
        xy_id = packet.XYID_GC_NOTIFY_MAIL,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCNotifyMail})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_MailCount = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_MailCount = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            self.m_MailCount = self.m_MailCount > define.UCHAR_MAX and define.UCHAR_MAX or self.m_MailCount
            stream:writeuchar(self.m_MailCount)
            return stream:get()
        end
    }


    packet.WGCCTUGabrielCommond = {
        xy_id = packet.XYID_WGC_CTU_GABRIEL_COMMOND,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.WGCCTUGabrielCommond})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.len = 0
            self.data = ""
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readushort()
            self.len = stream:readushort()
            self.data = stream:read(self.len)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.unknow_1)
            stream:writeushort(self.len)
            stream:write(self.data, self.len)
            return stream:get()
        end
    }


    packet.CGAskDetailAbilityInfo = {
        xy_id = packet.XYID_CG_ASK_DETAIL_ABILITY_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskDetailAbilityInfo})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end
    }


    packet.CGWuhunWG = {
        xy_id = packet.XYID_CG_WUHUN_WG,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGWuhunWG})
            o:ctor()
            return o
        end,
        ctor = function(self)end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuint()
            if self.type == 0 or self.type == 1 then
                self.targetId = stream:readint()
            elseif self.type == 2 then
                self.huanhun_id = stream:readshort()
                self.qiankun = stream:readint()
            elseif self.type == 3 then
                self.unknow_3 = stream:readshort()
            end
        end
    }


    packet.CGAskDetailSkillList = {
        xy_id = packet.XYID_CG_ASK_DETAIL_SKILL_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskDetailSkillList})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end
    }


    packet.CGAutoCreateTeam = {
        xy_id = packet.XYID_CG_AUTO_CREATE_TEAM,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAutoCreateTeam})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:readuint()
        end
    }


    packet.CGCharAllTitles = {
        xy_id = packet.XYID_CG_CHAR_ALL_TITLES,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharAllTitles})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end
    }


    packet.CGAskServerTime = {
        xy_id = packet.XYID_CG_ASK_SERVER_TIME,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskServerTime})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
            self.unknow_2 = stream:readuint()
        end
    }


    packet.CGMinorPasswd = {
        xy_id = packet.XYID_CG_MINOR_PASSWD,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.CGMinorPasswd})
            o:ctor()
            return o
        end,
        ctor = function(self) self.flag = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.flag = stream:readuchar()
            local FLAG = define.MINORPASSWD_REQUEST_TYPE
            if self.flag == FLAG.MREQT_SETPASSWD or self.flag == FLAG.MREQT_UNLOCKPASSWD then
                local password_size = stream:readuchar()
                if password_size > 0 and password_size < 0x11 then
                    self.password = stream:read(password_size)
                end
            elseif self.flag == FLAG.MREQT_MODIFYPASSWD then
                local old_password_size = stream:readuchar()
                if old_password_size > 0 and old_password_size < 0x11 then
                    self.old_password = stream:read(old_password_size)
                end
                local new_password_size = stream:readuchar()
                if new_password_size > 0 and new_password_size < 0x11 then
                    self.new_password = stream:read(new_password_size)
                end
            end
        end
    }


    packet.CGAskDetailEquipList = {
        xy_id = packet.XYID_CG_ASK_DETAIL_EQUIP_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskDetailEquipList})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end
    }


    packet.CGAskMyBagSize = {
        xy_id = packet.XYID_CG_ASK_MY_BAG_SIZE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskMyBagSize})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.CGAskSetting = {
        xy_id = packet.XYID_CG_ASK_SETTING,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskSetting})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.CGBankMoney = {
        xy_id = packet.XYID_CG_BANK_MONEY,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGBankMoney})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow_1 = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.op = stream:readuchar()
            self.money = stream:readuint()
        end
    }


    packet.CGAskMail = {
        xy_id = packet.XYID_CG_ASK_MAIL,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskMail})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_askType = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_askType = stream:readuchar()
        end
    }


    packet.CGWAskAladdinToken = {
        xy_id = packet.XYID_CGW_ASK_ALADDIN_TOKEN,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGWAskAladdinToken})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow_1 = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
        end
    }


    packet.CG_Unknow_0431 = {
        xy_id = packet.XYID_CG_UNKNOW_0431,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CG_Unknow_0431})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.GCCharImpactListUpdate = {
        xy_id = packet.XYID_GC_CHAR_IMPACT_LIST_UPDATE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharImpactListUpdate})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_nOwnerID = 0
            self.unknow_1 = 0
            self.size = 0
            self.m_aImpact = {}
            self.unknow_2 = 0xffff
        end,
        bis = function(self, buffer)
            local stream    = bistream.new()
            stream:attach(buffer)
            self.m_nOwnerID = stream:readuint()
            self.unknow_1 = stream:readuint()
            self.size = stream:readushort()
            if self.size > 30 then
                self.size = 30
            end
            if self.size > 0 then
                for i = 1, self.size do
                    local l = {}
                    l.bufferid = stream:readushort()
                    l.sender = stream:readuint()
                    l.index = stream:readuint()
                    table.insert(self.m_aImpact, l)
                end
            end
            self.unknow_2 = stream:readushort()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_nOwnerID)
            stream:writeuint(self.unknow_1)
            stream:writeushort(self.size)
            if self.size > 30 then
                self.size = 30
            end
            if self.size > 0 then
                for i = 1, self.size do
                    self.m_aImpact[i] = self.m_aImpact[i]
                    stream:writeshort(self.m_aImpact[i].buffer_id)
                    stream:writeuint(self.m_aImpact[i].sender)
                    stream:writeuint(self.m_aImpact[i].index)
                end
            end
            stream:writeushort(self.unknow_2)
            return stream:get()
        end
    }


    packet.GCRMBChatFaceInfo = {
        xy_id = packet.XYID_GC_RMB_CHAT_FACE_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRMBChatFaceInfo})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.id = stream:readuint()
            for i = 1, 4 do self.list[i] = stream:readuint() end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.id)
            for i = 1, 4 do
                self.dates[i] = self.dates[i] or 0
                stream:writeuint(self.dates[i])
            end
            return stream:get()
        end
    }


    packet.GCDoubleExpInfo = {
        xy_id = packet.XYID_GC_DOUBLE_EXP_INFO,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCDoubleExpInfo})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_3 = 0
        end,
        bis = function(self, buffer)
            local stream    = bistream.new()
            stream:attach(buffer)
            self.available_hour = stream:readuint()
            self.is_lock = stream:readuint()
            self.money_time = stream:readuint()
            self.total_time = stream:readuint()
            self.rtime = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.available_hour)   -- offset 24, 4B
            stream:writeuint(self.is_lock)           -- offset 28, 4B
            stream:writeuint(self.money_time)        -- offset 32, 4B
            -- total_time 从4B扩展为8B (uint64 little-endian)
            stream:writeuint(self.total_time)        -- offset 36, 低4B
            stream:writeuint(0)                      -- offset 40, 高4B
            -- rtime 从4B扩展为8B (uint64 little-endian)
            stream:writeuint(self.rtime)             -- offset 44, 低4B
            stream:writeuint(0)                      -- offset 48, 高4B
            -- 新增字段 8B
            stream:writeuint(0)                      -- offset 52
            stream:writeuint(0)                      -- offset 56
            -- 新增字段 4B + 4B
            stream:writeuint(0)                      -- offset 60
            stream:writeuint(0)                      -- offset 64
            return stream:get()
        end
    }


    packet.GCJuqingPoint = {
        xy_id = packet.XYID_GC_JUQING_POINT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCJuqingPoint})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow_1 = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow_1)
            return stream:get()
        end
    }


    packet.GCCooldownUpdate = {
        xy_id = packet.XYID_GC_COOLDOWN_UPDATE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCooldownUpdate})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_uHighSection = 0
            self.m_uLowSection = 0

            self.m_nNumCooldown = 0
            self.m_aCooldowns = {}
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_uHighSection)
            stream:writeuint(self.m_uLowSection)
            stream:writeushort(self.m_nNumCooldown)
            for i = 1, self.m_nNumCooldown do
                self.m_aCooldowns[i] = self.m_aCooldowns[i] or
                                           {
                        m_nID = 0,
                        m_nCooldown = 0,
                        m_nCooldownElapsed = 0
                    }
                stream:writeint(self.m_aCooldowns[i].m_nID)
                self.m_aCooldowns[i].m_nCooldown = self.m_aCooldowns[i].m_nCooldown < 0 and 0 or self.m_aCooldowns[i].m_nCooldown
                stream:writeuint(self.m_aCooldowns[i].m_nCooldown)
                stream:writeuint(self.m_aCooldowns[i].m_nCooldownElapsed)
            end
            return stream:get()
        end
    }


    packet.GCDetailAbilityInfo = {
        xy_id = packet.XYID_GC_DETAIL_ABILITY_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDetailAbilityInfo})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_uAbilityIDList = {}
            self.m_aAbility = {}
            self.m_aPrescr = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.m_wNumAbility = stream:readuchar()
            if self.m_wNumAbility > 0 and self.m_wNumAbility < 0x40 then
                for i = 1, self.m_wNumAbility do
                    self.m_uAbilityIDList[i] = stream:readuchar()
                end
                for i = 1, self.m_wNumAbility do
                    local ability = {}
                    ability.m_Level = stream:readuint()
                    ability.m_Exp = stream:readuint()
                    table.insert(self.m_aAbility, ability)
                end
            end
            for i = 1, 0x100 do self.m_aPrescr[i] = stream:readuchar() end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuchar(self.m_wNumAbility)
            if self.m_wNumAbility > 0 and self.m_wNumAbility < 0x40 then
                for i = 1, self.m_wNumAbility do
                    stream:writeuchar(self.m_uAbilityIDList[i])
                end
                for i = 1, self.m_wNumAbility do
                    self.m_aAbility[i] = self.m_aAbility[i] or
                                             {m_Level = 0, m_Exp = 0}
                    stream:writeuint(self.m_aAbility[i].m_Level)
                    stream:writeuint(self.m_aAbility[i].m_Exp)
                end
            end
            for i = 1, 0x100 do stream:writeuchar(self.m_aPrescr[i]) end
            return stream:get()
        end
    }


    packet.GCDetailXinFaList = {
        xy_id = packet.XYID_GC_DETAIL_XINFA_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDetailXinFaList})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.m_wNumXinFa = 0
            self.m_aXinFa = {}
            self.unknow = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.m_wNumXinFa = stream:readushort()
            if self.m_wNumXinFa > 0 and self.m_wNumXinFa < 0x10 then
                for i = 1, self.m_wNumXinFa do
                    local xinfa = {}
                    xinfa.m_nXinFaID = stream:readuint()
                    xinfa.m_nXinFaLevel = stream:readuint()
                    table.insert(self.m_aXinFa, xinfa)
                end
            end
            self.unknow = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeushort(self.m_wNumXinFa)
            if self.m_wNumXinFa > 0 and self.m_wNumXinFa < 0x10 then
                for i = 1, self.m_wNumXinFa do
                    self.m_aXinFa[i] = self.m_aXinFa[i] or
                                             {m_nXinFaID = 0, m_nXinFaLevel = 0}
                    stream:writeuint(self.m_aXinFa[i].m_nXinFaID)
                    stream:writeuint(self.m_aXinFa[i].m_nXinFaLevel)
                end
            end
            stream:writeuint(self.unknow)
            return stream:get()
        end
    }


    packet.GCDetailXiulianList = {
        xy_id = packet.XYID_GC_DETAIL_XIULIAN_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDetailXiulianList})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.xiulian = {}
            self.unknow_2 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            for i = 1, 15 do self.xiulian[i] = {level=stream:readushort()} end
            for i = 1, 15 do self.xiulian[i].upper_limit=stream:readushort() end
            self.unknow_2 = stream:readuint()
            self.activated = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            for i = 1, 15 do
                local xiulian = self.xiulian[i]
                stream:writeushort(xiulian.level)
            end
            for i = 1, 15 do
                local xiulian = self.xiulian[i]
                stream:writeushort(xiulian.upper_limit)
            end
            stream:writeuint(self.unknow_2)
            stream:writeuint(self.activated or 0)
            return stream:get()
        end
    }


    packet.GCSectDetail = {
        xy_id = packet.XYID_GC_SECT_DETAIL,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCSectDetail})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readint()
            self.understand_point = stream:readint()
            self.talent_type = stream:readint()
            self.unknow_4 = stream:readint()
            for i = 1, 30 do
                local l = {}
                l.id = stream:readshort()
                l.level = stream:readuchar()
                table.insert(self.list, l)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.talent_type)
            stream:writeuint(self.understand_point)
            stream:writeuint(self.show_type)
            stream:writeuint(self.unknow_4 or 0)
            for i = 1, 30 do
                local talent_study = self.list[i]
                if talent_study then
                    stream:writeshort(talent_study.id)
                    stream:writeuchar(talent_study.level)
                else
                    stream:writeshort(-1)
                    stream:writeuchar(0)
                end
            end
            return stream:get()
        end
    }


    packet.GCWuhunWG = {
        xy_id = packet.XYID_GC_WUHUN_WG,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCWuhunWG})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unlockd = {}
        end,
        bis = function(self, buffer)
            local stream    = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuint()
            if self.type == 0 or self.type == 1 then
                self.wg = stream:readint()
            else
                self.huanhun_id = stream:readshort()
            end
            self.huanhun_unlock_count= stream:readuint()
            for i = 1, self.huanhun_unlock_count do
                local huanhun = {}
                huanhun.id = stream:readushort()
                huanhun.level = stream:readushort()
                huanhun.grade = stream:readushort()
                huanhun.today_count = stream:readushort()
                table.insert(self.unlockd, huanhun)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.type)
            if self.type == 0 or self.type == 1 then
                stream:writeint(self.wg)
            else
                stream:writeshort(self.huanhun_id)
            end
            stream:writeuint(self.huanhun_unlock_count)
            for i = 1, self.huanhun_unlock_count do
                local huanhun = self.unlockd[i]
                stream:writeushort(huanhun.id)
                stream:writeushort(huanhun.level)
                stream:writeushort(huanhun.grade)
                stream:writeushort(huanhun.today_count)
                -- table.insert(self.unlockd, huanhun)
            end
            return stream:get()
        end
    }


    packet.GCDetailSkillList = {
        xy_id = packet.XYID_GC_DETAIL_SKILL_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDetailSkillList})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.m_wNumSkill = 0
            self.m_aSkill = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.m_wNumSkill = stream:readushort()
            if self.m_wNumSkill > 0 and self.m_wNumSkill < 0x80 then
                for i = 1, self.m_wNumSkill do
                    self.m_aSkill[i] = stream:readuint()
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeushort(self.m_wNumSkill)
            if self.m_wNumSkill > 0 and self.m_wNumSkill < 0x80 then
                for i = 1, self.m_wNumSkill do
                    self.m_aSkill[i] = self.m_aSkill[i] or 0
                    stream:writeuint(self.m_aSkill[i])
                end
            end
            return stream:get()
        end
    }


    packet.GCCharAllTitles = {
        xy_id = packet.XYID_GC_CHAR_ALL_TITLES,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharAllTitles})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.m_nTitleId = 0
            self.m_nTitleStr = 0
            self.m_TitleIdList = {}
            self.m_TitleStrList = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.m_nTitleId = stream:readuchar()
            self.m_nTitleStr = stream:readuchar()
            if self.m_nTitleId > 0x86 then self.m_nTitleId = 0x86 end
            if self.m_nTitleStr > 0x10 then self.m_nTitleStr = 0x10 end
            if self.m_nTitleId > 0 then
                for i = 1, self.m_nTitleId do
                    local l = {}
                    l.unknow_1 = stream:readuint()
                    l.unknow_2 = stream:readuint()
                    l.unknow_3 = stream:readuint()
                    table.insert(self.m_TitleIdList, l)
                end
            end
            if self.m_nTitleStr > 0 then
                for i = 1, self.m_nTitleStr do
                    local l = {}
                    l.unknow_1 = stream:readuint()
                    l.size = stream:readuchar()
                    l.unknow_2 = stream:readuint()
                    l.unknow_3 = stream:readuint()
                    if l.size < 0x22 then
                        l.unknow_4 = stream:read(l.size)
                    end
                    table.insert(self.m_TitleStrList, l)
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuchar(self.m_nTitleId)
            stream:writeuchar(self.m_nTitleStr)
            if self.m_nTitleId > 0x86 then self.m_nTitleId = 0x86 end
            if self.m_nTitleStr > 0x10 then self.m_nTitleStr = 0x10 end
            if self.m_nTitleId > 0 then
                for i = 1, self.m_nTitleId do
                    local title = self.m_TitleIdList[i] 
                    stream:writeuint(0)
                    stream:writeuint(title.id)
                    stream:writeuint(title.remain_time or 0)
                end
            end
            if self.m_nTitleStr > 0 then
                for i = 1, self.m_nTitleStr do
                    local title = self.m_TitleStrList[i]
                    stream:writeuint(title.id)
                    title.str = gbk.fromutf8(title.str)
                    local len = string.len(title.str)
                    stream:writeuchar(len)
                    stream:writeuint(0)
                    stream:writeuint(0)
                    if len < 0x22 then
                        stream:write(title.str, len)
                    end
                end
            end
            return stream:get()
        end
    }


    packet.GCExteriorInfo = {
        xy_id = packet.XYID_GC_EXTERIOR_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCExteriorInfo})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        read_extrior_list = function(self, stream)
            self.extrior_count = stream:readuint()
            if self.extrior_list > 0 then
                self.rider_list = {}
                for i = 1, self.extrior_count do
                    self.extrior_list[i] = {}
                    self.extrior_list[i].id = stream:readushort()
                    self.extrior_list[i].remindtime = stream:readint()
                    self.extrior_list[i].unknow_3 = stream:readuchar()
                end
            end
        end,
        read_sub_2 = function(self, stream)
            self.sub_2_unknow_1 = stream:readushort()
            self.sub_2_unknow_2 = stream:readushort()
            self.sub_2_unknow_3 = stream:readushort()
            self.sub_2_unknow_4 = stream:readushort()
            self.sub_2_unknow_5 = stream:readushort()
            self.sub_2_unknow_6 = stream:readuint()
            self.sub_2_unknow_7 = stream:readushort()
            self.extrior_weapon_visual_id = stream:readushort()
            self.extrior_weapon_visual_level = stream:readushort()
    		self.extrior_soul_ranse = stream:readushort()
    		self.exterior_back_id = stream:readushort()
    		self.exterior_head_id = stream:readushort()
    		self.exterior_back_pos = stream:readint()
    		self.exterior_head_pos = stream:readint()
        end,
        read_weapon_visual = function(self, stream)
            local visual = {}
            visual.id = stream:readushort()
            visual.term = stream:readint()
            visual.unknow_1 = stream:readchar()
            visual.level = stream:readuchar()
            table.insert(self.weapon_visuals, visual)
        end,
        write_extrior_list = function(self, stream)
            stream:writeuint(self.extrior_count or 0)
            if self.extrior_count > 0 then
                for i = 1, self.extrior_count do
                    stream:writeushort(self.extrior_list[i].id)
                    stream:writeint(self.extrior_list[i].remindtime)
                    stream:writeuchar(self.extrior_list[i].unknow_3)
                end
            end
        end,
        write_sub_2 = function(self, stream)
            stream:writeshort(self.sub_2_unknow_1 or -1)
            stream:writeshort(self.sub_2_unknow_2 or -1)
            stream:writeshort(self.sub_2_unknow_3 or -1)
            stream:writeshort(self.sub_2_unknow_4 or -1)
            stream:writeshort(self.sub_2_unknow_5 or -1)
            stream:writeint(self.sub_2_unknow_6 or -1)
            stream:writeshort(self.sub_2_unknow_7 or -1)
            stream:writeshort(self.extrior_weapon_visual_id)
            stream:writeshort(self.extrior_weapon_visual_level)
    		--2 默认-1 兽魂染色数据 如果数据是131，则外观id是13 1为颜色
    		stream:writeshort(self.extrior_soul_ranse or -1)
    		--当前背饰
    		stream:writeshort(self.exterior_back_id)
    		--当前头饰
    		stream:writeshort(self.exterior_head_id)
    		--当前背饰位置
    		stream:writeint(self.exterior_back_pos or 0)	--CurOrnamentsBackPos
    		--当前头饰位置
    		stream:writeint(self.exterior_head_pos or 0)	--CurOrnamentsHeadPos
        end,
        write_weapon_visual = function(self, stream, visual)
            stream:writeushort(visual.id)
            stream:writeint(visual.term)
            stream:writeuchar(0)
            stream:writeuchar(visual.level)
        end,
        -- GCExteriorInfo 中该字段是发色方案数量，不是当前选中的发色索引。
        write_hair_colors = function(self, stream)
            local count = self.exterior_hair_color_index or 0
            stream:writeuint(count)
            for i = 1, 20 do
                local hair_color = self.hair_colors[i] or { value = 0 }
                stream:writeint(hair_color.value or 0)
                stream:writeuchar(0)
            end
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.type)
            stream:writeuint(self.unknow_2)
            if self.type == 0 then
                for i = 1, 5 do
                    stream:writeuint(self.list_1[i].size)
                    if self.list_1[i].size > 0 then
                        for j = 1, self.list_1[i].size do
                            stream:writeushort(self.list_1[i].list[j].unknow_1)
                            stream:writeint(self.list_1[i].list[j].unknow_2)
                            stream:writeuchar(self.list_1[i].list[j].unknow_3)
                        end
                    end
                end
                self:write_hair_colors(stream)
                stream:writeuint(self.weapon_visual_count)
                if self.weapon_visual_count > 0 then
                    for i = 1, self.weapon_visual_count do
                        local visual = self.weapon_visuals[i]
                        self:write_weapon_visual(stream, visual)
                    end
                end
            end
            if self.type == 1 then
                self:write_extrior_list(stream)
            elseif self.type == 2 then
                self:write_extrior_list(stream)
            elseif self.type == 3 then
                self:write_extrior_list(stream)
            elseif self.type == 4 then
                self:write_extrior_list(stream)
            elseif self.type == 7 then
                self:write_extrior_list(stream)
            end
            if self.type ~= 5 then
                if self.type == 6 then
                    self:write_sub_2(stream)
                elseif self.type == 8 then
                    stream:writeuint(self.weapon_visual_count)
                    if self.weapon_visual_count > 0 then
                        for i = 1, self.weapon_visual_count do
                            local visual = self.weapon_visuals[i]
                            self:write_weapon_visual(stream, visual)
                        end
                    end
                end
            else
                self:write_hair_colors(stream)
            end
            return stream:get()
        end
    }


    packet.GCAskFashionDepotData = {
        xy_id = packet.XYID_GC_ASK_FASHION_DEPOT_DATA,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCAskFashionDepotData})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
            self.size = 0
            self.unknow_3 = 0
            self.list = {}
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow_1)
            stream:writeuint(self.unknow_2)
            stream:writeuint(self.size)
            self.size = self.size > 100 and 100 or self.size
            if self.size > 0 then
                for i = 1, self.size do
                    local fashion = self.list[i]
                    stream:writeint(fashion.item_index or define.INVAILD_ID)
                    stream:writeuchar(fashion.quality)
                    stream:writeushort(fashion.visual)
                    for j = 1, 4 do
                        stream:writeuchar(0)
                    end
                    -- FashionDepotElement +11 maps to ItemInfo +81 (slot_count).
                    stream:writeuchar(fashion.slot_count or 0)
                    local gems = fashion.list_2 or {}
                    for j = 1, 3 do
                        stream:writeint(gems[j] or 0)
                    end
                    stream:writeuchar(0)
                end
            end
            stream:writeuchar(self.open_editor or 0)
            return stream:get()
        end
    }


    packet.GCAskServerTime = {
        xy_id = packet.XYID_GC_ASK_SERVER_TIME,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCAskServerTime})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.year = 0 -- 0x7e6
            self.month = 0 -- 0x7
            self.day = 0 -- 0x1c
            self.hour = 0 -- 0xf
            self.min = 0 -- 0x31
            self.sec = 0 -- 0x2b
            self.secneid = 0 -- 0x2
            self.servertime = 0 -- 0x630b1e17  1661672983 2022-08-28 15:49:43
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.year = stream:readushort()
            self.month = stream:readuchar()
            self.day = stream:readuchar()

            self.hour = stream:readuchar()
            self.min  = stream:readuchar()
            self.sec = stream:readuchar()
            self.secneid = stream:readuint()
            self.servertime = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.year)
            stream:writeuchar(self.month)
            stream:writeuchar(self.day)
            stream:writeuchar(self.hour)
            stream:writeuchar(self.min )
            stream:writeuchar(self.sec)
            stream:writeuint(self.secneid)
            stream:writeuint(self.servertime)
            return stream:get()
        end
    }


    packet.GCMinorPasswd = {
        xy_id = packet.XYID_GC_MINOR_PASSWD,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCMinorPasswd})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_ReturnSetup = {}
            self.m_ReturnDeleteTime = {}
        end,
        bis = function(self, buffer)
            local stream    = bistream.new()
            stream:attach(buffer)
            self.m_Type = stream:readuchar()
            if self.m_Type == 0x1 or self.m_Type == 0xE then
                self.m_ReturnSetup.m_uFlag = stream:readuchar()
            elseif self.m_Type == 0x2 then
                self.m_ReturnDeleteTime.m_uTime = stream:readuint()
            end
            if self.m_Type == 1 or self.m_Type == 0xE then
                self.unknow = stream:readuchar()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.m_Type)
            if self.m_Type == 0x1 or self.m_Type == 0xE then
                stream:writeuchar(self.m_ReturnSetup.m_uFlag)
            elseif self.m_Type == 0x2 then
                stream:writeuint(self.m_ReturnSetup.m_uTime)
            end
            if self.m_Type == 1 or self.m_Type == 0xE then
                stream:writeuchar(self.unknow or 0)
            end
            return stream:get()
        end
    }

    packet.GCDetailEquipList = {
        xy_id = packet.XYID_GC_DETAIL_EQUIP_LIST,
        ASK_EQUIP_MODE = {ASK_EQUIP_ALL = 0, ASK_EQUIP_SET = 1},
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDetailEquipList})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.m_mode = 0
            self.m_wPartFlags = {}
            self.itemList = {}
            self.unknow = 0
        end,
        bis = function(self, buffer)

            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.m_mode = stream:readuint()
            for i = 1, 0xc do
                self.m_wPartFlags[i] = stream:readuchar()
            end
            for i = 0, 83 do
                local index = math.floor(i / 8) + 1
                local shift = i % 8
                if (self.m_wPartFlags[index] or 0) & (1 << shift) == (1 << shift) then
                    local item = packet.ItemInfo.new()
                    item:bis(stream)
                    table.insert(self.itemList, item)
                end
            end
            self.unknow = stream:readuint()

        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.m_mode)
            self.m_wPartFlags = {}
            for i = 0, 83 do
                local index = math.floor(i / 8) + 1
                local shift = i % 8
                local item = self.itemList[i]
                if item then
                    self.m_wPartFlags[index] = (self.m_wPartFlags[index] or 0) | 1 << shift
                end
            end
            for i = 1, 0xc do
                stream:writeuchar(self.m_wPartFlags[i] or 0)
            end
            for i = 0, 83 do
                local item = self.itemList[i]
                if item then
                    packet.ItemInfo.bos(item, stream)
                end
            end
            stream:writeuint(self.unknow)
            return stream:get()
        end
    }


    packet.GCBagSizeChange = {
        xy_id = packet.XYID_GC_BAG_SIZE_CHANGE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCBagSizeChange})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.prop_size = 0
            self.material_size = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.prop_size = stream:readuchar()
            self.material_size = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.prop_size)
            stream:writeuchar(self.material_size)
            return stream:get()
        end
    }


    packet.GCMyBagList = {
        xy_id = packet.XYID_GC_MY_BAG_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCMyBagList})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_Mode = 0
            self.m_AskCount = 0
            self.list = {}
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_Mode)
            stream:writeuchar(self.m_AskCount)
            if self.m_AskCount > 0xF0 then self.m_AskCount = 0xF0 end
            for i = 1, self.m_AskCount do
                local item = self.list[i]
                stream:writeuchar(item.index)
                for j = 1, 0x3 do stream:writeuchar(item.unknow[j]) end
                packet.ItemGUID.bos(item.guid, stream)
                stream:writeuint(item.item_index)
                stream:writeuchar(item.count)
                for j = 1, 0x3 do stream:writeuchar(item.unknow_1[j]) end
            end
            return stream:get()
        end
    }


    packet.GCGroupingNameRet = {
        xy_id = packet.XYID_GC_GROUPING_NAME_RET,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCGroupingNameRet})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.list = {}
            self.unknow = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            for i = 1, 4 do
                local l = {}
                l.size = stream:readuint()
                if l.size > 0 and l.size <= 20 then
                    l.data = stream:read(l.size)
                end
                table.insert(self.list, l)
            end
            self.unknow = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            for i = 1, 4 do
                self.list[i] = {size = 0, unknow_2 = ""}
                stream:writeuint(self.list[i].size)
                if self.list[i].size > 0 and self.list[i].size <= 20 then
                    stream:write(self.list[i].data, self.list[i].size)
                end
            end
            stream:writeuint(self.unknow)
            return stream:get()
        end
    }


    packet.GCBankMoney = {
        xy_id = packet.XYID_GC_BANK_MONEY,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCBankMoney})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_4 = 0
            self.unknow_5 = ""
            self.list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.op = stream:readuchar()
            self.bank_save_money = stream:readuint()
            self.result = stream:readuchar()
            self.unknow_size = stream:readuint()
            if self.size > 0 and self.size < 0x13 then
                for i = 1, self.size do
                    local l = {}
                    l.unknow_1 = stream:readuint()
                    table.insert(self.list, l)
                end
                for i = 1, self.size do
                    self.list[i].unknow_2 = stream:readuint()
                end
            end
            self.unknow_4 = stream:readuint()
            if self.unknow_4 < 0x3FF then
                self.unknow_5 = stream:read(self.unknow_4)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.op)
            stream:writeuint(self.bank_save_money)
            stream:writeuchar(self.result)
            local size = #self.list
            stream:writeuint(size)
            if size > 0 and size < 0x13 then
                for i = 1, size do
                    self.list[i] = self.list[i] or {unknow_1 = 0, unknow_2 = 0}
                    stream:writeuint(self.list[i].unknow_1)
                end
                for i = 1, size do
                    stream:writeuint(self.list[i].unknow_2)
                end
            end
            stream:writeuint(self.unknow_4)
            if self.unknow_4 < 0x3FF then
                stream:write(self.unknow_5, self.unknow_4)
            end
            return stream:get()
        end
    }


    packet.GCOpenWorldReference = {
        xy_id = packet.XYID_GC_OPEN_WORLD_REFERENCE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCOpenWorldReference})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow = "" end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:read(0x20)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:write(self.unknow, 0x20)
            return stream:get()
        end
    }


    packet.GCRetGSChitChatInfo = {
        xy_id = packet.XYID_GC_RET_GS_CHIT_CHAT_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRetGSChitChatInfo})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.unknow_1)
            stream:writeuchar(self.unknow_2)
            return stream:get()
        end
    }


    packet.GCLevelUpLock = {
        xy_id = packet.XYID_GC_LEVEL_UP_LOCK,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCLevelUpLock})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
            self.unknow_2 = stream:readuint()
            self.unknow_3 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow_1)
            stream:writeuint(self.unknow_2)
            stream:writeuint(self.unknow_3)
            return stream:get()
        end
    }


    packet.GCVirtualNPCInfo = {
        xy_id = packet.XYID_GC_VIRTUAL_NPC_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCVirtualNPCInfo})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_nFlag = 0
            self.unknow_1 = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
            self.unknow_4 = 0
            self.unknow_5 = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_nFlag = stream:readuchar()
            if self.m_nFlag == 1 then
                self.unknow_1 = stream:readuchar()
                self.unknow_2 = stream:readushort()
                self.unknow_3 = stream:readuint()
                self.unknow_4 = stream:readuint()
            else
                for i = 1, 0x10 do self.unknow_5[i] = stream:readuchar() end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.m_nFlag)
            if self.m_nFlag == 1 then
                stream:writeuchar(self.unknow_1)
                stream:writeushort(self.unknow_2)
                stream:writeuint(self.unknow_3)
                stream:writeuint(self.unknow_4)
            else
                for i = 1, 0x10 do stream:writeuchar(self.unknow_5[i]) end
            end
            return stream:get()
        end
    }


    packet.GCDelObject = {
        xy_id = packet.XYID_GC_DEL_OBJECT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDelObject})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_objID = 0
            self.m_idScene = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.m_idScene = stream:readushort()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeushort(self.m_idScene)
            return stream:get()
        end
    }


    packet.CGAskDoubleExp = {
        xy_id = packet.XYID_CG_ASK_DOUBLE_EXP,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskDoubleExp})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }


    packet.CGAskJuqingPoint = {
        xy_id = packet.XYID_CG_ASK_JUQING_POINT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskJuqingPoint})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow)
            return stream:get()
        end
    }


    packet.CGAskDetailAttrib = {
        xy_id = packet.XYID_CG_ASK_DETAIL_ATTRIB,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskDetailAttrib})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            return stream:get()
        end
    }


    packet.CGAskDetailXinFaList = {
        xy_id = packet.XYID_CG_ASK_DETAIL_XINFA_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskDetailXinFaList})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            return stream:get()
        end
    }


    packet.CGAskTeamInfo = {
        xy_id = packet.XYID_CG_ASK_TEAM_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskTeamInfo})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            return stream:get()
        end
    }


    packet.GCCheDiFuLuData = {
        xy_id = packet.XYID_GC_CHEDIFULU_DATA,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCheDiFuLuData})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.size = 0
            self.list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuchar()
            self.size = stream:readuchar()
            if self.size > 0 then
                for i = 1, self.size do
                    if i < 30 then
                        local l = {}
                        l.index = stream:readuint()
                        l.sceneid = stream:readuint()
                        l.x = stream:readuint()
                        l.y = stream:readuint()
                        table.insert(self.list, l)
                    end
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.unknow_1)
            stream:writeuchar(self.size)
            if self.size > 0 then
                for i = 1, self.size do
                    local l = self.list[i] or
                                  {
                            index = 0,
                            sceneid = 0,
                            x = 0,
                            y = 0
                        }
                    stream:writeuint(l.index)
                    stream:writeuint(l.sceneid)
                    stream:writeuint(l.x)
                    stream:writeuint(l.y)
                end
            end
            return stream:get()
        end
    }


    packet.CGAskDiGongShopInfo = {
        xy_id = packet.XYID_CG_ASK_DIGONG_SHOP_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskDiGongShopInfo})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }


    packet.CGExteriorRequest = {
        xy_id = packet.XYID_CG_EXTERIOR_REQUEST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGExteriorRequest})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.type = 0
            self.flag = 0
            self.size = 0
            self.list = {}
            self.unknow_2 = 0
            self.unknow_3 = 0
            self.unknow_4 = 0
            self.unknow_5 = 0

            self.unknow_6 = 0
            self.unknow_7 = 0

            self.unknow_8 = 0
            self.unknow_9 = 0
            self.unknow_10 = 0

            self.unknow_11 = 0

    		self.OrnamentsBackExteriorId = 0
    		self.OrnamentsHeadExteriorId = 0
    		self.OrnamentsBackPos = 0
    		self.OrnamentsHeadPos = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuint()
            self.flag = stream:readuint()
            if self.type == 0 then
                self.unknow_11 = stream:readuchar()
            else
                if self.type == 7 then
                    self.size = stream:readuint()
                    if self.size > 0 then
                        self.list = {}
                        for i = 1, self.size do
                            local l = {}
                            l.unknow_1 = stream:readuint()
                            l.unknow_2 = stream:readushort()
                            l.unknow_3 = stream:readuint()
                            table.insert(self.list, l)
                        end
                    end
                    self.unknow_2 = stream:readuchar()
                    self.unknow_3 = stream:readuint()	--m_WeaponChanged
                    self.unknow_4 = stream:readushort()	--m_SaveWeaponId
                    self.unknow_5 = stream:readuchar()	--m_SaveWeaponLv

    				self.OrnamentsBackExteriorId = stream:readushort()
    				self.OrnamentsHeadExteriorId = stream:readushort()
    				self.OrnamentsBackPos = stream:readuint()
    				self.OrnamentsHeadPos = stream:readuint()
                elseif self.type == 10 then
                    self.unknow_6 = stream:readushort()
                    self.unknow_7 = stream:readuchar()
                else
                    self.unknow_8 = stream:readuint()
                    self.unknow_9 = stream:readuint()
                    self.unknow_10 = stream:readuint()
                end
            end
        end,
        bos = function(self)
        end
    }


    packet.CGAskFashionDepotData = {
        xy_id = packet.XYID_CG_ASK_FASHION_DEPOT_DATA,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskFashionDepotData})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readuint()
            self.unknow_3 = stream:readuint()
            self.unknow_4 = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.unknow_1)
            stream:writeuint(self.unknow_2)
            stream:writeuint(self.unknow_3)
            stream:writeuchar(self.unknow_4 or 0)
            return stream:get()
        end
    }


    packet.CGAskMyBagList = {
        xy_id = packet.XYID_CG_ASK_MY_BAG_LIST,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskMyBagList})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.size = 0
            self.list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
            self.size = stream:readuchar()
            if self.size > 0xf0 then self.size = 0xf0 end
            for i = 1, self.size do self.list[i] = stream:readuchar() end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow_1)
            stream:writeuchar(self.size)
            for i = 1, self.size do stream:writeuchar(self.list[i]) end
            return stream:get()
        end
    }


    packet.CGAskGSChitChatInfo = {
        xy_id = packet.XYID_CG_ASK_GS_CHIT_CHAT_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskGSChitChatInfo})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow_1 = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.unknow_1)
            return stream:get()
        end
    }




    packet.GCCharEquipment = {
        xy_id = packet.XYID_GC_CHAR_EQUIPMENT,  -- 原 XYID_CG_CHAR_EQUIPMENT, GC方向
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharEquipment})
            o:ctor()
            return o
        end,
        set_weapon = function(self,m_WeaponID,WeaponGemID,Weapon_visual)
    		self.m_WeaponID = m_WeaponID
    		self.WeaponGemID = WeaponGemID
    		self.Weapon_visual = Weapon_visual
    		self.flag = self.flag | 0x1
        end,
        set_cap = function(self,m_CapID,CapGemID,Cap_visual)
    		self.m_CapID = m_CapID
    		self.CapGemID = CapGemID
    		self.Cap_visual = Cap_visual
    		self.flag = self.flag | 0x2
        end,
        set_armour = function(self,m_ArmourID,ArmourGemID,Armour_visual)
    		self.m_ArmourID = m_ArmourID
    		self.ArmourGemID = ArmourGemID
    		self.Armour_visual = Armour_visual
    		self.flag = self.flag | 0x4
    	end,
        set_cuff = function(self,m_CuffID,CuffGemID,Cuff_visual)
    		self.m_CuffID = m_CuffID
    		self.CuffGemID = CuffGemID
    		self.Cuff_visual = Cuff_visual
    		self.flag = self.flag | 0x8
        end,
        set_unknow_6 = function(self,item_index,gemid,visual)
    		self.unknow_6_a = item_index
    		self.unknow_6_b = gemid
    		self.unknow_6_c = visual
    		self.flag = self.flag | 0x10
        end,
        set_fasion = function(self,fashion_item_id,fashion_unknow_2,fashion_unknow_3,fashion_unknow_4,visual)
    		self.fashion_item_id = fashion_item_id
    		self.fashion_unknow_2 = fashion_unknow_2
    		self.fashion_unknow_3 = fashion_unknow_3
    		self.fashion_unknow_4 = fashion_unknow_4
    		self.visual = visual
    		self.flag = self.flag | 0x10000
        end,
        set_wuhun = function(self,wuhun_item_id,wuhun_visual)
    		self.wuhun_item_id = wuhun_item_id
    		self.wuhun_visual = wuhun_visual
    		self.flag = self.flag | 0x40000
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.flag = 0
        end,
        bis = function(self, buffer)
            -- local stream = bistream.new()
            -- stream:attach(buffer)
            -- self.m_objID = stream:readuint()
            -- self.unknow_1 = stream:readuint()
            -- self.flag = stream:readuint()

            -- if self.flag & 0x1 == 0x1 then
                -- self.m_WeaponID = stream:readuint()
                -- self.WeaponGemID = stream:readint()
                -- self.Weapon_visual = stream:readushort()
            -- end

            -- if self.flag & 0x2 == 0x2 then
                -- self.m_CapID = stream:readuint()
                -- self.CapGemID = stream:readint()
                -- self.Cap_visual = stream:readushort()
            -- end

            -- if self.flag & 0x4 == 0x4 then
                -- self.m_ArmourID = stream:readuint()
                -- self.ArmourGemID = stream:readint()
                -- self.Armour_visual = stream:readushort()
            -- end

            -- if self.flag & 0x8 == 0x8 then
                -- self.m_CuffID = stream:readuint()
                -- self.CuffGemID = stream:readint()
                -- self.Cuff_visual = stream:readushort()
            -- end

            -- if self.flag & 0x10 == 0x10 then
                -- self.unknow_6_a = stream:readuint()
                -- self.unknow_6_b = stream:readint()
                -- self.unknow_6_c = stream:readushort()
            -- end

            -- if self.flag & 0x10000 == 0x10000 then
                -- self.fashion_item_id = stream:readint()
                -- self.visual          = stream:readshort()
                -- self.fashion_unknow_2 = stream:readint()
                -- self.fashion_unknow_3 = stream:readint()
                -- self.fashion_unknow_4 = stream:readint()
            -- end

            -- if self.flag & 0x40000 == 0x40000 then
                -- self.wuhun_item_id = stream:readint()
                -- self.wuhun_visual = stream:readshort()
            -- end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.unknow_1)
            stream:writeuint(self.flag)

            if self.flag & 0x1 == 0x1 then
                stream:writeint(self.m_WeaponID)
                stream:writeint(self.WeaponGemID)
                stream:writeshort(self.Weapon_visual)
            end

            if self.flag & 0x2 == 0x2 then
    			if not self.Cap_visual or self.Cap_visual < 0 then
    				self.m_CapID = -1
    				self.CapGemID = -1
    				self.Cap_visual = 0
    			end
                stream:writeint(self.m_CapID)
                stream:writeint(self.CapGemID)
                stream:writeshort(self.Cap_visual)
            end

            if self.flag & 0x4 == 0x4 then
    			if not self.Armour_visual or self.Armour_visual < 0 then
    				self.m_ArmourID = -1
    				self.ArmourGemID = -1
    				self.Armour_visual = 0
    			end
                stream:writeint(self.m_ArmourID)
                stream:writeint(self.ArmourGemID)
                stream:writeshort(self.Armour_visual)
            end

            if self.flag & 0x8 == 0x8 then
    			if not self.Cuff_visual or self.Cuff_visual < 0 then
    				self.m_CuffID = -1
    				self.CuffGemID = -1
    				self.Cuff_visual = 0
    			end
                stream:writeint(self.m_CuffID)
                stream:writeint(self.CuffGemID)
                stream:writeshort(self.Cuff_visual)
            end

            if self.flag & 0x10 == 0x10 then
    			if not self.unknow_6_c or self.unknow_6_c < 0 then
    				self.unknow_6_a = -1
    				self.unknow_6_b = -1
    				self.unknow_6_c = 0
    			end
                stream:writeint(self.unknow_6_a)
                stream:writeint(self.unknow_6_b)
                stream:writeshort(self.unknow_6_c)
            end

            if self.flag & 0x10000 == 0x10000 then
    			if not self.visual or self.visual < 0 then
    				self.fashion_item_id = -1
    				self.fashion_unknow_2 = -1
    				self.fashion_unknow_3 = -1
    				self.fashion_unknow_4 = -1
    				self.visual = 0
    			end
                stream:writeint(self.fashion_item_id)
                stream:writeshort(self.visual)
                stream:writeint(self.fashion_unknow_2)
                stream:writeint(self.fashion_unknow_3)
                stream:writeint(self.fashion_unknow_4)
            end

            if self.flag & 0x40000 == 0x40000 then
    			if not self.wuhun_visual or self.wuhun_visual < 0 then
    				self.wuhun_item_id = -1
    				self.wuhun_visual = 0
    			end
                stream:writeint(self.wuhun_item_id)
                stream:writeshort(self.wuhun_visual)
            end
            return stream:get()
        end
    }





    packet.unknow_440 = {
        xy_id = packet.XYID_UNKNOW_440,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.unknow_440})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow_1 = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readushort()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.unknow_1)
            return stream:get()
        end
    }


    packet.WGCAladdinToken = {
        xy_id = packet.XYID_WGC_AlADDIN_TOKEN,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.WGCAladdinToken})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
            self.unknow_3 = ""
            self.unknow_4 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readushort()
            self.unknow_2 = stream:readuint()
            self.unknow_3 = stream:read(0x10)
            self.unknow_4 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.unknow_1)
            stream:writeuint(self.unknow_2)
            stream:write(self.unknow_3, 0x10)
            stream:writeuint(self.unknow_4)
            return stream:get()
        end
    }


    packet.GCRetNetDelay = {
        xy_id = packet.XYID_GC_RET_NET_DELAY,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRetNetDelay})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }


    packet.CGCharStopLogic = {
        xy_id = packet.XYID_CG_CHAR_STOP_LOGIC,  -- 原 XYID_GC_CHAR_STOP_LOGIC, CG方向
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGCharStopLogic})
            o:ctor()
            return o
        end,
        ctor = function(self) self.m_objID = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            return stream:get()
        end
    }


    packet.CGModifySetting = {
        xy_id = packet.XYID_CG_MODIFY_SETTING,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGModifySetting})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.type = 0
            self.setting = {type = 0, data = 0}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            self.setting.type = stream:readuchar()
            self.setting.data = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.type)
            stream:writeuchar(self.setting.type)
            stream:writeuint(self.setting.data)
            return stream:get()
        end
    }


    packet.CGAskQuit = {
        xy_id = packet.XYID_CG_ASK_QUIT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskQuit})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
            self.unknow_4 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
            self.unknow_2 = stream:readuchar()
            self.unknow_3 = stream:readuint()
            self.unknow_4 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow_1)
            stream:writeuchar(self.unknow_2)
            stream:writeuint(self.unknow_3)
            stream:writeuint(self.unknow_4)
            return stream:get()
        end
    }


    packet.GCRetAskQuit = {
        xy_id = packet.XYID_GC_RET_ASK_QUIT,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRetAskQuit})
            o:ctor()
            return o
        end,
        ctor = function(self) self.flag = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.flag = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.flag)
            return stream:get()
        end
    }


    packet.GCDetailImpactListUpdate = {
        xy_id = packet.XYID_GC_DETAIL_IMPACT_LIST_UPDATE,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCDetailImpactListUpdate})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.list = {}
            self.unknow_2 = -1
        end,
        bis = function(self, buffer)
            local stream    = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.size = stream:readushort()
            if self.size > 30 then
                self.size = 30
            end
            for i = 1, self.size do
                local impact = {}
                impact.sender = stream:readint()
                impact.buffer_id = stream:readint()
                impact.skill_id = stream:readint()
                impact.sn = stream:readint()
                impact.continuance = stream:readint()
                self.list[i] = impact
            end
            self.unknow_2 = stream:readshort()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeushort(self.size)
            if self.size > 30 then
                self.size = 30
            end
            for i = 1, self.size do
                local impact = self.list[i]
                stream:writeint(impact.sender)
                stream:writeint(impact.buffer_id)
                stream:writeint(impact.skill_id)
                stream:writeint(impact.sn)
                stream:writeint(impact.continuance)
            end
            stream:writeshort(self.unknow_2)
            return stream:get()
        end
    }


    packet.GCUnknow_1093 = {
        xy_id = packet.XYID_GC_UNKNOW_1093,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCUnknow_1093})
            o:ctor()
            return o
        end,
        ctor = function(self) self.unknow = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.unknow)
            return stream:get()
        end
    }


    packet.GCShowMonsterTaps = {
        xy_id = packet.XYID_GC_SHOW_MONSTER_TAPS,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCShowMonsterTaps})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.taps = {}    
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            local size = stream:readuchar()
            self.taps = {}
            for i = 1, size do
                local tap = {}
                tap.pos = {}
                tap.pos.x = stream:readfloat()
                tap.pos.y = stream:readfloat()
                tap.id = stream:readuint()
                self.taps[i] = tap
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(#self.taps)
            for i = 1, #self.taps do
                local tap = self.taps[i]
                stream:writefloat(tap.pos.x)
                stream:writefloat(tap.pos.y)
                stream:writeuint(tap.id)
            end
            stream:writeuchar(1)
            return stream:get()
        end
    }


    packet.CGPackage_SwapItem = {
        xy_id = packet.XYID_CG_PACKAGE_SWAP_ITEM,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGPackage_SwapItem})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.index_from = stream:readuchar()
            self.index_to = stream:readuchar()
            self.count = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.index_from)
            stream:writeuchar(self.index_to)
            stream:writeuchar(self.count)
            return stream:get()
        end
    }


    packet.GCPackage_SwapItem = {
        xy_id = packet.XYID_GC_PACKAGE_SWAP_ITEM,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCPackage_SwapItem})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readuchar()
            self.index_from = stream:readuchar()
            self.index_to = stream:readuchar()
            self.count = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.result)
            stream:writeuchar(self.index_from)
            stream:writeuchar(self.index_to)
            stream:writeuchar(self.count)
            return stream:get()
        end
    }


    packet.CGAskItemInfo = {
        xy_id = packet.XYID_CG_ASK_ITEM_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskItemInfo})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bagIndex = stream:readushort()
            self.askid = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.bagIndex)
            stream:writeuint(self.askid)
            return stream:get()
        end
    }


    packet.GCItemInfo = {
        xy_id = packet.XYID_GC_ITEM_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCItemInfo})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.bag_type = 0
            self.askid = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bagIndex = stream:readushort()
            self.unknow_1 = stream:readint()
            self.item = packet.ItemInfo.new()
            self.item:bis(stream)
            self.askid = stream:readuint()
            self.bag_type = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeshort(self.bagIndex)
            stream:writeint(self.unknow_1)
            packet.ItemInfo.bos(self.item, stream)
            stream:writeuint(self.askid)
            stream:writeint(self.bag_type)
            return stream:get()
        end
    }


    -- CYS fix 2026-09-14: id 1032 la GCYuanBao (server->client) trong client CY, khong phai
    -- CGShowFashionDepotData. Bo dang ky giai ma de 1032 khong con la goi CG hop le.
    -- ID CG that cua CGShowFashionDepotData chua xac minh (can DumpPacketById tren Game.exe).
    --[[
    packet.CGShowFashionDepotData = {
        xy_id = packet.XYID_GC_YUAN_BAO,  -- 原 XYID_CG_SHOW_FASHION_DEPOT_DATA, GC方向客户端: GCYuanBao
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGShowFashionDepotData})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.unknow)
            return stream:get()
        end
    }
    ]] -- CYS fix 2026-09-14 (het khoi chu thich CGShowFashionDepotData)


    packet.GCNotifyChangeScene = {
        xy_id = packet.XYID_GC_NOTIFY_CHANGE_SCENE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCNotifyChangeScene})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_5 = {
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0
            }
            self.unknow_6 = {
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 63, 0, 0, 0, 0, 0, 0, 0, 0
            }
            self.unknow_3 = 9
            self.client_res = 0
            self.world_pos = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.scene_from = stream:readushort()
            self.scene_to = stream:readushort()
            self.world_pos = {}
            self.world_pos.x = stream:readfloat()
            self.world_pos.y = stream:readfloat()
            self.unknow_3 = stream:readuchar()
            self.client_res = stream:readushort()
            self.unknow_5 = {}
            for i = 1, 0x1A do self.unknow_5[i] = stream:readuchar() end
            self.unknow_6 = {}
            for i = 1, 0x18 do self.unknow_6[i] = stream:readuchar() end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.scene_from)
            stream:writeushort(self.scene_to)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writeuchar(self.unknow_3)
            stream:writeushort(self.client_res)
            for i = 1, 0x1A do stream:writeuchar(self.unknow_5[i]) end
            for i = 1, 0x18 do stream:writeuchar(self.unknow_6[i]) end
            return stream:get()
        end
    }


    packet.CGAskChangeScene = {
        xy_id = packet.XYID_CG_ASK_CHANGE_SCENE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGAskChangeScene})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.scene_from = stream:readushort()
            self.scene_to = stream:readushort()
            self.unknow_1 = stream:readuint()
            self.unknow_2 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()

            return stream:get()
        end
    }


    packet.GCRetChangeScene = {
        xy_id = packet.XYID_GC_RET_CHANGE_SCENE,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRetChangeScene})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.key = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readuchar()
            if self.result == 1 then
                self.ip = stream:read(0x18)
                self.port = stream:readushort()
            end
            self.key = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.result )
            if self.result == 1 then
                stream:write(self.ip, 0x18)
                stream:writeushort(self.port)
            end
            stream:writeuint(self.key)
            return stream:get()
        end
    }


    packet.GCCharSkill_Gather = {
        xy_id = packet.XYID_GC_CHAR_SKILL_GATHER,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharSkill_Gather})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.logic_count = stream:readuint()
            self.skill_id = stream:readuint()
            self.world_pos = {}
            self.world_pos.x = stream:readfloat()
            self.world_pos.y = stream:readfloat()
            self.target_id = stream:readint()
            self.target_pos = {}
            self.target_pos.x = stream:readfloat()
            self.target_pos.y = stream:readfloat()
            self.dir = stream:readfloat()
            self.total_time = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.logic_count)
            stream:writeuint(self.skill_id)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writeint(self.target_id)
            stream:writefloat(self.target_pos.x)
            stream:writefloat(self.target_pos.y)
            stream:writefloat(self.dir)
            stream:writeuint(self.total_time)
            return stream:get()
        end
    }


    packet.GCCharSkill_Send = {
        xy_id = packet.XYID_GC_CHAR_SKILL_SEND,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharSkill_Send})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 1
            self.unknow_2 = 0
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.logic_count)
            stream:writeuint(self.skill_id)
            stream:writeint(self.target_id)
            stream:writefloat(self.target_pos.x)
            stream:writefloat(self.target_pos.y)
            stream:writeuchar(self.unknow_1)
            stream:writeuchar(self.unknow_2)
            return stream:get()
        end
    }


    packet.GCCharBuff = {
        xy_id = packet.XYID_GC_CHAR_BUFF,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharBuff})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_6 = 0
            self.unknow_2 = -1
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.reciver)
            local flag = self.sn + 2
            stream:writeint(flag)
            stream:writeshort(self.buffer_id)
            stream:writeuint(self.enable)
            stream:writeint(self.sender)
            stream:writeint(self.unknow_2)
            stream:writeuint(self.sn)
            if self.enable ~= 0 then
                stream:writeint(self.logic_count)
            end
            if self.buffer_id == 4740 then
                stream:writeushort(self.unknow_6)
            end
            return stream:get()
        end
    }


    packet.GCDetailBuff = {
        xy_id = packet.XYID_GC_DETAIL_BUFF,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDetailBuff})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_7 = -1
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.sn)
            stream:writeuint(self.enable)
            if self.enable ~= 0 then
                stream:writeint(self.sender)
                stream:writeint(self.reciver)
                stream:writeshort(self.buffer_id)
                stream:writeint(self.skill_id)
                stream:writeint(self.logic_count)
                stream:writeint(self.continuance)
            end
            stream:writeshort(self.unknow_7)
            return stream:get()
        end
    }


    packet.GCTargetListAndHitFlags = {
        xy_id = packet.XYID_GC_TARGET_LIST_AND_HIT_FLAGS,
        enum_type = {
            UNIT_USE_SKILL = 0,
            SPECIAL_OBJ_ACTIVATE = 1,
        },
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCTargetListAndHitFlags})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1  = 1
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.data_type)
            stream:writeuint(self.m_objID)
            stream:writeuint(self.logic_count)
            stream:writeuint(self.skill_or_special_obj_id)
            stream:writefloat(self.target_pos.x)
            stream:writefloat(self.target_pos.y)
            stream:writeuchar(self.unknow_1)
            self.size = self.size > 0x40 and 0x40 or self.size
            stream:writeuchar(self.size)
            for i = 1, self.size do
                stream:writeuint(self.target_list[i])
            end
    		--某种子弹效果 可能是恶人谷用
    		stream:writeshort(self.shenme or 0)
            return stream:get()
        end
    }


    packet.GCRetSetting = {
        xy_id = packet.XYID_GC_RET_SETTING,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRetSetting})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.setting = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            stream:readuchar()
            for i = 1, 0x6D do
                local setting = {}
                setting.type = stream:readuchar()
                setting.data = stream:readuint()
                self.setting[i] = setting
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(1)
            for i = 1, 0x6D do
                local setting = self.setting[i] or { type = 0, data = 0}
                stream:writeuchar(setting.type)
                if setting.data == -1 then
                    setting.data = define.UINT_MAX
                end
                stream:writeuint(setting.data)
            end
            return stream:get()
        end
    }


    packet.GCDetailHealsAndDamages = {
        xy_id = packet.XYID_GC_DETAIL_HEALS_AND_DAMAGES,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDetailHealsAndDamages})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.dirty_flags = 0
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.dirty_flags)
            stream:writeuint(self.reciver)
            stream:writeint(self.sender)
            stream:writeuint(self.logic_count)
            if self.dirty_flags & 1 == 1 then
                stream:writeint(self.hp_modification)
            end
            if self.dirty_flags & 2 == 2 then
                stream:writeint(self.mp_modification)
            end
            if self.dirty_flags & 4 == 4 then
                stream:writeint(self.rage_modification)
            end
            if self.dirty_flags & 8 == 8 then
                stream:writeint(self.strike_point_modification)
            end
            stream:writeuchar(self.is_critical_hit)
            return stream:get()
        end
    }


    packet.GCCharSkill_Missed = {
        xy_id = packet.XYID_GC_CHAR_SKILL_MISSED,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharSkill_Missed})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.reciver = stream:readuint()
            self.sender = stream:readuint()
            self.skill_id = stream:readuint()
            self.flag = stream:readuchar()
            self.sender_logic_count = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.reciver)
            stream:writeint(self.sender)
            stream:writeint(self.skill_id)
            stream:writechar(self.flag)
            stream:writeuint(self.sender_logic_count or 0)

            return stream:get()
        end
    }


    packet.GCNewItemBox = {
        xy_id = packet.XYID_GC_NEW_ITEM_BOX,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCNewItemBox})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_7 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.owner_guid = stream:readuint()
            self.monster_id = stream:readuint()
            self.world_pos = {}
            self.world_pos.x = stream:readfloat()
            self.world_pos.y = stream:readfloat()
            self.item_box_type = stream:readint()
            self.unknow_7 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeint(self.owner_guid)
            stream:writeint(self.monster_id)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writeint(self.item_box_type)
            stream:writeuint(self.unknow_7)

            return stream:get()
        end
    }


    packet.GCFashionDepotOperation = {
        xy_id = packet.XYID_GC_FASHION_DEPOT_OPERATION,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCFashionDepotOperation})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.flag = stream:readuchar()
            self.unknow_2 = stream:readuint()
            self.unknow_3 = stream:readuchar()
            if self.flag == 5 then
                self.unknow_3 = stream:readuint()
            else
                self.fashion = {}
                self.fashion.item_index = stream:readuint()
                self.fashion.quality = stream:readuchar()
                self.fashion.visual = stream:readushort()
                self.fashion.unknow_4 = {}
                for j = 1, 0xc do
                    self.fashion.unknow_4[j] = stream:readuchar()
                end
                for j = 1, 5 do
                    stream:readuchar()
                end
            end
            if self.flag == 3 or self.flag == 5 then
                self.unknow_4 = stream:readuint()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.flag)
            stream:writeuint(self.unknow_2)
            stream:writeuchar(self.unknow_3 or 0)
            if self.flag == 5 then
                stream:writeuint(self.unknow_3)
            else
                stream:writeint(self.fashion.item_index)
                stream:writeuchar(self.fashion.quality)
                stream:writeushort(self.fashion.visual)
                for j = 1, 0xc do
                    stream:writeuchar(self.fashion.unknow_4[j])
                end
                for j = 1, 5 do
                    stream:writeuchar(0)
                end
            end
            if self.flag == 3 or self.flag == 5 then
                stream:writeuint(self.unknow_4)
            end
            return stream:get()
        end
    }


    packet.GCDetailExp = {
        xy_id = packet.XYID_GC_DETAIL_EXP,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCDetailExp})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.exp = 0
            self.award_exp = 0
            self.bb_exp = 0
            self.bb_award_exp = 0
            self.anqi_exp = 0
            self.anqi_award_exp = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
            self.exp = stream:readuint()
            self.award_exp = stream:readuint()
            self.bb_exp = stream:readuint()
            self.bb_award_exp = stream:readuint()
            self.anqi_exp = stream:readuint()
            self.anqi_award_exp = stream:readuint()
            self.reserved_1 = stream:readuint()
            self.reserved_2 = stream:readuint()
            self.reserved_3 = stream:readuint()
            self.reserved_4 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow_1)
            stream:writeuint(self.exp)
            stream:writeuint(self.award_exp)
            stream:writeuint(self.bb_exp)
            stream:writeuint(self.bb_award_exp)
            stream:writeuint(self.anqi_exp)
            stream:writeuint(self.anqi_award_exp)
            stream:writeuint(self.reserved_1 or 0)
            stream:writeuint(self.reserved_2 or 0)
            stream:writeuint(self.reserved_3 or 0)
            stream:writeuint(self.reserved_4 or 0)

            return stream:get()
        end
    }


    packet.GCCharStopAction = {
        xy_id = packet.XYID_GC_CHAR_STOP_ACTION,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCCharStopAction})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.logic_count = stream:readuint()
            self.stop_time = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.logic_count)
            stream:writeuint(self.stop_time)
            return stream:get()
        end
    }


    packet.CGOpenItemBox = {
        xy_id = packet.XYID_CG_OPEN_ITEM_BOX,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGOpenItemBox})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            return stream:get()
        end
    }


    packet.GCBoxItemList = {
        xy_id = packet.XYID_GC_BOX_ITEM_LIST,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCBoxItemList})
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.size = stream:readuchar()
            self.size = self.size > 10 and 10 or self.size
            self.item_box_type = stream:readshort()
            self.item_list = {}
            for i = 1, self.size do
                local item = packet.ItemInfo.new()
                item:bis(stream)
                self.item_list[i] = item
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuchar(self.size)
            self.size = self.size > 10 and 10 or self.size
            stream:writeshort(self.item_box_type)
            for i = 1, self.size do
                local item = self.item_list[i]
                packet.ItemInfo.bos(item, stream)
            end
            return stream:get()
        end
    }


    packet.GCObjTeleport = {
        xy_id = packet.XYID_GC_OBJ_TELEPORT,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.GCObjTeleport })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.world_pos = {}
            self.world_pos.x = stream:readfloat()
            self.world_pos.y = stream:readfloat()
            self.reserved_1 = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writeuint(self.reserved_1 or 0)
            return stream:get()
        end
    }


    packet.GCLevelUpResult = {
        xy_id = packet.XYID_GC_LEVEL_UP_RESULT,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.GCLevelUpResult })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.remind_exp = stream:readuint()
            self.result = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.remind_exp)
            stream:writeuint(self.result)
            return stream:get()
        end
    }


    packet.GCLevelUp = {
        xy_id = packet.XYID_GC_LEVEL_UP,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.GCLevelUp })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.level = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.level)
            return stream:get()
        end
    }


    packet.GCArrive = {
        xy_id = packet.XYID_GC_ARRIVE,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.GCArrive })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.handleid = stream:readuint()
            self.unknow = stream:readchar()
            self.world_pos = {}
            self.world_pos.x = stream:readfloat()
            self.world_pos.y = stream:readfloat()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.handleid)
            stream:writechar(self.unknow)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            return stream:get()
        end
    }


    packet.GCOperateResult = {
        xy_id = packet.XYID_GC_OPERATE_RESULT,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.GCOperateResult })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readint()
            self.reserved_1 = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
    		-- local skynet = require "skynet"
    		-- skynet.logi("self.result = ",self.result)
            stream:writeint(self.result or 0)
            stream:writeint(self.reserved_1 or 0)
            return stream:get()
        end
    }


    packet.GCXinfaStudyInfo = {
        xy_id = packet.XYID_GC_XINFA_STUDY_INFO,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.GCXinfaStudyInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.menpai = self:readushort()
            self.teacher = self:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.menpai)
            stream:writeuint(self.teacher)
            return stream:get()
        end
    }


    packet.GCStudyXinfa = {
        xy_id = packet.XYID_GC_STUDY_XINFA,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.GCStudyXinfa })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.spare_money = stream:readuint()
            self.spare_exp = stream:readuint()
            self.xinfa = stream:readushort()
            self.now_level = stream:readushort()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.spare_money)
            stream:writeuint(self.spare_exp)
            stream:writeushort(self.xinfa)
            stream:writeushort(self.now_level)
            return stream:get()
        end
    }


    packet.CGAskStudyXinfa = {
        xy_id = packet.XYID_CG_ASK_STUDY_XINFA,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.CGAskStudyXinfa })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.menpai = stream:readushort()
            self.xinfa = stream:readushort()
            self.now_level = stream:readushort()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.menpai)
            stream:writeushort(self.xinfa)
            stream:writeushort(self.now_level)
            return stream:get()
        end
    }


    packet.GCAddSkill = {
        xy_id = packet.XYID_GC_ADD_SKILL,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.GCAddSkill })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.skill = stream:readuint()
            self.unknow = stream:readushort()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.skill)
            stream:writeushort(self.unknow)
            return stream:get()
        end
    }


    packet.CGReqLevelUp = {
        xy_id = packet.XYID_CG_REQ_LEVEL_UP,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.CGReqLevelUp })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }


    packet.GCCharSkill_Lead = {
        xy_id = packet.XYID_GC_CHAR_SKILL_LEAD,
        new = function(o)
            o = o or {}
            setmetatable(o, { __index = packet.GCCharSkill_Lead })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.logic_count = stream:readuint()
            self.skill_id = stream:readuint()
            self.world_pos = {}
            self.world_pos.x = stream:readfloat()
            self.world_pos.y = stream:readfloat()
            self.target_id = stream:readuint()
            self.tar_pos = {}
            self.tar_pos.x = stream:readfloat()
            self.tar_pos.y = stream:readfloat()
            self.dir = stream:readfloat()
            self.total_time = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.logic_count)
            stream:writeuint(self.skill_id)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writeuint(self.target_id)
            stream:writefloat(self.tar_pos.x)
            stream:writefloat(self.tar_pos.y)
            stream:writefloat(self.dir)
            stream:writeuint(self.total_time)
            return stream:get()
        end
    }


    packet.CGUseGem = {
        xy_id = packet.XYID_CG_USE_GEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGUseGem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.gem_index = stream:readuchar()
            self.equip_index = stream:readuchar()
            self.unknow_3 = stream:readuchar()
            self.unknow_4 = stream:readuchar()
            self.unknow_5 = stream:readuint()
            self.unknow_6 = stream:readuchar()
        end,
    }


    packet.CGRemoveGem = {
        xy_id = packet.XYID_CG_REMOVE_GEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGRemoveGem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.gem_index = stream:readuchar()
            self.equip_index = stream:readuchar()
            self.mat_index = stream:readuchar()
        end,
    }


    packet.CGDisplaceGem = {
        xy_id = packet.XYID_CG_DISPLACE_GEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGDisplaceGem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.from_bag_index = stream:readuchar()
            self.to_bag_index = stream:readuchar()
        end
    }


    packet.GCAbilityLevel = {
        xy_id = packet.XYID_GC_ABILITY_LEVEL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAbilityLevel })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.id = stream:readushort()
            self.level = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.id)
            stream:writeuint(self.level)
            return stream:get()
        end
    }


    packet.GCPrescription = {
        xy_id = packet.XYID_GC_PRESCRIPTION,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPrescription })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.id = stream:readuint()
            self.learn_or_abandon = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.id)
            stream:writeuint(self.learn_or_abandon)
            return stream:get()
        end
    }


    packet.GCAbilityResult = {
        xy_id = packet.XYID_GC_ABILITY_RESULT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAbilityResult })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.ability = stream:readushort()
            self.prescription = stream:readuint()
            self.result = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.ability)
            stream:writeint(self.prescription)
            stream:writeint(self.result)
            return stream:get()
        end
    }


    packet.GCAbilityAction = {
        xy_id = packet.XYID_GC_ABILITY_ACTION,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAbilityAction })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.logic_count = stream:readuint()
            self.ability = stream:readushort()
            self.prescription = stream:readuint()
            self.target_obj_id = stream:readint()
            self.begin_or_end = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.m_objID)
            stream:writeuint(self.logic_count)
            stream:writeushort(self.ability)
            stream:writeint(self.prescription)
            stream:writeuint(self.target_obj_id)
            stream:writeuchar(self.begin_or_end)
            return stream:get()
        end
    }


    packet.GCAbilitySucc = {
        xy_id = packet.XYID_GC_ABILITY_SUCC,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAbilitySucc })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.ability = stream:readushort()
            self.prescription = stream:readuint()
            self.item_index = stream:readuint()
            self.num = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.ability)
            stream:writeint(self.prescription)
            stream:writeint(self.item_index)
            stream:writeuchar(self.num)
            stream:writeuchar(0)
            return stream:get()
        end
    }


    packet.CGAskTeamMemberInfo = {
        xy_id = packet.XYID_CG_ASK_TEAM_MEMBER_INFO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAskTeamMemberInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.guid = stream:readint()
            self.sceneid = stream:readshort()
        end
    }


    packet.GCBankBegin = {
        xy_id = packet.XYID_GC_BANK_BEGIN,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCBankBegin })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.flag = 1
            self.unknow = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.flag = stream:readuchar()
            self.npc = stream:readint()
            self.unknow = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.flag)
            stream:writeint(self.npc)
            stream:writeuchar(self.unknow)
            return stream:get()
        end
    }


    packet.CGBankAcquireList = {
        xy_id = packet.XYID_CG_BANK_ACQUIRE_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGBankAcquireList })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.flag = stream:readuchar()
        end
    }


    packet.GCBankAcquireList = {
        xy_id = packet.XYID_GC_BANK_ACQUIRE_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCBankAcquireList })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.bank_items = {}
            self.unknow_4 = 1
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.used_space = stream:readchar()
            self.all_space = stream:readchar()
            self.save_money = stream:readuint()
            self.unknow_4 = stream:readchar()
            for i = 1, self.used_space do
                local bank_item = {}
                bank_item.bag_index = stream:readuchar()
                bank_item.unknow_2 = stream:readuchar() -- 1
                bank_item.count = stream:readuchar()
                if bank_item.unknow_2 ~= 0 then
                    bank_item.item = packet.ItemInfo.new()
                    bank_item.item:bis(stream)
                else
                    bank_item.unknow_4 = stream:readint()
                end
                self.bank_items[i] = bank_item
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.used_space)
            stream:writeuchar(self.all_space)
            stream:writeint(self.save_money)
            stream:writechar(self.unknow_4)
            for i = 1, self.used_space do
                local bank_item = self.bank_items[i]
                if bank_item then
                    stream:writeuchar(bank_item.bag_index)
                    stream:writechar(bank_item.unknow_2)
                    stream:writeuchar(bank_item.count)
                    if bank_item.unknow_2 ~= 0 then
                        packet.ItemInfo.bos(bank_item.item, stream)
                    else
                        stream:writeint(bank_item.unknow_4)
                    end
                end
            end
            return stream:get()
        end
    }


    packet.GCBankItemInfo = {
        xy_id = packet.XYID_GC_BANK_ITEM_INFO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCBankItemInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.bank_items = {}
            self.unknow_3 = 0
            self.unknow_4 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readshort()
            self.unknow_2 = stream:readint()
            self.item = packet.ItemInfo.new()
            self.item:bis(stream)
        end,
    }


    packet.CGBankSwapItem = {
        xy_id = packet.XYID_CG_BANK_SWAP_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGBankSwapItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.from_bag = stream:readuchar()
            self.to_bag = stream:readuchar()
            self.from_index = stream:readuchar()
            self.to_index = stream:readuchar()
        end
    }


    packet.GCBankSwapItem = {
        xy_id = packet.XYID_GC_BANK_SWAP_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCBankSwapItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.from_bag = stream:readuchar()
            self.to_bag = stream:readuchar()
            self.from_index = stream:readuchar()
            self.to_index = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.from_bag)
            stream:writeuchar(self.to_bag)
            stream:writeuchar(self.from_index)
            stream:writeuchar(self.to_index)
            return stream:get()
        end
    }


    packet.CGBankAddItem = {
        xy_id = packet.XYID_CG_BANK_ADD_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGBankAddItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.from_bag = stream:readuchar()
            self.from_index = stream:readuchar()
            self.to_index = stream:readuchar()
        end
    }


    packet.GCBankAddItem = {
        xy_id = packet.XYID_GC_BANK_ADD_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCBankAddItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.from_bag = stream:readuchar()
            self.from_index = stream:readuchar()
            self.to_index = stream:readuchar()
            self.result = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.from_bag)
            stream:writeuchar(self.from_index)
            stream:writeuchar(self.to_index)
            stream:writeuchar(self.result)
            return stream:get()
        end
    }


    packet.CGBankRemoveItem = {
        xy_id = packet.XYID_CG_BANK_REMOVE_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGBankRemoveItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.to_bag = stream:readuchar()
            self.from_index = stream:readuchar()
            self.to_index = stream:readuchar()
        end
    }


    packet.GCBankRemoveItem = {
        xy_id = packet.XYID_GC_BANK_REMOVE_ITEM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCBankRemoveItem })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.to_bag = stream:readuchar()
            self.from_index = stream:readuchar()
            self.to_index = stream:readchar()
            self.result = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.to_bag)
            stream:writeuchar(self.from_index)
            stream:writeuchar(self.to_index)
            stream:writeuchar(self.result)
            return stream:get()
        end
    }


    packet.GCPlayerDie = {
        xy_id = packet.XYID_GC_PlAYER_DIE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerDie })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.new_player = stream:readuint()
            self.can_relive = stream:readuint()
            self.utime = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.new_player)
            stream:writeuint(self.can_relive)
            stream:writeint(0)
            stream:writeuint(self.utime)
            return stream:get()
        end
    }


    packet.CGPlayerDieResult = {
        xy_id = packet.XYID_CG_PlAYER_DIE_RESULT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGPlayerDieResult })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.code = stream:readuint()
        end
    }


    packet.GCPlayerRelive = {
        xy_id = packet.XYID_GC_PlAYER_RELIVE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCPlayerRelive })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }


    packet.CommisionShop = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CommisionShop })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.merchadise_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            local size = stream:readuchar()
            self.grade = stream:readuchar()
            self.target_id = stream:readint()
            for i = 1, size do
                local merchadise = {}
                merchadise.serial = stream:readuint()
                merchadise.type = stream:readuchar()
                merchadise.name = stream:readuint()
                merchadise.price = stream:readuint()
                merchadise.unknow_2 = stream:readuint()
                table.insert(self.merchadise_list, merchadise)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            local size = 0
            for i = 1, 20 do
                i = tostring(i)
                local merchadise = self.merchadise_list[i]
                if merchadise then
                    size = size + 1
                end
            end
            stream:writeuchar(size)
            stream:writeuchar(self.grade)
            stream:writeint(self.target_id)
            for i = 1, 20 do
                i = tostring(i)
                local merchadise = self.merchadise_list[i]
                if merchadise then
                    stream:writeuint(merchadise.serial)
                    stream:writeuchar(0)
                    stream:writeuint(merchadise.name)
                    stream:writeuint(merchadise.price)
                    stream:writeuint(merchadise.unknow_2 or 0)
                end
            end
            return stream:get()
        end
    }


    packet.CGReqManualAttr = {
        xy_id = packet.XYID_CG_REQ_MANUAL_ATTR,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGReqManualAttr })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.str = stream:readint()
            self.spr = stream:readint()
            self.con = stream:readint()
            self.int = stream:readint()
            self.dex = stream:readint()
        end
    }


    packet.GCManualAttrResult = {
        xy_id = packet.XYID_GC_MANUAL_ATTR_RESULT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCManualAttrResult })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.result = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.result)
            return stream:get()
        end
    }


    packet.CGFashionDepotOperation = {
        xy_id = packet.XYID_CG_FASHION_DEPOT_OPERATION,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGFashionDepotOperation })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.dest_container = stream:readuchar()
            self.from_index = stream:readuint()
            self.dest_index = stream:readint()
        end,
    }


    packet.CGManipulatePet = {
        xy_id = packet.XYID_CG_MANIPULATE_PET,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGManipulatePet })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readuint()
            self.pet_guid = packet.PetGUID.new()
            self.pet_guid:bis(stream)
            self.type = stream:readint()
        end
    }


    packet.GCManipulatePetRet = {
        xy_id = packet.XYID_GC_MANIPULATE_PET_RET,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCManipulatePetRet })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.is_fighting = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.guid = packet.PetGUID.new()
            self.guid:bis(stream)
            self.is_fighting = stream:readuint()
            self.ret = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PetGUID.bos(self.guid, stream)
            stream:writeuint(self.is_fighting)
            stream:writeint(self.ret)
            return stream:get()
        end
    }


    packet.CGSetPetAttrib = {
        xy_id = packet.XYID_CG_SET_PET_ATTRIB,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGSetPetAttrib })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_Flags = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.guid = packet.PetGUID.new()
            self.guid:bis(stream)
            for i = 1, 2 do
                self.m_Flags[i] = stream:readuchar()
            end
            if self.m_Flags[1] & 0x1 == 0x1 then
                local len = stream:readuchar()
                if len > 0x1E then
                    len = 0x1E
                end
                self.name = gbk.toutf8(stream:read(len))
            end
            if self.m_Flags[1] & 0x2 == 0x2 then
                self.str_increment = stream:readuint()
            end
            if self.m_Flags[1] & 0x4 == 0x4 then
                self.con_increment = stream:readuint()
            end
            if self.m_Flags[1] & 0x8 == 0x8 then
                self.dex_increment = stream:readuint()
            end
            if self.m_Flags[1] & 0x10 == 0x10 then
                self.spr_increment = stream:readuint()
            end
            if self.m_Flags[1] & 0x20 == 0x20 then
                self.int_increment = stream:readuint()
            end
            if self.m_Flags[1] & 0x40 == 0x40 then
                self.current_title = stream:readint()
            end
        end
    }


    packet.GCRefreshDarkSkill = {
        xy_id = packet.XYID_GC_REFRESH_DARK_SKILL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCRefreshDarkSkill })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.skills = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bag_pos = stream:readuint()
            self.skills = {}
            for i = 1, 3 do
                self.skills[i] = stream:readushort()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.bag_pos)
            for i = 1, 3 do
                stream:writeushort(self.skills[i])
            end
            return stream:get()
        end
    }


    packet.CGAskDarkAdjust = {
        xy_id = packet.XYID_CG_ASK_DARK_ADJUST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAskDarkAdjust })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bag_index = stream:readuint()
            self.type = stream:readuint()
            if self.type == 0 then
                self.unknow_1 = stream:readuint()
            elseif self.type == 3 then
                self.unknow_2 = stream:readuint()
            end
            self.unknow_3 = stream:readuchar()
        end
    }


    packet.GCComboSkillOperation = {
        xy_id = packet.XYID_GC_COMBO_SKILL_OPERATION,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCComboSkillOperation })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_3 = 0
            self.combo_list = { 0, 0, 0, 0, 0 }
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.cur_comb = stream:readint()
            self.skill_id = stream:readint()
            self.unknow_3 = stream:readint()
            self.tempnum = stream:readint()
            self.combo_list = {}
            for i = 1, 5 do
                self.combo_list[i] = stream:readuint()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.cur_comb)
            stream:writeint(self.skill_id)
            stream:writeint(self.unknow_3)
            stream:writeint(self.tempnum)
            for i = 1, 5 do
                stream:writeuint(self.combo_list[i])
            end
            return stream:get()
        end
    }


    packet.GCSpecialObj_ActNow = {
        xy_id = packet.XYID_GC_SPECIAL_OBJ_ACT_NOW,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCSpecialObj_ActNow })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.obj_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.logic_count = stream:readint()
            self.obj_count = stream:readint()
            if self.obj_count > 512 then
                self.obj_count = 512
            end
            for i = 1, self.obj_count do
                self.obj_list[i] = stream:readint()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writeint(self.logic_count)
            stream:writeint(self.obj_count)
            for i = 1, self.obj_count do
                stream:writeint(self.obj_list[i])
            end
            return stream:get()
        end
    }


    packet.GCNewSpecial = {
        xy_id = packet.XYID_GC_NEW_SPECIAL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCNewSpecial })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.world_pos = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.world_pos.x = stream:readfloat()
            self.world_pos.y = stream:readfloat()
            self.dir = stream:readfloat()
            self.data_id = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writefloat(self.dir)
            stream:writeint(self.data_id)
            return stream:get()
        end
    }


    packet.GCSpecialObj_FadeOut = {
        xy_id = packet.XYID_GC_SPECIAL_OBJ_FADE_OUT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCSpecialObj_FadeOut })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            return stream:get()
        end
    }


    packet.CGKfsOperate = {
        xy_id = packet.XYID_CG_KFS_OPERATE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGKfsOperate })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.operate = stream:readint()
            self.arg_1 = stream:readuchar()
            self.arg_2 = stream:readuchar()
            self.arg_3 = stream:readchar()
        end 
    }


    packet.GCRefreshKFSSkill = {
        xy_id = packet.XYID_GC_REFRESH_KFS_SKILL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCRefreshKFSSkill })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.skills = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bag_index = stream:readuint()
            for i = 1, 3 do
                self.skills[i] = stream:readshort()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.bag_index)
            for i = 1, 3 do
                stream:writeshort(self.skills[i])
            end
            return stream:get()
        end
    }


    packet.CGAskPrivateInfo = {
        xy_id = packet.XYID_CG_ASK_PRIVATE_INFO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAskPrivateInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
        end, 
    }


    packet.GCCharCharge = {
        xy_id = packet.XYID_GC_CHAR_CHARGE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCCharCharge })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writeint(self.logic_count)
            stream:writefloat(self.from.x)
            stream:writefloat(self.from.y)
            stream:writefloat(self.to.x)
            stream:writefloat(self.to.y)
            stream:writeint(self.unknow or 1)
            stream:writeint(self.nSkillId or 0)
            return stream:get()
        end
    }


    packet.GCGameCommond = {
        xy_id = packet.XYID_GC_GAME_COMMOND,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCGameCommond })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.type = 4
            self.is_end = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.is_end = stream:readint()
            self.type = stream:readint()
            if self.type > 0 and self.type < 0x100 then
                self.effect = stream:readint()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.is_end)
            stream:writeint(self.type)
            if self.type > 0 and self.type < 0x100 then
                stream:writeint(self.effect)
            end
            return stream:get()
        end
    }


    packet.GCRefreshSuperAttr = {
        xy_id = packet.XYID_GC_REFRESH_SUPER_ATTR,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCRefreshSuperAttr })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.bagIndex = stream:readuint()
            self.attr_count = stream:readuint()
            self.attr_type = stream:readulong()
            self.attr_values = {}
            for i = 1, 16 do
                self.attr_values[i] = stream:readushort()
            end
            self.item_index = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.bagIndex)
            stream:writeuint(self.attr_count)
            stream:writeulong(self.attr_type)
            for i = 1, 16 do
                stream:writeushort(self.attr_values[i] or 0)
            end
            stream:writeuint(self.item_index)
            return stream:get()
        end
    }


    packet.GCCharModifyAction = {
        xy_id = packet.XYID_GC_CHAR_MODIFY_ACTION,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCCharModifyAction })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writeint(self.logic_count)
            stream:writeint(self.modify_time)
            return stream:get()
        end
    }


    packet.CGAskTeamFollow = {
        xy_id = packet.XYID_CG_ASK_TEAM_FOLLOW,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAskTeamFollow })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.GCReturnTeamFollow = {
        xy_id = packet.XYID_GC_RETURN_TEAM_FOLLOW,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCReturnTeamFollow })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.return_type)
            stream:writeint(self.guid)
            return stream:get()
        end
    }


    packet.GCAskTeamFollow = {
        xy_id = packet.XYID_GC_ASK_TEAM_FOLLOW,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCAskTeamFollow })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            return stream:get()
        end
    }


    packet.CGStopTeamFollow = {
        xy_id = packet.XYID_CG_STOP_TEAM_FOLLOW,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGStopTeamFollow })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.CGReturnTeamFollow = {
        xy_id = packet.XYID_CG_RETURN_TEAM_FOLLOW,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGReturnTeamFollow })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.return_type = stream:readuchar()
        end
    }


    packet.GCOpenPlayerShop = {
        xy_id = packet.XYID_GC_OPEN_PLAYER_SHOP,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCOpenPlayerShop })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.unknow)
            return stream:get()
        end
    }


    packet.CGAutoMoveItemFromBagToPlayerShop_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAutoMoveItemFromBagToPlayerShop_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuchar()
            self.shop_serial = stream:readuchar()
        end
    }


    packet.CGAutoMoveItemFromPlayerShopToBag_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAutoMoveItemFromPlayerShopToBag_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuchar()
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readuchar()
            self.unknow_3 = stream:readuchar()
            self.unknow_4 = stream:readuchar()
            self.unknow_5 = stream:readuchar()
            self.unknow_6 = stream:readuchar()
            self.unknow_7 = stream:readuchar()
            self.shop_serial = stream:readuchar()
            self.unknow_9 = stream:readuchar()
            self.serial = stream:readuchar()
            self.unknow_8 = stream:readuchar()
        end
    }


    packet.CGManuMoveItemFromBagToPlayerShop_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGManuMoveItemFromBagToPlayerShop_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuchar()
            self.serial = stream:readuchar()
        end
    }


    packet.CGManuMoveItemFromPlayerShopToBag_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGManuMoveItemFromPlayerShopToBag_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuchar()
            self.serial = stream:readuchar()
        end
    }


    packet.CGManuMoveItemFromPlayerShopToPlayerShop_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGManuMoveItemFromPlayerShopToPlayerShop_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuint()
            self.serial_source = stream:readuint()
            self.serial_dest = stream:readuint()
            self.shop_serial = stream:readuchar()
            self.unknow_6 = stream:readuchar()
            self.unknow_7 = stream:readuchar()
            self.unknow_8 = stream:readuchar()
        end
    }


    packet.CGAutoMovePetFromPlayerShopToBag_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAutoMovePetFromPlayerShopToBag_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuchar()
            self.serial = stream:readuchar()
            self.shop_serial = stream:readuchar()
        end
    }


    packet.GCMoveItemFromBagToPlayerShop_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCMoveItemFromBagToPlayerShop_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuint()
            self.serial = stream:readuint()
            self.shop_serial = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_guid, stream)
            stream:writeuint(self.stall_index)
            stream:writeuint(self.serial)
            stream:writeuint(self.shop_serial)
            return stream:get()
        end
    }


    packet.GCMoveItemFromPlayerShopToBag_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCMoveItemFromPlayerShopToBag_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
            self.unknow_4 = 0
            self.unknow_5 = 0
            self.unknow_7 = 0
            self.unknow_8 = 0
            self.unknow_9 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuchar()
            self.flag = stream:readuchar()
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readuchar()
            self.serial = stream:readuint()
            self.shop_serial = stream:readuint()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_guid, stream)
            stream:writeuchar(self.stall_index)
            stream:writeuchar(self.flag)
            stream:writeuchar(self.unknow_1)
            stream:writeuchar(self.unknow_2)
            stream:writeuint(self.serial)
            stream:writeuint(self.shop_serial)
            return stream:get()
        end
    }


    packet.GCMovePetFromBagToPlayerShop_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCMovePetFromBagToPlayerShop_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuchar()
            self.serial = stream:readuchar()
            self.shop_serial = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_guid, stream)
            stream:writeuchar(self.stall_index)
            stream:writeuchar(self.serial)
            stream:writeuchar(self.shop_serial)
            return stream:get()
        end
    }


    packet.GCMovePetFromPlayerShopToBag_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCMovePetFromPlayerShopToBag_t })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuchar()
            self.flag = stream:readuchar()
            self.serial = stream:readuchar()
            self.shop_serial = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_guid, stream)
            stream:writeuchar(self.stall_index)
            stream:writeuchar(self.flag)
            stream:writeuchar(self.serial)
            stream:writeuchar(self.shop_serial)
            return stream:get()
        end
    }


    packet.CGCreateGuildLeague = {
        xy_id = packet.XYID_CG_CREATE_GUILD_LEAGUE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGCreateGuildLeague })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.name = stream:read(0x20)
            self.name = gbk.toutf8(self.name)
            self.desc = stream:read(0x40)
            self.desc = gbk.toutf8(self.desc)
        end
    }


    packet.CGSectOper = {
        xy_id = packet.XYID_CG_SECT_OPER,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGSectOper })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.op = stream:readuint()
            self.val = stream:readuint()
        end
    }


    packet.CGAskCampaignCount = {
        xy_id = packet.XYID_CG_ASK_CAMPAIGN_COUNT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAskCampaignCount })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuint()
        end
    }


    packet.CGAskSecKillNum = {
        xy_id = packet.XYID_CG_ASK_SEC_KILL_NUM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAskSecKillNum })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.CGAskSecKillData = {
        xy_id = packet.XYID_CG_ASK_SEC_KILL_DATA,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAskSecKillData })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end
    }


    packet.GCRetSecKillData = {
        xy_id = packet.XYID_GC_RET_SEC_KILL_DATA,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCRetSecKillData })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.item_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readuchar()
            self.fuben_index = stream:readuchar()
            self.boss_id = stream:readuchar()

            self.item_count = stream:readuchar()
            self.unknow_6 = stream:readuchar()
            self.unknow_7 = stream:readuchar()
            self.unknow_8 = stream:readuchar()
            self.unknow_8b = stream:readuchar()
            self.unknow_9 = stream:readuint()
            self.unknow_10 = stream:readint()
            self.unknow_10b = stream:readuchar()
            self.unknow_10c = stream:readint()
            if self.item_count > 0 then
                for i = 1, self.item_count do
                    local l = {}
                    l.unknow_1 = stream:readuchar()
                    l.unknow_2 = stream:readuchar()
                    l.count = stream:readuchar()
                    l.item_index = stream:readint()
                    self.item_list[i] = l
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            self.unknow_1 = self.unknow_1 or 0
            stream:writeuchar(self.unknow_1)
            if self.unknow_1 == 0 then
                stream:writeuchar(self.have_next or 0)
                stream:writeuchar(self.fuben_index or 0)
                stream:writeuchar(self.boss_id or 0)
                self.item_list = self.item_list or {}
                -- 客户端物品槽上限 12，超过会导致 Read Packet Size error[873]
                local send_count = math.min(#self.item_list, 12)
                stream:writeuchar(send_count)
                stream:writeuchar(self.unknow_6 or 0)
                stream:writeuchar(self.have_next or 0)
                stream:writeuchar(self.unknow_8 or 0)
                stream:writeuchar(self.unknow_8b or 0)
                stream:writeuint(self.unknow_9 or 0)
                stream:writeint(self.unknow_10 or 0)
                stream:writeuchar(self.unknow_10b or 0)
                stream:writeint(self.unknow_10c or 0)
                for i = 1, send_count do
                    local l = self.item_list[i]
                    stream:writeuchar(l.index or (i - 1))
                    stream:writeuchar(l.unknow_2 or 0)
                    stream:writeuchar(l.count)
                    stream:writeint(l.id)
                end
            else
                if self.unknow_1 == 1 then
                    stream:writeint(self.unknow_11 or 0)
                elseif self.unknow_1 == 2 then
                    stream:writeint(self.unknow_12 or 0)
                end
            end
            return stream:get()
        end
    }


    packet.GCRetCampaignCount = {
        xy_id = packet.XYID_GC_RET_CAMPAIGN_COUNT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCRetCampaignCount })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.list_1 = {}
            self.list_2 = {}
            self.list_3 = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuint()
            if self.unknow_1 == 1 or self.unknow_1 == 3 then
                for i = 1, 38 do
                    self.list_1[i] = stream:readuint()
                end
            end
            if self.unknow_1 == 2 then
                for i = 1, 50 do
                    self.list_2[i] = stream:readuint()
                end
                for i = 1, 38 do
                    self.list_3[i] = stream:readuint()
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.unknow_1)
            if self.unknow_1 == 1 or self.unknow_1 == 3 then
                for i = 1, 38 do
                    stream:writeuint(self.list_1[tostring(i)] or 0)
                end
            end
            if self.unknow_1 == 2 then
                for i = 1, 50 do
                    stream:writeuint(self.list_2[i])
                end
                for i = 1, 38 do
                    stream:writeuint(self.list_3[i])
                end
            end
            return stream:get()
        end
    }


    packet.GCRetSecKillNum = {
        xy_id = packet.XYID_GC_RET_SEC_KILL_NUM,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCRetSecKillNum })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            for i = 1, 32 do
                self.list[tostring(i)] = stream:readuchar()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            for i = 1, 32 do
                local v = self.list[tostring(i)] or 0
                stream:writeuchar(v)
            end
            stream:writeint(0)
            return stream:get()
        end
    }


    packet.CGExteriorCoupleFashion = {
        xy_id = packet.XYID_CG_EXTERIOR_COUPLE_FASHION,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGExteriorCoupleFashion })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readshort()
        end,
    }


    packet.GCExteriorCoupleFashion = {
        xy_id = packet.XYID_GC_EXTERIOR_COUPLE_FASHION,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExteriorCoupleFashion })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.list_1 = {}
            self.list_2 = {}
            self.list_3 = {}
            self.list_4 = {}
            self.list_5 = {}
            self.list_6 = {}
            self.list_7 = {}
            self.list_8 = {}

            self.list_9 = {}
            self.list_10 = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readchar()
            self.unknow_2 = stream:readshort()
            self.unknow_3 = stream:readchar()
            if self.unknow_1 == 1 then
                for i = 1, 150 do
                    self.list_1[i] = stream:readchar()
                end
            end
            if self.unknow_1 == 3 or self.unknow_1 == 5 or self.unknow_1 == 21 then
                self.unknow_4 = stream:readushort()
                self.unknow_4 = self.unknow_4 > 20 and 20 or self.unknow_4
                for i = 1, self.unknow_4 do
                    self.list_2[i] = stream:read(0x1D)
                end
                self.unknow_5 = stream:readushort()
                self.unknow_5 = self.unknow_5 > 20 and 20 or self.unknow_5
                for i = 1, self.unknow_5 do
                    self.list_3[i] = stream:read(0x1D)
                end
                for i = 1, 150 do
                    self.list_4[i] = stream:readuchar()
                end
            end
            if self.unknow_1 == 10 then
                self.unknow_6 = stream:readushort()
                self.unknow_6 = self.unknow_6 > 20 and 20 or self.unknow_6
                for i = 1, self.unknow_6 do
                    self.list_7[i] = stream:read(0x1D)
                end
                for i = 1, 150 do
                    self.list_8[i] = stream:readuchar()
                end
            end
            if self.unknow_1 == 11 then
                self.unknow_9 = stream:readushort()
                self.unknow_9 = self.unknow_9 > 20 and 20 or self.unknow_9
                for i = 1, self.unknow_9 do
                    self.list_10[i] = stream:read(0x1D)
                end
            end
            if self.unknow_1 == 17 then
                self.list_11 = stream:read(0x14)
                self.list_12 = stream:read(0x14)
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.unknow_1 or 0)
            stream:writeshort(self.unknow_2 or 0)
            stream:writeuchar(self.unknow_3 or 0)
            if self.unknow_1 == 1 then
                for i = 1, 150 do
                    stream:writechar(self.list_1[i] or 0)
                end
            end
            if self.unknow_1 == 3 or self.unknow_1 == 5 or self.unknow_1 == 21 then
                self.unknow_4 = self.unknow_4 and (self.unknow_4 > 20 and 20 or self.unknow_4) or 0
                stream:writeushort(self.unknow_4)
                for i = 1, self.unknow_4 do
                    stream:write(self.list_2[i], 0x1D)
                end
                self.unknow_5 = self.unknow_5 and (self.unknow_5 > 20 and 20 or self.unknow_5) or 0
                stream:writeushort(self.unknow_5)
                for i = 1, self.unknow_5 do
                    stream:write(self.list_3[i], 0x1D)
                end
                for i = 1, 150 do
                    stream:writechar(self.list_4[i] or 0)
                end
            end
            if self.unknow_1 == 10 then
                self.unknow_6 = self.unknow_6 and (self.unknow_6 > 20 and 20 or self.unknow_6) or 0
                stream:writeushort(self.unknow_6)
                for i = 1, self.unknow_6 do
                    stream:write(self.list_7[i], 0x1D)
                end
                for i = 1, 150 do
                    stream:writechar(self.list_8[i] or 0)
                end
            end
            if self.unknow_1 == 11 then
                self.unknow_9 = self.unknow_9 and (self.unknow_9 > 20 and 20 or self.unknow_9) or 0
                stream:writeushort(self.unknow_9)
                for i = 1, self.unknow_9 do
                    stream:write(self.list_10[i], 0x1D)
                end
            end
            if self.unknow_1 == 17 then
                stream:write(self.list_11 or string.rep("\0", 0x14), 0x14)
                stream:write(self.list_12 or string.rep("\0", 0x14), 0x14)
            end
            return stream:get()
        end
    }


    packet.GCSetDynamicRegion = {
        xy_id = packet.XYID_GC_SET_DYNAMIC_REGION,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCSetDynamicRegion })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.world_pos = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.id = stream:readshort()
            self.data_index = stream:readint()
            self.world_pos = {}
            self.world_pos.x = stream:readfloat()
            self.world_pos.y = stream:readfloat()
            self.dir = stream:readfloat()
            self.enable = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeshort(self.id)
            stream:writeint(self.data_index)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writefloat(self.dir)
            stream:writeint(self.enable)
            return stream:get()
        end
    }


    packet.CGZdZdRequest = {
        xy_id = packet.XYID_CG_ZDZD_REQUEST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGZdZdRequest })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuint()
            if self.type == 1 then
                self.args = {}
                for i = 1, 7 do
                    table.insert(self.args, stream:readuint())
                end
            elseif self.type == 4 then
                self.unknow_7 = stream:readuint()
            end
        end
    }


    packet.GCZhouHuoYueInfo = {
        xy_id = packet.XYID_GC_ZHOU_HUOYUE_INFO,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCZhouHuoYueInfo})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.can_get = {}
            self.getd = {}
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            for i = 1, 0x2A do
                local can_get = self.can_get[i] or 0
                can_get = can_get > define.UINT32_MAX and define.UINT32_MAX or can_get
                stream:writeuint(can_get or 0)
            end
            for i = 1, 0x2A do
                local getd = self.getd[i] or 0
                getd = getd > define.UINT32_MAX and define.UINT32_MAX or getd
                stream:writeuint(getd or 0)
            end
            stream:writeuint(self.week_get)
            stream:writeuint(self.unknow_4)
            stream:writeuint(self.get_award_index)
            stream:writeuint(self.level)
            stream:writeuint(self.day_get)
            return stream:get()
        end
    }


    packet.GCShengWangInfo = {
        xy_id = packet.XYID_GC_SHENG_WANG_INFO,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCShengWangInfo})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.list_1 = {}
            self.list_2 = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readint()
            self.camp = stream:readint()
            self.unknow_3 = stream:readint()
            self.player_camp = stream:readint()
            self.show_wanshige = stream:readint()
            self.unknow_6 = stream:readint()
            self.unknow_7 = stream:readint()
            for i = 1, 3 do
                self.list_1[i] = stream:readint()
            end
            for i = 1, 3 do
                self.list_2[i] = stream:readint()
            end
            self.unknow_10 = stream:readint()
            self.unknow_11 = stream:read(0x190)
            self.unknow_12 = stream:read(0x190)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.unknow_1)
            stream:writeint(self.camp)
            stream:writeint(self.unknow_3)
            stream:writeint(self.player_camp)
            stream:writeint(self.show_wanshige)
            stream:writeint(self.unknow_6)
            stream:writeint(self.unknow_7)
            for i = 1, 6 do
                stream:writeint(self.list_1[i] or 0)
            end
            for i = 1, 6 do
                stream:writeint(self.list_2[i] or 0)
            end
            stream:writeint(self.unknow_10)
            stream:write(self.unknow_11 or "", 0x190)
            for i = 1, 50 do
                local item = self.item_list[i] or { id = 0, count = 0}
                stream:writeint(item.id)
                stream:writeint(item.count)
            end
            stream:writeint(0)
            return stream:get()
        end
    }


    packet.CGCharUpdateCurTitle = {
        xy_id = packet.XYID_CG_CHAR_UPDATE_CUR_TITLE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGCharUpdateCurTitle })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.id = stream:readuint()
            self.id_title_id = stream:readushort()
        end
    }


    packet.GCNewBus = {
        xy_id = packet.XYID_GC_NEW_BUS,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCNewBus})
            o:ctor()
            return o
        end, 
        ctor = function(self)
            self.path = {}
        end,
        bis = function(self, buffer)
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writeint(self.data_id)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writeint(0)
            stream:writeuint(#self.path)
            if #self.path <= 8 then
                for _, pos in ipairs(self.path) do
                    stream:writefloat(pos.x)
                    stream:writefloat(pos.y)
                end
            end
            return stream:get()
        end
    }


    packet.GCNewBus_Move = {
        xy_id = packet.XYID_GC_NEW_BUS_MOVE,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCNewBus_Move})
            o:ctor()
            return o
        end, 
        ctor = function(self)
            self.path = {}
        end,
        bis = function(self, buffer)
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeint(self.m_objID)
            stream:writeint(self.data_id)
            stream:writefloat(self.world_pos.x)
            stream:writefloat(self.world_pos.y)
            stream:writefloat(self.world_pos.z)
            stream:writefloat(self.next_pos.x)
            stream:writefloat(self.next_pos.y)
            stream:writefloat(self.next_pos.z)
    		stream:writeint(-1)
            stream:writeuint(#self.path)
            if #self.path <= 8 then
                for _, pos in ipairs(self.path) do
                    stream:writefloat(pos.x)
                    stream:writefloat(pos.y)
                end
            end
            return stream:get()
        end
    }


    packet.GCNotifyGoodBad = {
        xy_id = packet.XYID_GC_NOTIFY_GOOD_BAD,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCNotifyGoodBad })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.mode)
            stream:writeint(self.bonus)
            return stream:get()
        end
    }


    packet.CGAskTargetESPlan = {
        xy_id = packet.XYID_CG_ASK_TARGET_ES_PLAN,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGAskTargetESPlan })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
        end
    }


    -- S->C 目标玩家珍藏外观分享方案 (opcode 1270, 固定265字节)
    -- IDA确认: GCTarExteriorSharePlan::Read = sub_14062B5C0, GetPacketSize = 265
    -- 客户端读取顺序:
    --   uchar(1) type_code + int(4) m_objID + int(4) plan_id
    --   + short(2) zan_count + short(2) unknow_2 + short(2) unknow_3 + int(4) unknow_4
    --   + 6×int(4) tag[6]
    --   + 6×(int4+uchar1+short2+int4+uchar1+bytes12) dress_entries
    --   + 6×(short2+uchar1+int4) ride_entries
    --   + 6×(short2+int4) weapon_entries
    packet.GCTarExteriorSharePlan = {
        xy_id = packet.XYID_GC_TAR_EXTERIOR_SHARE_PLAN,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCTarExteriorSharePlan })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.type_code = 0
            self.m_objID = 0
            self.plan_id = 0
            self.zan_count = 0
            self.unknow_2 = 0
            self.unknow_3 = 0
            self.unknow_4 = 0
            self.tag = {-1,-1,-1,-1,-1,-1}
            self.dress = {}    -- 6个条目, 每个: {id, flag1, slot, extra_id, flag2, data12}
            self.ride = {}     -- 6个条目, 每个: {id_short, flag, extra_id}
            self.weapon = {}   -- 6个条目, 每个: {id_short, extra_id}
            for i = 1, 6 do
                self.dress[i] = { id = -1, flag1 = 0, slot = -1, extra_id = -1, flag2 = 0, data12 = "" }
                self.ride[i] = { id_short = -1, flag = 0, extra_id = -1 }
                self.weapon[i] = { id_short = -1, extra_id = -1 }
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            -- header: 1+4+4+2+2+2+4 = 19 bytes
            stream:writeuchar(self.type_code or 0)
            stream:writeint(self.m_objID or 0)
            stream:writeint(self.plan_id or 0)
            stream:writeshort(self.zan_count or 0)
            stream:writeshort(self.unknow_2 or 0)
            stream:writeshort(self.unknow_3 or 0)
            stream:writeint(self.unknow_4 or 0)
            -- tag[6]: 6×int(4) = 24 bytes
            for i = 1, 6 do
                stream:writeint(self.tag and self.tag[i] or -1)
            end
            -- dress_entries[6]: 6×(4+1+2+4+1+12) = 6×24 = 144 bytes
            for i = 1, 6 do
                local d = self.dress and self.dress[i] or {}
                stream:writeint(d.id or -1)
                stream:writeuchar(d.flag1 or 0)
                stream:writeshort(d.slot or -1)
                stream:writeint(d.extra_id or -1)
                stream:writeuchar(d.flag2 or 0)
                local data = d.data12 or ""
                if #data < 12 then data = data .. string.rep("\0", 12 - #data) end
                stream:write(data, 12)
            end
            -- ride_entries[6]: 6×(2+1+4) = 6×7 = 42 bytes
            for i = 1, 6 do
                local r = self.ride and self.ride[i] or {}
                stream:writeshort(r.id_short or -1)
                stream:writeuchar(r.flag or 0)
                stream:writeint(r.extra_id or -1)
            end
            -- weapon_entries[6]: 6×(2+4) = 6×6 = 36 bytes
            for i = 1, 6 do
                local w = self.weapon and self.weapon[i] or {}
                stream:writeshort(w.id_short or -1)
                stream:writeint(w.extra_id or -1)
            end
            -- total: 19+24+144+42+36 = 265
            return stream:get()
        end
    }


    packet.CGSetMoodToHead = {
        xy_id = packet.XYID_CG_SET_MOOD_TO_HEAD,
        new = function()
            local o = o or {}
            setmetatable(o, { __index = packet.CGSetMoodToHead })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.show = stream:readuchar()
        end
    }


    packet.GCRMBChatActionInfo = {
        xy_id = packet.XYID_GC_RMB_CHAT_ACTION_INFO,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCRMBChatActionInfo})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.flag = 0
            self.bitmask_1 = 0
            self.group_a = {0,0,0,0, 0,0,0,0, 0,0,0}  -- 11 slots
            self.bitmask_2 = 0
            self.group_b = {0,0,0,0, 0,0,0,0, 0,0,0}  -- 11 slots
            self.bitmask_3 = 0
            self.bitmask_4 = 0
            self.bitmask_5 = 0
            self.bitmask_6 = 0
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.flag = stream:readint()
            self.bitmask_1 = stream:readint()
            self.group_a = {}
            for i = 1, 11 do
                self.group_a[i] = stream:readint()
            end
            self.bitmask_2 = stream:readint()
            self.group_b = {}
            for i = 1, 11 do
                self.group_b[i] = stream:readint()
            end
            self.bitmask_3 = stream:readint()
            self.bitmask_4 = stream:readint()
            self.bitmask_5 = stream:readint()
            self.bitmask_6 = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.flag)
            stream:writeint(self.bitmask_1)
            for i = 1, 11 do
                stream:writeint(self.group_a[i])
            end
            stream:writeint(self.bitmask_2)
            for i = 1, 11 do
                stream:writeint(self.group_b[i])
            end
            stream:writeint(self.bitmask_3)
            stream:writeint(self.bitmask_4)
            stream:writeint(self.bitmask_5)
            stream:writeint(self.bitmask_6)
            return stream:get()
        end
    }


    packet.CGAskCheDiFuLuData = {
        xy_id = packet.XYID_CG_ASK_CHEDIFULU_DATA,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.CGAskCheDiFuLuData})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readchar()
            self.unknow_2 = stream:readchar()
        end
    }


    packet.GCTJCPVPCmnData = {
        xy_id = packet.XYID_GC_TJC_PVP_CMN_DATA,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCTJCPVPCmnData})
            o:ctor()
            return o
        end,
        ctor = function(self) self.buy_counts = { 0, 0, 0, 0, 0, 1} end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readint()
            self.buy_counts = {}
            for i = 1, 6 do
                self.buy_counts[i] = stream:readuint()
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(1)
            for i = 1, 6 do
                stream:writeint(self.buy_counts[i])
            end
            return stream:get()
        end
    }


    packet.GCAbilityExp = {
        xy_id = packet.XYID_GC_ABILITY_EXP,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCAbilityExp})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.ability)
            stream:writeuint(self.exp)
            stream:writeuint(self.exp_top)
            return stream:get()
        end
    }


    packet.CGReportWaigua = {
        xy_id = packet.XYID_CG_REPORT_WAIGUA,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.CGReportWaigua})
            o:ctor()
            return o
        end,
        ctor = function(self) end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.type = stream:readuchar()
            self.name = stream:read(0x1E)
            if self.type == 1 then
                self.guid = stream:readint()
            end
        end
    }


    -- 客户端发送 8C 04 - CGExteriorSharePlan (外观分享方案)
    packet.CGExteriorSharePlan = {
        xy_id = packet.XYID_CG_EXTERIOR_SHARE_PLAN,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.CGExteriorSharePlan})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.op_code = 0   -- 操作码 (通常为1)
            self.sub_code = 0  -- 子操作码 (1/3/4/5/6)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)

            if #buffer < 1 then
                self.op_code = 0
                self.sub_code = 0
                return
            end

            -- IDA确认: offset+24 = 1字节 op_code (always)
            local byte_value = stream:readuchar()
            self.op_code = byte_value
            self.sub_code = byte_value

            -- IDA确认: op=17/18 → offset+25 = 1字节 flag_value
            if byte_value == 17 or byte_value == 18 then
                self.flag_value = stream:readuchar()
            end

            -- IDA确认: op=7 → offset+28 = 24字节 tag (6 x int32)
            if byte_value == 7 then
                self.save_tag = {}
                for i = 1, 6 do
                    self.save_tag[i] = stream:readint()
                end
            end

            -- IDA确认: op=8 → offset+76(24字节) + offset+52(24字节) = dress_b先写,dress_a后写
            if byte_value == 8 then
                self.save_dress_b = {}
                for i = 1, 6 do
                    self.save_dress_b[i] = stream:readint()
                end
                self.save_dress_a = {}
                for i = 1, 6 do
                    self.save_dress_a[i] = stream:readint()
                end
            end

            -- IDA确认: op=9 → offset+124 = 24字节 ride (6 x int32)
            if byte_value == 9 then
                self.save_ride = {}
                for i = 1, 6 do
                    self.save_ride[i] = stream:readint()
                end
            end

            -- IDA确认: op=10 → offset+100 = 24字节 weapon (6 x int32)
            if byte_value == 10 then
                self.save_weapon = {}
                for i = 1, 6 do
                    self.save_weapon[i] = stream:readint()
                end
            end

            -- IDA确认: op=20 → offset+148 = 4字节 plan_id (int32)
            if byte_value == 20 then
                self.save_plan_id = stream:readint()
            end
        end
    }


    -- 服务端发送 - GCExteriorSharePlan (外观分享方案响应, wire opcode 1169)
    -- type_code: 2=全量数据, 3=标签编辑, 11=标签保存确认, 12=时装保存确认, 13=坐骑保存确认, 14=幻饰保存确认, 19=槽位flag
    packet.GCExteriorSharePlan = {
        xy_id = packet.XYID_GC_EXTERIOR_SHARE_PLAN,
        new = function()
            local o = {}
            setmetatable(o, {__index = packet.GCExteriorSharePlan})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.type_code = 2
        end,
        bos = function(self)
            local stream = bostream.new()

            stream:writeuchar(self.type_code)

            if self.type_code == 2 then
                -- 全量数据: plan_id + tag[6] + dress_b[6] + dress_a[6] + weapon_a[6] + weapon_b[6] + ride_a[6] + ride_b[6]
                stream:writeint(self.plan_id or 0)
                for i = 1, 6 do stream:writeint(self.tag and self.tag[i] or -1) end
                -- 时装: 客户端需要 dress_b(时装对象ID) 在前, dress_a(槽位索引) 在后
                for i = 1, 6 do stream:writeint(self.dress_b and self.dress_b[i] or -1) end
                for i = 1, 6 do stream:writeint(self.dress_a and self.dress_a[i] or -1) end
                for i = 1, 6 do stream:writeint(self.weapon_a and self.weapon_a[i] or -1) end
                for i = 1, 6 do stream:writeint(self.weapon_b and self.weapon_b[i] or -1) end
                for i = 1, 6 do stream:writeint(self.ride_a and self.ride_a[i] or -1) end
                for i = 1, 6 do stream:writeint(self.ride_b and self.ride_b[i] or -1) end

            elseif self.type_code == 3 then
                -- 标签编辑(打开编辑框): tag[6]
                for i = 1, 6 do stream:writeint(self.tag and self.tag[i] or -1) end

            elseif self.type_code == 11 then
                -- 标签保存确认: tag[6]
                for i = 1, 6 do stream:writeint(self.tag and self.tag[i] or -1) end

            elseif self.type_code == 12 then
                -- 时装保存确认: 客户端需要 dress_b[6](时装对象ID) + dress_a[6](槽位索引)
                for i = 1, 6 do stream:writeint(self.dress_b and self.dress_b[i] or -1) end
                for i = 1, 6 do stream:writeint(self.dress_a and self.dress_a[i] or -1) end

            elseif self.type_code == 13 then
                -- 坐骑保存确认: ride_a[6] + ride_b[6]
                for i = 1, 6 do stream:writeint(self.ride_a and self.ride_a[i] or -1) end
                for i = 1, 6 do stream:writeint(self.ride_b and self.ride_b[i] or -1) end

            elseif self.type_code == 14 then
                -- 幻饰保存确认: weapon_a[6] + weapon_b[6]
                for i = 1, 6 do stream:writeint(self.weapon_a and self.weapon_a[i] or -1) end
                for i = 1, 6 do stream:writeint(self.weapon_b and self.weapon_b[i] or -1) end

            elseif self.type_code == 19 then
                -- 槽位flag切换确认: 1字节
                stream:writeuchar(self.flag_value or 0)

            elseif self.type_code == 20 then
                -- 点赞结果: 1字节 (1=成功, 2=失败)
                -- IDA确认: 873 Execute type_code=20 读取offset+424的1字节,
                -- 值为1时 ++plan_counter, --zan_remain, fire_event(1191), 显示成功消息
                stream:writeuchar(self.zan_result or 1)
            end

            return stream:get()
        end
    }


    -- GCMsgBall: 服务端发包, 消息气泡通知 (ID 694)
    -- GetPacketSize: 动态 = #str1 + #str2 + #str3 + #str4 + 13
    -- 字段顺序按 IDA 客户端 Read 逆向还原
    packet.GCMsgBall = {
        xy_id = packet.XYID_GC_MSG_BALL,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCMsgBall})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.obj_id   = 0   -- uint(4)
            self.str1     = ""  -- 变长字符串(max 30)
            self.unknow_4 = 0   -- uint(4)
            self.unknow_5 = 0   -- uchar(1)
            self.str2     = ""  -- 变长字符串(max 256)
            self.str3     = ""  -- 变长字符串(max 256)
            self.str4     = ""  -- 变长字符串(max 256)
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuint(self.obj_id)
            local s1 = self.str1 or ""
            stream:writeuchar(#s1)
            if #s1 > 0 then stream:write(s1, #s1) end
            stream:writeuint(self.unknow_4)
            stream:writeuchar(self.unknow_5)
            local s2 = self.str2 or ""
            stream:writeuchar(#s2)
            if #s2 > 0 then stream:write(s2, #s2) end
            local s3 = self.str3 or ""
            stream:writeuchar(#s3)
            if #s3 > 0 then stream:write(s3, #s3) end
            local s4 = self.str4 or ""
            stream:writeuchar(#s4)
            if #s4 > 0 then stream:write(s4, #s4) end
            return stream:get()
        end
    }


    -- CGYuanBaoToBind: 客户端发包, 元宝转换绑定请求 (ID 846)
    -- GetPacketSize: 4 (固定)
    -- 字段顺序按 IDA 客户端 Write 逆向还原
    packet.CGYuanBaoToBind = {
        xy_id = packet.XYID_CG_YUAN_BAO_TO_BIND,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGYuanBaoToBind})
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.yuan_bao = 0  -- uint(4): 元宝数量
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.yuan_bao = stream:readuint()  -- uint(4)
        end,
        bos = function(self)
        end
    }

end
return M
