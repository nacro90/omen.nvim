local set = {}

---Creates a set like table from a list
---@generic T
---@param list T[]
---@return table<T,boolean>
function set.from(list)
  local s = {}
  for _, elem in ipairs(list) do
    s[elem] = true
  end
  return s
end

return set
