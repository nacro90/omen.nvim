local omen = require "omen"
local gpg = require "omen.gpg"

local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local function on_entry_selected(prompt_bufnr)
  actions.select_default:replace(function()
    local selection = action_state.get_selected_entry()
    if not selection then
      print "[Omen] Nothing currently selected"
      return
    end

    actions.close(prompt_bufnr)

    local entry = selection.display
    local decoded, err = gpg.decrypt(entry, omen.get_password_store())
    if err then
      decoded, err = gpg.decrypt(entry, omen.get_password_store(), omen.input_passphrase())
      if err then
        print(err)
        return
      end
    end

    local reg = omen.opts.register
    omen.save_to_register(reg, decoded)
    local reg_timeout = omen.opts.register_timeout
    omen.schedule_clear(reg, reg_timeout)
    if not omen.opts.silent then
      omen.clear_cmd()
      local template = "Copied %s to the register `%s`. Will clear in %d seconds."
      print(template:format(entry, reg, reg_timeout))
    end
  end)

  return true
end

function omen.telescope()
  local pass_entries = omen.get_pass_entries()

  local picker = pickers.new {
    prompt_title = "Omen",
    finder = finders.new_table {
      results = pass_entries,
      entry_maker = function(entry)
        return {
          ordinal = entry,
          display = omen.clear_entry(entry),
          filename = omen.get_password_store() .. entry,
        }
      end,
    },
    sorter = conf.generic_sorter {},
    attach_mappings = on_entry_selected,
  }
  picker:find()
end
local has_telescope, telescope = pcall(require, "telescope")
assert(has_telescope, "This plugins requires nvim-telescope/telescope.nvim")

return telescope.register_extension {
  setup = function() end,
  exports = {
    list = omen.telescope,
  },
}
