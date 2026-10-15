-- Integer/SSE arithmetic used by the donor hook. No donor executable is loaded.
local M = {}
function M.i32(v)
    v = assert(math.tointeger(v), "native integer required") & 0xffffffff
    return v >= 0x80000000 and v - 0x100000000 or v
end
function M.f32(v) return (string.unpack("f", string.pack("f", v))) end
function M.trunc(v) return v < 0 and math.ceil(v) or math.floor(v) end
-- The original C++ GameUtil.h Float2Int: positive halves round up;
-- negative values truncate toward zero. Native binding must certify this rule.
function M.legacy_float2int(v)
    local i = M.trunc(v)
    return v - i < 0.5 and i or i + 1
end
-- Verified directly in main Server0x6e6a20, including CVTTSS2SI overflow.
function M.float2int(value)
    local v=M.f32(value)
    local i
    if v~=v or v>=2147483648 or v< -2147483648 then i=-2147483648 else i=M.trunc(v) end
    local fraction=M.f32(v-M.f32(i))
    -- UCOMISS unordered also sets BE, so NaN adds one to the integer sentinel.
    return M.i32(i+((fraction~=fraction or fraction>=0.5) and 1 or 0))
end
function M.scale(value, numerator, denominator, float2int)
    local product = M.i32(M.i32(value) * M.i32(numerator))
    return float2int(M.f32(M.f32(product) / M.f32(denominator)))
end
return M
