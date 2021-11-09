local debug_ = {}

---@diagnostic disable-next-line: unused-local
local log = require "omen.log"

--- Get called function name
---@return string
function debug_.fname()
  return debug.getinfo(2, "n").name .. "()"
end

function debug_.reload()
  for name in pairs(package.loaded) do
    if name:find "omen" then
      package.loaded[name] = nil
    end
  end
  print "RELOADED"
end

return debug_
