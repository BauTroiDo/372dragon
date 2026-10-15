-- Additive composition: the live phase-one tables and registries retain identity.
local M={}
function M.configure(config)
 if config.phase2_configured then return config end
 local delta=require 'cy_four_combat.phase2_config'
 for _,key in ipairs({'resolve','impacts','collections','disabled_impacts','disabled_logic_ids'})do
  config[key]=config[key] or {}
  for id,value in pairs(delta[key])do
   if key=='resolve' then
    config.resolve[id]=config.resolve[id] or {}
    for source,target in pairs(value)do
     assert(config.resolve[id][source]==nil or config.resolve[id][source]==target,'phase2 reference collision')
     config.resolve[id][source]=target
    end
   else assert(config[key][id]==nil,'phase2 config collision');config[key][id]=value end
  end
 end
 for _,key in ipairs({'guigu_aura_payload_verified','tao_action_packet_verified','tao_logic168_verified'})do config[key]=delta[key] end
 config.jue_skill_instances=require('cy_four_combat.jue_skill_config')
 config.phase2_configured=true
 return config
end
function M.prepare(config,base)
 if config.tao_action_packet_verified then
  function base:do_action(obj,action,target)return require('cy_four_combat.action_packet').send(obj,action,target)end
 end
 local formations,missing=require('cy_four_combat.guigu_installation').prepare(config,base)
 assert(formations,'formation preflight: '..table.concat(missing or {},', '))
 local tao=require('cy_four_combat.tao_installation').prepare(config,base)
 local jue=require('cy_four_combat.jue_hooks').new(config,base)
 local out={formations=formations,tao=tao,jue=jue}
 -- Per-skill gates remain after a future global enable; unavailable branches
 -- must fail before resource spending rather than silently lose a callback.
 config.disabled_skills=config.disabled_skills or {}
 local function block(source,reason)
  local target=assert(config.resolve.skill_templates[source],'unmapped blocked template')
  config.disabled_skills[target]=reason
 end
 if not config.guigu_aura_payload_verified then
  block(3447,'YinYang aura payload unverified');block(3453,'TanLang aura payload unverified')
 end
 for _,source in ipairs(require('cy_four_combat.tao').native_skills)do
  local ready,why=tao.port:ready(source);if not ready then block(source,why)end
 end
 -- The summon success callback is implemented; its separate table-driven
 -- script808280 fade callback still has no verified body in this donor.
 if not config.tao_landing_replacement then block(3801,'donor808280 requires landing replacement')end
 for _,source in ipairs({3840,3851})do
  if config.disabled_logic_ids[171] then block(source,'GL temporary skill swap unverified')end
 end
 function out:on_use_skill_successfully(owner,info)
  if config.gameplay_enabled~=true then return false end
  local faction=base:donor_faction(owner)
  if faction==12 then return formations:on_use_skill_successfully(owner,info)
  elseif faction==13 then return tao:on_use_skill_successfully(owner,info)
  elseif faction==14 then return jue:on_use_skill_successfully(owner,info) end
 end
 return out,formations.callback_adapters
end
return M
