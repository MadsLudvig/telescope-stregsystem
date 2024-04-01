<!-- TODO: Write introduction, installation guide, mp4 preview -->
# 🔭 Felescope
[Telescope](https://github.com/nvim-telescope/telescope.nvim) extension til [f-klubbens stregystem](https://github.com/f-klubben/stregsystemet)

![demo](assets/demo.gif)
## Krav
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [curl](https://curl.se/)
- [nvim.notify](https://github.com/rcarriga/nvim-notify)

## Minimal Telescope Konfiguration
Via [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "madsludvig/felescope",
        dependencies = {
          "rcarriga/nvim-notify",
        },
      },
    },
    cmd = { "Telescope" },
    keys = {
      vim.keymap.set("n", "<leader>-", "<cmd>Telescope stregsystem<CR>", { desc = "[-]StregSystem" }),
    },
    config = function()
      require("telescope").setup({
        extensions = {
          ["stregsystem"] = {
            username = "INDSÆT_STREGSYSTEM_BRUGERNAVN_HER",
          },
        },
      })
      pcall(require("telescope").load_extension, "stregsystem")
    end,
  },
}

```



