-- CY-Source controller for the unchanged DATA CY control tree.
-- CY Lua is encoded; event workflow is adapted from the readable GL controller.
-- __CYS_RANDOM_NAMES__ comes from the four original DATA CY name tables.
local names = __CYS_RANDOM_NAMES__
local sex, page, preview, previewSex = 0, 0, -1, 0
local selection = {face = 0, hair = 0, outfit = 0, portrait = 0}
local choices = {}
local kinds = {"face", "hair", "outfit", "portrait"}
local images, buttons

local function status(text) CreateRole_Info:SetProperty("Text", text) end
local function stopModel()
    GameProduceLogin:ModelRotEnd(0)
    GameProduceLogin:ModelZoom(0)
end
local function unhookRtt()
    CreateRole_Model:SetFakeObject("")
    CreateRole_Model:Hide()
end
local function portraits()
    local count = table.getn(choices.portrait)
    for i = 1, 9 do
        local index = page * 9 + i
        if index <= count then
            images[i]:SetProperty("Image", choices.portrait[index].image)
            images[i]:Show()
            buttons[i]:Show()
            buttons[i]:SetCheck(selection.portrait == index - 1 and 1 or 0)
        else
            images[i]:Hide()
            buttons[i]:Hide()
        end
    end
    if page > 0 then CreateRole_PageUp:Enable() else CreateRole_PageUp:Disable() end
    if (page + 1) * 9 < count then CreateRole_PageDown:Enable() else CreateRole_PageDown:Disable() end
end
local function refresh()
    GameProduceLogin:ApplyCreateAppearance(sex, selection.face, selection.hair, selection.outfit, selection.portrait)
    local labels = {face = CreateRole_SelectFace_Text2, hair = CreateRole_SelectHair_Text2,
                    outfit = CreateRole_SelectClothing_Text2}
    for kind, label in pairs(labels) do
        local index = selection[kind] + 1
        label:SetProperty("Text", index .. "/" .. table.getn(choices[kind]))
        label:SetToolTip(choices[kind][index].label)
    end
    CreateRole_SelectSex_Girl:SetCheck(sex == 0 and 1 or 0)
    CreateRole_SelectSex_Boy:SetCheck(sex == 1 and 1 or 0)
    portraits()
end
local function selectSex(value)
    sex, page = value, 0
    for _, kind in ipairs(kinds) do
        choices[kind] = GameProduceLogin:GetCreateOptions(sex, kind)
        assert(table.getn(choices[kind]) > 0, "CreateRole: empty appearance catalog")
        selection[kind] = 0
    end
    refresh()
end
local function step(kind, amount)
    if preview >= 0 then return end
    local count = table.getn(choices[kind])
    selection[kind] = math.mod(selection[kind] + amount + count, count)
    refresh()
end
local function portrait(slot)
    if preview >= 0 then return end
    local index = page * 9 + slot - 1
    if index >= table.getn(choices.portrait) then return end
    selection.portrait = index
    refresh()
end
local function showPreview()
    stopModel()
    local object, title, description = GameProduceLogin:ShowCreatePreview(preview, previewSex)
    assert(title ~= "" and description ~= "", "CreateRole: incomplete native preview")
    CreateRole_Info2_Frame_Back2:SetProperty("Image", title)
    -- Native wrapping breaks at codepoints; short sentences use explicit line breaks.
    local lines = string.gsub(description, "%. ", ".\n")
    Createshow_Info2:SetProperty("Text", lines)
    CreateRole_Info2_Frame_Back4:SetCheck(previewSex == 1 and 1 or 0)
    CreateRole_Info2_Frame_Back5:SetCheck(previewSex == 0 and 1 or 0)
    CreateRole_Info_Frame:Hide()
    CreateRole_Info3_Frame:Hide()
    CreateRole_Name:Hide()
    CreateRole_Name:SetProperty("DefaultEditBox", "False")
    CreateRole_RandomName:Hide()
    CreateRole_Info2_Frame:Show()
    CreateRole_MenpaiModel00:Enable()
    status("Xem trước môn phái. Hủy để trở lại tạo nhân vật.")
end

function CreateRole_SelectGirl() if preview < 0 then selectSex(0) end end
function CreateRole_SelectBoy() if preview < 0 then selectSex(1) end end
function CreateRole_SelectFace_TurnLeft1_Clicked() step("face", -1) end
function CreateRole_SelectFace_TurnRight1_Clicked() step("face", 1) end
function CreateRole_SelectHair_TurnLeft1_Clicked() step("hair", -1) end
function CreateRole_SelectHair_TurnRight1_Clicked() step("hair", 1) end
function CreateRole_SelectClothin_TurnLeft1_Clicked() step("outfit", -1) end
function CreateRole_SelectClothin_TurnRight1_Clicked() step("outfit", 1) end
function CreateRole_BnSelFace1() portrait(1) end
function CreateRole_BnSelFace2() portrait(2) end
function CreateRole_BnSelFace3() portrait(3) end
function CreateRole_BnSelFace4() portrait(4) end
function CreateRole_BnSelFace5() portrait(5) end
function CreateRole_BnSelFace6() portrait(6) end
function CreateRole_BnSelFace7() portrait(7) end
function CreateRole_BnSelFace8() portrait(8) end
function CreateRole_BnSelFace9() portrait(9) end
function CreateRole_BnClickFacePageUp() if page > 0 then page = page - 1; portraits() end end
function CreateRole_BnClickFacePageDown()
    if (page + 1) * 9 < table.getn(choices.portrait) then page = page + 1; portraits() end
end
function CreateRole_Random_Clicked()
    if preview >= 0 then return end
    for _, kind in ipairs(kinds) do selection[kind] = math.random(table.getn(choices[kind])) - 1 end
    page = math.floor(selection.portrait / 9)
    refresh()
end
function CreateRole_RandomName_Clicked()
    local parts = names[sex + 1]
    CreateRole_Name:SetProperty("Text", parts[1][math.random(table.getn(parts[1]))] ..
                                   parts[2][math.random(table.getn(parts[2]))])
end
function CreateRole_BnClickCreateRole()
    if preview >= 0 then return end
    local name = CreateRole_Name:GetText()
    if name == "" then status("Hãy nhập tên nhân vật."); return end
    if string.len(name) > 29 then status("Tên quá dài. Hãy chọn tên ngắn hơn."); return end
    GameProduceLogin:CreateRole(name, sex)
end
function CreateRole_BnClickMenpaiModel(id)
    if id >= 0 then
        preview, previewSex = id, sex
        showPreview()
    else
        stopModel()
        local restore = preview >= 0
        if restore then GameProduceLogin:HideCreatePreview() end
        preview = -1
        CreateRole_Info2_Frame:Hide()
        CreateRole_Info_Frame:Show()
        CreateRole_Info3_Frame:Show()
        CreateRole_Name:Show()
        CreateRole_Name:SetProperty("DefaultEditBox", "True")
        CreateRole_RandomName:Show()
        if restore then refresh() end
        status("Chọn diện mạo và nhập tên nhân vật.")
    end
end
function CreateRole_Preview_Man_Clicked() if preview >= 0 then previewSex = 1; showPreview() end end
function CreateRole_Preview_Woman_Clicked() if preview >= 0 then previewSex = 0; showPreview() end end
function CreateRole_BnClickReturnSelectRole()
    stopModel()
    if preview >= 0 then GameProduceLogin:HideCreatePreview(); preview = -1 end
    GameProduceLogin:ChangeToSelectRoleDlgFromCreateRole()
end
function CreateRole_Modle_TurnLeft(start)
    if start == 1 then GameProduceLogin:ModelRotBegin(-1) else GameProduceLogin:ModelRotEnd(0) end
end
function CreateRole_Modle_TurnRight(start)
    if start == 1 then GameProduceLogin:ModelRotBegin(1) else GameProduceLogin:ModelRotEnd(0) end
end
function CreateRole_Modle_ZoomOut(start) GameProduceLogin:ModelZoom(start == 1 and -1 or 0) end
function CreateRole_Modle_ZoomIn(start) GameProduceLogin:ModelZoom(start == 1 and 1 or 0) end
function CreateRole_MouseEnter(index)
    local hints = {[1] = "Hỗ trợ tiếng Việt và tiếng Trung", [4] = "Chọn giới tính", [5] = "Chọn chân dung",
                   [7] = "Tạo nhân vật", [8] = "Trở lại chọn nhân vật", [9] = "Kết thúc xem trước"}
    status(hints[index] or "Xem trước môn phái")
end
function CreateRole_MouseLeave() status("") end
function CreateRole_Random_MouseEnter() status("Chọn diện mạo ngẫu nhiên") end
function CreateRole_Random_MouseLeave() status("") end
function CreateRole_RandomName_MouseEnter() status("Gợi ý tên nhân vật") end
function CreateRole_RandomName_MouseLeave() status("") end

function LoginCreateRole_PreLoad()
    this:RegisterEvent("GAMELOGIN_OPEN_CREATE_CHARACTOR")
    this:RegisterEvent("GAMELOGIN_CLOSE_CREATE_CHARACTOR")
    this:RegisterEvent("GAMELOGIN_CREATE_CLEAR_NAME")
end
function LoginCreateRole_OnLoad()
    images = {CreateRole_Select_HeadImage1, CreateRole_Select_HeadImage2, CreateRole_Select_HeadImage3,
              CreateRole_Select_HeadImage4, CreateRole_Select_HeadImage5, CreateRole_Select_HeadImage6,
              CreateRole_Select_HeadImage7, CreateRole_Select_HeadImage8, CreateRole_Select_HeadImage9}
    buttons = {CreateRole_Select_Head1, CreateRole_Select_Head2, CreateRole_Select_Head3,
               CreateRole_Select_Head4, CreateRole_Select_Head5, CreateRole_Select_Head6,
               CreateRole_Select_Head7, CreateRole_Select_Head8, CreateRole_Select_Head9}
    CreateRole_SelectSex_Girl:SetProperty("Text", "Nữ")
    CreateRole_SelectSex_Boy:SetProperty("Text", "Nam")
    CreateRole_SelectSex_Girl:SetProperty("CheckMode", "1")
    CreateRole_SelectSex_Boy:SetProperty("CheckMode", "1")
    CreateRole_Info2_Frame:Hide()
    unhookRtt()
end
function LoginCreateRole_OnEvent(event)
    if event == "GAMELOGIN_OPEN_CREATE_CHARACTOR" then
        this:Show()
        unhookRtt()
        preview = -1
        selectSex(sex)
        CreateRole_BnClickMenpaiModel(-1)
    elseif event == "GAMELOGIN_CLOSE_CREATE_CHARACTOR" then
        stopModel()
        if preview >= 0 then GameProduceLogin:HideCreatePreview(); preview = -1 end
        unhookRtt()
        CreateRole_Name:SetProperty("DefaultEditBox", "False")
        this:Hide()
    elseif event == "GAMELOGIN_CREATE_CLEAR_NAME" then
        CreateRole_Name:SetProperty("Text", "")
    end
end
