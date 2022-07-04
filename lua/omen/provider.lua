local provider = {}

local path = require "omen.path"
local set = require "omen.set"

local function get_files(store, ignored)
  assert(path.is_dir(store), "`store` must be a directory path: " .. store)

  local collected = {}
  for entry in path.iter(store) do
    if ignored and ignored[entry] then
      goto continue
    end

    local entry_abs = path.concat(store, entry)
    if path.is_dir(entry_abs) then
      vim.list_extend(collected, get_files(entry_abs, ignored), nil, nil)
    else
      table.insert(collected, entry_abs)
    end

    ::continue::
  end

  return collected
end

---This is about avoid recursion with table access
function provider.get_files(store, ignored)
  local ignored_set
  if ignored then
    ignored_set = set.from(ignored)
  end
  return get_files(store, ignored_set)
end

---Creates getter functional
---@param store string @Path of the store
---@param ignored string[] @Ignored files that will be excluded
---@return fun(): string[] @Function that returns the results
function provider.create_getter(store, ignored)
  return function()
    return provider.get_files(store, ignored)
  end
end

return provider
