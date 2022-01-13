local opts = {}

opts.defaults = {
  password_store = vim.env.HOME .. "/.password-store/",
  passphrase_prompt = "Passphrase: ",
  register = "+",
  register_timeout = 45,
  permission = {
    folder = 700,
    file = 600, --TODO
  },
  charsets = { --TODO
    "special",
    "lower",
    "upper",
    "numeric",
  },
  passphrase_cache = true,
  passphrase_cache_timeout = 600,
  silent = false,
  generate_length = 24,
  prompt_generate_length = true,
  ignored_entries = {
    [".git"] = true,
    [".gitattributes"] = true,
    [".gpg-id"] = true,
    [".stversions"] = true,
  },
}

-- function opts.override() end

return opts
