local set = require "omen.set"

describe("set", function()
  describe("from", function()
    it("should create a set from a list", function()
      --- given
      local list = { "a", "b", "c" }
      local expected = {
        ["a"] = true,
        ["b"] = true,
        ["c"] = true,
      }
      --- when
      local actual = set.from(list)
      --- then
      assert.same(expected, actual)
    end)
  end)
end)
