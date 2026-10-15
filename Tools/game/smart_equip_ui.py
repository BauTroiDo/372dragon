"""SelfEquip's last three stat icons reflect this server's actual rules."""
import re
def patch(raw):
 s=raw.decode('utf8')
 start=s.index('\t--天锐 地磐');end=s.index('\n\t--神木王鼎',start)
 s=s[:start]+'''    -- MD602/603 are the authoritative combat totals, not CY set bonus estimates.
    local att = iEnchanceAtt and iEnchanceAtt >= 0 and tostring(iEnchanceAtt) or "Đang đồng bộ"
    local def = iEnchanceDef and iEnchanceDef >= 0 and tostring(iEnchanceDef) or "Đang đồng bộ"
    SelfEquip_HurtFastness:SetToolTip("#YXuyên thích#W#rChỉ số: "..att.."#rSát thương thêm từ#rphần xuyên vượt kháng.#rNgười chơi: x1#rQuái / Trân thú: x5#rChí mạng: x2#rKích hoạt từ +9.")
    SelfEquip_DefenceFastness:SetToolTip("#YKháng xuyên thích#W#rChỉ số: "..def.."#rGiảm xuyên thích#rcủa người đánh,#rtrước hệ số sát thương.#rPhần xuyên còn lại#rkhông thấp hơn 0.#rKích hoạt từ +9.")
'''+s[end:]
 s=s.replace('local strConText = "#{XLDL_140606_02}";','local strConText = "#YThần đỉnh#W";')
 s=s.replace('SelfEquip_ShenDing_Icon:SetToolTip("#{XLDL_140606_01}");','SelfEquip_ShenDing_Icon:SetToolTip("Thần đỉnh mở từ cấp 15.");')
 return (s+'''
-- Refresh already-open tooltips when the server publishes new values.
local CysPiercingPreload = SelfEquip_PreLoad
function SelfEquip_PreLoad()
 CysPiercingPreload()
 this:RegisterEvent("CYS_PIERCING_UPDATE")
 this:RegisterEvent("CYS_SHENDING_UPDATE")
end
local CysPiercingEvent = SelfEquip_OnEvent
function SelfEquip_OnEvent(event)
 if event=="CYS_PIERCING_UPDATE" or event=="CYS_SHENDING_UPDATE" then
  if this:IsVisible() then SelfEquip_SetStateTooltip() end
  return
 end
 CysPiercingEvent(event)
end
''').encode()
