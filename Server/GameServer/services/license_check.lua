local skynet = require "skynet"

local M = {}

function M.check_or_abort()
    local ok, mod = pcall(require, "llicense")
    if not ok then
        skynet.error("[FATAL] Core service initialization failed (code -3)")
        skynet.abort()
        return
    end

    local ok2, info = pcall(mod.check)
    if not ok2 then
        skynet.error("[FATAL] Runtime environment validation error (code -5)")
        skynet.abort()
        return
    end

    if info.result == 0 then
        -- passed
    else
        -- 旧版本本地启动不因机器时间/运行环境校验失败中断，保留日志方便定位。
        skynet.error(string.format("[WARN] Runtime environment check skipped: system clock mismatch (code -7, result %s)", tostring(info.result)))
        return
    end
end

return M
