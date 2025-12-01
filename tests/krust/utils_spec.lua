local utils = require("krust.utils")

describe("krust.utils", function()
  describe("strip_ansi_codes", function()
    it("removes CSI sequences", function()
      local text = "\27[31mred text\27[0m"
      local result = utils.strip_ansi_codes(text)
      assert.equals("red text", result)
    end)

    it("removes multiple CSI sequences", function()
      local text = "\27[1m\27[31mbold red\27[0m\27[32mgreen\27[0m"
      local result = utils.strip_ansi_codes(text)
      assert.equals("bold redgreen", result)
    end)

    it("removes OSC sequences", function()
      local text = "before\27]0;window title\27\\after"
      local result = utils.strip_ansi_codes(text)
      assert.equals("beforeafter", result)
    end)

    it("removes character set sequences", function()
      local text = "test\27(Bmore\27)A"
      local result = utils.strip_ansi_codes(text)
      assert.equals("testmore", result)
    end)

    it("handles text without ANSI codes", function()
      local text = "plain text"
      local result = utils.strip_ansi_codes(text)
      assert.equals("plain text", result)
    end)

    it("handles empty string", function()
      local result = utils.strip_ansi_codes("")
      assert.equals("", result)
    end)

    it("removes complex rust-analyzer style ANSI", function()
      local text = "\27[0m\27[1m\27[38;5;9merror\27[0m\27[0m\27[1m: unused variable\27[0m"
      local result = utils.strip_ansi_codes(text)
      assert.equals("error: unused variable", result)
    end)
  end)

  describe("get_max_line_width", function()
    it("returns width for single line", function()
      local text = "hello world"
      local result = utils.get_max_line_width(text)
      assert.equals(11, result)
    end)

    it("returns max width across multiple lines", function()
      local text = "short\nlonger line\nok"
      local result = utils.get_max_line_width(text)
      assert.equals(11, result) -- "longer line"
    end)

    it("handles empty string", function()
      local result = utils.get_max_line_width("")
      assert.equals(0, result)
    end)

    it("handles single newline", function()
      local result = utils.get_max_line_width("\n")
      assert.equals(0, result)
    end)

    it("trims empty lines", function()
      local text = "first\n\n\nsecond"
      local result = utils.get_max_line_width(text)
      assert.equals(6, result) -- "second"
    end)

    it("handles unicode characters correctly", function()
      local text = "hello\n世界\némoji 🦀"
      local result = utils.get_max_line_width(text)
      -- "emoji 🦀" should be 8 (emoji takes 2 width, space is 1, letters are 5)
      assert.equals(8, result)
    end)

    it("works with text that had ANSI codes stripped", function()
      local text_with_ansi = "\27[31mred\27[0m\n\27[32mgreen text\27[0m"
      local stripped = utils.strip_ansi_codes(text_with_ansi)
      local result = utils.get_max_line_width(stripped)
      assert.equals(10, result) -- "green text"
    end)
  end)
end)
