local omen = require "omen"

local telescope = require "telescope"

return telescope.register_extension {
  setup = function() end,
  exports = {
    pick = omen.pick,
  },
}
