-- wire_charset.lua  -> đặt vào GameServer/lualib/
-- Bộ chuyển mã tại BIÊN PACKET, thay require "gbk" trong file packet.
-- CYCLE-PROOF: ở utf8 mode KHÔNG require "gbk" lúc load (fromutf8/toutf8 là identity);
-- chỉ lazy-load gbk khi thực sự cần (gbk mode, hoặc len/byte/char).
-- KHÔNG swap file bootstrap (preloader.lua) — nó chạy qua LUA_PRELOAD trước main().
--
-- DỊCH TÊN NPC/QUÁI/DANH HIỆU (utf8 mode): fromutf8 là điểm mã hóa DUY NHẤT cho mọi
-- chuỗi server->client. Tra từ điển khớp-chuỗi-đầy-đủ `wire_names_vi` (sinh bởi
-- gen_wire_names.py từ MonsterAttrExTable + scene ini). CHỈ ảnh hưởng chuỗi GỬI ĐI
-- (hiển thị); logic server vẫn dùng khóa chữ Trung. fail-safe: thiếu/hỏng từ điển
-- -> identity, không bao giờ crash wire.
local mode = "gbk"
do
    local ok, conf = pcall(require, "server_conf")
    if ok and conf and conf.client_wire_encoding then
        mode = conf.client_wire_encoding
    end
end

local _gbk
local function realgbk()
    if not _gbk then _gbk = require "gbk" end
    return _gbk
end

-- từ điển dịch tên (lazy, fail-safe). false = đã thử và không có.
local _names
local function names()
    if _names == nil then
        local ok, t = pcall(require, "wire_names_vi")
        _names = (ok and type(t) == "table") and t or false
    end
    return _names
end

local M = {}
if mode == "utf8" then
    M.fromutf8 = function(s)
        if not s or s == "" then return s or "" end
        local d = names()
        if d then
            local hit = d[s]
            if hit ~= nil then return hit end
        end
        return s
    end
    M.toutf8   = function(s) return s or "" end
else
    M.fromutf8 = function(s) return realgbk().fromutf8(s) end
    M.toutf8   = function(s) return realgbk().toutf8(s) end
end
M.len  = function(...) return realgbk().len(...) end
M.byte = function(...) return realgbk().byte(...) end
M.char = function(...) return realgbk().char(...) end

function M.truncate_utf8_bytes(s, limit)
    if not s or #s <= limit then return s end
    local i = limit
    while i > 0 do
        local b = string.byte(s, i + 1)
        if not b or b < 0x80 or b >= 0xC0 then break end
        i = i - 1
    end
    return string.sub(s, 1, i)
end

M.mode = mode
return M
