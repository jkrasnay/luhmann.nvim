local ok, curl = pcall(require, "plenary.curl")
if not ok then
  error("luhmann.nvim requires plenary.nvim. Please load the plenary.nvim plugin in your config.")
end

local M = {}

------------------------------------------------------------
-- State and setup function
--

-- Don't check up front, since Luhmann might not be running when vim starts
M._luhmann_url = nil

-- Config loaded from the configured Luhmann instance and cached here
-- Cleared by setup()
M._config = nil

M.setup = function(options)
  -- TODO error message if luhmann_url is not provided
  if not options.luhmann_url then
    error("Please configure `luhmann_url` to point to your Luhmann installation.")
  end
  M._luhmann_url = options.luhmann_url
  M._config = nil
end


------------------------------------------------------------
--
-- Utility functions

-- http_get
--
-- Performs an HTTP GET function call, returning the body.
-- Accepts a table of options as per plenary.curl (https://github.com/nvim-lua/plenary.nvim/blob/master/lua/plenary/curl.lua)
-- except also accepts "uri", which is appended to the Luhmann
-- URL to for the full URL.
--
-- The body is assumed to be JSON and decoded to a table.
local http_get = function(opts)

  if opts.uri then
    opts.url = M._luhmann_url .. opts.uri
  end

  if not M._luhmann_url then
    error("Luhmann not set up. Please call setup with a correct base URL to the Luhmann instance.")
  end

  local ok, resp = pcall(curl.get, opts)

  if not ok then
    error("Unable to call Luhmann at "..M._luhmann_url..". Is it running?")
  end

  if resp.status ~= 200 then
    error("GET "..opts.url.." failed with status "..resp.status)
  end

  return vim.fn.json_decode(resp.body)

end

local load_config = function()
  if not M._config then
    M._config = http_get({uri="/api/config"})
  end
  return M._config
end


------------------------------------------------------------
-- Implementation
--

function M.index_file()
  local config = load_config()
  return config["root-dir"].."/index.adoc"
end


function M.search(q)
  local results = http_get({uri="/api/search",query={q=q}})
  local qflist = {}
  local root_dir = load_config()["root-dir"]
  for _, result in ipairs(results) do
    table.insert(qflist, {filename=root_dir.."/"..string.gsub(result.path, "html$", "adoc"), lnum=1, text=result.title})
  end
  vim.fn.setqflist(qflist)
  vim.api.nvim_command("copen")
end

return M
