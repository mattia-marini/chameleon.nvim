function execute_kitty_cmd(cmd, success, fail)
  vim.system(cmd, {},
    function(rv)
      -- print(vim.inspect(rv))

      if rv.code == 0 then
        if success then
          success(rv.stdout)
        end
      else
        if fail then
          fail(rv)
        end
      end
    end)
end

function get_current_tab_windows()
  local t = { "kitty", "@", "ls", "--match-tab=recent:0" }

  function on_success(stdout)
    local json = vim.json.decode(stdout)
    local current_tab_id = json[1].tabs[1].id
    local windows = {}

    for _, window in ipairs(json[1].tabs[1].windows) do
      table.insert(windows, window.id)
    end

    -- print("povco dio")
    print(vim.inspect({ [current_tab_id] = windows }))
  end

  function on_fail(rv)
    print("ERROR")
    print(vim.inspect(rv))
  end

  execute_kitty_cmd(t, on_success, on_fail)
end
