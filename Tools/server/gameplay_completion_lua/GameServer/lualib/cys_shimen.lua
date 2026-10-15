-- Preserve the nine authored school quest variants and their rewards.
-- Completion marker is numeric (Lua treats 0 as true); return code 2 opens
-- the item/pet selection dialogue and MUST NOT grant a direct submission.
local M={}
function M.install(cls)
    local check,submit,default=cls.CheckSubmit,cls.OnSubmit,cls.OnDefaultEvent
    function cls:CheckSubmit(who)
        if not self:IsHaveMission(who,self.g_MissionId)then return 0 end
        local index=self:GetMissionIndexByID(who,self.g_MissionId)
        local kind=self:GetMissionParam(who,index,1)
        if kind==self.g_SubMissionTypeEnum.XunWu then
            local id=self:GetMissionParam(who,index,self.g_StrForePart+1)
            if self:LuaFnGetAvailableItemCount(who,id)<1 then return 0 end
            return self:IsEquipItem(id)==1 and self:IsWhiteEquip(id)~=1 and 2 or 1
        end
        if kind~=self.g_SubMissionTypeEnum.ShouJi
            and kind~=self.g_SubMissionTypeEnum.BuZhuo then
            return (self:GetMissionParam(who,index,0) or 0)>0 and 1 or 0
        end
        return check(self,who)
    end
    function cls:GetItemDetailInfo(id)return self:GetItemInfoByItemId(id)end
    function cls:GetMenpaiYiWuInfo(who)
        for _,row in ipairs(self.g_MenpaiYiWuList)do
            if row.menpai==self:GetMenPai(who)then return row.menpainame,row.itemName,row.itemId,row.scene end
        end
    end
    function cls:OnSubmit(who,npc,...)
        if self:CheckSubmit(who)~=1 then return false end
        return submit(self,who,npc,...)
    end
    function cls:GetDemandKillCount(who)
        local level,last=self:GetLevel(who)
        for _,row in ipairs(self.g_DemandKillcountTable)do
            last=row
            if level<=row.levelEnd then return row.killcount end
        end
        -- Characters above the historical 150 ceiling retain its last authored band.
        return last and last.killcount
    end
    function cls:GetRateOfDropYiWu(who)
        local level,last=self:GetLevel(who)
        for _,row in ipairs(self.g_RateOfDropYiWuTable)do
            last=row
            if level<row.playerLevel then return row.dropRate end
        end
        return last and last.dropRate or 0
    end
    function cls:OnKillObject(who,model,monster)
        -- human:on_kill_object invokes a mission once per monster, then the
        -- authored school callback credits its owners. Check EACH owner's target.
        local name=self:GetMonsterNamebyDataId(model)
        for n=0,self:GetMonsterOwnerCount(monster)-1 do
            local owner=self:GetMonsterOwnerID(monster,n)
            if self:IsHaveMission(owner,self.g_MissionId)then
                local index=self:GetMissionIndexByID(owner,self.g_MissionId)
                if self:GetMissionParam(owner,index,1)==self.g_SubMissionTypeEnum.killMonster
                    and self:GetMissionParam(owner,index,0)<=0 then
                    local npc=self:GetMissionParam(owner,index,self.g_StrForePart+3)
                    local _,wanted=self:GetNpcInfoByNpcId(npc)
                    if wanted==name then
                        local goal=self:GetMissionParamEx(owner,index,3,0)
                        local current=self:GetMissionParamEx(owner,index,3,1)
                        if goal>0 and current<goal then
                            current=current+1;self:SetMissionParamByIndexEx(owner,index,3,1,current)
                            self:BeginEvent(self.script_id)
                            self:AddText(string.format('Đã tiêu diệt %d/%d %s',current,goal,name))
                            self:EndEvent();self:DispatchMissionTips(owner)
                            if current>=goal then self:SetMissionByIndex(owner,index,0,1)end
                        end
                    end
                end
            end
        end
    end
    function cls:OnDefaultEvent(who,npc,...)
        if self:IsHaveMission(who,self.g_MissionId) and self:GetName(npc)~=self.g_Name then
            local index=self:GetMissionIndexByID(who,self.g_MissionId)
            local kind=self:GetMissionParam(who,index,1)
            local wanted
            if kind==self.g_SubMissionTypeEnum.SongXin then
                local id=self:GetMissionParam(who,index,self.g_StrForePart+1)
                local _,name=self:GetNpcInfoByNpcId(id);wanted=name
            elseif kind==self.g_SubMissionTypeEnum.KaiGuang then
                wanted=self.g_StrList[self:GetMissionParam(who,index,self.g_StrForePart+1)+1]
            end
            if not wanted or self:GetName(npc)~=wanted then return false end
        end
        return default(self,who,npc,...)
    end
    for _,name in ipairs({'OnItemChanged','OnPetChanged','CheckCondition_UseItem','Active_UseItem','OnMissionCheck'})do
        local original=cls[name]
        if original then cls[name]=function(self,who,...)
            if not self:IsHaveMission(who,self.g_MissionId)then return 0 end
            return original(self,who,...)
        end end
    end
    return cls
end
return M
