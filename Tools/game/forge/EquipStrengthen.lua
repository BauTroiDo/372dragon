-- Same registered window/NPC entry point; explicit equipment and material slots.
CysForge_State={phase="empty",seq=0,equip=-1,material=-1,materialID=0,auto=0}
local function clock() return CysForge_Clock() end
local function age(t) local n=clock()-t;if n<0 then n=n+4294967296 end;return n end
local function say(t) Forge_Status:SetText(t) end
local function itemID(slot)
    if not slot or slot<0 then return -1 end
    local a=EnumAction(slot,"packageitem")
    if a and a:GetID()~=0 then return a:GetItemTableIndex() end
    return -1
end
local function send(fn,a,b,c)
    Clear_XSCRIPT();Set_XSCRIPT_ScriptID(809262);Set_XSCRIPT_Function_Name(fn)
    Set_XSCRIPT_Parameter(0,a or 0);Set_XSCRIPT_Parameter(1,b or 0);Set_XSCRIPT_Parameter(2,c or 0)
    Set_XSCRIPT_ParamCount(3);Send_XSCRIPT()
end
local function action(button,slot)
    if slot and slot>=0 then
        local a=EnumAction(slot,"packageitem")
        if a and a:GetID()~=0 then button:SetActionItem(a:GetID());return end
    end
    button:SetActionItem(-1)
end
local function progress(level)
    for i=1,9 do
        local c=_G["Forge_Level"..i]
        c:SetText((i<=level and "#Y" or "#W").."+"..i)
    end
    Forge_Current:SetText("Cường hoá hiện tại: +"..level.." / 9")
end
function EquipStrengthen_PreLoad()
    this:RegisterEvent("UI_COMMAND",true)
    this:RegisterEvent("PUT_STENGTHEN_ITEM",false)
    this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
    this:RegisterEvent("MONEY_CHANGE_EX",false)
    this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
end
function EquipStrengthen_OnLoad() end
function CysForge_Open()
    this:Show();CysForge_Capture(1)
    SetTimer("EquipStrengthen","CysForge_Tick()",16)
    local s=CysForge_State
    s.phase="empty";s.equip=-1;s.material=-1;s.materialID=0;s.auto=0;s.nonce=0
    action(Forge_Equip,-1);action(Forge_Material,-1);progress(0)
    Forge_Stats:SetText("Chỉ số tăng theo bảng cường hoá của trang bị.")
    Forge_Cost:SetText("Chi phí mỗi lượt: —")
    Forge_Required:SetText("Đặt trang bị để xem nguyên liệu cần dùng.")
    Forge_White:Hide();Forge_Cursor:Hide();Forge_Start:Disable()
    say("Đặt trang bị và nguyên liệu từ hành trang vào hai ô bên trên.")
end
function CysForge_Quote()
    local s=CysForge_State;if s.equip<0 then return end
    s.seq=s.seq+1;s.phase="quote"
    say("Đang kiểm tra trang bị và chi phí...")
    Forge_Start:Disable();send("CysForgeQuote",s.equip,s.seq)
end
function CysForge_Drop(kind,slot)
    local s=CysForge_State
    if not this:IsVisible() or s.phase=="pending" or s.phase=="run" or s.phase=="strike" or s.phase=="result" or s.phase=="stopping" then return end
    if kind==0 then
        s.equip=slot;s.auto=0;action(Forge_Equip,slot);CysForge_Quote()
    elseif kind==1 then
        s.material=slot;s.materialID=itemID(slot)
        action(Forge_Material,slot)
        s.auto=0;if s.equip>=0 then CysForge_Quote() end
    end
end
function CysForge_Clear(kind)
    local s=CysForge_State
    if s.phase=="run" or s.phase=="pending" or s.phase=="strike" or s.phase=="result" or s.phase=="stopping" then return end
    s.auto=0
    if kind==0 then s.equip=-1;s.phase="empty";action(Forge_Equip,-1);Forge_Stats:SetText("")
    else s.material=-1;s.materialID=0;action(Forge_Material,-1) end
    Forge_Start:Disable();say("Đặt đủ trang bị và nguyên liệu trước khi bắt đầu.")
end
function CysForge_Start()
    local s=CysForge_State
    if s.phase~="ready" or s.equip<0 or s.materialID<=0 then return end
    local m=s.material
    if m<0 or itemID(m)~=s.materialID then m=CysForge_FindMaterial(s.materialID) end
    if m<0 then s.auto=0;say("Đã hết nguyên liệu đã chọn. Đặt thêm nguyên liệu để tiếp tục.");Forge_Start:Disable();return end
    s.material=m;action(Forge_Material,m);s.auto=1;s.phase="pending";s.sent=clock()
    Forge_Start:Disable();say("Đang xác nhận chi phí và khóa trang bị...")
    send("CysForgeBegin",s.equip,s.material,s.seq)
end
function CysForge_Strike()
    local s=CysForge_State;if s.phase~="run" then return end
    local elapsed=math.floor(age(s.at)+s.offset-s.delay)
    if elapsed<0 then return end
    s.phase="strike";say("Búa đã hạ — đang nhận kết quả...")
    send("CysForgeStrike",s.nonce,elapsed)
end
function CysForge_Stop()
    local s=CysForge_State;s.auto=0
    if s.phase=="run" or s.phase=="pending" or s.phase=="strike" then
        send("CysForgeCancel",s.seq);s.phase="stopping";say("Đang dừng lượt rèn...")
    elseif s.equip>=0 then CysForge_Quote() end
end
function CysForge_Tick()
    if not this:IsVisible() then return end
    local s=CysForge_State
    Forge_Money:SetProperty("MoneyNumber",tostring(Player:GetData("MONEY")))
    Forge_Jiaozi:SetProperty("MoneyNumber",tostring(Player:GetData("MONEY_JZ")))
    if s.phase=="run" then
        local t=age(s.at)+s.offset-s.delay
        if t<0 then say("Chuẩn bị... "..math.ceil(-t/1000))
        else
            local x=math.mod(t,2*s.period);if x>s.period then x=2*s.period-x end
            s.position=x/s.period
            Forge_Cursor:SetProperty("AbsolutePosition","x:"..(39+math.floor(640*s.position)).." y:400")
            say("Bấm SPACE khi tâm dấu nhắc nằm trong vùng trắng.")
        end
    elseif s.phase=="result" and age(s.resultAt)>1100 then
        if s.auto==1 and s.level<9 then CysForge_Quote() else s.phase="done" end
    end
end
function EquipStrengthen_OnEvent(event)
    local s=CysForge_State
    if event=="UI_COMMAND" then
        if tonumber(arg0)==1002 then
            if not this:IsVisible() then CysForge_Open() end
            return
        end
        if tonumber(arg0)~=990023 or not this:IsVisible() then return end
        local kind=Get_XParam_INT(0);local seq=Get_XParam_INT(1)
        if seq~=s.seq then return end
        if kind==0 then
            s.level=Get_XParam_INT(3);s.phase="ready";progress(s.level)
            Forge_Stats:SetText(Get_XParam_STR(0))
            Forge_Cost:SetText("Mỗi lượt: "..Get_XParam_INT(4).." đồng + 1 nguyên liệu/lượt Lộ")
            Forge_Required:SetText("Cần: #{_ITEM"..Get_XParam_INT(5).."}"..(Get_XParam_INT(6)>0 and " hoặc #{_ITEM"..Get_XParam_INT(6).."}" or ""))
            if s.level>=9 then s.phase="done";s.auto=0;Forge_Start:Disable();say("Đã đạt giới hạn +9. Trang bị cấp cao hơn được giữ nguyên.")
            elseif s.auto==1 then CysForge_Start()
            else
                if s.materialID>0 then Forge_Start:Enable() end
                say("Bấm đúng: tăng 1 cấp và tự tiếp tục. Trượt: giảm 1 cấp và dừng.")
            end
        elseif kind==1 and s.phase=="pending" then
            s.nonce=Get_XParam_INT(2);s.level=Get_XParam_INT(3)
            s.center=Get_XParam_INT(4);s.width=Get_XParam_INT(5);s.period=Get_XParam_INT(6);s.delay=Get_XParam_INT(7)
            s.offset=math.min(age(s.sent)/2,250);s.at=clock();s.phase="run"
            local left=40+640*(s.center-s.width/2)/10000
            Forge_White:SetProperty("AbsolutePosition","x:"..math.floor(left).." y:410")
            Forge_White:SetProperty("AbsoluteSize","w:"..math.floor(640*s.width/10000).." h:24")
            Forge_White:Show();Forge_Cursor:Show();progress(s.level)
        elseif kind==2 then
            s.level=Get_XParam_INT(4);progress(s.level);s.resultAt=clock()
            if Get_XParam_INT(3)==1 then
                s.phase="result";say(s.level==9 and "#YThành công! Trang bị đã đạt +9." or "#GThành công! +"..s.level.." — chuẩn bị lượt tiếp theo...")
            else
                s.auto=0;s.phase="failed";say("#RTrượt nhịp. Trang bị còn +"..s.level.."; chi phí lượt này đã tiêu hao.")
                Forge_Start:Enable()
            end
            action(Forge_Equip,s.equip)
        elseif kind==3 then
            s.auto=0;s.phase="error";Forge_Start:Disable();say(Get_XParam_STR(0))
        end
    elseif event=="PUT_STENGTHEN_ITEM" and this:IsVisible() then CysForge_Drop(0,tonumber(arg0))
    end
end
function CysForge_Button()
    local s=CysForge_State
    if s.phase=="failed" or s.phase=="error" then s.auto=1;CysForge_Quote() else CysForge_Start() end
end
function EquipStrengthen_OnHiden()
    local s=CysForge_State
    if s.phase=="pending" or s.phase=="run" or s.phase=="strike" or s.phase=="stopping" then send("CysForgeCancel",s.seq) end
    s.auto=0;s.phase="closed";CysForge_Capture(0);KillTimer("CysForge_Tick()")
end
