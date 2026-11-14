-- Markdown 终端实时渲染
-- https://yelog.org/2024/08/02/write-markdown-in-neovim-experience-and-tips/
return {
  {
    "yelog/marklive.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    lazy = true,
    ft = "markdown",
  },
}
