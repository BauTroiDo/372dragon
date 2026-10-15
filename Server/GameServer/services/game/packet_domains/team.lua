-- packet_domains/team.lua
-- 由 split_packet.py 自动生成，勿手动修改
local M = {}

function M.bind(packet, bistream, bostream, gbk, define)

    --enum RAID_POISTION
    --{
    --	RAID_POISTION_LEADER = 0,	//团长
    --	RAID_POISTION_ASSISTANT,	//助理
    --	RAID_POISTION_MEMBER,		//普通团员
    --};
    --有新的团队邀请
    packet.GCRaidAskInvite = {
        xy_id = packet.XYID_GCRaidAskInvite,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCRaidAskInvite })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.m_ZoneWorldID = -1
            self.member_list = {}
    		self.m_uLeaderLevel = 1		--团队团长等级
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.guid)
            self.nickname = gbk.fromutf8(self.nickname)
            stream:write(self.nickname, 0x1E)
            stream:writeshort(self.m_ZoneWorldID)
            stream:writeint(self.m_uLeaderLevel)

    		stream:writeshort(0)
    		stream:writeint(0)
            return stream:get()
        end 
    }

    --团队申请回复
    packet.CGRaidRetApply = {
        xy_id = packet.XYID_CGRaidRetApply,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGRaidRetApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
    		self.return_type = 0
    		self.source_guid = -1
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.return_type = stream:readuchar()
            self.source_guid = stream:readint()
    		stream:readint()
        end
    }

    --离开团队
    packet.CGRaidLeave = {
        xy_id = packet.XYID_CGRaidLeave,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGRaidLeave })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.guid = stream:readint()
        end
    }

    --团队操作结果
    --enum RAID_RESULT
    --{
    --	RAID_RESULT_MEMBERENTER = 0,		//成员加入团队
    --	RAID_RESULT_MEMBERLEAVE,			//成员离开团队
    --	RAID_RESULT_LEADERLEAVE,			//团长离开团队
    --	RAID_RESULT_KICK,					//踢除成员
    --	RAID_RESULT_APPOINT,				//任命新职务
    --	RAID_RESULT_STARTCHANGESCENE,		//开始切换场景
    --	RAID_RESULT_ENTERSCENE,				//团队成员进入新场景
    --	RAID_RESULT_REFRESH,				//重新请求团队信息的回复
    --	RAID_RESULT_MEMBEROFFLINE,			//玩家离线
    --	RAID_RESULT_DISMISS,				//团队解散
    --	RAID_RESULT_NUMBER ,				//团队结果类型的最大值
    --};
    packet.GCRaidResult = {
        xy_id = packet.XYID_GCRaidResult,
        new = function()
            local o = o or {}
            setmetatable(o, { __index = packet.GCRaidResult })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_7 = define.INVAILD_ID
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            self.name = gbk.fromutf8(self.name)
            self.name_size = string.len(self.name)
            stream:writeuchar(self.return_type)
            stream:writeint(self.guid)
    		stream:writeushort(self.raid_id)
            stream:writeint(self.guid_ex)
    		stream:writeint(self.m_objID)

            stream:writeshort(self.sceneid)
            stream:writeshort(self.client_res)

            stream:writeuchar(self.name_size)
            if self.name_size > 0 and self.name_size <= 0x1E then
                stream:write(self.name, self.name_size)
            end
            stream:writeuint(self.portrait_id)
            stream:writeushort(self.sex == 1 and 1 or 0)
    		stream:writechar(0)
    		stream:writechar(self.m_Position)		--调整职务后要更新这里
    		stream:writeuint(self.m_SquadIdx)		--团队小队ID
    		stream:writeuint(self.m_MemberIdx)		--团队小队位置
    		stream:writeushort(self.m_ZoneWorldID)	--归属服务器id
    		stream:writeuint(self.m_iFightScore)	--战斗评分
    		--帮会名
    		local m_uGuildNameSize = string.len(self.GuildName)
    		stream:writeshort(m_uGuildNameSize)
    		if m_uGuildNameSize < 32 then
    			stream:write(self.GuildName, m_uGuildNameSize)
    		end
            stream:writeint(0)

            return stream:get()
        end
    }

    --团队错误信息
    --error_code
    --enum RAID_ERROR
    --{
    --	RAID_ERROR_INVITEDESTHASRAID=0 ,		//邀请对象已经加入一个团队
    --	RAID_ERROR_INVITEDHASINRAID,			//您邀请的玩家已经在您的团队中
    --	RAID_ERROR_INVITEDTARGETNOTONLINE,		//您只能邀请在线的玩家加入团队
    --	RAID_ERROR_RAID_NOTEXIST_OR_LEADEROUT,	//该团队已解散，或团长已离团。
    --	RAID_ERROR_INVITEREFUSE,				//对方拒绝了你的邀请
    --	RAID_ERROR_FULL,						//团队已满。
    --	RAID_ERROR_FULL_CANTINVITE,				//团队已满，无法加入新成员。
    --
    --	RAID_RESERVER,
    --
    --	RAID_ERROR_KICKNOTLEADER,				//只有团长或助理才能踢人
    --	RAID_ERROR_KICKLEADER,					//不能请离团长！
    --	RAID_ERROR_KICK_ASSISTANT,				//不能请离和你同职位的助理！
    --
    --	RAID_ERROR_TARGET_IN_OTHERRAID,			//对方已经加入一个团队
    --	RAID_ERROR_TARGET_NOT_IN_RAID,			//对方不属于某个团队
    --	RAID_ERROR_APPLYLEADERREFUSE,			//团长拒绝你加入团队
    --	RAID_ERROR_APPLY_FULL,					//团队已满。
    --	RAID_ERROR_APPOINTSOURNOLEADER,			//团长已换人，请重新申请入团。
    --	RAID_ERROR_NOT_IN_RAID,					//你不在团队中。
    --	RAID_ERROR_TARGET_NOT_IN_YOUR_RAID,		//对方不在你的团队中。
    --	RAID_ERROR_TARGET_NOT_IN_YOUR_RAID_2,	//对方不在你的团队中。
    --	RAID_ERROR_NOT_LEADER,					//你已不是团长了。
    --	RAID_ERROR_ASSISTANT_MAX,				//团长助理的名额最多为2人，无法继续任命团长助理。
    --	RAID_ERROR_APPOINT_FAIL,				//任命失败
    --	RAID_ERROR_APPLYLEADERCANTANSWER,		//团长目前无法答复
    --
    --	RAID_RESERVER_2,
    --	RAID_RESERVER_3,
    --	RAID_ERROR_FULL_CANTAPPLY,				//团队已满，无法加入新成员。
    --	RAID_ERROR_TARGETNOTONLINE,				//对方已经离线，加入失败。
    --	RAID_ERROR_APPLYTOOMUCH,				//已有太多人向该玩家提出了申请入团，请稍等。
    --	RAID_ERROR_INVITETOOMUCH,				//已有太多人向该玩家提出了入团邀请，请稍等。
    --	RAID_ERROR_APPLYALREADYIN,				//你已经对该玩家提出了申请入团，请稍等。
    --	RAID_ERROR_INVITEALREADYIN,				//你已经对该玩家提出了入团邀请，请稍等。
    --	RAID_ERROR_ADDMEMFAILED,				//申请入队的玩家处于异常状态，添加团员失败！
    --	RAID_ERROR_ADDMEMFAILED_INVITEERR,		//邀请人异常，加入团队失败
    --	RAID_ERROR_CHANGE_POISTION_1,			//调整团员位置失败。
    --	RAID_ERROR_CHANGE_POISTION_2,			//调整团员位置失败。
    --	RAID_ERROR_CHANGE_POISTION_3,			//调整团员位置失败。
    --	RAID_ERROR_CHANGE_POISTION_4,			//调整团员位置失败。
    --
    --	RAID_RESERVER_4,
    --	RAID_RESERVER_5,
    --	RAID_RESERVER_6,
    --	RAID_RESERVER_7,
    --
    --	RAID_ERROR_NUMBER ,						//团队功能错误号的最大值
    --};
    packet.GCRaidError = {
        xy_id = packet.XYID_GCRaidError,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRaidError})
            o:ctor()
            return o
        end,
        ctor = function(self) self.error_code = 0 end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.error_code)
            return stream:get()
        end
    }


    --返回团队成员信息
    packet.GCRaidMemberInfo = {
    	xy_id = packet.XYID_GCRaidMemberInfo,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCRaidMemberInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_19 = 0
            self.flag = 0
            self.data_index = 0
    		self.m_RaidID = -1		--团队ID
        end,
        set_menpai = function(self, menpai)
            self.menpai = menpai
            self.flag = menpai and self.flag | 0x1 or self.flag & ~0x1
        end,
        set_level = function(self, level)
            self.level = level
            self.flag = level and self.flag | 0x2 or self.flag & ~0x2
        end,
        set_world_pos = function(self, world_pos)
            self.worldPos = world_pos
            self.flag = world_pos and self.flag | 0x4 or self.flag & ~0x4
        end,
        set_hp = function(self, hp)
            self.hp = hp
            self.flag = hp and self.flag | 0x8 or self.flag & ~0x8
        end,
        set_hp_max = function(self, hp_max)
            self.hp_max = hp_max
            self.flag = hp_max and self.flag | 0x10 or self.flag & ~0x10
        end,
        set_mp = function(self, mp)
            self.mp = mp
            self.flag = mp and self.flag | 0x20 or self.flag & ~0x20
        end,
        set_mp_max = function(self, mp_max)
            self.mp_max = mp_max
            self.flag = mp_max and self.flag | 0x40 or self.flag & ~0x40
        end,
        set_rage = function(self, rage)
            self.rage = rage
            self.flag = rage and self.flag | 0x80 or self.flag & ~0x80
        end,
        set_offline = function(self, offline)
            self.offline = offline and 1 or 0
            self.flag = offline and self.flag | 0x8000 or self.flag & ~0x8000
        end,
        set_is_die = function(self, is_die)
            self.is_die = is_die and 1 or 0
            self.flag = is_die and self.flag | 0x10000 or self.flag & ~0x10000
        end,
        set_hair_id = function(self, hair_id)
            self.hair_id = hair_id
            self.flag = hair_id and self.flag | 0x40000 or self.flag & ~0x40000
        end,
        set_hair_color = function(self, hair_color)
            self.hair_color = hair_color
            self.flag = hair_color and self.flag | 0x80000 or self.flag & ~0x80000
        end,
        set_portrait_id = function(self, portrait_id)
            self.portrait_id = portrait_id
            self.flag = portrait_id and self.flag | 0x200000 or self.flag & ~0x200000
        end,
        set_weapon = function(self, weapon)
    		if weapon then
    			self.weapon = weapon
    			self.flag = self.flag | 0x200
    		else
    			self.flag = self.flag & ~0x200
    		end
        end,
        set_cap = function(self, cap)
    		if cap then
    			self.cap = cap
    			self.flag = self.flag | 0x400
    		else
    			self.flag = self.flag & ~0x400
    		end
        end,
        set_armour = function(self, armour)
    		if armour then
    			self.armour = armour
    			self.flag = self.flag | 0x800
    		else
    			self.flag = self.flag & ~0x800
    		end
        end,
        set_cuff = function(self, cuff)
    		if cuff then
    			self.cuff = cuff
    			self.flag = self.flag | 0x1000
    		else
    			self.flag = self.flag & ~0x1000
    		end
        end,
        set_foot = function(self, foot)
    		if foot then
    			self.foot = foot
    			self.flag = self.flag | 0x2000
    		else
    			self.flag = self.flag & ~0x2000
    		end
        end,
        set_fashion = function(self, fashion)
    		if fashion then
    			self.fashion = fashion
    			self.flag = self.flag | 0x100000
    		else
    			self.flag = self.flag & ~0x100000
    		end
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.guid)
    		stream:writeshort(self.m_RaidID)
            stream:writeuint(self.data_index)
            stream:writeint(self.flag)
            if self.flag & 0x1 == 0x1 then
                stream:writeint(self.menpai)
            end
            if self.flag & 0x2 == 0x2 then
                stream:writeint(self.level)
            end
            if self.flag & 0x4 == 0x4 then
                stream:writefloat(self.worldPos.x)
                stream:writefloat(self.worldPos.y)
            end
            if self.flag & 0x8 == 0x8 then
                stream:writeuint(self.hp)
            end
            if self.flag & 0x10 == 0x10 then
                stream:writeuint(self.hp_max)
            end
            if self.flag & 0x20 == 0x20 then
                stream:writeuint(self.mp)
            end
            if self.flag & 0x40 == 0x40 then
                stream:writeuint(self.mp_max)
            end
            if self.flag & 0x80 == 0x80 then
                stream:writeuint(self.rage)
            end
    		if self.flag & 0x2000000 == 0x2000000 then
                stream:writeuint(0)		--空
            end
    		if self.flag & 0x100 == 0x100 then
                stream:writeuint(0)		--空
            end
            if self.flag & 0x200 == 0x200 then
                stream:writeint(self.weapon[define.WG_KEY_A])
                stream:writeint(self.weapon[define.WG_KEY_B])
                stream:writeshort(self.weapon[define.WG_KEY_C])
            end
            if self.flag & 0x400 == 0x400 then
                stream:writeint(self.cap[define.WG_KEY_A])
                stream:writeint(self.cap[define.WG_KEY_B])
                stream:writeshort(self.cap[define.WG_KEY_C])
            end
            if self.flag & 0x800 == 0x800 then
                stream:writeint(self.armour[define.WG_KEY_A])
                stream:writeint(self.armour[define.WG_KEY_B])
                stream:writeshort(self.armour[define.WG_KEY_C])
            end
            if self.flag & 0x1000 == 0x1000 then
                stream:writeint(self.cuff[define.WG_KEY_A])
                stream:writeint(self.cuff[define.WG_KEY_B])
                stream:writeshort(self.cuff[define.WG_KEY_C])
            end
            if self.flag & 0x2000 == 0x2000 then
                stream:writeint(self.foot[define.WG_KEY_A])
                stream:writeint(self.foot[define.WG_KEY_B])
                stream:writeshort(self.foot[define.WG_KEY_C])
            end
            if self.flag & 0x8000 == 0x8000 then
                stream:writeuchar(self.offline)	--离线标记
            end
    		if self.flag & 0x10000 == 0x10000 then
                stream:writeuchar(self.is_die)		--死亡标记
            end
    		--face_id ??
            if self.flag & 0x40000 == 0x40000 then
                stream:writeuint(self.hair_id)	--发型ID  hair_id
            end
            if self.flag & 0x80000 == 0x80000 then
                stream:writeint(self.hair_color)		--发色   hair_color
            end

            if self.flag & 0x100000 == 0x100000 then
                stream:writeint(self.fashion[define.WG_KEY_A])
                stream:writeint(self.fashion[define.WG_KEY_D])
                stream:writeint(self.fashion[define.WG_KEY_E])
                stream:writeint(self.fashion[define.WG_KEY_F])
                stream:writeshort(self.fashion[define.WG_KEY_C])
            end
            if self.flag & 0x200000 == 0x200000 then
                stream:writeuint(self.portrait_id)		--头像  portrait_id
            end
            return stream:get()
        end
    }


    --通知客户端当前团队列表
    packet.GCRaidList = {
        xy_id = packet.XYID_GCRaidList,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRaidList})
            o:ctor()
            return o
        end,
        ctor = function(self) 
    		--enum RAID_EVENT_ID
    --		{
    --			RAID_EVENT_CREATE = 0,			//转为团队
    --			RAID_EVENT_ADD_NEWMEM = 1,		//加入一个新团队
    --			RAID_EVENT_RET_RAIDINFO = 2,	//返回团队信息
    --
    --			RAID_EVENT_NUMBER,
    --		};
    		self.m_nEventID = 0
    		self.m_TeamID = -1	--组队ID
    		self.m_RaidID = -1	--团队ID
    		self.m_bLeaveRaid = 0	--离开团队
    		self.m_nMemberCount = 0	--团队成员数量，最大30
    		--【注意】member_list来自队伍的member_list，请自行适配
    		self.member_list = {}
    	end,
        bis = function(self, buffer)
        end,
        bos = function(self)
    		local text,text_size
    		local stream = bostream.new()
    		stream:writeuint(self.m_nEventID)
    		stream:writeshort(self.m_TeamID)
    		stream:writeshort(self.m_RaidID)
    		stream:writeuint(self.m_bLeaveRaid)
    		stream:writeuchar(self.m_nMemberCount)
    		for tid,team in ipairs(self.member_list) do
    			for mid,mb in ipairs(team) do
    				stream:writeuint(mb.guid)
    				stream:writeushort(mb.sceneid)
    				stream:writeushort(mb.client_res)
    				stream:writeint(mb.m_objID)
    				text = gbk.fromutf8(mb.name)
    				text_size = string.len(text)
    				stream:writeuchar(text_size)
    				if text_size <= 0x1E then
    					stream:write(text, text_size)
    				end
    				stream:writeuint(mb.portrait_id)
					stream:writeushort(mb.model == 1 and 1 or 0)
    				--团队内职务
    				stream:writeuchar(mb.m_Position)
    				--团队小队序号
    				stream:writeuint(tid - 1)
    				--团队小队位置
    				stream:writeuint(mid - 1)
    				stream:writeshort(mb.m_ZoneWorldID)
    				--空 战斗评分-经典
    				stream:writeuint(mb.m_iFightScore)
    				--帮会名
    				text = gbk.fromutf8(mb.GuildName)
    				text_size = string.len(text)
    				stream:writeshort(text_size)
    				if text_size <= 32 then
    					stream:write(text, text_size)
    				end
    				stream:writeint(-1)
    			end
    		end
            return stream:get()
        end
    }


    --通知客户端有团队申请
    packet.GCRaidAskApply = {
        xy_id = packet.XYID_GCRaidAskApply,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCRaidAskApply})
            o:ctor()
            return o
        end,
        ctor = function(self) 
    		self.m_SourGUID = -1		--申请人GUID
    		self.SourceName = ""		--申请人名
    		self.m_uFamily = 9			--申请人门派
    		self.sceneid = -1
    		self.m_Level = 0
    		self.m_DetailFlag = 0
    		self.m_uDataID = 0			--性别
    		self.m_nDefEquip = 0
    		self.m_ZoneWorldID = 0
    		self.m_iFightScore = 0		--空
    		self.GuildName = ""
    		self.m_OperateKey = 0		--操作key 无用
    	end,
        bis = function(self, buffer)
        end,
        bos = function(self)
    		local stream = bostream.new()
    		stream:writeuint(self.m_SourGUID)
    		self.SourceName = gbk.fromutf8(self.SourceName)
    		local SourceSize = string.len(self.SourceName)
            stream:writeuchar(SourceSize)
            if SourceSize < 30 then
                stream:write(self.SourceName, SourceSize)
            end
    		stream:writeuint(self.m_uFamily)
    		stream:writeshort(self.sceneid)
    		stream:writeuint(self.m_Level)
    		stream:writechar(self.m_DetailFlag)
    		stream:writeushort(self.m_uDataID)
    		stream:writeuint(self.m_nDefEquip)
    		stream:writeshort(self.m_ZoneWorldID)
    		stream:writeuint(self.m_iFightScore)
    		self.GuildName = gbk.fromutf8(self.GuildName)
    		local m_uGuildNameSize = string.len(self.GuildName)
    		stream:writeshort(m_uGuildNameSize)
    		if m_uGuildNameSize < 32 then
    			stream:write(self.GuildName, m_uGuildNameSize)
    		end
    		--【注意】uinfo来自队伍的uinfo，请自行适配
    		if self.m_DetailFlag > 0 then
    			stream:writeint(self.weapon[define.WG_KEY_A])
                stream:writeint(self.weapon[define.WG_KEY_B])
                stream:writeushort(self.weapon[define.WG_KEY_C])

                stream:writeint(self.cap[define.WG_KEY_A])
                stream:writeint(self.cap[define.WG_KEY_B])
                stream:writeushort(self.cap[define.WG_KEY_C])

                stream:writeint(self.armour[define.WG_KEY_A])
                stream:writeint(self.armour[define.WG_KEY_B])
                stream:writeushort(self.armour[define.WG_KEY_C])

                stream:writeint(self.cuff[define.WG_KEY_A])
                stream:writeint(self.cuff[define.WG_KEY_B])
                stream:writeushort(self.cuff[define.WG_KEY_C])

                stream:writeint(self.foot[define.WG_KEY_A])
                stream:writeint(self.foot[define.WG_KEY_B])
                stream:writeushort(self.foot[define.WG_KEY_C])
    			--脸型ID
    			stream:writeuint(self.face_id)
    			--发型ID
    			stream:writeuint(self.hair_id)
    			--发色
    			stream:writeuint(self.hair_color)
    			--时装ID
    			stream:writeint(self.fashion[define.WG_KEY_A])
    			--点缀
    			stream:writeint(self.fashion[define.WG_KEY_D])
    			stream:writeint(self.fashion[define.WG_KEY_E])
    			stream:writeint(self.fashion[define.WG_KEY_F])
    			-- stream:writeint(self.fashion[define.WG_KEY_A])
    			stream:writeuint(self.fashion[define.WG_KEY_C])
    			--预留
    			stream:writeint(-1)
    			stream:writeint(-1)
    			stream:writeint(-1)

    			stream:writeushort(0)
    			stream:writeushort(0)

    			stream:writeint(-1)
    			stream:writeint(-1)

    		end
    		stream:writeint(self.m_OperateKey)
            return stream:get()
        end
    }


    --调整团队成员位置
    packet.CGRaidModifyMemberPosition = {
        xy_id = packet.XYID_CGRaidModifyMemberPosition,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGRaidModifyMemberPosition})
            o:ctor()
            return o
        end,
        ctor = function(self) 
    		self.m_OperateGUID = -1		--操作GUID
    		self.m_sSquadIndex = -1		--源小队ID
    		self.m_sMemIndex = -1		--源小队内位置

    		self.m_dSquadIndex = -1
    		self.m_dMemIndex = -1
    	end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
    		self.m_OperateGUID = stream:readuint()
    		stream:readshort()

    		self.m_sSquadIndex = stream:readshort()
    		self.m_sMemIndex = stream:readint()

    		self.m_dSquadIndex = stream:readshort()
    		self.m_dMemIndex = stream:readint()
        end,
        bos = function(self)
        end
    }

    --回应邀请操作
    packet.CGRaidRetInvite = {
        xy_id = packet.XYID_CGRaidRetInvite,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGRaidRetInvite})
            o:ctor()
            return o
        end,
        ctor = function(self) 
    		self.m_Return = 0
    		self.m_GUID = -1		--对象GUID
    	end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
    		self.m_Return = stream:readchar()
    		self.m_GUID = stream:readuint()
    		--空
    		stream:readuint()
        end,
        bos = function(self)
        end
    }

    --踢出团队
    packet.CGRaidKick = {
        xy_id = packet.XYID_CGRaidKick,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGRaidKick})
            o:ctor()
            return o
        end,
        ctor = function(self) 
    		self.m_OperateGUID = -1		--人操作GUID
    		self.m_TargetGUID = -1		--对象GUID
    	end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_OperateGUID = stream:readuint()
    		self.m_TargetGUID = stream:readuint()
        end,
        bos = function(self)
        end
    }

    --团队任命
    packet.CGRaidAppoint = {
        xy_id = packet.XYID_CGRaidAppoint,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGRaidAppoint})
            o:ctor()
            return o
        end,
        ctor = function(self) 
    		self.m_OperateGUID = -1		--人操作GUID
    		self.m_TargetGUID = -1		--对象GUID
    		self.m_Position = 0			--任命的职务
    	end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_OperateGUID = stream:readuint()
    		self.m_TargetGUID = stream:readuint()
    		self.m_Position = stream:readchar()
        end,
        bos = function(self)
        end
    }

    --创建团队
    packet.CGRaidCreate = {
        xy_id = packet.XYID_CGRaidCreate,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGRaidCreate})
            o:ctor()
            return o
        end,
        ctor = function(self) 
    		self.m_CreateGUID = -1
    		self.m_CreateTeamId = -1
    		self.nCountInRaid = 0
    		self.m_aPlayerInRaid = {}
    	end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_CreateGUID = stream:readuint()
    		--空
    		stream:readuint()
    		self.m_CreateTeamId = stream:readshort()
    		self.nCountInRaid = stream:readint()
    		if self.nCountInRaid > 30 then
    			self.nCountInRaid = 30
    		end
    		for i = 1,self.nCountInRaid do
    			self.m_aPlayerInRaid[i] = stream:readint()
    		end
        end,
        bos = function(self)
        end
    }


    --申请进入团队
    packet.CGRaidApply = {
        xy_id = packet.XYID_CGRaidApply,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGRaidApply})
            o:ctor()
            return o
        end,
        ctor = function(self) 
    		self.m_SourGUID = -1		--操作guid
    		self.m_DestName = ""
    		self.m_ZoneWorldID = -1
    	end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
    		self.m_SourGUID = stream:readuint()
    		local m_DestNameSize = stream:readuchar()
    		if m_DestNameSize > 0 and m_DestNameSize < 30 then
    			self.m_DestName = gbk.toutf8(stream:read(m_DestNameSize)) 
    		end
    		self.m_ZoneWorldID = stream:readshort()
        end,
        bos = function(self)
        end
    }


    --邀请进入团队
    packet.CGRaidInvite = {
        xy_id = packet.XYID_CGRaidInvite,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.CGRaidInvite})
            o:ctor()
            return o
        end,
        ctor = function(self) 
    		self.m_SourObjID = -1		--操作obj
    		self.m_DestName = ""
    		self.m_ZoneWorldID = -1
    	end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
    		self.m_SourObjID = stream:readuint()
    		local m_DestNameSize = stream:readuchar()
    		if m_DestNameSize > 0 and m_DestNameSize < 30 then
    			self.m_DestName = gbk.toutf8(stream:read(m_DestNameSize)) 
    		end
    		self.m_ZoneWorldID = stream:readshort()
        end,
        bos = function(self)
        end
    }


    packet.GCTeamError = {
        xy_id = packet.XYID_GC_TEAM_ERROR,
        new = function(o)
            o = o or {}
            setmetatable(o, {__index = packet.GCTeamError})
            o:ctor()
            return o
        end,
        ctor = function(self) self.error_code = 0 end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.error_code = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.error_code)
            return stream:get()
        end
    }


packet.GCTeamList = {
    xy_id = packet.XYID_GC_TEAM_LIST,
    new = function()
        local o = {}
        setmetatable(o, {__index = packet.GCTeamList})
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.type = 0
        self.exp_mode = 0
        self.member_size = 0
        self.member_list = {}
        self.uinfos = {}
    end,
    bis = function(self, buffer)
    end,
    bos = function(self)
        --新客户端格式: [data_length:4] + [buffer:data_length字节]
        --buffer内部格式:
        --  [prefix=0x00:1] [header:15字节] [member_data:N*108字节]
        --  header = type(4)+team_id(2)+exp_mode(4)+member_size(1)+unknow(4)
        --  每个member = 60字节基础结构体 + 48字节扩展信息(交错排列)
        local inner = bostream.new()
        --prefix字节
        inner:writeuchar(0)
        --header (15字节, 紧凑排列)
        inner:writeuint(self.type)
        inner:writeushort(self.team_id)
        inner:writeuint(self.exp_mode)
        if self.member_size > 6 then
            self.member_size = 6
        end
        inner:writeuchar(self.member_size)
        inner:writeint(0)
        --每个member写108字节(60基础+48扩展, 交错排列)
        if self.member_size > 0 then
            for i = 1, self.member_size do
                local mb = self.member_list[i]
                mb.name = gbk.fromutf8(mb.name)
                mb.name_size = string.len(mb.name)
                --基础数据 60字节 结构体布局(含对齐间隙)
                inner:writeint(mb.guid)              --offset 0: guid (4)
                inner:writeshort(mb.sceneid)          --offset 4: sceneid (2)
                inner:writeshort(mb.client_res)       --offset 6: client_res (2)
                inner:writeint(mb.m_objID)            --offset 8: m_objID (4)
                inner:writeuchar(mb.name_size)        --offset 12: name_size (1)
                --offset 13: name[30] + offset 43: padding = 31字节
                if mb.name_size > 0 and mb.name_size <= 0x1E then
                    inner:write(mb.name, mb.name_size)
                    local pad = 31 - mb.name_size
                    if pad > 0 then
                        inner:write(string.rep("\0", pad), pad)
                    end
                else
                    inner:write(string.rep("\0", 31), 31)
                end
                local race_id = tonumber(mb.model) == 1 and 1 or 0
                inner:writeuint(mb.portrait_id)       --offset 44: portrait_id (4)
                inner:writeushort(race_id)            --offset 48: model/race (2)
                inner:writeushort(0)                  --offset 50: padding (2)
                inner:writeuint(mb.level)             --offset 52: level (4)
                inner:writeuchar(mb.menpai)           --offset 56: menpai (1)
                inner:writeuchar(0)                   --offset 57: padding (1)
                -- 客户端会把该值保存到队员模型缓存，必须保持为 0/1。
                inner:writeshort(race_id)             --offset 58: cached race/model (2)
                --基础数据共60字节
                -- 这 48 字节就是 TeamMemberInfo；首个 uint32 是 model/RaceID，不能写成员序号。
                local uinfo = self.uinfos[i] or mb
                packet.TeamMemberInfo.bos(uinfo, inner)
                --扩展信息共48字节, 每个member共108字节
            end
        end
        local inner_data = inner:get()
        --外层写: data_length + buffer
        local stream = bostream.new()
        stream:writeint(#inner_data)
        stream:write(inner_data, #inner_data)
        return stream:get()
    end
}


packet.CGTeamInvite = {
    xy_id = packet.XYID_CG_TEAM_INVITE,
    new = function()
        local o = {}
        setmetatable(o, { __index = packet.CGTeamInvite })
        o:ctor()
        return o
    end,
    ctor = function(self)
    end,
    bis = function(self, buffer)
        local stream = bistream.new()
        stream:attach(buffer)
        self.data_length = stream:readint()        --新客户端: 数据长度前缀
        self.m_objID = stream:readint()
        self.unknow = stream:readint()            --新客户端: 新增字段(原-1)
        self.dest_name_size = stream:readuchar()
        if self.dest_name_size > 0 and self.dest_name_size < 0x1E then
            self.dest_name = gbk.toutf8(stream:read(self.dest_name_size))
        end
        self.unknow_1 = stream:readushort()
    end
}


packet.CGTeamDismiss = {
    xy_id = packet.XYID_CG_TEAM_DISMISS,
    new = function()
        local o = {}
        setmetatable(o, { __index = packet.CGTeamDismiss })
        o:ctor()
        return o
    end,
    ctor = function(self)
    end,
    bis = function(self, buffer)
        local stream = bistream.new()
        stream:attach(buffer)
        self.guid = stream:readint()
    end
}

packet.GCTeamResult = {
    xy_id = packet.XYID_GC_TEAM_RESULT,
    new = function()
        local o = {}
        setmetatable(o, { __index = packet.GCTeamResult })
        o:ctor()
        return o
    end,
    ctor = function(self)
        self.unknow_7 = define.INVAILD_ID
    end,
    bis = function(self, buffer)
    end,
    bos = function(self)
        local stream = bostream.new()
        local name = gbk.fromutf8(self.name or "")
        local name_size = 0
        local offset = 1
        while offset <= #name and name_size < 0x1E do
            local width = string.byte(name, offset) < 0x80 and 1 or 2
            if name_size + width > 0x1E or offset + width - 1 > #name then
                break
            end
            name_size = name_size + width
            offset = offset + width
        end
        name = string.sub(name, 1, name_size)
        stream:writeuchar(self.return_type)
        stream:writeint(self.guid)
        stream:writeushort(self.team_id)
        stream:writeint(self.guid_ex)
        stream:writeshort(self.sceneid)
        stream:writeshort(self.client_res)
        stream:writeuchar(name_size)
        if name_size > 0 then
            stream:write(name, name_size)
        end
        stream:writeuint(self.portrait_id)
        stream:writeushort(self.sex == 1 and 1 or 0)
        stream:writeshort(self.sex == 1 and 1 or 0)
        if self.return_type == 8 or self.return_type == 0 then
            packet.TeamMemberInfo.bos(self.uinfo, stream)
        end
        return stream:get()
    end
}



    packet.GCTeamAskInvite = {
        xy_id = packet.XYID_GC_TEAM_ASK_INVITE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCTeamAskInvite })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_1 = -1
            self.member_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.guid = stream:readint()
            self.nickname = stream:read(0x1E)
            self.unknow_1 = stream:readshort()
            self.member_size = stream:readuchar()
            if self.member_size > 6 then
                self.member_size = 6
            end
            if self.member_size > 0 then
                for i = 1, self.member_size do
                    local uinfo = {}
                    uinfo.detail_flag = stream:readuchar()
                    local nickname_size = stream:readuchar()
                    if nickname_size > 0 and nickname_size < 0x1E then
                        uinfo.nickname = stream:read(nickname_size)
                    end
                    uinfo.menpai = stream:readint()
                    uinfo.sceneid = stream:readshort()
                    uinfo.level = stream:readuint()
                    uinfo.model = stream:readshort() --0
                    uinfo.unknow_6 = stream:readint()   --0
                    uinfo.unknow_7 = stream:readshort() --3
                    -- if uinfo.detail_flag ~= 0 then
                        -- uinfo.weapon[define.WG_KEY_A] = stream:readint()
                        -- uinfo.weapon[define.WG_KEY_B] = stream:readint()
                        -- uinfo.weapon[define.WG_KEY_C] = stream:readushort()

                        -- uinfo.cap[define.WG_KEY_A] = stream:readint()
                        -- uinfo.cap[define.WG_KEY_B] = stream:readint()
                        -- uinfo.cap[define.WG_KEY_C] = stream:readushort()

                        -- uinfo.armour[define.WG_KEY_A] = stream:readint()
                        -- uinfo.armour[define.WG_KEY_B] = stream:readint()
                        -- uinfo.armour[define.WG_KEY_C] = stream:readushort()

                        -- uinfo.cuff[define.WG_KEY_A] = stream:readint()
                        -- uinfo.cuff[define.WG_KEY_B] = stream:readint()
                        -- uinfo.cuff[define.WG_KEY_C] = stream:readushort()

                        -- uinfo.foot[define.WG_KEY_A] = stream:readint()
                        -- uinfo.foot[define.WG_KEY_B] = stream:readint()
                        -- uinfo.foot[define.WG_KEY_C] = stream:readushort()

                        -- uinfo.unknow_7 = stream:readint()   -- 100
                        -- uinfo.fasion_visual = stream:readint()
                        -- uinfo.unknow_9 = stream:readint()   -- 0
                        -- uinfo.fashion[define.WG_KEY_A] = stream:readint()
                        -- uinfo.fashion[define.WG_KEY_D] = stream:readint()  -- -1
                        -- uinfo.fashion[define.WG_KEY_E] = stream:readint()  -- -1
                        -- uinfo.fashion[define.WG_KEY_F] = stream:readint()  -- -1
                        -- uinfo.unknow_14 = stream:readuint() -- 3394306053
                        -- uinfo.fashion[define.WG_KEY_C] = stream:readushort() -- 1744

                        -- uinfo.unknow_7 = stream:readint()   -- 100
                        -- uinfo.fasion_visual = stream:readint()
                        -- uinfo.unknow_9 = stream:readint()   -- 0
                        -- uinfo.fashion = stream:readint()
                        -- uinfo.unknow_11 = stream:readint()  -- -1
                        -- uinfo.unknow_12 = stream:readint()  -- -1
                        -- uinfo.unknow_13 = stream:readint()  -- -1
                        -- uinfo.unknow_14 = stream:readuint() -- 3394306053
                        -- uinfo.unknow_15 = stream:readushort() -- 1744
                    -- end
                    table.insert(self.member_list, uinfo)
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.guid)
            self.nickname = gbk.fromutf8(self.nickname)
            stream:write(self.nickname, 0x1E)
            stream:writeshort(self.unknow_1)
            stream:writeuchar(self.member_size)
            if self.member_size > 6 then
                self.member_size = 6 
            end
            if self.member_size > 0 then
                for i = 1, self.member_size do
                    local uinfo = self.member_list[i]
                    stream:writeuchar(uinfo.detail_flag or 0)
                    uinfo.nickname = gbk.fromutf8(uinfo.nickname)
                    local nickname_size = string.len(uinfo.nickname)
                    stream:writeuchar(nickname_size)
                    if nickname_size > 0 and nickname_size <= 0x1E then
                        stream:write(uinfo.nickname, nickname_size)
                    end
                    stream:writeint(uinfo.menpai)
                    stream:writeshort(uinfo.sceneid)
                    stream:writeint(uinfo.level)
                    stream:writeshort(uinfo.model == 1 and 1 or 0)
                    stream:writeint(uinfo.unknow_6 or 0)
                    stream:writeshort(uinfo.model == 1 and 1 or 0)
                    -- if uinfo.detail_flag ~= 0 then
                        -- stream:writeint(uinfo.weapon[define.WG_KEY_A])
                        -- stream:writeint(uinfo.weapon[define.WG_KEY_B])
                        -- stream:writeushort(uinfo.weapon[define.WG_KEY_C])

                        -- stream:writeint(uinfo.cap[define.WG_KEY_A])
                        -- stream:writeint(uinfo.cap[define.WG_KEY_B])
                        -- stream:writeushort(uinfo.cap[define.WG_KEY_C])

                        -- stream:writeint(uinfo.armour[define.WG_KEY_A])
                        -- stream:writeint(uinfo.armour[define.WG_KEY_B])
                        -- stream:writeushort(uinfo.armour[define.WG_KEY_C])

                        -- stream:writeint(uinfo.cuff[define.WG_KEY_A])
                        -- stream:writeint(uinfo.cuff[define.WG_KEY_B])
                        -- stream:writeushort(uinfo.cuff[define.WG_KEY_C])

                        -- stream:writeint(uinfo.foot[define.WG_KEY_A])
                        -- stream:writeint(uinfo.foot[define.WG_KEY_B])
                        -- stream:writeushort(uinfo.foot[define.WG_KEY_C])

                        -- stream:writeint(uinfo.unknow_7 or 100)
                        -- stream:writeint(uinfo.fasion_visual or 0)
                        -- stream:writeint(uinfo.unknow_9 or 0)
                        -- stream:writeint(uinfo.fashion[define.WG_KEY_A])
                        -- stream:writeint(uinfo.fashion[define.WG_KEY_D])
                        -- stream:writeint(uinfo.fashion[define.WG_KEY_E])
                        -- stream:writeint(uinfo.fashion[define.WG_KEY_F])
                        -- stream:writeushort(uinfo.fashion[define.WG_KEY_C])

                        -- stream:writeint(uinfo.unknow_7 or 100)
                        -- stream:writeint(uinfo.fasion_visual)
                        -- stream:writeint(uinfo.unknow_9 or 0)
                        -- stream:writeint(uinfo.fashion)
                        -- stream:writeint(uinfo.unknow_11 or -1)
                        -- stream:writeint(uinfo.unknow_12 or -1)
                        -- stream:writeint(uinfo.unknow_13 or -1)
                        -- stream:writeushort(uinfo.unknow_15 or 1744)
                    -- end
                end
            end
            stream:writeuint(71147369)
            return stream:get()
        end 
    }


    packet.CGTeamRetInvite = {
        xy_id = packet.XYID_CG_TEAM_RET_INVITE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGTeamRetInvite })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.return_type = stream:readuchar()
            self.guid = stream:readuint()
            self.unknow_3 = stream:readuint()
            for i = 1, 8 do
                self.list[i] = stream:readuint()
            end
        end
    }


    packet.GCTeamMemberInfo = {
        xy_id = packet.XYID_GC_TEAM_MEMBER_INFO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCTeamMemberInfo })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.unknow_19 = 0
            self.flag = 0
            self.data_index = 0
        end,
        set_menpai = function(self, menpai)
            self.menpai = menpai
            self.flag = menpai and self.flag | 0x1 or self.flag & ~0x1
        end,
        set_level = function(self, level)
            self.level = level
            self.flag = level and self.flag | 0x2 or self.flag & ~0x2
        end,
        set_world_pos = function(self, world_pos)
            self.world_pos = world_pos
            self.flag = world_pos and self.flag | 0x4 or self.flag & ~0x4
        end,
        set_hp = function(self, hp)
            self.hp = hp
            self.flag = hp and self.flag | 0x8 or self.flag & ~0x8
        end,
        set_hp_max = function(self, hp_max)
            self.hp_max = hp_max
            self.flag = hp_max and self.flag | 0x10 or self.flag & ~0x10
        end,
        set_mp = function(self, mp)
            self.mp = mp
            self.flag = mp and self.flag | 0x20 or self.flag & ~0x20
        end,
        set_mp_max = function(self, mp_max)
            self.mp_max = mp_max
            self.flag = mp_max and self.flag | 0x40 or self.flag & ~0x40
        end,
        set_rage = function(self, rage)
            self.rage = rage
            self.flag = rage and self.flag | 0x80 or self.flag & ~0x80
        end,
        set_weapon = function(self, weapon)
    		if weapon then
    			self.weapon = weapon
    			self.flag = self.flag | 0x100
    		else
    			self.flag = self.flag & ~0x100
    		end
        end,
        set_cap = function(self, cap)
    		if cap then
    			self.cap = cap
    			self.flag = self.flag | 0x200
    		else
    			self.flag = self.flag & ~0x200
    		end
        end,
        set_armour = function(self, armour)
    		if armour then
    			self.armour = armour
    			self.flag = self.flag | 0x400
    		else
    			self.flag = self.flag & ~0x400
    		end
        end,
        set_cuff = function(self, cuff)
    		if cuff then
    			self.cuff = cuff
    			self.flag = self.flag | 0x800
    		else
    			self.flag = self.flag & ~0x800
    		end
        end,
        set_foot = function(self, foot)
    		if foot then
    			self.foot = foot
    			self.flag = self.flag | 0x1000
    		else
    			self.flag = self.flag & ~0x1000
    		end
        end,
        set_fashion = function(self, fashion)
    		if fashion then
    			self.fashion = fashion
    			self.flag = self.flag | 0x80000
    		else
    			self.flag = self.flag & ~0x80000
    		end
        end,
        set_face_style = function(self, face_style)
            self.unknow_11 = face_style or 0
            self.flag = self.flag | 0x10000
        end,
        set_hair_style = function(self, hair_style)
            self.unknow_12 = hair_style or 0
            self.flag = self.flag | 0x20000
        end,
        set_hair_color = function(self, hair_color)
            self.unknow_13 = hair_color or 0
            self.flag = self.flag | 0x40000
        end,
        set_exterior_back = function(self, exterior_id, exterior_pos)
            self.exterior_back_id = exterior_id or 0
            self.exterior_back_pos = exterior_pos or 0
            self.flag = self.flag | 0x200000
        end,
        set_exterior_head = function(self, exterior_id, exterior_pos)
            self.exterior_head_id = exterior_id or 0
            self.exterior_head_pos = exterior_pos or 0
            self.flag = self.flag | 0x400000
        end,
        set_pet_soul_melting_model = function(self, model)
            model = tonumber(model)
            if model and model >= 0 then
                self.pet_soul_melting_model = model
                self.flag = self.flag | 0x800000
            else
                self.pet_soul_melting_model = define.INVAILD_ID
                self.flag = self.flag & ~0x800000
            end
        end,
        set_ride_model = function(self, model)
            model = tonumber(model)
            if model and model >= 0 then
                self.ride_model = model
                self.flag = self.flag | 0x1000000
            else
                self.ride_model = define.INVAILD_ID
                self.flag = self.flag & ~0x1000000
            end
        end,
        bis = function(self, buffer)
            -- local stream = bistream.new()
            -- stream:attach(buffer)
            -- self.guid = stream:readint()
            -- self.data_index = stream:readint()
            -- self.flag = stream:readuint()
            -- if self.flag & 0x1 == 0x1 then
                -- self.menpai = stream:readuint()
            -- end
            -- if self.flag & 0x2 == 0x2 then
                -- self.level = stream:readuint()
            -- end
            -- if self.flag & 0x4 == 0x4 then
                -- self.world_pos = {}
                -- self.world_pos.x = stream:readfloat()
                -- self.world_pos.y = stream:readfloat()
            -- end
            -- if self.flag & 0x8 == 0x8 then
                -- self.hp = stream:readuint()
            -- end
            -- if self.flag & 0x10 == 0x10 then
                -- self.hp_max = stream:readuint()
            -- end
            -- if self.flag & 0x20 == 0x20 then
                -- self.mp = stream:readuint()
            -- end
            -- if self.flag & 0x40 == 0x40 then
                -- self.mp_max = stream:readuint()
            -- end
            -- if self.flag & 0x80 == 0x80 then
                -- self.rage = stream:readuint()
            -- end
            -- if self.flag & 0x100 == 0x100 then
    			-- self.weapon = {}
                -- self.weapon[define.WG_KEY_A] = stream:readint()
                -- self.weapon[define.WG_KEY_B] = stream:readint()
                -- self.weapon[define.WG_KEY_C] = stream:readushort()
            -- end
            -- if self.flag & 0x200 == 0x200 then
    			-- self.cap = {}
                -- self.cap[define.WG_KEY_A] = stream:readint()
                -- self.cap[define.WG_KEY_B] = stream:readint()
                -- self.cap[define.WG_KEY_C] = stream:readushort()
            -- end
            -- if self.flag & 0x400 == 0x400 then
    			-- self.armour = {}
                -- self.armour[define.WG_KEY_A] = stream:readint()
                -- self.armour[define.WG_KEY_B] = stream:readint()
                -- self.armour[define.WG_KEY_C] = stream:readushort()
            -- end
            -- if self.flag & 0x800 == 0x800 then
    			-- self.cuff = {}
                -- self.cuff[define.WG_KEY_A] = stream:readint()
                -- self.cuff[define.WG_KEY_B] = stream:readint()
                -- self.cuff[define.WG_KEY_C] = stream:readushort()
            -- end
            -- if self.flag & 0x1000 == 0x1000 then
    			-- self.foot = {}
                -- self.foot[define.WG_KEY_A] = stream:readint()
                -- self.foot[define.WG_KEY_B] = stream:readint()
                -- self.foot[define.WG_KEY_C] = stream:readushort()
            -- end
            -- if self.flag & 0x4000 == 0x4000 then
                -- self.strike_point = stream:readuchar()
            -- end
            -- if self.flag & 0x8000 == 0x8000 then
                -- self.unknow_10 = stream:readuchar()
            -- end
            -- if self.flag & 0x10000 == 0x10000 then
                -- self.unknow_11 = stream:readuint()
            -- end
            -- if self.flag & 0x20000 == 0x20000 then
                -- self.unknow_12 = stream:readuint()
            -- end
            -- if self.flag & 0x40000 == 0x40000 then
                -- self.unknow_13 = stream:readuint()
            -- end
            -- if self.flag & 0x80000 == 0x80000 then
    			-- self.fashion = {}
                -- self.fashion[define.WG_KEY_A] = stream:readint()
                -- self.fashion[define.WG_KEY_D] = stream:readint()
                -- self.fashion[define.WG_KEY_E] = stream:readint()
                -- -- self.fashion[define.WG_KEY_F] = stream:readint()
                -- self.fashion[define.WG_KEY_C] = stream:readshort()
            -- end
            -- if self.flag & 0x100000 == 0x100000 then
                -- self.unknow_18 = stream:readuint()
            -- end
            -- self.unknow_19 = stream:readchar()
        end,
        bos = function(self)
            -- 客户端只将该字节与 0x9C 标记比较；它不是 RaceID。
            local tail_marker = tonumber(self.unknow_19) or 0
            if tail_marker < 0 or tail_marker > 0xFF then
                tail_marker = 0
            end
            self.unknow_19 = tail_marker
            if self.flag & 0x800000 == 0x800000
                and (tonumber(self.pet_soul_melting_model) or define.INVAILD_ID) < 0 then
                self.flag = self.flag & ~0x800000
            end
            if self.flag & 0x1000000 == 0x1000000
                and (tonumber(self.ride_model) or define.INVAILD_ID) < 0 then
                self.flag = self.flag & ~0x1000000
            end
            local stream = bostream.new()
            stream:writeint(self.guid)
            stream:writeuint(self.data_index)
            stream:writeint(self.flag)
            if self.flag & 0x1 == 0x1 then
                stream:writeint(self.menpai)
            end
            if self.flag & 0x2 == 0x2 then
                stream:writeint(self.level)
            end
            if self.flag & 0x4 == 0x4 then
                stream:writefloat(self.world_pos.x)
                stream:writefloat(self.world_pos.y)
            end
            if self.flag & 0x8 == 0x8 then
                stream:writeuint(self.hp)
            end
            if self.flag & 0x10 == 0x10 then
                stream:writeuint(self.hp_max)
            end
            if self.flag & 0x20 == 0x20 then
                stream:writeuint(self.mp)
            end
            if self.flag & 0x40 == 0x40 then
                stream:writeuint(self.mp_max)
            end
            if self.flag & 0x80 == 0x80 then
                stream:writeuint(self.rage)
            end
            if self.flag & 0x100 == 0x100 then
                stream:writeint(self.weapon[define.WG_KEY_A])
                stream:writeint(self.weapon[define.WG_KEY_B])
                stream:writeshort(self.weapon[define.WG_KEY_C])
            end
            if self.flag & 0x200 == 0x200 then
                stream:writeint(self.cap[define.WG_KEY_A])
                stream:writeint(self.cap[define.WG_KEY_B])
                stream:writeshort(self.cap[define.WG_KEY_C])
            end
            if self.flag & 0x400 == 0x400 then
                stream:writeint(self.armour[define.WG_KEY_A])
                stream:writeint(self.armour[define.WG_KEY_B])
                stream:writeshort(self.armour[define.WG_KEY_C])
            end
            if self.flag & 0x800 == 0x800 then
                stream:writeint(self.cuff[define.WG_KEY_A])
                stream:writeint(self.cuff[define.WG_KEY_B])
                stream:writeshort(self.cuff[define.WG_KEY_C])
            end
            if self.flag & 0x1000 == 0x1000 then
                stream:writeint(self.foot[define.WG_KEY_A])
                stream:writeint(self.foot[define.WG_KEY_B])
                stream:writeshort(self.foot[define.WG_KEY_C])
            end
            if self.flag & 0x4000 == 0x4000 then
                stream:writeuchar(self.strike_point)
            end
            if self.flag & 0x8000 == 0x8000 then
                stream:writeuchar(self.unknow_10)
            end
            if self.flag & 0x10000 == 0x10000 then
                stream:writeuint(self.unknow_11)
            end
            if self.flag & 0x20000 == 0x20000 then
                stream:writeuint(self.unknow_12)
            end
            if self.flag & 0x40000 == 0x40000 then
                stream:writeuint(self.unknow_13)
            end
            if self.flag & 0x80000 == 0x80000 then
                stream:writeint(self.fashion[define.WG_KEY_A])
                stream:writeint(self.fashion[define.WG_KEY_D])
                stream:writeint(self.fashion[define.WG_KEY_E])
                stream:writeint(self.fashion[define.WG_KEY_F])
                stream:writeshort(self.fashion[define.WG_KEY_C])
            end
            if self.flag & 0x100000 == 0x100000 then
                stream:writeuint(self.unknow_18)
            end
            if self.flag & 0x200000 == 0x200000 then
                stream:writeshort(self.exterior_back_id)
                stream:writeint(self.exterior_back_pos)
            end
            if self.flag & 0x400000 == 0x400000 then
                stream:writeshort(self.exterior_head_id)
                stream:writeint(self.exterior_head_pos)
            end
            stream:writeuchar(self.unknow_19)
            if self.flag & 0x800000 == 0x800000 then
                stream:writeint(self.pet_soul_melting_model)
            end
            if self.flag & 0x1000000 == 0x1000000 then
                stream:writeint(self.ride_model)
            end
            return stream:get()
        end
    }


    packet.CGTeamLeave = {
        xy_id = packet.XYID_CG_TEAM_LEAVE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGTeamLeave })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.guid = stream:readint()
        end
    }


    packet.GCTeamFollowList = {
        xy_id = packet.XYID_GC_TEAM_FOLLOW_LIST,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCTeamFollowList })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.guids = {}
        end,
        bos = function(self)
            local stream = bostream.new()
            local count = math.min(#self.guids, 6)
            stream:writeint(self.m_objID)
            stream:writeuchar(count)
            for i = 1, count do
                stream:writeint(self.guids[i])
            end
            return stream:get()
        end
    }


    packet.GCTeamFollowErr = {
        xy_id = packet.XYID_GC_TEAM_FOLLOW_ERR,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCTeamFollowErr })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.error)
            return stream:get()
        end
    }


    packet.CGTeamKick = {
        xy_id = packet.XYID_CG_TEAM_KICK,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGTeamKick })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.source_guid = stream:readint()
            self.dest_guid = stream:readint()
        end
    }


    packet.CGTeamApply = {
        xy_id = packet.XYID_CG_TEAM_APPLY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGTeamApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.source_guid = stream:readint()
            self.unknow_1= stream:readint()
            local len = stream:readuchar()
            if len > 0 and len < 0x1E then
                self.dest_name = stream:read(len)
                self.dest_name = gbk.toutf8(self.dest_name)
            end
            self.unknow_2 = stream:readushort()
        end
    }


    packet.CGTeamRetApply = {
        xy_id = packet.XYID_CG_TEAM_RET_APPLY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGTeamRetApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.return_type = stream:readuchar()       -- 1 byte
            self.source_guid = stream:readint()         -- 4 bytes
            self.dest_guid = stream:readint()           -- 4 bytes (IDA offset 32)
            self.team_guids = {}
            for i = 1, 8 do
                self.team_guids[i] = stream:readint()   -- 8 x 4 = 32 bytes
            end
            -- Total: 1 + 4 + 4 + 32 = 41 bytes (matches IDA GetPacketSize)
        end
    }


    packet.CGTeamLeaderRetInvite = {
        xy_id = packet.XYID_CG_TEAM_LEADER_RET_INVITE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGTeamLeaderRetInvite })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.return_type = stream:readuchar()
            self.source_guid = stream:readint()
            self.dest_guid = stream:readint()
            self.guids = {}
            for i = 1, 8 do
                self.guids[i] = stream:readint()
            end
            self.team_guids = {}
            for i = 1, 8 do
                self.team_guids[i] = stream:readint()
            end
        end
    }


    packet.GCTeamAskApply = {
        xy_id = packet.XYID_GC_TEAM_ASK_APPLY,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCTeamAskApply })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.source_guid)
            stream:writeint(self.dest_guid)
            self.source_name = gbk.fromutf8(self.source_name)
            self.dest_name = gbk.fromutf8(self.dest_name)
            local source_len = string.len(self.source_name)
            local dest_len = string.len(self.dest_name)
            stream:writeuchar(source_len)
            stream:writeuchar(dest_len)
            if source_len < 0x1E then
                stream:write(self.source_name, source_len)
            end
            if dest_len < 0x1E then
                stream:write(self.dest_name, dest_len)
            end
            local uinfo = self.uinfo
            stream:writeuint(uinfo.menpai)
            stream:writeushort(uinfo.sceneid)
            stream:writeuint(uinfo.level)
            stream:writeuchar(uinfo.detail_flag or 0)
            stream:writeushort(uinfo.model == 1 and 1 or 0)
            stream:writeint(uinfo.unknow_1 or 2)
            stream:writeshort(uinfo.unknow_2 or -1)

    		-- stream:writeint(uinfo.weapon[define.WG_KEY_A])
    		-- stream:writeint(uinfo.weapon[define.WG_KEY_B])
    		-- stream:writeushort(uinfo.weapon[define.WG_KEY_C])

    		-- stream:writeint(uinfo.cap[define.WG_KEY_A])
    		-- stream:writeint(uinfo.cap[define.WG_KEY_B])
    		-- stream:writeushort(uinfo.cap[define.WG_KEY_C])

    		-- stream:writeint(uinfo.armour[define.WG_KEY_A])
    		-- stream:writeint(uinfo.armour[define.WG_KEY_B])
    		-- stream:writeushort(uinfo.armour[define.WG_KEY_C])

    		-- stream:writeint(uinfo.cuff[define.WG_KEY_A])
    		-- stream:writeint(uinfo.cuff[define.WG_KEY_B])
    		-- stream:writeushort(uinfo.cuff[define.WG_KEY_C])

    		-- stream:writeint(uinfo.foot[define.WG_KEY_A])
    		-- stream:writeint(uinfo.foot[define.WG_KEY_B])
    		-- stream:writeushort(uinfo.foot[define.WG_KEY_C])

    		-- stream:writeint(100)
    		-- stream:writeint(0)
    		-- stream:writeint(0)

    		-- -- stream:writeint(uinfo.unknow_7 or 100)
    		-- -- stream:writeint(uinfo.equip.fasion_visual)
    		-- -- stream:writeint(uinfo.unknow_9 or 0)

    		-- stream:writeint(uinfo.fashion[define.WG_KEY_A])
    		-- stream:writeint(uinfo.fashion[define.WG_KEY_D])
    		-- stream:writeint(uinfo.fashion[define.WG_KEY_E])
    		-- stream:writeint(uinfo.fashion[define.WG_KEY_F])
    		-- stream:writeushort(uinfo.fashion[define.WG_KEY_C])

            -- if uinfo.detail_flag == 1 then
                -- stream:writeuint(uinfo.equip.weapon)
                -- stream:writeint(uinfo.equip.weapon_gem)
                -- stream:writeushort(uinfo.equip.weapon_visual)
                -- stream:writeuint(uinfo.equip.cap)

                -- stream:writeint(uinfo.equip.cap_gem)
                -- stream:writeushort(uinfo.equip.cap_visual)

                -- stream:writeuint(uinfo.equip.armour)
                -- stream:writeint(uinfo.equip.armour_gem)
                -- stream:writeushort(uinfo.equip.armour_visual)

                -- stream:writeuint(uinfo.equip.cuff)
                -- stream:writeint(uinfo.equip.cuff_gem)
                -- stream:writeushort(uinfo.equip.cuff_visual)

                -- stream:writeuint(uinfo.equip.foot)
                -- stream:writeint(uinfo.equip.foot_gem)
                -- stream:writeushort(uinfo.equip.foot_visual)

                -- stream:writeint(uinfo.unknow_7 or 100)
                -- stream:writeint(uinfo.equip.fasion_visual)
                -- stream:writeint(uinfo.unknow_9 or 0)
                -- stream:writeint(uinfo.equip.fashion)
                -- stream:writeint(uinfo.unknow_11 or -1)
                -- stream:writeint(uinfo.unknow_12 or -1)
                -- stream:writeint(uinfo.unknow_13 or -1)
                -- stream:writeushort(uinfo.unknow_14 or 0)
            -- end
            stream:writeuint(uinfo.unknow_15 or 39344113)
            return stream:get()
        end
    }


    packet.CGTeamAppoint = {
        xy_id = packet.XYID_CG_TEAM_APPOINT,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGTeamAppoint })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.source_guid = stream:readint()
            self.dest_guid = stream:readint()
        end
    }


    packet.CGExchangeApplyI = {
        xy_id = packet.XYID_CG_EXCHANGE_APPLY_I,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGExchangeApplyI })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.m_objID = stream:readint()
            self.unknow = stream:readint()
        end
    }


    packet.GCExchangeError = {
        xy_id = packet.XYID_GC_EXCHANGE_ERROR,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangeError })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.error_code)
            return stream:get()
        end
    }


    packet.GCExchangeApplyI = {
        xy_id = packet.XYID_GC_EXCHANGE_APPLY_I,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangeApplyI })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.source_oid = stream:readint()
            self.source_guid = stream:readint()
            local len = stream:readuint()
            if len < 30 then
                self.source_name = stream:read(len)
            end
            self.source_name = gbk.toutf8(self.source_name)
            self.source_level = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.source_oid)
            stream:writeint(self.source_guid)
            self.source_name = gbk.fromutf8(self.source_name)
            local len = string.len(self.source_name)
            stream:writeuint(len)
            if len < 30 then
                stream:write(self.source_name, len)
            end
            stream:writeint(self.source_level)
            return stream:get()
        end
    }


    packet.GCExchangeEstablishI = {
        xy_id = packet.XYID_GC_EXCHANGE_ESTABLISH_I,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangeEstablishI })
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


    packet.GCExchangeNotifySerial = {
        xy_id = packet.XYID_GC_EXCHANGE_NOTIFY_SERIAL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangeNotifySerial })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.serial = stream:readint()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.serial)
            return stream:get()
        end
    }


    packet.CGExchangeReplyI = {
        xy_id = packet.XYID_CG_EXCHANGE_REPLY_I,  -- 原 XYID_GC_EXCHANGE_REPLY_I, CG方向
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGExchangeReplyI })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.source_oid = stream:readint()
            self.soure_guid = stream:readint()
        end
    }


    packet.CGExchangeSynchItemII = {
        xy_id = packet.XYID_CG_EXCHANGE_SYNCH_ITEM_II,
        OPT = {
    		OPT_ERROR = 0,
    		OPT_ADDITEM = 1,
    		OPT_REMOVEITEM = 2,
    		OPT_MONEY = 3,
    		OPT_REMOVEMONEY = 4,
    		OPT_ADDPET = 5,
    		OPT_REMOVEPET = 6,
        },
        POS = 
    	{
    		POS_ERR	= 0,
    		POS_BAG = 1,	--背包
    		POS_EQUIP = 2,	--装备
    		POS_PET = 3,    --宠物
    	},
        ERR =
    	{
    		ERR_ERR = 0,
    		ERR_SELF_IN_EXCHANGE = 1,
    		ERR_TARGET_IN_EXCHANGE = 2,
    		ERR_DROP = 3,
    		ERR_ALREADY_LOCKED = 4,
    		ERR_ILLEGAL = 5,
    		ERR_NOT_ENOUGHT_ROOM_SELF = 6,
    		ERR_NOT_ENOUGHT_ROOM_OTHER = 7,
    		ERR_NOT_ENOUGHT_EXROOM = 8,
    		ERR_NOT_ENOUGHT_MONEY_SELF = 9,
    		ERR_NOT_ENOUGHT_MONEY_OTHER = 10,
    		ERR_TOO_FAR = 11,
    		ERR_REFUSE_TRADE = 12,
    		ERR_PET_LEVEL_TOO_HIGH = 13,
    	},
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGExchangeSynchItemII })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.opt = stream:readuchar()
            if self.opt == self.OPT.OPT_ADDITEM then
                self.from_type = stream:readuchar()
                self.from_index = stream:readuchar()
                self.series = stream:readint()
            elseif self.opt == self.OPT.OPT_ADDPET or self.opt == self.OPT.OPT_REMOVEPET then
                self.pet_guid = packet.PetGUID.new()
                self.pet_guid:bis(stream)
                self.series = stream:readint()
            elseif self.opt == self.OPT.OPT_REMOVEITEM then
                self.from_index = stream:readuchar()
                self.to_type = stream:readuchar()
                self.to_index = stream:readuchar()
                self.series = stream:readint()
            end
        end
    }


    packet.CGExchangeCancel = {
        xy_id = packet.XYID_CG_EXCHANGE_CANCEL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGExchangeCancel })
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


    packet.CGExchangeSynchLock = {
        xy_id = packet.XYID_CG_EXCHANGE_SYNCH_LOCK,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGExchangeSynchLock })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.lock_my_self = stream:readuchar()
            self.serial =  stream:readint()
        end
    }


    packet.CGExchangeOkIII = {
        xy_id = packet.XYID_CG_EXCHANGE_OK_III,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGExchangeOkIII })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.series =  stream:readint()
        end
    }


    packet.CGExchangeSynchMoneyII = {
        xy_id = packet.XYID_CG_EXCHANGE_SYNCH_MONEY_II,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGExchangeSynchMoneyII })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.money = stream:readuint()
            self.series =  stream:readint()
        end
    }


    packet.GCExchangeSynchLock = {
        xy_id = packet.XYID_GC_EXCHANGE_SYNCH_LOCK,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangeSynchLock })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow = stream:readushort()
            self.is_both = stream:readuchar()
            self.is_my_self = stream:readuchar()
            self.is_lockd = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeushort(self.unknow or 0)
            stream:writeuchar(self.is_both)
            stream:writeuchar(self.is_my_self)
            stream:writeuchar(self.is_lockd)
            return stream:get()
        end
    }


    packet.GCExchangeSynchConfirmII = {
        xy_id = packet.XYID_GC_EXCHANGE_SYNCH_CONFIRM_II,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangeSynchConfirmII })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.is_enable = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.is_enable)
            return stream:get()
        end
    }


    packet.GCExchangeSuccessIII = {
        xy_id = packet.XYID_GC_EXCHANGE_SUCCESS_III,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangeSuccessIII })
            o:ctor()
            return o
        end,
        ctor = function(self)
            self.item_list = {}
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.guid = stream:readint()
            self.item_num = stream:readuchar()
            if self.item_num < 0xA then
                self.item_list = {}
                for i = 1, 0xA do
                    local item = {}
                    item.from_type = stream:readuchar()
                    item.from_index = stream:readuchar()
                    item.to_type = stream:readuchar()
                    item.to_index = stream:readuchar()
                    self.item_list[i] = item
                end
            end
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.guid)
            stream:writeuchar(#self.item_list)
            if #self.item_list < 0xA then
                for _, item in ipairs(self.item_list) do
                    stream:writeuchar(item.from_type)
                    stream:writeuchar(item.from_index)
                    stream:writeuchar(item.to_type)
                    stream:writeuchar(item.to_index)
                end
            end
            return stream:get()
        end
    }


    packet.GCExchangeCancel = {
        xy_id = packet.XYID_GC_EXCHANGE_CANCEL,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangeCancel })
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


    packet.GCExchangeSynchII = {
        xy_id = packet.XYID_GC_EXCHANGE_SYNCH_II,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangeSynchII })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeuchar(self.is_my_self)
            stream:writeuchar(self.opt)
            stream:writeushort(self.unknow or 0)
            if self.is_my_self == 1 then
                if self.opt == 1 then
                    stream:writeuchar(self.from_type)
                    stream:writeuchar(self.from_index)
                    stream:writeuchar(self.to_index)
                elseif self.opt == 2 then
                    stream:writeuchar(self.to_type)
                    stream:writeuchar(self.to_index)
                    stream:writeuchar(self.from_index)
                elseif self.opt == 3 or self.opt == 4 then
                    stream:writeuint(self.money)
                elseif self.opt == 5 then
                    stream:writeuchar(self.to_index)
                    packet.PetGUID.bos(self.pet_guid, stream)
                elseif self.opt == 6 then
                    packet.PetGUID.bos(self.pet_guid, stream)
                end
            else
                if self.opt == 1  then
                    stream:writeuchar(self.to_index)
                    stream:writeuchar(self.is_blue_equip)
                    stream:writeuchar(self.by_number)
                    if self.is_blue_equip == 1 then
                        packet.EquipStream.bos(self.item_data, stream)
                    else
                        stream:writeuint(self.item_guid)
                    end
                elseif self.opt == 2 then
                    stream:writeuchar(self.from_index)
                elseif self.opt == 3 or self.opt == 4 then
                    stream:writeuint(self.money)
                elseif self.opt == 6 then
                    packet.PetGUID.bos(self.pet_guid, stream)
                end
            end
            return stream:get()
        end
    }


    packet.GCExchangeItemFromPlayerShopToBag_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangeItemFromPlayerShopToBag_t })
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


    packet.GCExchangeItemFromPlayerShopToPlayerShop_t = {
        xy_id = define.INVAILD_ID,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCExchangeItemFromPlayerShopToPlayerShop_t })
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
            self.shop_guid = packet.PlayerShopGUID.new()
            self.shop_guid:bis(stream)
            self.stall_index = stream:readuint()
            self.source_serial = stream:readuint()
            self.dest_serial = stream:readuint()
            self.shop_serial = stream:readuchar()
            self.unknow_1 = stream:readuchar()
            self.unknow_2 = stream:readuchar()
            self.unknow_3 = stream:readuchar()
        end,
        bos = function(self)
            local stream = bostream.new()
            packet.PlayerShopGUID.bos(self.shop_guid, stream)
            stream:writeuint(self.stall_index)
            stream:writeuint(self.source_serial)
            stream:writeuint(self.dest_serial)
            stream:writeuchar(self.shop_serial)
            stream:writeuchar(self.unknow_1)
            stream:writeuchar(self.unknow_2)
            stream:writeuchar(self.unknow_3)
            return stream:get()
        end
    }


    packet.GCTeamLeaderAskInvite = {
        xy_id = packet.XYID_GC_TEAM_LEADER_ASK_INVITE,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.GCTeamLeaderAskInvite })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.source_guid = stream:readint()
            self.dest_guid = stream:readint()
            local source_name_size = stream:readuchar()
            local dest_name_size = stream:readuchar()
            if source_name_size <= 0x1E then
                self.source_name = stream:read(source_name_size)
            end
            if dest_name_size <= 0x1E then
                self.dest_name = stream:read(dest_name_size)
            end
            self.unknow_1 = stream:readint()
            self.unknow_2 = stream:readint()
            self.unknow_3 = stream:readshort()
            self.unknow_4 = stream:readshort()
        end,
        bos = function(self, buffer)
            local stream = bostream.new()
            stream:writeint(self.source_guid)
            stream:writeint(self.dest_guid)
            self.source_name = gbk.fromutf8(self.source_name)
            self.dest_name = gbk.fromutf8(self.dest_name)
            local source_name_size = string.len(self.source_name)
            local dest_name_size = string.len(self.dest_name)
            stream:writeuchar(source_name_size)
            stream:writeuchar(dest_name_size)
            if source_name_size <= 0x1E then
                stream:write(self.source_name, source_name_size)
            end
            if dest_name_size <= 0x1E then
                stream:write(self.dest_name, dest_name_size)
            end
            stream:writeint(self.unknow_1 or define.INVAILD_ID)
            stream:writeint(self.unknow_2 or define.INVAILD_ID)
            stream:writeshort(self.unknow_3 or define.INVAILD_ID)
            stream:writeshort(self.unknow_4 or define.INVAILD_ID)
            return stream:get()
        end
    }


    packet.CGEXchangeYuanBaoPiao  = {
        xy_id = packet.XYID_CG_EXCHANGE_YUANBAO_PIAO,
        new = function()
            local o = {}
            setmetatable(o, { __index = packet.CGEXchangeYuanBaoPiao })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            stream:read(40)
            local b = stream:read(4)
            if b and #b >= 4 then
                self.count = string.unpack(">I4", b)
            else
                self.count = 0
            end
        end
    }


    packet.CGTeamChangeOption = {
        xy_id = packet.XYID_CG_TEAM_CHANGE_OPTION,
        new = function()
            local o = o or {}
            setmetatable(o, { __index = packet.CGTeamChangeOption })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readint()
            self.exp_mode = stream:readulong()
        end
    }


    packet.GCTeamOptionChanged = {
        xy_id = packet.XYID_GC_TEAM_OPTION_CHANGED,
        new = function()
            local o = o or {}
            setmetatable(o, { __index = packet.GCTeamOptionChanged })
            o:ctor()
            return o
        end,
        ctor = function(self)
        end,
        bis = function(self, buffer)
            local stream = bistream.new()
            stream:attach(buffer)
            self.unknow_1 = stream:readint()
            self.exp_mode = stream:readulong()
        end,
        bos = function(self)
            local stream = bostream.new()
            stream:writeint(self.unknow_1 or 0)
            stream:writeulong(self.exp_mode)
            return stream:get()
        end
    }

end
return M
