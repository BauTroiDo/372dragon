-- tlbb_decrypt.lua
-- 天龙八部 密码解密模块
-- 完整实现: CRT解码 + 混合基数 + RC4解密 + 逐字符提取验证

local md5 = require "md5"
local M = {}

-- 加密版本号 (LCRetConnect.unknow1 发送给客户端)
M.VERSION = 3474034634  -- 0xCF118FCA

--------------------------------------------------------------------------------
-- 大数运算 (32位 limb 数组, 小端序, limb[1]最低位)
--------------------------------------------------------------------------------

local MASK32 = 0xFFFFFFFF

local function bn_trim(a)
    while #a > 1 and a[#a] == 0 do a[#a] = nil end
    return a
end

local function bn_cmp(a, b)
    local na, nb = #a, #b
    if na ~= nb then return na < nb and -1 or 1 end
    for i = na, 1, -1 do
        if a[i] ~= b[i] then return a[i] < b[i] and -1 or 1 end
    end
    return 0
end

local function bn_add(a, b)
    local n = math.max(#a, #b)
    local r = {}
    local carry = 0
    for i = 1, n do
        local s = (a[i] or 0) + (b[i] or 0) + carry
        r[i] = s & MASK32
        carry = s >> 32
    end
    if carry > 0 then r[n + 1] = carry end
    return r
end

local function bn_sub(a, b)
    local n = #a
    local r = {}
    local borrow = 0
    for i = 1, n do
        local s = (a[i] or 0) - (b[i] or 0) - borrow
        if s < 0 then
            s = s + 0x100000000
            borrow = 1
        else
            borrow = 0
        end
        r[i] = s
    end
    return bn_trim(r)
end

local function bn_mul(a, b)
    local na, nb = #a, #b
    local r = {}
    for i = 1, na + nb do r[i] = 0 end
    for i = 1, nb do
        local bi = b[i]
        if bi ~= 0 then
            local carry = 0
            for j = 1, na do
                local idx = i + j - 1
                local p = a[j] * bi + r[idx] + carry
                r[idx] = p & MASK32
                carry = p >> 32
            end
            if carry > 0 then
                r[i + na] = r[i + na] + carry
            end
        end
    end
    return bn_trim(r)
end

local function bn_bits(a)
    if #a == 0 or (#a == 1 and a[1] == 0) then return 0 end
    local top = a[#a]
    local bits = (#a - 1) * 32
    while top > 0 do
        bits = bits + 1
        top = top >> 1
    end
    return bits
end

local function bn_shl(a, n)
    if n == 0 then
        local r = {}
        for i = 1, #a do r[i] = a[i] end
        return r
    end
    local words = n // 32
    local bits = n % 32
    local r = {}
    for i = 1, words do r[i] = 0 end
    if bits == 0 then
        for i = 1, #a do r[words + i] = a[i] end
    else
        local carry = 0
        for i = 1, #a do
            local v = (a[i] << bits) | carry
            r[words + i] = v & MASK32
            carry = v >> 32
        end
        if carry > 0 then r[words + #a + 1] = carry end
    end
    return bn_trim(r)
end

local function bn_mod(a, m)
    local r = {}
    for i = 1, #a do r[i] = a[i] end
    while bn_cmp(r, m) >= 0 do
        local rb = bn_bits(r)
        local mb = bn_bits(m)
        local shift = rb - mb
        if shift > 0 then
            local ms = bn_shl(m, shift)
            if bn_cmp(r, ms) < 0 then
                shift = shift - 1
                ms = bn_shl(m, shift)
            end
            r = bn_sub(r, ms)
        else
            r = bn_sub(r, m)
        end
    end
    return bn_trim(r)
end

local function bn_from_bytes_le(s, offset, count)
    local r = {}
    local word = 0
    local shift = 0
    for i = 0, count - 1 do
        local b = string.byte(s, offset + i)
        word = word | (b << shift)
        shift = shift + 8
        if shift == 32 then
            r[#r + 1] = word
            word = 0
            shift = 0
        end
    end
    if shift > 0 then r[#r + 1] = word end
    if #r == 0 then r[1] = 0 end
    return r
end

--------------------------------------------------------------------------------
-- 预计算常量 (来自IDA逆向分析)
--------------------------------------------------------------------------------

-- 外层CRT (128位)
local OUTER_MOD = {0x8852099A, 0x23FE9ECE, 0xEB30F968, 0xA819989F}
local OUTER_M1  = {0xEF368072, 0xD9FBAE6A, 0x8F50576F, 0x02D6DF63}
local OUTER_M2  = {0x991B8929, 0x4A02F063, 0x5BE0A1F8, 0xA542B93C}

-- 内层CRT (64位)
local INNER_MOD = {0xC660E015, 0xCD5A49DC}
local INNER_MA  = {0xED10A0A0, 0xC865D81F}
local INNER_MB  = {0xD9503F76, 0x04F471BC}

-- 15素数CRT
local PRIMES     = {3, 5, 7, 11, 13, 17, 19, 23, 31, 37, 41, 43, 47, 53, 59}
local BIT_WIDTHS = {2, 3, 3,  4,  4,  5,  5,  5,  5,  6,  6,  6,  6,  6,  6}
local PRIME_P    = {0x0B3BC23B, 0xCC1027B6, 0x00000001}
local PRIME_MI   = {
    {0x5913EB69, 0x995AB7E7, 0x00000000},  -- p=3
    {0xD14B1A7E, 0xB8067648, 0x00000000},  -- p=5
    {0xE373D3E1, 0x489DD338, 0x00000001},  -- p=7
    {0x4F025919, 0x786A4F09, 0x00000001},  -- p=11
    {0xA4738B38, 0x1B1DA248, 0x00000001},  -- p=13
    {0x08971C0F, 0x5FD01E5E, 0x00000001},  -- p=17
    {0x591E8F1E, 0x52FE6E1A, 0x00000001},  -- p=19
    {0x93A048EE, 0x780436E1, 0x00000000},  -- p=23
    {0x706D9186, 0xCFC53B39, 0x00000000},  -- p=31
    {0x54007AA6, 0x43499F5D, 0x00000001},  -- p=37
    {0x9979276C, 0x93F53599, 0x00000001},  -- p=41
    {0x25150D5C, 0x2B937329, 0x00000001},  -- p=43
    {0x007A5F6A, 0x1393C054, 0x00000000},  -- p=47
    {0x856D574B, 0x412D16E4, 0x00000001},  -- p=53
    {0x65972A37, 0xACDF54BF, 0x00000001},  -- p=59
}

--------------------------------------------------------------------------------
-- MD5 原始摘要
--------------------------------------------------------------------------------

local function md5_raw(data)
    if md5.sum then
        return md5.sum(data)
    end
    -- 回退: 从hex转二进制
    local hex = md5.sumhexa(data)
    return hex:gsub('..', function(cc) return string.char(tonumber(cc, 16)) end)
end

--------------------------------------------------------------------------------
-- 外层CRT解码: 16字节 → (lo32, hi32)
-- 输入: r1(8字节LE) || r2(8字节LE)
-- 输出: N = (r1*M1 + r2*M2) mod (c1*c2), 取低64位拆成两个32位
--------------------------------------------------------------------------------

function M.outer_crt_decode(data, offset)
    local r1 = bn_from_bytes_le(data, offset, 8)
    local r2 = bn_from_bytes_le(data, offset + 8, 8)
    local t1 = bn_mod(bn_mul(r1, OUTER_M1), OUTER_MOD)
    local t2 = bn_mod(bn_mul(r2, OUTER_M2), OUTER_MOD)
    local N = bn_mod(bn_add(t1, t2), OUTER_MOD)
    return N[1] or 0, N[2] or 0
end

--------------------------------------------------------------------------------
-- 混合基数解码: 9字节(数组) → 15残差 → CRT重建 → (lo32, hi32)
-- 位打包: LSB优先, 按 BIT_WIDTHS 顺序
--------------------------------------------------------------------------------

function M.mixed_radix_decode(bytes_9)
    -- 读72位到 lo(64位) + hi(8位)
    local lo = 0
    for i = 0, 7 do
        lo = lo | (bytes_9[i + 1] << (i * 8))
    end
    local hi = bytes_9[9]

    -- 提取15个残差
    local residues = {}
    local bit_pos = 0
    for i = 1, 15 do
        local width = BIT_WIDTHS[i]
        local mask = (1 << width) - 1
        local r
        if bit_pos + width <= 64 then
            r = (lo >> bit_pos) & mask
        elseif bit_pos >= 64 then
            r = (hi >> (bit_pos - 64)) & mask
        else
            -- 跨越64位边界
            local lo_bits = 64 - bit_pos
            local lo_part = (lo >> bit_pos) & ((1 << lo_bits) - 1)
            local hi_part = hi & ((1 << (width - lo_bits)) - 1)
            r = lo_part | (hi_part << lo_bits)
        end
        if r >= PRIMES[i] then
            return nil, nil
        end
        residues[i] = r
        bit_pos = bit_pos + width
    end

    -- CRT重建: W = Σ(residues[i] * Mi) mod P
    local W = {0}
    for i = 1, 15 do
        if residues[i] > 0 then
            local term = bn_mul(PRIME_MI[i], {residues[i]})
            W = bn_add(W, term)
        end
    end
    W = bn_mod(W, PRIME_P)
    return W[1] or 0, W[2] or 0
end

--------------------------------------------------------------------------------
-- 内层CRT解码: (lo32, hi32) → seed
-- lo = seed mod ca, hi = seed mod cb
-- seed = (lo*MA + hi*MB) mod (ca*cb), 取低32位
--------------------------------------------------------------------------------

function M.inner_crt_decode(lo, hi)
    local t1 = bn_mul({lo}, INNER_MA)
    local t2 = bn_mul({hi}, INNER_MB)
    local V = bn_mod(bn_add(t1, t2), INNER_MOD)
    return V[1] or 0
end

--------------------------------------------------------------------------------
-- LFSR 逆运算 (并行前缀XOR)
--------------------------------------------------------------------------------

function M.lfsr_inv(y)
    local x = y
    x = (x ~ (x << 1)) & MASK32
    x = (x ~ (x << 2)) & MASK32
    x = (x ~ (x << 4)) & MASK32
    x = (x ~ (x << 8)) & MASK32
    x = (x ~ (x << 16)) & MASK32
    return x
end

--------------------------------------------------------------------------------
-- v4 位排列 (sub_14038F480中的确定性位重排)
--------------------------------------------------------------------------------

function M.bit_perm(v5)
    local v3 = 0
    local v4 = 0
    local used = {}
    for i = 0, 31 do used[i] = false end

    for i = 0, 31 do
        if ((v5 >> i) & 1) == 1 then
            v3 = v3 * 2
        else
            v3 = v3 + 1
        end
        if v3 >= 32 then v3 = 0 end
        while used[v3] do
            v3 = (v3 + 1) % 32
        end
        used[v3] = true
        v4 = (v4 << 1) | ((v5 >> v3) & 1)
    end
    return v4 & MASK32
end

--------------------------------------------------------------------------------
-- 从16字节CRT块提取单个密码字符
-- 流程: 外层CRT解码 → LFSR逆 → f480 → XOR提取
--------------------------------------------------------------------------------

function M.extract_char(data, offset)
    -- 外层CRT解码 → (v12, v9)
    local v12, v9 = M.outer_crt_decode(data, offset)
    -- LFSR逆运算
    local per_char_seed = M.lfsr_inv(v12)
    local combined = M.lfsr_inv(v9)
    -- f480: v5 = (-27659595) * (seed + 2003149044) mod 2^32
    local v5 = ((-27659595) * ((per_char_seed + 2003149044) & MASK32)) & MASK32
    local v4 = M.bit_perm(v5)
    -- 提取字符: char = combined XOR v5 XOR v4
    return (combined ~ v5 ~ v4) & 0xFF
end

--------------------------------------------------------------------------------
-- RC4
--------------------------------------------------------------------------------

function M.rc4_init(key)
    local S = {}
    for i = 0, 255 do S[i] = i end
    local key_len = #key
    local j = 0
    for i = 0, 255 do
        j = (j + S[i] + string.byte(key, (i % key_len) + 1)) % 256
        S[i], S[j] = S[j], S[i]
    end
    return {S = S, i = 0, j = 0}
end

function M.rc4_crypt(state, data)
    local S = state.S
    local si, sj = state.i, state.j
    local out = {}
    for k = 1, #data do
        si = (si + 1) % 256
        sj = (sj + S[si]) % 256
        S[si], S[sj] = S[sj], S[si]
        local t = (S[si] + S[sj]) % 256
        out[k] = string.char(string.byte(data, k) ~ S[t])
    end
    state.i = si
    state.j = sj
    return table.concat(out)
end

--------------------------------------------------------------------------------
-- 主解密验证函数
-- encrypted_data: 原始加密数据(Lua string)
-- version: 加密版本号(整数, 默认0xCF118FCA)
-- db_password: 数据库明文密码(string)
-- 返回: success(bool), message(string)
--------------------------------------------------------------------------------

function M.decrypt_password(encrypted_data, version, db_password)
    version = version or M.VERSION
    local data_len = #encrypted_data

    if data_len < 21 then
        return false, "data too short: " .. data_len
    end

    -- 1. 解析CRT头(16字节) + MR_byte9(1字节)
    local mr_lo, mr_hi = M.outer_crt_decode(encrypted_data, 1)
    local mr_byte9 = string.byte(encrypted_data, 17)

    -- 2. 构建9字节混合基数数据
    local bytes_9 = {
        mr_lo & 0xFF, (mr_lo >> 8) & 0xFF,
        (mr_lo >> 16) & 0xFF, (mr_lo >> 24) & 0xFF,
        mr_hi & 0xFF, (mr_hi >> 8) & 0xFF,
        (mr_hi >> 16) & 0xFF, (mr_hi >> 24) & 0xFF,
        mr_byte9
    }

    -- 3. 混合基数解码 → 内层CRT值
    local inner_lo, inner_hi = M.mixed_radix_decode(bytes_9)
    if not inner_lo then
        return false, "mixed radix decode failed"
    end

    -- 4. 内层CRT解码 → seed
    local seed = M.inner_crt_decode(inner_lo, inner_hi)

    -- 5. 生成RC4密钥: MD5(seed_LE || version_LE)
    local seed_bytes = string.char(
        seed & 0xFF, (seed >> 8) & 0xFF,
        (seed >> 16) & 0xFF, (seed >> 24) & 0xFF)
    local ver_bytes = string.char(
        version & 0xFF, (version >> 8) & 0xFF,
        (version >> 16) & 0xFF, (version >> 24) & 0xFF)
    local rc4_key = md5_raw(seed_bytes .. ver_bytes)

    -- 6. RC4解密 encrypted_data[18:]
    local rc4_state = M.rc4_init(rc4_key)
    local rc4_data = string.sub(encrypted_data, 18)
    local decrypted = M.rc4_crypt(rc4_state, rc4_data)

    -- 7. 读取count
    if #decrypted < 4 then
        return false, "decrypted too short for count"
    end
    local count = string.byte(decrypted, 1)
              | (string.byte(decrypted, 2) << 8)
              | (string.byte(decrypted, 3) << 16)
              | (string.byte(decrypted, 4) << 24)

    -- 8. 验证count与密码长度
    local pwd = string.lower(db_password)
    if count ~= #pwd then
        return false, "count mismatch: got " .. count .. " expected " .. #pwd
    end

    -- 9. 验证数据完整性
    if #decrypted < 4 + count * 16 then
        return false, "insufficient char blocks"
    end

    -- 10. 逐字符提取验证
    for i = 1, count do
        local block_offset = 5 + (i - 1) * 16  -- decrypted内偏移(1-based)
        local char_byte = M.extract_char(decrypted, block_offset)
        local expected = string.byte(pwd, i)
        if char_byte ~= expected then
            return false, string.format("char[%d] mismatch: got 0x%02X expected 0x%02X('%s')",
                i, char_byte, expected, string.sub(pwd, i, i))
        end
    end

    return true, "password verified (" .. count .. " chars)"
end

return M
