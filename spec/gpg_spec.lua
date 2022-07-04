---@diagnostic disable: unused-local

local gpg = require "omen.gpg"

local Job = require "plenary.job"

local mock = require "luassert.mock"
local stub = require "luassert.stub"
local spy = require "luassert.spy"
local match = require "luassert.match"

describe("gpg", function()

  describe("decrypt", function()

    it("should decrypt given entry via gpg", function()
      mock(Job, true)
      Job.new.returns(Job)

      Job.sync.returns(nil)
      Job.stderr_result.returns {}
      Job.result.returns { "some-decrypted" }

      --- when
      local actual_decrypted, actual_err = gpg.decrypt("some-entry-name", "some-passphrase")

      --- then
      assert.stub(Job.new).was.called_with(Job, {
        command = "gpg",
        args = {
          "--batch",
          "--yes",
          "--passphrase-fd",
          "0",
          "--pinentry-mode",
          "loopback",
          "--decrypt",
          "some-entry-name",
        },
        writer = "some-passphrase",
      })
      assert.stub(Job.sync).was.called()
      assert.stub(Job.stderr_result).was.called()
      assert.stub(Job.result).was.called()
      assert.is_nil(actual_err)
      assert.equals("some-decrypted", actual_decrypted)
    end)

    it("should return an error when wrong passphrase given", function()
      mock(Job, true)
      Job.new.returns(Job)

      Job.sync.returns(nil)
      Job.stderr_result.returns { "Bad passphrase" }

      --- when
      local actual_decrypted, actual_err = gpg.decrypt("some-entry-name", "some-passphrase")

      --- then
      assert.stub(Job.new).was.called_with(Job, {
        command = "gpg",
        args = {
          "--batch",
          "--yes",
          "--passphrase-fd",
          "0",
          "--pinentry-mode",
          "loopback",
          "--decrypt",
          "some-entry-name",
        },
        writer = "some-passphrase",
      })
      assert.stub(Job.sync).was.called()
      assert.stub(Job.stderr_result).was.called()
      assert.equals("Bad passphrase", actual_err)
    end)

    it("should return an error when there are no stdout from gpg", function()
      mock(Job, true)
      Job.new.returns(Job)

      Job.sync.returns(nil)
      Job.stderr_result.returns {}
      Job.result.returns {}

      --- when
      local actual_decrypted, actual_err = gpg.decrypt("some-entry-name", "some-passphrase")

      --- then
      assert.stub(Job.new).was.called_with(Job, {
        command = "gpg",
        args = {
          "--batch",
          "--yes",
          "--passphrase-fd",
          "0",
          "--pinentry-mode",
          "loopback",
          "--decrypt",
          "some-entry-name",
        },
        writer = "some-passphrase",
      })
      assert.stub(Job.sync).was.called()
      assert.stub(Job.stderr_result).was.called()
      assert.equals("GPG process returns empty", actual_err)
    end)
  end)
end)
