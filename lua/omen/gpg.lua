local gpg = {}

local errors = require "omen.errors"

local Job = require "plenary.job"

---Decrypts given encrypted file with a passphrase.
---GPG decrypts the file without a passphrase if there is a valid cache.
---So the function can be used without the passphrase parameter safely.
---@param file string @File to be decrypted
---@param passphrase string?
---@return string|nil @First line of decoded content
---@return string|nil @Error
function gpg.decrypt(file, passphrase)
  passphrase = passphrase or ""

  local job = Job:new {
    command = "gpg",
    args = {
      "--batch",
      "--yes",
      "--passphrase-fd",
      "0",
      "--pinentry-mode",
      "loopback",
      "--decrypt",
      file,
    },
    writer = passphrase,
  }
  job:sync()

  for _, line in ipairs(job:stderr_result()) do
    if line:find "Bad passphrase" then
      return nil, errors.BAD_PASSPHRASE
    end
  end

  local result = job:result()
  if #result == 0 then
    return nil, errors.EMPTY_RESULT
  end

  return result[1]
end

return gpg
