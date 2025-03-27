# 🍿 `stregsystem-snacks`
[Snacks](https://github.com/folke/snacks.nvim) picker for [F-Klubbens StregSystem](https://github.com/f-klubben/stregsystemet)

![demo](assets/demo.gif)
## Requirements
- [Snacks](https://github.com/folke/snacks.nvim)
- [curl](https://curl.se/)
- [nvim.notify](https://github.com/rcarriga/nvim-notify)

## Installation
Via [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  {
    keys = {
      {
        "<leader>-",
        function()
          require("stregsystem").stregsystem()
        end,
      },
    },
    "madsludvig/stregsystem-snacks",
    config = function()
      require("stregsystem").setup({
        endpoint = "https://stregsystem.fklub.dk/api/",
        username = "INSERT_USERNAME_HERE",
      })
    end,
    dependencies = {
      {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
          picker = { enabled = true },
        },
      },
    },
  },
}
```

## Disclaimer
It is important to be aware that this plugin is not officially approved by F-Klubben, and therefore it is used at your own risk. 
I disclaim any responsibility for mistaken purchases or unintended actions that may arise from the use of this plugin.

