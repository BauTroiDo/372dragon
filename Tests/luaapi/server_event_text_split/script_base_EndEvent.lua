-- CYS-QUEST: proposed replacement of script_base:EndEvent (GameServer/lualib/script_base.lua, private server cys-test-20260913).
-- CY Game.exe reads an event-list text of 1..255 bytes (GCScriptCommand event reader 0x1408471d0: len-1 < 0xff, buffer
-- 256) and the server writer (packet_domains/mission.lua bos) writes the length but NO bytes when len >= 256, so the
-- Vietnamese UTF-8 texts longer than 255 bytes (174 AddText literals in 161 script files; the Chinese GBK originals
-- fitted) reach the client empty. The text is now sent as several text items of <= 254 bytes + "\31" (continuation
-- mark); the CY-Source client joins them back into one paragraph. The event count stays within CY's 16 (size <= 0x10).
local CYS_TEXT_MAX = 255
local CYS_CONT = "\31"

local function cys_split_text(s)
    if #s <= CYS_TEXT_MAX then return { s } end
    local out = {}
    local pos = 1
    while #s - pos + 1 > CYS_TEXT_MAX do
        local cut = pos + CYS_TEXT_MAX - 2 -- last byte of a 254-byte chunk
        -- never inside a UTF-8 sequence
        while cut > pos and (string.byte(s, cut + 1) or 0) >= 0x80 and (string.byte(s, cut + 1) or 0) < 0xC0 do
            cut = cut - 1
        end
        -- prefer ending after a space (readable even without the client join)
        local sp = cut
        while sp > pos + 127 and string.sub(s, sp, sp) ~= " " do sp = sp - 1 end
        if string.sub(s, sp, sp) == " " then cut = sp end
        out[#out + 1] = string.sub(s, pos, cut) .. CYS_CONT
        pos = cut + 1
    end
    out[#out + 1] = string.sub(s, pos)
    return out
end

function script_base:EndEvent()
    local spare = 16 - self.size
    for i = 1, self.size do
        local str = gbk.fromutf8(self.strs[i])
        local parts = { str }
        if self.flags[i] ~= 1 and #str > CYS_TEXT_MAX then
            parts = cys_split_text(str)
            while #parts - 1 > spare do table.remove(parts) end -- no free slot: keep what fits (as before: lost)
            spare = spare - (#parts - 1)
            if #parts > 0 then parts[#parts] = string.gsub(parts[#parts], CYS_CONT .. "$", "") end
        end
        for _, part in ipairs(parts) do
            local e = {}
            e.flag = self.flags[i]
            e.str = part
            e.type = self.types[i]
            e.index = self.indexs[i]
            e.script_id = self.script_ids[i] or self.script_id
            e.len = string.len(e.str)
            e.split = -1
            table.insert(self.event, e)
        end
    end
end
