-- Original DATA CY 50-control selection tree; the native scene owns its actors.
local slots
-- Character faction IDs from GL SelectRole.lua, not the separate preview IDs.
local sectNames = {[0]="Thiếu Lâm", [1]="Minh Giáo", [2]="Cái Bang", [3]="Võ Đang", [4]="Nga Mi",
                   [5]="Tinh Túc", [6]="Thiên Long", [7]="Thiên Sơn", [8]="Tiêu Dao", [9]="Vô môn",
                   [10]="Mạn Đà Sơn Trang", [11]="Ác Nhân Cốc", [12]="Mộ Dung"}
local function status(text) SelectRole_Info:SetProperty("Text", text) end
local function stopModel()
    GameProduceLogin:ModelRotEnd(0)
    GameProduceLogin:ModelZoom(0)
end
function SelectRole_Clicked(index)
    if index < 0 or index >= GameProduceLogin:GetRoleCount() then return end
    assert(GameProduceLogin:SelectRoleSlot(index) == 1, "SelectRole: native selection failed")
    for i = 1, 3 do
        if i == index + 1 then slots[i].highlight:Show() else slots[i].highlight:Hide() end
    end
end
local function refresh()
    local count = GameProduceLogin:GetRoleCount()
    assert(count >= 0 and count <= 3, "SelectRole: unsupported slot count")
    for i = 1, 3 do
        local slot = slots[i]
        slot.highlight:Hide()
        slot.deleted:Hide()
        slot.sell:Hide()
        if i <= count then
            local name, menpai, level, deleteTime, portrait = GameProduceLogin:GetRoleInfo(i - 1)
            slot.name:SetProperty("Text", name)
            slot.level:SetProperty("Text", "Cấp " .. level)
            slot.menpai:SetProperty("Text", menpai == -1 and "Vô môn" or (sectNames[menpai] or ("Môn phái " .. menpai)))
            slot.icon:SetProperty("Image", portrait)
            slot.name:Show(); slot.level:Show(); slot.menpai:Show()
            slot.icon:Show(); slot.lace:Show(); slot.empty:Hide()
            if deleteTime > 0 then slot.deleted:SetProperty("Text", "Đang xóa"); slot.deleted:Show() end
        else
            slot.name:SetProperty("Text", "")
            slot.name:Hide(); slot.level:Hide(); slot.menpai:Hide()
            slot.icon:Hide(); slot.lace:Hide()
            slot.empty:SetProperty("Text", "Ô trống")
            slot.empty:Show()
        end
    end
    if count > 0 then
        local selected = GameProduceLogin:GetCurSelectRole()
        assert(selected >= 0 and selected < count, "SelectRole: invalid native selected slot")
        SelectRole_Clicked(selected)
        status("Chọn nhân vật của bạn.")
    else
        status("Tạo nhân vật để bắt đầu hành trình.")
    end
    if count < 3 then SelectRole_Create:Enable() else SelectRole_Create:Disable() end
    -- CYS 13/09: entering the world works (CLAskCharLogin -> game socket through NetCore,
    -- CGamePro_CharSel::SendEnterGameMsg); deleting a character is not wired yet.
    if count > 0 then SelectRole_Play:Enable() else SelectRole_Play:Disable() end
    SelectRole_Play:SetToolTip("Vào game")
    SelectRole_Delete:Disable()
    SelectRole_Delete:SetToolTip("Chức năng chưa sẵn sàng.")
end
function SelectRole_CreateRole()
    if GameProduceLogin:GetRoleCount() < 3 then DataPool:AskCreateCharCode() end
end
function SelectRole_Return()
    stopModel()
    GameProduceLogin:ChangeToAccountInputDlgFromSelectRole()
end
function SelectRole_EnterGame()
    local count = GameProduceLogin:GetRoleCount()
    if count <= 0 then status("Tạo nhân vật để bắt đầu hành trình.") return end
    local selected = GameProduceLogin:GetCurSelectRole()
    if selected < 0 or selected >= count then status("Chọn một nhân vật.") return end
    stopModel()
    status("Đang vào game...")
    GameProduceLogin:SendEnterGameMsg(selected)
end
function SelectRole_DelRole() status("Chức năng chưa sẵn sàng.") end
function SelectRole_DoubleClicked(index)
    SelectRole_Clicked(index)
    if index >= 0 and index < GameProduceLogin:GetRoleCount() then SelectRole_EnterGame() end
end
function SelectRole_Role_Modle_TurnLeft(start)
    if start == 1 then GameProduceLogin:ModelRotBegin(-1) else GameProduceLogin:ModelRotEnd(0) end
end
function SelectRole_Role_Modle_TurnRight(start)
    if start == 1 then GameProduceLogin:ModelRotBegin(1) else GameProduceLogin:ModelRotEnd(0) end
end
function SelectRole_Modle_ZoomOut(start) GameProduceLogin:ModelZoom(start == 1 and -1 or 0) end
function SelectRole_Modle_ZoomIn(start) GameProduceLogin:ModelZoom(start == 1 and 1 or 0) end
function SelectRole_MouseEnterCharArea(index)
    status(index < GameProduceLogin:GetRoleCount() and "Chọn nhân vật" or "Ô nhân vật còn trống")
end
function SelectRole_MouseLeave() status("") end
function SelectRole_Play_MouseEnter() status("Vào game") end
function SelectRole_Create_MouseEnter() status("Tạo nhân vật mới") end
function SelectRole_Delete_MouseEnter() status("Chức năng chưa sẵn sàng.") end
function SelectRole_Last_MouseEnter() status("Trở lại đăng nhập") end
function LoginSelectRole_PreLoad()
    this:RegisterEvent("GAMELOGIN_OPEN_SELECT_CHARACTOR")
    this:RegisterEvent("GAMELOGIN_CLOSE_SELECT_CHARACTOR")
    this:RegisterEvent("GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR")
    this:RegisterEvent("GAMELOGIN_CREATE_ROLE_OK")
end
function LoginSelectRole_OnLoad()
    slots = {
        {name=SelectRole_TargetInfo_Name_Text, level=SelectRole_TargetInfo_Level_Text,
         menpai=SelectRole_TargetInfo_Menpai_Text, empty=SelectRole_TargetInfo_Create,
         deleted=SelectRole_TargetInfo_Delete, sell=SelectRole_TargetInfo_Sell,
         icon=SelectRole_Icon, lace=SelectRole_Icon_Lace, highlight=SelectRole_TargetInfo_Gaoliang1},
        {name=SelectRole_TargetInfo_Name_Text2, level=SelectRole_TargetInfo_Level_Text2,
         menpai=SelectRole_TargetInfo_Menpai_Text2, empty=SelectRole_TargetInfo_Create2,
         deleted=SelectRole_TargetInfo_Delete2, sell=SelectRole_TargetInfo_Sell2,
         icon=SelectRole_Icon2, lace=SelectRole_Icon_Lace2, highlight=SelectRole_TargetInfo_Gaoliang2},
        {name=SelectRole_TargetInfo_Name_Text3, level=SelectRole_TargetInfo_Level_Text3,
         menpai=SelectRole_TargetInfo_Menpai_Text3, empty=SelectRole_TargetInfo_Create3,
         deleted=SelectRole_TargetInfo_Delete3, sell=SelectRole_TargetInfo_Sell3,
         icon=SelectRole_Icon3, lace=SelectRole_Icon_Lace3, highlight=SelectRole_TargetInfo_Gaoliang3}}
end
function LoginSelectRole_OnEvent(event)
    if event == "GAMELOGIN_OPEN_SELECT_CHARACTOR" then
        this:Show()
        refresh()
    elseif event == "GAMELOGIN_REFRESH_ROLE_SELECT_CHARACTOR" then
        refresh()
    elseif event == "GAMELOGIN_CREATE_ROLE_OK" then
        refresh()
    elseif event == "GAMELOGIN_CLOSE_SELECT_CHARACTOR" then
        stopModel()
        this:Hide()
    end
end
