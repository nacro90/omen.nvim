local path = require "omen.path"

describe("path", function()
  describe("end_with_sep", function()
    it("should append a sep when it does not exist", function()
      --- given
      local str = "/some/path"
      --- when
      local actual = path.end_with_sep(str)
      --- then
      assert.equal("/some/path/", actual)
    end)

    it("should return original path if ends with sep", function()
      --- given
      local str = "/some/path/"
      --- when
      local actual = path.end_with_sep(str)
      --- then
      assert.equal("/some/path/", actual)
    end)
  end)

  describe("concat", function()
    it("should concat two paths with separator in between", function()
      --- given
      local left, right = "a/", "b"
      --- when
      local actual = path.concat(left, right)
      --- then
      assert.equal("a/b", actual)
    end)

    it("should concat two paths without separator in between", function()
      --- given
      local left, right = "a", "b"
      --- when
      local actual = path.concat(left, right)
      --- then
      assert.equal("a/b", actual)
    end)
  end)

  describe("is_dir", function()
    it("should return true if given path is dir", function()
      --- given
      local p = vim.loop.os_homedir()
      --- when
      local actual = path.is_dir(p)
      --- then
      assert.is_true(actual)
    end)
  end)

  describe("remove_parent", function()
    it("should remove parent from a path", function()
      --- given
      local p = "/a/b/c/d"
      --- when
      local actual = path.remove_parent(p, "/a/b/")
      --- then
      assert.equal("c/d", actual)
    end)
    it("should remove parent from a path without ending with sep", function()
      --- given
      local p = "/a/b/c/d"
      --- when
      local actual = path.remove_parent(p, "/a/b")
      --- then
      assert.equal("c/d", actual)
    end)
  end)

  describe("remove_gpg_ext", function()
    it("should remove gpg extension", function()
      --- given
      local str = "some.gpg"
      --- when
      local actual = path.remove_gpg_ext(str)
      --- then
      assert.equal("some", actual)
    end)
  end)
end)
