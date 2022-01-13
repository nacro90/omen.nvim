local gpg = {}

local Job = require "plenary.job"

local BAD_PASSPHRASE = "Bad passphrase"

---@TODO Doc
function gpg.decrypt(entry, pass_dir, passphrase)
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
      entry .. ".gpg",
    },
    cwd = pass_dir,
    writer = passphrase,
  }
  job:sync()

  for _, line in ipairs(job:stderr_result()) do
    if line:find(BAD_PASSPHRASE) then
      return nil, BAD_PASSPHRASE
    end
  end

  local result = job:result()
  if #result == 0 then
    return nil, "Unknown error"
  end

  return result[1]
end

---@TODO Doc
function gpg.encrypt(name, recipient, pass_dir, password)
  local job = Job:new {
    command = "gpg",
    args = {
      "--encrypt",
      "--recipient",
      recipient,
      "--output",
      name .. ".gpg",
    },
    cwd = pass_dir,
    writer = password,
  }
  job:sync()

  local result = job:stderr_result()
  if result and not vim.tbl_isempty(result) then
    return table.concat(result, ", ")
  end
end

return gpg
