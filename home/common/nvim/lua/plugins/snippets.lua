return {
  -- Add custom snippets
  {
    "L3MON4D3/LuaSnip",
    opts = function()
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node
      local f = ls.function_node

      ls.add_snippets("all", {
        s("clo", {
          t('console.log("'),
          i(1),
          t('", '),
          f(function(args) return args[1][1] end, {1}),
          t(");"),
        }),
      })
    end,
  },
}
