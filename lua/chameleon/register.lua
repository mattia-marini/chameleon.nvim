local dir = vim.fn.stdpath("cache") .. "/prova.json"

function write_cache()
  local json_decoded = read_json()
  json_decoded["new_id"] = "42"
end

function test()
  local json_decoded = read_json()
  json_decoded["new_id"] = "42"
  write_json(json_decoded)
end

function read_json()
  local json = vim.fn.readfile(dir)        -- Make sure to use absolute path
  local content = table.concat(json, "\n") -- Convert table to string
  local json_decoded = vim.json.decode(content)
  return json_decoded
end

function write_json(table)
  local json_encoded = vim.json.encode(table, { indent = 1 })
  vim.fn.writefile({ json_encoded }, dir)
end

-- saves the current nvim instance as
-- kitty_window_id = "path to socket"
function register()
  print(dir)

  local json = read_json()
end

function unregister()
end
