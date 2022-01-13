---@diagnostic disable: unused-local

local random = require "omen.random"

local uv = vim.loop

local mock = require "luassert.mock"
local stub = require "luassert.stub"
local spy = require "luassert.spy"
local match = require "luassert.match"

describe("random", function()
  describe("generate", function()
    it("should generate random string from given charset at given length", function()
      --- given
      stub(uv, "random")
      uv.random.returns(2)

      local charset = "some-charset"
      local expected = charset:sub(2, 2):rep(5)

      --- when
      local actual = random.generate(5, charset)

      --- then
      assert.are.equals(expected, actual)
    end)
  end)

  describe("generate_from_charsets", function()
    it("should generate random string from predefined charsets at given length", function()
      --- given
      stub(uv, "random")
      uv.random.returns(2)
      stub(random, "generate")
      random.generate.returns "some-random-string"

      --- when
      local actual = random.generate_from_charsets(5, { "numeric", "lower", "upper" })

      --- then
      assert.are.equals("some-random-string", actual)
    end)
  end)
end)
