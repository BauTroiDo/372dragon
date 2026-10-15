-- Admission happens before any RPC/yield. Server/system mail bypasses this player-only guard.
local M={interval=5,window=60,maximum=10,duplicate_window=60}
function M.accept(state,mail,now)
 if type(mail)~='table' or type(mail.dest)~='string' or type(mail.content)~='string'
  or #mail.dest<1 or #mail.dest>120 or #mail.content<1 or #mail.content>1024
  or mail.dest:find('[%z\r\n]') or mail.content:find('%z') then return false end
 state.recent=state.recent or {}
 for key,t in pairs(state.recent) do if now-t>=M.duplicate_window then state.recent[key]=nil end end
 if state.last and now-state.last<M.interval then return false end
 if not state.since or now-state.since>=M.window then state.since=now;state.count=0 end
 local key=mail.dest..'\0'..mail.content
 if (state.count or 0)>=M.maximum or state.recent[key] then return false end
 state.last=now;state.count=(state.count or 0)+1;state.recent[key]=now
 return true
end
return M
