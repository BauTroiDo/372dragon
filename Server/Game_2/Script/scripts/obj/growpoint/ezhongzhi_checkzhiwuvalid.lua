local class = require "class"
local define = require "define"
local ScriptGlobal = require "scripts.ScriptGlobal"
local script_base = require "script_base"
local ezhongzhi_checkzhiwuvalid = class("ezhongzhi_checkzhiwuvalid", script_base)
ezhongzhi_checkzhiwuvalid.script_id = 713551
local v_ZhongZhiId = {
    20104001,
    20104002,
    20104003,
    20104004,
    20104005,
    20104006,
    20104007,
    20104008,
    20104009,
    20104010,
    20104011,
    20104012,
    20105001,
    20105002,
    20105003,
    20105004,
    20105005,
    20105006,
    20105007,
    20105008,
    20105009,
    20105010,
    20105011,
    20105012
}
local v_ZhongZhiNeedLevel = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
local v_ItemBoxTypeId = {
    501,
    504,
    507,
    510,
    513,
    516,
    519,
    522,
    525,
    528,
    531,
    534,
    537,
    540,
    543,
    546,
    549,
    552,
    555,
    558,
    561,
    564,
    567,
    570
}

function ezhongzhi_checkzhiwuvalid:CheckZhiWuValid(selfId, zhiwuId)
   local  v_AbilityLevel = self:QueryHumanAbilityLevel(selfId, define.ABILITY_ZHONGZHI)
    for k, findId in pairs(v_ZhongZhiId) do
        if zhiwuId == findId then
            if v_AbilityLevel >= v_ZhongZhiNeedLevel[k] then
                return k
            else
                return 0
            end
        end
    end
end

function ezhongzhi_checkzhiwuvalid:FindItemBoxTypeId(selfId, zhiwuId)
    for m, findId in pairs(v_ZhongZhiId) do
        if zhiwuId == findId then
            return v_ItemBoxTypeId[m]
        end
    end
    return 0
end

function ezhongzhi_checkzhiwuvalid:FindZhiWuLevel(selfId, zhiwuId)
    for n, findId in pairs(v_ZhongZhiId) do
        if zhiwuId == findId then
            return v_ZhongZhiNeedLevel[n]
        end
    end
    return 0
end

return ezhongzhi_checkzhiwuvalid
