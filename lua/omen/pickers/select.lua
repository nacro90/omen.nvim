---@type OmenPicker
local select = {}

local function create_opts(data)
  return {
    prompt = data.title,
    format_item = data.formatter,
  }
end

---Pick via vim.ui.select
---@param data PickData
function select.pick(data)
  vim.ui.select(data.get_files(), create_opts(data), data.on_selected)
end

return select
