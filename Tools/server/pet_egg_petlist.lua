-- pet-egg-56 (19/09/2026): dump BANG g_petList THAT bang cach CHAY file 300027.lua,
-- khong dung regex. Manh hon dem theo dong vi tinh ca ghi de, dinh nghia lap lai, va
-- moi dang khoi tao bang. Chi doi MOT ky tu trong nguon: `local g_petList` -> `g_petList`.
--   lua5.4 11-petlist-runtime.lua <duong dan 300027.lua>   > petlist.tsv
local path = assert(arg[1], "usage: lua5.4 11-petlist-runtime.lua <300027.lua>")
local f = assert(io.open(path, "rb"))
local src = f:read("a"); f:close()

local n
src, n = src:gsub("local%s+g_petList%s*=%s*{%s*}", "g_petList = {}", 1)
assert(n == 1, "khong tim thay `local g_petList = {}` (n=" .. n .. ")")

-- moi truong sandbox: bat ky khoa chua biet deu tra ve mot bang "de dai"
local function loose(name)
  local t = {}
  return setmetatable(t, {
    __index = function(_, k) local v = loose(name .. "." .. tostring(k)); rawset(t, k, v); return v end,
    __call = function(_, ...) return loose(name .. "()") end,
    __tostring = function() return "<" .. name .. ">" end,
    __concat = function(a, b) return tostring(a) .. tostring(b) end,
    __eq = function() return false end,
  })
end

local env = {}
env._G = env
for _, k in ipairs{"pairs","ipairs","type","tostring","tonumber","string","table","math","os","io",
                   "select","error","assert","pcall","xpcall","setmetatable","getmetatable","rawget",
                   "rawset","rawequal","rawlen","next","unpack","print"} do env[k] = _G[k] end
env.require = function(mod)
  if mod == "class" then
    return function(_, base) local c = {}; c.__index = c; setmetatable(c, {__index = base or loose("base")}); return c end
  end
  return loose(mod)
end
setmetatable(env, {__index = function(_, k) return loose(k) end})

local chunk = assert(load(src, "@" .. path, "t", env))
local ok, err = pcall(chunk)
if not ok then io.stderr:write("CHAY LOI: " .. tostring(err) .. "\n"); os.exit(2) end

local list = rawget(env, "g_petList")
assert(type(list) == "table", "g_petList khong phai bang")
local keys = {}
for k, v in pairs(list) do if type(k) == "number" then keys[#keys+1] = k end end
table.sort(keys)
-- xuat JSON. type=1 -> dataId don; type=2 -> mang dai cap nhan vat (dataIds[i])
local function jn(v)  -- so Lua -> so JSON; thieu -> null
  if type(v) == "number" then return string.format("%d", v) end
  if v == nil then return "null" end
  return '"' .. tostring(v) .. '"'
end
local out = {}
for _, k in ipairs(keys) do
  local v = list[k]
  local s
  if type(v) ~= "table" then
    s = string.format('{"item":%d,"shape":"nontable"}', k)
  else
    local dids, parts = rawget(v, "dataIds"), {}
    if type(dids) == "table" then
      for i = 1, 64 do
        local e = rawget(dids, i)
        if type(e) == "table" then
          parts[#parts+1] = string.format('{"dataId":%s,"min":%s,"max":%s}',
            jn(rawget(e,"dataId")), jn(rawget(e,"minHumanLevel")), jn(rawget(e,"maxHumanLevel")))
        end
      end
    end
    s = string.format('{"item":%d,"type":%s,"dataId":%s,"level":%s,"bands":[%s]}',
      k, jn(rawget(v,"type")), jn(rawget(v,"dataId")), jn(rawget(v,"level")), table.concat(parts, ","))
  end
  out[#out+1] = s
end
print("[" .. table.concat(out, ",\n") .. "]")
io.stderr:write("runtime entries = " .. #keys .. "\n")
