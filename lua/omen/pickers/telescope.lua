---@type OmenPicker
local telescope = {}

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"

---Creates entry maker for telescope
---@param formatter DisplayFormatter
---@return function
local function create_entry_maker(formatter)
  return function(entry)
    return {
      ordinal = entry,
      display = formatter(entry),
      file = entry,
    }
  end
end

---Creates telescope callback for entry selection
---@param bufnr integer
---@param on_selected SelectCallback
---@return fun()
local function create_on_entry_selected(bufnr, on_selected)
  return function()
    local entry = action_state.get_selected_entry()
    if not entry then
      print "[Omen] Nothing currently selected"
      return
    end
    actions.close(bufnr)
    on_selected(entry.file)
  end
end

---Create telescope options
---@param data PickData
---@return table @Options table for telescope
local function create_opts(data)
  return {
    prompt_title = data.title,
    finder = finders.new_table {
      results = data.get_files(),
      entry_maker = create_entry_maker(data.formatter),
    },
    sorter = conf.generic_sorter {},
    attach_mappings = function(bufnr)
      local on_entry_selected = create_on_entry_selected(bufnr, data.on_selected)
      actions.select_default:replace(on_entry_selected)
      return true
    end,
  }
end

---Pick via telescope
---@param data PickData
function telescope.pick(data)
  local tel_opts = create_opts(data)
  local picker = pickers.new(tel_opts, nil)

  picker:find()
end

return telescope
