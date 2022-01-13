local register = {}

local fn = vim.fn

---@class RegisterCache
---@field public counter integer @Overlapped store counter
---@field public content string

---@type table<string, RegisterCache>
local register_caches = {}

function register.clear_caches()
  register_caches = {}
end

function register.get_caches()
  return register_caches
end

local function create_defer_callback(register_char)
  return function()
    local cache = register_caches[register_char]
    assert(cache.counter > 0)
    if cache.counter == 1 then
      fn.setreg(register_char, cache.content, "c")
      register_caches[register_char] = nil
    end
    cache.counter = cache.counter - 1
  end
end

function register.store_pass(password, register_char, timeout_in_seconds)
  if not register_caches[register_char] then
    register_caches[register_char] = { counter = 0 }
  end
  local cache = register_caches[register_char]
  cache.content = cache.content or fn.getreg(register_char)
  fn.setreg(register_char, password, "c")
  cache.counter = cache.counter + 1
  vim.defer_fn(create_defer_callback(register_char), timeout_in_seconds)
end

if _TEST then
  ---Expose locals for test
  register.create_defer_callback = create_defer_callback
end

return register
