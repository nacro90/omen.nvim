local omen = {}

local Job = require "plenary.job"

local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local finders = require "telescope.finders"
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values

local log = require "omen.log"

local vim = vim
local uv = vim.loop
local fn = vim.fn
local api = vim.api
local map = api.nvim_set_keymap

local BAD_PASSPHRASE = "Bad passphrase"

local previous_reg_content
local passphrase_cache

math.randomseed(os.clock() ^ 5)

omen.opts = {
  password_store = vim.env.HOME .. "/.password-store/",
  passphrase_prompt = "Passphrase: ",
  register = "+",
  register_timeout = 45,
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

local function get_password_store()
  local path = assert(omen.opts.password_store)
  return path:find "/$" and path or (path .. "/")
end

local function is_dir(path)
  assert(path)
  local stats = uv.fs_stat(path)
  return stats.type == "directory"
end

function omen.get_pass_entries(pass_dir)
  pass_dir = pass_dir or get_password_store()
  assert(is_dir(pass_dir), "`pass_dir` must be a directory path")

  local fp = assert(uv.fs_scandir(pass_dir))

  local function entry_iter()
    return uv.fs_scandir_next(fp)
  end

  local collected = {}

  for direntry in entry_iter do
    if not omen.opts.ignored_entries[direntry] then
      local entry_abs = pass_dir .. direntry
      if is_dir(entry_abs) then
        vim.list_extend(collected, omen.get_pass_entries(entry_abs .. "/"))
      else
        table.insert(collected, entry_abs)
      end
    end
  end

  return collected
end

local function clear_cmd()
  vim.cmd "mode"
end

local function input_passphrase()
  local input = fn.inputsecret(omen.opts.passphrase_prompt)
  if input == "" then
    return
  end
  return input
end

local function decode_entry(entry, pass_dir, passphrase)
  pass_dir = pass_dir or get_password_store()
  passphrase = passphrase or passphrase_cache

  if not passphrase then
    passphrase = input_passphrase()
  end

  if not passphrase then
    return nil, BAD_PASSPHRASE
  end

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

  if omen.opts.passphrase_cache then
    if not passphrase_cache then
      passphrase_cache = passphrase
    end
    ---FIXME cache is removed early if there is another decode
    vim.defer_fn(function()
      passphrase_cache = nil
    end, omen.opts.passphrase_cache_timeout * 1000)
  end

  return result[1]
end

local function clear_entry(entry, prefix)
  prefix = prefix or get_password_store()
  local pass_dir_pattern = prefix:gsub("-", "%%-")
  return entry:gsub(pass_dir_pattern, ""):gsub(".gpg", "")
end

local function schedule_clear(register, seconds)
  vim.defer_fn(function()
    fn.setreg(register, previous_reg_content or "", "c")
    if not omen.opts.silent then
      print(("Cleared the register `%s`"):format(register))
    end
  end, seconds * 1000)
end

local function save_to_register(register, content)
  previous_reg_content = fn.getreg(register)
  fn.setreg(register, content, "c")
end

local function on_entry_selected(prompt_bufnr)
  actions.select_default:replace(function()
    local selection = action_state.get_selected_entry()
    if not selection then
      print "[Omen] Nothing currently selected"
      return
    end

    actions.close(prompt_bufnr)

    local entry = selection.display
    local decoded = assert(decode_entry(entry))
    local reg = omen.opts.register
    save_to_register(reg, decoded)
    local reg_timeout = omen.opts.register_timeout
    schedule_clear(reg, reg_timeout)
    if not omen.opts.silent then
      clear_cmd()
      local template = "Copied %s to the register `%s`. Will clear in %d seconds."
      print(template:format(entry, reg, reg_timeout))
    end
  end)

  return true
end

function omen.telescope()
  local pass_entries = omen.get_pass_entries()

  local picker = pickers.new {
    prompt_title = "Omen",
    finder = finders.new_table {
      results = pass_entries,
      entry_maker = function(entry)
        return {
          ordinal = entry,
          display = clear_entry(entry),
          filename = get_password_store() .. entry,
        }
      end,
    },
    sorter = conf.generic_sorter {},
    attach_mappings = on_entry_selected,
  }
  picker:find()
end

local function file_exists(file)
  local f = io.open(file, "rb")
  if f then
    f:close()
  end
  return f ~= nil
end

local function get_recipient(password_store)
  password_store = password_store or omen.opts.password_store
  local f = password_store .. ".gpg-id"
  if not file_exists(f) then
    return nil, "GPG Id file not found"
  end
  local line_iter = io.lines(f)
  return line_iter() --first line
end

local function get_dir(path)
  return path:gsub("/?[^/]+$", "")
end

local function get_name(path)
  return path:match "/?([^/]+)$"
end

local function prompt_path()
  return fn.input "Enter path: "
end

local function insert_entry(path, pass, password_store)
  password_store = password_store or omen.opts.password_store
  local dir = password_store .. get_dir(path)
  if dir ~= "" then
    fn.mkdir(dir, "p", tonumber(700, 8))
  end

  local recipient = assert(get_recipient(password_store))
  local name = get_name(path)
  local job = Job:new {
    command = "gpg",
    args = {
      "--encrypt",
      "--recipient",
      recipient,
      "--output",
      name .. ".gpg",
    },
    cwd = dir,
    writer = pass,
  }
  job:sync()

  local stderr_result = job:stderr_result()
  assert(#stderr_result == 0, table.concat(stderr_result, ", "))
end

function omen.insert()
  local path = prompt_path()
  local pass
  local repass
  repeat
    pass = fn.inputsecret(("Enter password for %s: "):format(path))
    repass = fn.inputsecret(("Retype password for %s: "):format(path))
    if pass == repass then
      print "The entered passwords do not match"
    end
    vim.cmd "mode"
  until pass == repass

  insert_entry(path, pass)
end

local CHARSET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

local function generate_random_string(n)
  n = n or omen.opts.generate_length
  local chars = {}
  for i = 1, n do
    local rand = math.random(#CHARSET)
    local char = CHARSET:sub(rand, rand)
    chars[i] = char
  end
  return table.concat(chars, "")
end

function omen.generate()
  local path = prompt_path()
  local default_length = omen.opts.generate_length
  local length = default_length
  if omen.opts.prompt_generate_length then
    local inp = fn.input {
      prompt = "How long should the password be? ",
      default = tostring(length),
      cancelreturn = default_length,
    }
    length = assert(tonumber(inp), "Invalid number")
  end
  insert_entry(path, generate_random_string(length))
  print(('Password for entry "%s" generated'):format(path))
end

function omen.setup(user_opts)
  log.info "plugin initialized"
  omen.opts = vim.tbl_extend("force", omen.opts, user_opts or {})
  map("n", "<leader>P", "<Cmd>lua require('omen').telescope()<CR>", {})
  -- nnoremap("<leader>P", omen.telescope)
  -- command("OmenTelescope", omen.telescope)
  -- command("OmenInsert", omen.insert)
  -- command("OmenGenerate", omen.generate)
end

return omen
