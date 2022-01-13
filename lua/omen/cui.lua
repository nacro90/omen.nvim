local cui = {}

local vim = vim
local cmd = vim.cmd

local commands

function cui.setup(commands)
  commands = commands
  cmd [[command! -nargs=* Omen lua require("omen.cui")._omen(<f-args>)]]
end

function cui._omen(...)
  args = {...}
  for _, arg in ipairs(args) do
    if not cuis[arg] then
      end
  end
end

return cui
