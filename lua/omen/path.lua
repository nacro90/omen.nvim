local path = {}

local uv = vim.loop

local SEP = require("plenary.path").path.sep

function path.end_with_sep(str)
  return str:find(SEP .. "$") and str or str .. SEP
end

function path.concat(left, right)
  left = path.end_with_sep(left)
  return left .. right
end

function path.iter(dir)
  local fp = assert(uv.fs_scandir(dir))
  return function()
    return uv.fs_scandir_next(fp)
  end
end

function path.is_dir(str)
  local stats = uv.fs_stat(str)
  return stats.type == "directory"
end

function path.remove_parent(full, parent)
  parent = path.end_with_sep(parent)
  local pattern = parent:gsub("-", "%%-")
  return full:gsub(pattern, "")
end

function path.remove_gpg_ext(str)
  return str:gsub(".gpg", "")
end

return path
