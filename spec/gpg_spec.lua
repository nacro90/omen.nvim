---@diagnostic disable: unused-local

local gpg = require "omen.gpg"

local Job = require "plenary.job"

local mock = require "luassert.mock"
local stub = require "luassert.stub"
local spy = require "luassert.spy"
local match = require "luassert.match"

describe("gpg", function()
  describe("encrypt", function()
    it("should dispatch a gpg process to encrypt given password", function()
      mock(Job, true)
      Job.new.returns(Job)

      Job.sync.returns(nil)
      Job.stderr_result.returns {}

      --- when
      local actual_err = gpg.encrypt(
        "some-entry-name",
        "some-recipient",
        "some-pass-dir",
        "some-password"
      )

      --- then
      assert.stub(Job.new).was.called_with(Job, {
        command = "gpg",
        args = {
          "--encrypt",
          "--recipient",
          "some-recipient",
          "--output",
          "some-entry-name.gpg",
        },
        cwd = "some-pass-dir",
        writer = "some-password",
      })
      assert.stub(Job.sync).was.called()
      assert.stub(Job.stderr_result).was.called()
      assert.is_nil(actual_err)
    end)

    it("should return an error when gpg process has a stderr result", function()
      --- given
      mock(Job, true)
      Job.new.returns(Job)

      Job.sync.returns(nil)
      Job.stderr_result.returns { "some-err-1", "some-err-2" }

      --- when
      local actual_err = gpg.encrypt(
        "some-entry-name",
        "some-recipient",
        "some-pass-dir",
        "some-password"
      )

      --- then
      assert.stub(Job.new).was.called_with(Job, {
        command = "gpg",
        args = {
          "--encrypt",
          "--recipient",
          "some-recipient",
          "--output",
          "some-entry-name.gpg",
        },
        cwd = "some-pass-dir",
        writer = "some-password",
      })
      assert.stub(Job.sync).was.called()
      assert.stub(Job.stderr_result).was.called()
      assert.are.equals("some-err-1, some-err-2", actual_err)
    end)
  end)

  describe("decrypt", function()
    it("should decrypt given entry via gpg", function()
      mock(Job, true)
      Job.new.returns(Job)

      Job.sync.returns(nil)
      Job.stderr_result.returns {}
      Job.result.returns { "some-decrypted" }

      --- when
      local actual_decrypted, actual_err = gpg.decrypt(
        "some-entry-name",
        "some-pass-dir",
        "some-passphrase"
      )

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
          "some-entry-name.gpg",
        },
        cwd = "some-pass-dir",
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
      local actual_decrypted, actual_err = gpg.decrypt(
        "some-entry-name",
        "some-pass-dir",
        "some-passphrase"
      )

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
          "some-entry-name.gpg",
        },
        cwd = "some-pass-dir",
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
      local actual_decrypted, actual_err = gpg.decrypt(
        "some-entry-name",
        "some-pass-dir",
        "some-passphrase"
      )

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
          "some-entry-name.gpg",
        },
        cwd = "some-pass-dir",
        writer = "some-passphrase",
      })
      assert.stub(Job.sync).was.called()
      assert.stub(Job.stderr_result).was.called()
      assert.equals("Unknown error", actual_err)
    end)
  end)
end)
