-- blockmap.lua
-- Ban do CHAN theo o, dung 1 bit / o. Sinh boi
-- `tools/map-convert/make_navmesh.py` cung luc voi `.path`.
--
-- Vi sao can: client CO doc navmesh trong `.path` (bam chuot vao cho bi chan thi
-- no bao "vi tri nay can su dung phuong phap dac biet moi co the den duoc"),
-- NHUNG khi di lien tuc thi no khong hoi navmesh, nen van luon vao duoc trong
-- tuong. Server phai tu chan.
--
-- Dinh dang:
--   "BLK1" | u32 xsize | u32 zsize | ceil(xsize/8) * zsize byte
--   bit dat = o BI CHAN. Bit thu i cua hang j nam o byte (i >> 3), bit (i & 7).
--
-- Toa do o: server dung DON VI O o khap noi (diem hoi sinh 124/158, ban kinh
-- cong 7...), nen chi can lay phan nguyen cua x, z la ra chi so o.

local blockmap = {}
blockmap.__index = blockmap

local sbyte = string.byte
local floor = math.floor

function blockmap.load(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local d = f:read("a")
    f:close()
    if not d or #d < 12 or d:sub(1, 4) ~= "BLK1" then return nil end
    local xs = sbyte(d, 5) + sbyte(d, 6) * 256 + sbyte(d, 7) * 65536 + sbyte(d, 8) * 16777216
    local zs = sbyte(d, 9) + sbyte(d, 10) * 256 + sbyte(d, 11) * 65536 + sbyte(d, 12) * 16777216
    local stride = floor((xs + 7) / 8)
    if #d < 12 + stride * zs then return nil end
    return setmetatable({ xs = xs, zs = zs, stride = stride, data = d, off = 12 }, blockmap)
end

-- true = o (x, z) bi chan. Ngoai bien cung coi la bi chan.
function blockmap:is_blocked(x, z)
    local i = floor(x)
    local j = floor(z)
    if i < 0 or j < 0 or i >= self.xs or j >= self.zs then return true end
    local b = sbyte(self.data, self.off + j * self.stride + floor(i / 8) + 1)
    if not b then return true end
    return floor(b / (2 ^ (i % 8))) % 2 == 1
end

-- Kiem tra ca doan thang, lay mau moi nua o. Dung cho mot buoc di chuyen: chi
-- kiem diem dich thi nguoi choi van "nhay" qua duoc mot buc tuong mong.
function blockmap:segment_blocked(x1, z1, x2, z2)
    local dx, dz = x2 - x1, z2 - z1
    local n = floor(math.max(math.abs(dx), math.abs(dz)) * 2) + 1
    if n > 256 then n = 256 end
    for k = 0, n do
        local t = k / n
        if self:is_blocked(x1 + dx * t, z1 + dz * t) then return true end
    end
    return false
end

return blockmap
