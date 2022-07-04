local function reload()
  for name in pairs(package.loaded) do
    if name:find "omen" then
      package.loaded[name] = nil
    end
  end
  print "RELOADED"
end

vim.keymap.set("n", "<leader><leader>R", reload)
vim.keymap.set("n", "<leader><leader>r", function()
  reload()
  require("omen").setup{
    picker = 'select'
  }
end)

vim.cmd [[set rtp+=getcwd()]]
vim.env.DEBUG = "true"
reload()
