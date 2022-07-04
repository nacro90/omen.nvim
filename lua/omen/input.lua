local input = {}

local gpg = require "omen.gpg"

local CANCEL_RETURN = "29bfa101a5784de0907b666c2d5ef510"

function input.clear()
  vim.cmd "mode"
end

function input.decrypt(file, prompt)
  local decoded, err = gpg.decrypt(file)
  if not err then
    return decoded
  end
  local passphrase = vim.fn.inputsecret {
    prompt = prompt,
    cancelreturn = CANCEL_RETURN,
  }
  if passphrase == CANCEL_RETURN then
    return
  end
  decoded, err = gpg.decrypt(file, passphrase)
  input.clear()
  if err then
    vim.api.nvim_err_writeln(err)
  end
  return decoded
end

return input
