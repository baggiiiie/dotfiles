if true then
  return {}
end
return {
  "coffebar/transfer.nvim",
  lazy = true,
  cmd = { "TransferInit", "DiffRemote", "TransferUpload", "TransferDownload", "TransferDirDiff", "TransferRepeat" },
  opts = {},
}
