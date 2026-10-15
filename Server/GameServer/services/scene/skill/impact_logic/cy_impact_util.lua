-- server-impact (CY-Source 15/09/2026): tiện ích chung cho các logic impact CY (tlbb15/HJ) chưa có trong skynet GL.
-- Mọi getter an toàn với nil: bảng StandardImpact CY có dòng thiếu nhãn hoặc ô rỗng.
local M = {}

function M.num(imp, key, default)
    local v = imp.params and imp.params[key]
    v = tonumber(v)
    if v == nil then
        return default or 0
    end
    return v
end

-- cộng điểm vào args.point (refix thuộc tính)
function M.add_point(args, value)
    if value and value ~= 0 then
        args.point = (args.point or 0) + math.floor(value)
    end
end

-- cộng phần trăm vào args.rate (refix thuộc tính)
function M.add_rate(args, value)
    if value and value ~= 0 then
        args.rate = (args.rate or 0) + math.floor(value)
    end
end

-- cộng phần trăm sát thương cho mọi hệ (damages[wg_rate..damage_rate])
function M.add_damage_rate(damages, rate_keys, value)
    if not damages or not damages.damage_rate or not value or value == 0 then
        return false
    end
    for _, key in ipairs(rate_keys) do
        damages[key] = (damages[key] or 100) + value
    end
    return true
end

return M
