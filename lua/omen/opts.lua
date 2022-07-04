local opts = {}

---@alias PickerType "telescope" | "select"

---@class OmenOpts
---@field picker? PickerType @Picker type
---@field title? string @Title to be displayed on the picker
---@field store? string @Password store directory
---@field passphrase_prompt? string @Prompt when asking the passphrase
---@field register? string @Which register to fill after decoding a password
---@field retention? integer @How much seconds the life of the decoded passwords in the register
---@field use_default_keymaps? boolean @Whether display info messages or not
---@field ignored? string[] @Ignored directories or files that are not to be listed in picker

opts.default_ignored = {
  ".git",
  ".gitattributes",
  ".gpg-id",
  ".stversions",
  "Recycle Bin",
}

---@type OmenOpts
opts.defaults = {
  picker = "telescope",
  title = "Omen",
  store = vim.env.HOME .. "/.password-store/",
  passphrase_prompt = "Passphrase: ",
  register = "+",
  retention = 45,
  ignored = opts.default_ignored,
  use_default_keymaps = true,
}

---Overrides given options table
---@param defaults table
---@param overrides table
---@return table
function opts.override(defaults, overrides)
  local overridden_opts = {}
  for k, v in pairs(defaults) do
    if type(v) == "table" and not vim.tbl_islist(v) then
      overridden_opts[k] = opts.override(defaults[k], overrides[k])
    else
      overridden_opts[k] = overrides[k] or defaults[k]
    end
  end
  return overridden_opts
end

---Creates overriden options
---@param overrides OmenOpts
function opts.create_overridden(overrides)
  if not overrides then
    return opts.defaults
  end
  return opts.override(opts.defaults, overrides)
end

return opts
