
# 🔭 Telescope-Stregsystem
[Telescope](https://github.com/nvim-telescope/telescope.nvim) extension for [F-Klubbens StregSystem](https://github.com/f-klubben/stregsystemet)

![demo](assets/demo.gif)
## Requirements
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [curl](https://curl.se/)
- [nvim.notify](https://github.com/rcarriga/nvim-notify)

## Minimal Telescope Configuration
Via [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      {
        "madsludvig/telescope-stregsystem",
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
            username = "INSERT_STREGSYSTEM_USERNAME_HERE",
          },
        },
      })
      pcall(require("telescope").load_extension, "stregsystem")
    end,
  },
}
```
## Disclaimer
It is important to be aware that this plugin is not officially approved by F-Klubben, and therefore it is used at your own risk. 
I disclaim any responsibility for mistaken purchases or unintended actions that may arise from the use of this plugin.
