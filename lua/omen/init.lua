local omen = {}

local pickers = require "omen.pickers"
local provider = require "omen.provider"
local formatter = require "omen.formatter"
local opts = require "omen.opts"
local input = require "omen.input"
local register = require "omen.register"

---@type OmenOpts
local active_opts

local function on_selected(file)
  local decoded = input.decrypt(file, active_opts.passphrase_prompt)
  if not decoded then
    return
  end
  register.fill_with_retention(active_opts.register, decoded, active_opts.retention)
end

function omen.pick()
  if not active_opts then
    error "Call setup() function to initialize Omen. `:lua require'omen'.setup()"
  end
  local pick_data = {
    title = active_opts.title,
    get_files = provider.create_getter(active_opts.store, active_opts.ignored),
    formatter = formatter.create_name_extractor(active_opts.store),
    on_selected = on_selected,
  }
  pickers.pick(active_opts.picker, pick_data)
end

local function set_default_keymaps()
  vim.keymap.set("n", "<leader>p", omen.pick)
end

---Setup omen
---@param user_opts OmenOpts
function omen.setup(user_opts)
  active_opts = opts.create_overridden(user_opts)
  if active_opts.use_default_keymaps then
    set_default_keymaps()
  end
end

return omen
