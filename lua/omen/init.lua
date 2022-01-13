local omen = {}

local PATH_SEPARATOR = require("plenary.path").sep

local log = require "omen.log"
local random = require "omen.random"
local gpg = require "omen.gpg"

local vim = vim
local uv = vim.loop
local fn = vim.fn
local api = vim.api
local map = api.nvim_set_keymap

local previous_reg_content

omen.opts = require("omen.opts").defaults

local function get_password_store()
  local pw_store = omen.opts.password_store
  return pw_store:find(PATH_SEPARATOR .. "$") and pw_store or (pw_store .. PATH_SEPARATOR)
end

local function is_dir(path)
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

local function file_exists(file)
  local f = io.open(file, "rb")
  if f then
    f:close()
    return true
  end
  return f ~= nil
end

local function get_recipient(password_store)
  password_store = password_store or get_password_store()
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

local function insert_entry(path, password, password_store)
  password_store = password_store or omen.opts.password_store
  local dir = password_store .. get_dir(path)
  if dir ~= "" then
    fn.mkdir(dir, "p", tonumber(omen.opts.permission.folder, 8))
  end

  local recipient = assert(get_recipient(password_store))
  local name = get_name(path)
  local err = gpg.encrypt(name, recipient, password_store, password)
  if err then
    log.fatal(err)
  end
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
  until pass == repass

  insert_entry(path, pass)
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
  insert_entry(path, random.generate(length))
  print(('Password for entry "%s" generated'):format(path))
end

function omen.setup(user_opts)
  log.info "plugin initialized"
  omen.opts = vim.tbl_extend("force", omen.opts, user_opts or {})
  map("n", "<leader>P", "<Cmd>lua require('omen').telescope()<CR>", {})
end

return omen
