"""Incremental CY Packet.lua updates; retain the full rebuild for snapshots/tab changes."""
def generate(text):
 old='elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then\n\t\tPacket_ChangeTabIndex(nTheTabIndex);'
 assert text.count(old)==1
 text=text.replace(old,'elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then\n        Packet_UpdateChangedSlot(arg0);')
 text += '''
-- Single-slot server deltas must not reset every action button and hover state.
function Packet_UpdateChangedSlot(raw)
 local slot=tonumber(raw)
 if slot==nil or slot<0 or slot>=220 or slot~=math.floor(slot) then
  Packet_ChangeTabIndex(nTheTabIndex)
  return
 end
 local tab=math.floor(slot/100)
 if tab~=nTheTabIndex then return end
 local index=slot-tab*100+1
 local names={"base","material","quest"}
 local count=DataPool:GetBaseBag_Num()
 if tab==1 then count=DataPool:GetMatBag_Num() end
 if tab==2 then count=DataPool:GetTaskBag_Num() end
 if index>count or PACKAGE_BUTTONS[index]==nil then return end
 local action,locked=PlayerPackage:EnumItem(names[tab+1],index-1)
 if action:GetID()~=0 then PACKAGE_BUTTONS[index]:SetActionItem(action:GetID())
 else PACKAGE_BUTTONS[index]:SetActionItem(-1) end
 if locked==1 then PACKAGE_BUTTONS[index]:Disable() else PACKAGE_BUTTONS[index]:Enable() end
 Lock_Flag=0
 for i=1,count do
  local a,l=PlayerPackage:EnumItem(names[tab+1],i-1)
  if l==1 then Lock_Flag=1 end
 end
 if Lock_Flag==0 then Packet_Classify:Enable() else Packet_Classify:Disable() end
end
'''
 return text
