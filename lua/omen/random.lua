local random = {}

local uv = vim.loop

---Predefined charsets
---@type table<string, string>
random.CHARSETS = {
  special = [[!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~]],
  lower = "abcdefghijklmnopqrstuvwxyz",
  upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
  numeric = "0123456789",
}

---Generate random string from predefined charsets at given length
---@param length integer
---@param charset_names '"special"' | '"lower"' | '"upper"' | '"numeric"'
---@return string
function random.generate_from_charsets(length, charset_names)
  local charsets = {}
  for _, name in ipairs(charset_names) do
    local charset = random.CHARSETS[name] or ""
    table.insert(charsets, charset)
  end

  local final_charset = table.concat(charsets, "")
  assert(#final_charset > 0, "Charset must not be empty")

  return random.generate(length, final_charset)
end

---Generates random string from given charset at desired length
---@param length integer
---@param charset string
---@return string
function random.generate(length, charset)
  local generated = {}
  for _ = 1, length do
    local rand = uv.random(#charset)
    local pick = charset:sub(rand, rand)
    table.insert(generated, pick)
  end

  return table.concat(generated, "")
end

return random
