local formatter = {}

local path = require "omen.path"

local function extract_name(file, store)
  local cleared = path.remove_parent(file, store)
  return path.remove_gpg_ext(cleared)
end

function formatter.create_name_extractor(store)
  return function(file)
    return extract_name(file, store)
  end
end

return formatter
