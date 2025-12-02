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

  describe("parse_ansi_codes", function()
    it("handles text without ANSI codes", function()
      local text = "plain text"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(1, #segments)
      assert.equals("plain text", segments[1].text)
      assert.is_nil(segments[1].hl_group)
    end)

    it("parses basic foreground color (red)", function()
      local text = "\27[31mred text\27[0m"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(1, #segments)
      assert.equals("red text", segments[1].text)
      assert.equals("KrustAnsiFg31", segments[1].hl_group)
    end)

    it("parses bold text", function()
      local text = "\27[1mbold text\27[0m"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(1, #segments)
      assert.equals("bold text", segments[1].text)
      assert.equals("KrustAnsiBold", segments[1].hl_group)
    end)

    it("parses bold + color combined", function()
      local text = "\27[1;31mbold red\27[0m"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(1, #segments)
      assert.equals("bold red", segments[1].text)
      assert.equals("KrustAnsiFg31Bold", segments[1].hl_group)
    end)

    it("parses 256-color format (bright red)", function()
      local text = "\27[38;5;9mred text\27[0m"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(1, #segments)
      assert.equals("red text", segments[1].text)
      assert.equals("KrustAnsiFg91", segments[1].hl_group) -- Color 9 maps to ANSI 91
    end)

    it("parses 256-color format (bright blue)", function()
      local text = "\27[38;5;12mblue text\27[0m"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(1, #segments)
      assert.equals("blue text", segments[1].text)
      assert.equals("KrustAnsiFg94", segments[1].hl_group) -- Color 12 maps to ANSI 94
    end)

    it("parses bold + 256-color format", function()
      local text = "\27[1m\27[38;5;9merror\27[0m"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(1, #segments)
      assert.equals("error", segments[1].text)
      assert.equals("KrustAnsiFg91Bold", segments[1].hl_group)
    end)

    it("handles reset codes", function()
      local text = "\27[31mred\27[0mnormal\27[32mgreen\27[0m"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(3, #segments)
      assert.equals("red", segments[1].text)
      assert.equals("KrustAnsiFg31", segments[1].hl_group)
      assert.equals("normal", segments[2].text)
      assert.is_nil(segments[2].hl_group)
      assert.equals("green", segments[3].text)
      assert.equals("KrustAnsiFg32", segments[3].hl_group)
    end)

    it("parses rust-analyzer style diagnostic", function()
      local text = "\27[0m\27[1m\27[38;5;9merror[E0004]\27[0m\27[0m\27[1m: non-exhaustive patterns\27[0m"
      local segments = utils.parse_ansi_codes(text)

      -- Should have segments for "error[E0004]" (bold red) and ": non-exhaustive patterns" (bold)
      local found_error = false
      local found_message = false

      for _, seg in ipairs(segments) do
        if seg.text:match("error%[E0004%]") then
          assert.equals("KrustAnsiFg91Bold", seg.hl_group)
          found_error = true
        elseif seg.text:match(": non%-exhaustive patterns") then
          assert.equals("KrustAnsiBold", seg.hl_group)
          found_message = true
        end
      end

      assert.is_true(found_error)
      assert.is_true(found_message)
    end)

    it("handles text with newlines", function()
      local text = "\27[31mline1\nline2\27[0m"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(1, #segments)
      assert.equals("line1\nline2", segments[1].text)
      assert.equals("KrustAnsiFg31", segments[1].hl_group)
    end)

    it("handles multiple colors on same line", function()
      local text = "\27[31mred\27[0m \27[32mgreen\27[0m \27[34mblue\27[0m"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(5, #segments)
      assert.equals("red", segments[1].text)
      assert.equals("KrustAnsiFg31", segments[1].hl_group)
      assert.equals(" ", segments[2].text)
      assert.is_nil(segments[2].hl_group)
      assert.equals("green", segments[3].text)
      assert.equals("KrustAnsiFg32", segments[3].hl_group)
      assert.equals(" ", segments[4].text)
      assert.is_nil(segments[4].hl_group)
      assert.equals("blue", segments[5].text)
      assert.equals("KrustAnsiFg34", segments[5].hl_group)
    end)

    it("handles bold disable (code 22)", function()
      local text = "\27[1mbold\27[22mnormal\27[0m"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(2, #segments)
      assert.equals("bold", segments[1].text)
      assert.equals("KrustAnsiBold", segments[1].hl_group)
      assert.equals("normal", segments[2].text)
      assert.is_nil(segments[2].hl_group)
    end)

    it("handles empty string", function()
      local segments = utils.parse_ansi_codes("")
      assert.equals(0, #segments)
    end)

    it("handles empty ANSI sequence", function()
      local text = "\27[mtext\27[0m"
      local segments = utils.parse_ansi_codes(text)
      assert.equals(1, #segments)
      assert.equals("text", segments[1].text)
      assert.is_nil(segments[1].hl_group)
    end)

    it("ignores 256-color indices outside 0-15 range", function()
      local text = "\27[38;5;200mhigh color\27[0m"
      local segments = utils.parse_ansi_codes(text)
      -- Color 200 is outside our supported range, should be ignored
      assert.equals(1, #segments)
      assert.equals("high color", segments[1].text)
      assert.is_nil(segments[1].hl_group) -- No color should be applied
    end)

    it("handles background colors (code 48) gracefully", function()
      local text = "\27[48;5;1mbg color\27[0m"
      local segments = utils.parse_ansi_codes(text)
      -- We don't support background colors, but shouldn't crash
      assert.equals(1, #segments)
      assert.equals("bg color", segments[1].text)
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
