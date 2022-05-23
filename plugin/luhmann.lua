if 1 ~= vim.fn.has "nvim-0.7.0" then
  vim.api.nvim_err_writeln "luhmann.nvim requires at least nvim-0.7.0."
  return
end

if vim.g.loaded_luhmann == 1 then
  return
end
vim.g.loaded_luhmann = 1

vim.api.nvim_create_user_command("LuhOpenIndex", function() vim.api.nvim_command("e "..require("luhmann").index_file()) end, {})
