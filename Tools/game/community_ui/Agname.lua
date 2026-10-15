-- CY frame / GL's authoritative owned-title selection contract.
local selected = -1
function Agname_PreLoad()
    this:RegisterEvent("OPEN_AGNAME",true)
    this:RegisterEvent("CLOSE_AGNAME",false)
    this:RegisterEvent("CYS_TITLES_CHANGED",false)
    this:RegisterEvent("RESET_ALLUI",false)
end
function Agname_OnLoad()
    Agname_Frame_Title:SetText("Danh hiệu")
    Agname_Chenghao:SetText("Đã sở hữu")
    Agname_Yueli:Hide()
    Agname_Frame_FenYeWindow2:Hide()
    Agname_Frame_FenYeWindow1:Show()
    Agname_ListContent_Lace1:Hide()
    Agname_Xianshishuxingchenghao:Hide()
    Agname_Shuxingchenghaoxianshi:Hide()
    Agname_Shuxingchenghaoxianshi_Text:Hide()
    Agname_Shuxingshiyong:Hide()
    Agname_Currently_Title4:Hide()
    Agname_Chenhaoshuxing_Text:Hide()
    Agname_Chenhaoshuxing_Text1:Hide()
    Agname_Chenhaoshuxing_Text2:Hide()
    Agname_Chenhaoshuxing_Text3:Hide()
    Agname_Currently_Title2:SetText("Trạng thái:")
    Agname_Currently_Title1:SetText("Thời hạn:")
    Agname_Currently_Title3:SetText("Mô tả:")
    Agname_Currently_Title5:SetText("Nguồn:")
    Agname_LeftTitleAnimate:Hide()
    Agname_RightTitleAnimate:Hide()
    Agname_TopTitleAnimate:Hide()
end
function Agname_OnEvent(event)
    if event=="OPEN_AGNAME" then
        this:TogleShow()
        if this:IsVisible() then Player:CysRefreshTitles();Agname_UpdateFrame() end
    elseif event=="CLOSE_AGNAME" or event=="RESET_ALLUI" then
        this:Hide()
        selected=-1
    elseif event=="CYS_TITLES_CHANGED" and this:IsVisible() then
        Agname_UpdateFrame()
    end
end
function Agname_UpdateFrame()
    Agname_ListContent:ClearListBox()
    local count=Player:CysTitleCount()
    for i=0,count-1 do
        local name,id,kind,remaining,current=Player:CysTitleAt(i)
        local text=name
        if current==1 then text="#G"..name.." [Đang dùng]" end
        Agname_ListContent:AddItem(text,i)
    end
    if selected>=count then selected=-1 end
    if selected<0 and count>0 then selected=0 end
    if selected>=0 then Agname_ListContent:SetItemSelectByItemID(selected) end
    Agname_ShowIcon()
end
function AgnameFrame_ListContentItemClick()
    local id=Agname_ListContent:GetFirstSelectItem()
    if id~=nil and tonumber(id) and tonumber(id)>=0 then selected=tonumber(id) end
    Agname_ShowIcon()
end
function Agname_ShowIcon()
    if selected<0 then
        Agname_PlayerTitle:SetText("Chưa sở hữu danh hiệu")
        Agname_Yulanxianshi:Disable()
        Agname_Chenhaoshuxing:SetText("")
        Agname_FinishCondition:SetText("")
        Agname_Dachengtiaojian:SetText("")
        Agname_Info1_Youxiaoqi:SetText("")
        Agname_Info1_Yueli:SetText("")
        return
    end
    local name,id,kind,remaining,current,desc,source,attrs=Player:CysTitleAt(selected)
    Agname_PlayerTitle:SetText(name)
    Agname_Yulanxianshi:Enable()
    if current==1 then Agname_Yulanxianshi:SetText("Ẩn") else Agname_Yulanxianshi:SetText("Hiển thị") end
    Agname_Info1_Yueli:SetText(current==1 and "Đang hiển thị" or "Đã sở hữu")
    Agname_Info1_Youxiaoqi:SetText(remaining>0 and tostring(remaining) or "Vĩnh viễn")
    Agname_Info1_Youxiaoqi1:SetText("")
    Agname_FinishCondition:SetText(desc or "")
    Agname_Dachengtiaojian:SetText(source or "")
    Agname_PlayerTitle:SetToolTip(name)
    Agname_FinishCondition:SetToolTip(desc or "")
    Agname_Dachengtiaojian:SetToolTip(source or "")
    Agname_Chenhaoshuxing:SetText((attrs or "").."#r#rThuộc tính của các danh hiệu đã sở hữu được cộng tự động. Đổi hoặc ẩn tên danh hiệu không tắt thuộc tính.")
end
function Agname_SetCheck()
    if selected<0 then return end
    local name,id,kind,remaining,current=Player:CysTitleAt(selected)
    if current==1 then Player:SetNullAgname() else Player:AskChangeCurrentAgname(selected) end
    -- Do not label the request successful until the server answers.
end
function Agname_OnChoice() Agname_UpdateFrame() end
function Agname_HideTitle_Clicked() Player:SetNullAgname() end
function Agname_OnlyShowEffect_SetCheck() Agname_UpdateFrame() end
function Agname_Effect_SetCheck() end
function Agname_Button_WaiGuanEffect() end
