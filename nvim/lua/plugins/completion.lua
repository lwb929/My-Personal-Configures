-- 补全键位（VSCode 风格）
--   <Tab>   有补全菜单时接受当前项；否则在 snippet 里跳到下一个占位符；再否则走原生 Tab
--   <CR>    不再接受补全，只换行（LazyVim 默认 preset "enter" 会用回车补全）
-- 注意：<S-Tab> 只在 snippet 里回跳，无菜单时不会反缩进（反缩进用 <C-d>）
return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "super-tab",
        ["<Tab>"] = {
          -- 与 upstream super-tab 一致：snippet 激活时 accept，否则接受当前选中项
          function(cmp)
            if cmp.snippet_active() then
              return cmp.accept()
            end
            return cmp.select_and_accept()
          end,
          "snippet_forward",
          "fallback",
        },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        ["<CR>"] = { "fallback" },
      },
    },
  },
}
