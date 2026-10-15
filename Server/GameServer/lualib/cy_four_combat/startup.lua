local M={}
function M.configure()
    local bootstrap=require 'cy_four_combat.bootstrap'
    if bootstrap.bridge then return bootstrap.bridge end
    local config=require 'cy_four_combat.deployment_config'
    local bridge,missing=require('cy_four_combat.integration').prepare(config,require('cy_four_combat.storage').adapters())
    assert(bridge,'CY combat preflight failed: '..bootstrap.describe(missing))
    bootstrap.bridge=bridge
    return bridge
end
return M
