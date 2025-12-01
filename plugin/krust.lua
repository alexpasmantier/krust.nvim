local krust = require("krust")
krust.setup()

vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function(args)
    local config = krust.get_config()

    vim.api.nvim_buf_create_user_command(args.buf, "Krust", function()
      krust.render()
    end, { desc = "Render rust-analyzer diagnostic on current line" })

    if config.keymap and config.keymap ~= false then
      vim.keymap.set("n", config.keymap, "<cmd>Krust<cr>", {
        buffer = args.buf,
        desc = "Show rust diagnostic",
        silent = true,
      })
    end
  end,
})
