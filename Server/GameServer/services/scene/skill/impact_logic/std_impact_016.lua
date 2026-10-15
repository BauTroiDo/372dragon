-- server-impact: logic 16 (tlbb15 StdImpact016 反应迟钝/虚弱…): sửa 5 thuộc tính cơ bản theo PHẦN TRĂM.
-- Nhãn: STR修正%(0为无效), Con修正%(0为无效), SPR修正%(0为无效), INT修正%(0为无效), DEX修正%(0为无效)
-- (logic 15 đã cài làm bản theo ĐIỂM với nhãn không có dấu %).
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local std_impact_016 = class("std_impact_016", base)

function std_impact_016:is_over_timed()
    return true
end

function std_impact_016:is_intervaled()
    return false
end

function std_impact_016:get_refix_str(imp, args)
    util.add_rate(args, util.num(imp, "STR修正%(0为无效)"))
end

function std_impact_016:get_refix_con(imp, args)
    util.add_rate(args, util.num(imp, "Con修正%(0为无效)"))
end

function std_impact_016:get_refix_spr(imp, args)
    util.add_rate(args, util.num(imp, "SPR修正%(0为无效)"))
end

function std_impact_016:get_refix_int(imp, args)
    util.add_rate(args, util.num(imp, "INT修正%(0为无效)"))
end

function std_impact_016:get_refix_dex(imp, args)
    util.add_rate(args, util.num(imp, "DEX修正%(0为无效)"))
end

return std_impact_016
