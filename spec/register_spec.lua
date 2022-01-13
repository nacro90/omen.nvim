---@diagnostic disable: unused-local
local register

local mock = require "luassert.mock"
local stub = require "luassert.stub"
local spy = require "luassert.spy"
local match = require "luassert.match"
local state = require "luassert.state"

describe("register", function()
  before_each(function()
    _TEST = true
    register = require "omen.register"
  end)

  after_each(function()
    register.clear_caches()
    _TEST = nil
  end)

  describe("get_caches", function()
    it("should get register cache table", function()
      local caches = register.get_caches()
      assert.are.same({}, caches)
    end)
  end)

  describe("clear_caches", function()
    it("should clear register caches", function()
      register.get_caches()["cache_key"] = { "cache_val" }
      register.clear_caches()
      assert.are.same({}, register.get_caches())
    end)
  end)

  describe("store_pass", function()
    it("should store password with given timeout", function()
      local defer_stub = stub(vim, "defer_fn")
      local getreg = stub(vim.fn, "getreg")
      local setreg = stub(vim.fn, "setreg")

      getreg.returns "some-content"

      register.store_pass("some-pass", "some-register", 0)

      assert.stub(defer_stub).was.called_with(match.is_function(), 0)
      assert.stub(getreg).was.called_with "some-register"
      assert.stub(setreg).was.called_with("some-register", "some-pass", "c")
      assert.are.same(
        { ["some-register"] = { content = "some-content", counter = 1 } },
        register.get_caches()
      )
    end)

    it(
      "should increment counter when two passwords are being stored same register consecutively",
      function()
        local defer_stub = stub(vim, "defer_fn")
        local getreg = stub(vim.fn, "getreg")
        local setreg = stub(vim.fn, "setreg")

        getreg.returns "some-content"

        register.store_pass("some-pass-1", "some-register", 0)
        register.store_pass("some-pass-2", "some-register", 0)

        assert.stub(defer_stub).was.called_with(match.is_function(), 0)
        assert.stub(getreg).was.called_with "some-register"
        assert.stub(getreg).was.called(1)
        assert.stub(setreg).was.called_with("some-register", "some-pass-1", "c")
        assert.stub(setreg).was.called_with("some-register", "some-pass-2", "c")
        assert.stub(setreg).was.called(2)
        assert.are.same(
          { ["some-register"] = { content = "some-content", counter = 2 } },
          register.get_caches()
        )
      end
    )
  end)

  describe("create_defer_callback", function()
    it(
      "should create a callback that should decrement the counter of the register cache",
      function()
        local getreg = stub(vim.fn, "getreg")
        local setreg = stub(vim.fn, "setreg")

        getreg.returns "some-content"

        register.store_pass("some-pass", "some-register", 0)

        register.create_defer_callback "some-register"()

        assert.are.same({}, register.get_caches())
      end
    )
    it(
      "should assert counter to be greater than zero",
      function()
        local getreg = stub(vim.fn, "getreg")
        local setreg = stub(vim.fn, "setreg")

        getreg.returns "some-content"

        register.store_pass("some-pass", "some-register", 0)

        register.create_defer_callback "some-register"()

        assert.are.same({}, register.get_caches())
      end
    )
  end)
end)
