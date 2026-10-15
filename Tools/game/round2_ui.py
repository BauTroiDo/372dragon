"""Reproducible overlays; canonical CY files are read-only inputs."""
import re,xml.etree.ElementTree as ET

def function(text,name,body):
    text,n=re.subn(r'^function '+re.escape(name)+r'\([^\n]*\)[^\n]*\n.*?^end\b',lambda _:body,text,count=1,flags=re.M|re.S)
    assert n==1,name
    return text

COMMON_UPDATE='''function CommonSkill_Update()
    CommonSkill_Target_Skill_Name:SetText("")
    CommonSkill_Target_Skill_Explain:SetText("")
    CommonSkill_Target_Skill:SetActionItem(-1)
    CommonSkill_Use:Hide()
    CommonSkill_ActionSkill:SetCheck(0)
    CommonSkill_LifeSkill:SetCheck(0)
    CommonSkill_CommonlySkill:SetCheck(1)
    local entries={}
    local pets={Pet:GetPetFightAction(),Pet:GetPetRelaxAction(),Pet:GetPetPossessionAction(),Pet:GetPetRestoreAction()}
    local tips={"#{Action_Pet_Fight_Exp}","#{Action_Pet_Relex_Exp}","#{ZSHT_BC_1008_13}","#{ZSHT_BC_1008_14}"}
    for i=1,4 do
        local a=pets[i]
        if a and a:GetID() and a:GetID()>0 then table.insert(entries,{id=a:GetID(),pet=i,name=a:GetName(),explain=tips[i]}) end
    end
    for i=0,GetActionNum("skill")-1 do
        local a=EnumAction(i,"skill")
        local id=a:GetDefineID()
        if a:GetID()>0 and a:GetOwnerXinfa()==-9999 and CommonSkill_IsZhenFaSkill(id)==0
            and (id<2500 or id>2547) and (id<3566 or id>3577) and (id<3588 or id>3590)
            and (id<4533 or id>4536) and (id<4528 or id>4529)
            and (id<g_commonskill_zdzdskill._start or id>g_commonskill_zdzdskill._end)
            and CommonSkill_IsZongMenSkill(id)==0 and IsLMSJSecond(id)==0 and IsJYJYSecond(id)==0 and IsWJQFSecond(id)==0 then
            table.insert(entries,{id=a:GetID(),skill=id})
        end
    end
    Current_Page=math.min(Current_Page,math.max(0,math.ceil(table.getn(entries)/COMMON_BUTTONS_NUM)-1))
    if Current_Page>0 then CommonSkill_PageUp:Enable() else CommonSkill_PageUp:Disable() end
    if (Current_Page+1)*COMMON_BUTTONS_NUM<table.getn(entries) then CommonSkill_PageDown:Enable() else CommonSkill_PageDown:Disable() end
    for i=1,COMMON_BUTTONS_NUM do
        local row=entries[Current_Page*COMMON_BUTTONS_NUM+i]
        COMMON_ROWS[i]=row
        COMMON_INDEX[i]=row and row.id or -1
        COMMON_BUTTONS[i]:SetPushed(0)
        COMMON_BUTTONS[i]:SetActionItem(COMMON_INDEX[i])
        if row and (row.pet or Player:GetSkillInfo(row.skill,"learn")) then COMMON_BUTTONS[i]:Enable() else COMMON_BUTTONS[i]:Disable() end
    end
    if not COMMON_ROWS[Current] then Current=1 end
    if COMMON_ROWS[Current] then CommonSkill_Buttons_Clicked(Current) end
end'''
COMMON_SELECT='''function CommonSkill_Buttons_Clicked(nIndex)
    local row=COMMON_ROWS[nIndex]
    if not row then return end
    COMMON_BUTTONS[Current]:SetPushed(0)
    Current=nIndex
    COMMON_BUTTONS[Current]:SetPushed(1)
    CommonSkill_Target_Skill:SetActionItem(row.id)
    if row.pet then
        CommonSkill_Target_Skill_Name:SetText(row.name)
        CommonSkill_Target_Skill_Explain:SetText(row.explain)
        CommonSkill_Target_Skill:Enable()
        CommonSkill_Use:Show()
    else
        CommonSkill_Target_Skill_Name:SetText(Player:GetSkillInfo(row.skill,"name"))
        CommonSkill_Target_Skill_Explain:SetText(Player:GetSkillInfo(row.skill,"explain").."\\n"..Player:GetSkillInfo(row.skill,"skilldata"))
        if Player:GetSkillInfo(row.skill,"learn") then CommonSkill_Target_Skill:Enable() else CommonSkill_Target_Skill:Disable() end
        if Player:GetSkillInfo(row.skill,"passivity")==0 and Player:GetSkillInfo(row.skill,"learn") then CommonSkill_Use:Show() else CommonSkill_Use:Hide() end
    end
end'''
COMMON_USE='''function CommonSkill_Button_Clicked()
    local row=COMMON_ROWS[Current]
    if row and (row.pet or (Player:GetSkillInfo(row.skill,"passivity")==0 and Player:GetSkillInfo(row.skill,"learn"))) then
        CommonSkill_Target_Skill:DoAction()
    end
end'''

def lua(data,name):
    t=data.decode('utf8')
    if name=='CommonSkill':
        t='local COMMON_ROWS={} -- CYS: compact valid actions, preserve pet identity across pages.\n'+t
        for fn,body in [('Update',COMMON_UPDATE),('Buttons_Clicked',COMMON_SELECT),('Button_Clicked',COMMON_USE)]:
            t=function(t,'CommonSkill_'+fn,body)
    elif name=='MainMenuBar_2':
        t=t.replace('function MainMenuBar_2_PreLoad()', 'function MainMenuBar_2_PreLoad()\n    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)\n    this:RegisterEvent("ADJEST_UI_POS",false)')
        t=t.replace('function MainMenuBar_2_OnEvent(event)', 'function MainMenuBar_2_OnEvent(event)\n    if event=="VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then MainMenuBar_2_AdjustMoveCtl() end')
        t=t.replace('MainMenuBar_2_PlayAnimate()','MainMenuBar_2_AdjustMoveCtl()\n            MainMenuBar_2_PlayAnimate()',1)
        t=function(t,'MainMenuBar_2_AdjustMoveCtl','''function MainMenuBar_2_AdjustMoveCtl(screenWidth,screenHeight)
    -- F1 is at screen centre -180, bottom -58. Alt+1 is directly above it.
    MainMenuBar_2_Frame:SetProperty("UnifiedPosition","{{0.5,-186},{1,-106}}")
end''')
    elif name=='MainMenuBar':
        old='function MainMenuBar_OnEvent(event)'
        assert old in t
        t=t.replace(old,old+'\n    if event=="PLAYER_ENTERING_WORLD" then PushEvent("OPEN_MENUBAR_2","1") end',1)
    elif name=='SelfEquip':
        t,n=re.subn(r'(NEEDEXP"\)\s*\*)\s*4\b',r'\1 3.5',t)
        assert n>=1,'SelfEquip EXP cap'
    elif name=='ZhenfaSkill':
        t=function(t,'ZhenfaSkill_Updataqingyi','''function ZhenfaSkill_Updataqingyi()
    ZhenfaSkill_QingyiNum_All:SetText("Trận kết nghĩa")
    ZhenfaSkill_QingyiNum_Have:SetText("Học để sử dụng")
end''')
        t=function(t,'ZhenfaSkill_UpdataSkill','''function ZhenfaSkill_UpdataSkill()
    for i=1,4 do
        local a=EnumAction(g_ZhenfaSkill_Skill[i],"zhenfaskill")
        g_ZhenfaActionID[i]=a and a:GetID() or -1
    end
    for index=0,GetActionNum("skill")-1 do
        local a=EnumAction(index,"skill")
        for i=1,4 do
            if a:GetDefineID()==g_ZhenfaSkill_Skill[i] and Player:GetSkillInfo(g_ZhenfaSkill_Skill[i],"learn") then g_ZhenfaActionID[i]=a:GetID() end
        end
    end
    for i=1,4 do g_SKillAction[i]:SetActionItem(g_ZhenfaActionID[i]) end
end''')
        t=function(t,'ZhenfaSkill_SetSelectSkillInfo','''function ZhenfaSkill_SetSelectSkillInfo(index)
    for i=1,4 do g_SKillAction[i]:SetPushed(i==index and 1 or 0) end
    local id=g_ZhenfaSkill_Skill[index]
    local learned=Player:GetSkillInfo(id,"learn")
    if learned then ZhenfaSkill_Use:Enable() else ZhenfaSkill_Use:Disable() end
    ZhenfaSkill_ZhenfaTarget:SetActionItem(g_ZhenfaActionID[index])
    ZhenfaSkill_Info_Name:SetText(g_ZhenfaName[index])
    ZhenfaSkill_Info_Level:SetText(learned and ("Cấp "..Player:GetSkillInfo(id,"level")) or "Chưa học")
    ZhenfaSkill_Explain:SetText(Player:GetSkillInfo(id,"explain").."#r"..Player:GetSkillInfo(id,"skilldata"))
end''')
    elif name=='AutoAttackSkill':
        # ComboBox text does not pass through the StaticText dictionary expander.
        t=re.sub(r'AddTextItem\("#\{([^}]+)\}",',r'AddTextItem(GetDictionaryString("\1"),',t)
        t=t.replace('GetDictionaryString("ZDZD_200724_52")','"Không dùng"')
        for key,label in [('09','Tự chiến đấu'),('27','Bắt đầu'),('28','Dừng')]:
            t=t.replace('#{ZDZD_200724_'+key+'}',label)
    if name in ['CommonSkill','ActionSkill','LifeSkill','ZhenfaSkill','AutoAttackSkill']:
        t=t.replace('if DataPool:Lua_CheckOpenTalent() == 1 then', '''if Player:GetData("LEVEL") < 120 then
        PushDebugMessage("Thiên phú môn phái yêu cầu cấp 120; thiên phú cốt lõi yêu cầu cấp 129.")
        g_'''+name+'''_PageButton[nPageNumber]:SetCheck(0)
        '''+name+'''_ClearPage()
    elseif DataPool:Lua_CheckOpenTalent() == 1 then''')
    return t.encode('utf8')

def layout(data,name):
    root=ET.fromstring(data)
    def prop(w,key,value):
        p=next((x for x in w.findall('Property') if x.get('Name')==key),None)
        if p is None:p=ET.SubElement(w,'Property',Name=key)
        p.set('Value',value)
    if name=='MainMenuBar_2':
        for w in root.iter('Window'):
            if w.get('Name')=='MainMenuBar_2_Frame':
                prop(w,'UnifiedPosition','{{0.5,-186},{1,-106}}')
                for key in ['MouseHollow','MouseLButtonHollow','MouseRButtonHollow','MouseMoveHollow']:prop(w,key,'True')
            m=re.fullmatch(r'MainMenuBar_2_Button_Action(\d+)',w.get('Name',''))
            if m:
                w.set('Type','TLBB_ActionButtonNULL') # Alt row: native transparent look, icons/cooldowns remain visible.
                prop(w,'CornerChar','TopRight A'+str(int(m[1])%10))
    elif name in ['ZhenfaSkill','AutoAttackSkill']:
        for w in root.iter('Window'):
            n=w.get('Name','')
            if n in ['ZhenfaSkill_Frame1_Title','AutoAttackSkill_Frame_Title']:
                prop(w,'Text','Trận pháp' if name=='ZhenfaSkill' else 'Tự chiến đấu')
                prop(w,'UnifiedSize','{{1,-145},{0,20}}')
            if n in ['ZhenfaSkill_QingyiNum_All','ZhenfaSkill_QingyiNum_Have','ZhenfaSkill_Info_Name','ZhenfaSkill_Info_Level']:
                prop(w,'Font','GLFit11')
            if n=='ZhenfaSkill_Set':prop(w,'Text','Thiết lập')
    return ET.tostring(root,encoding='utf-8',xml_declaration=True)
