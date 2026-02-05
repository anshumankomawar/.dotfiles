return {
  cmd = { 'zls' },
  filetypes = { 'zig', 'zir' },
  root_markers = { 'zls.json', 'build.zig', '.git' },
  capabilities = vim.lsp.protocol.make_client_capabilities(),
  settings = {
    zls = {
      enable_build_on_save = false,
      semantic_tokens = "partial",
    }
  },
  workspace_required = false,
}
