return {
  "zk-org/zk-nvim",
  config = function()
    require("zk").setup()
  end,
  keys = {
    {
      "<leader>zn",
      "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>",
      desc = "zk new note",
    },
    {
      "<leader>zo",
      "<Cmd>ZkNotes { sort = { 'modified' } }<CR>",
      desc = "zk open notes",
    },
    {
      "<leader>zt",
      "<Cmd>ZkTags<CR>",
      desc = "zk find tags",
    },
    {
      "<leader>zf",
      "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>",
      desc = "zk find match with title",
    },
    {
      "<leader>zb",
      "<Cmd>ZkBuffers",
      desc = "zk buffer",
    },
    {
      "<leader>zv",
      ":'<,'>ZkMatch<CR>",
      desc = "zk find match under selection",
      mode = { "v" },
    },
    {
      "<leader>zi",
      ":ZkInsertLink<CR>",
      desc = "zk insert link",
      mode = { "n" },
    },
    {
      "<leader>zi",
      ":'<,'>ZkInsertLinkAtSelection<CR>",
      desc = "zk insert link under selection",
      mode = { "v" },
    },
  },
}
