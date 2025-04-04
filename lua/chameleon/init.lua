local M = {}
local fn = vim.fn
local api = vim.api
M.original_bg_color = nil
M.inactive_tab_foreground = nil
M.active_tab_background = nil

local function executeKittyCmd(cmd)
  fn.jobstart(cmd, {
    on_stderr = function(_, d, _)
      if #d > 1 then
        vim.notify(
          "Chameleon.nvim: Error changing background. Make sure kitty remote control is turned on.",
          vim.log.levels.WARN
        )
      end
    end,
  })
end

local get_kitty_original_colors = function()
  if M.original_bg_color == nil then
    fn.jobstart({ "kitty", "@", "get-colors" }, {
      on_stdout = function(_, d, _)
        for _, result in ipairs(d) do
          if string.match(result, "^background") then
            local color = vim.split(result, "%s+")[2]
            M.original_bg_color = color
          elseif string.match(result, "^inactive_tab_foreground") then
            local color = vim.split(result, "%s+")[2]
            M.inactive_tab_foreground = color
          elseif string.match(result, "^active_tab_background") then
            local color = vim.split(result, "%s+")[2]
            M.active_tab_background = color
          end
        end
      end,
      on_stderr = function(_, d, _)
        if #d > 1 then
          vim.notify(
            "Chameleon.nvim: Error getting background. Make sure kitty remote control is turned on.",
            vim.log.levels.WARN
          )
        end
      end,
    })
  end
end

local change_background = function(color, sync)
  local arg = 'background="' .. color .. '"'
  local command = "kitty @ set-colors --match=recent:0 " .. arg
  if not sync then
    fn.jobstart(command, {
      on_stderr = function(_, d, _)
        if #d > 1 then
          vim.notify(
            "Chameleon.nvim: Error changing background. Make sure kitty remote control is turned on.",
            vim.log.levels.WARN
          )
        end
      end,
    })
  else
    fn.system(command)
  end
end

local change_foreground = function(color, sync, opts)
  if not opts then
    opts = { inactive_tab_foreground = true, active_tab_background = true }
  end

  local set_inactive_fg = 'inactive_tab_foreground="' .. color .. '"'
  local set_active_bg = 'active_tab_background="' .. color .. '"'
  local command = "kitty @ set-colors --match=recent:0"

  if opts.inactive_tab_foreground then
    command = command .. " " .. set_inactive_fg
  end
  if opts.active_tab_background then
    command = command .. " " .. set_active_bg
  end

  if not sync then
    executeKittyCmd(command)
  else
    fn.system(command)
  end
end

local function restore_original_colors()
  if M.original_bg_color ~= nil then
    change_background(M.original_bg_color, true)
  end

  if M.inactive_tab_foreground ~= nil then
    change_foreground(M.inactive_tab_foreground, true, { inactive_tab_foreground = true })
  end

  if M.active_tab_background ~= nil then
    change_foreground(M.active_tab_background, true, { active_tab_background = true })
  end
end


local setup_autocmds = function()
  local autocmd = api.nvim_create_autocmd
  local autogroup = api.nvim_create_augroup
  local bg_change = autogroup("BackgroundChange", { clear = true })

  autocmd({ "ColorScheme", "VimResume", "VimEnter" }, {
    pattern = "*",
    callback = function()
      local bg_color = string.format("#%06X", vim.api.nvim_get_hl(0, { name = "Normal" }).bg)
      local fg_color = string.format("#%06X", vim.api.nvim_get_hl(0, { name = "Normal" }).fg)



      change_background(bg_color)
      change_foreground(fg_color)
    end,
    group = bg_change,
  })

  autocmd("User", {
    pattern = "NvChadThemeReload",
    callback = function()
      local bg_color = string.format("#%06X", vim.api.nvim_get_hl(0, { name = "Normal" }).bg)
      local fg_color = string.format("#%06X", vim.api.nvim_get_hl(0, { name = "Normal" }).fg)

      change_background(bg_color)
      change_foreground(fg_color)
    end,
    group = bg_change,
  })

  autocmd({ "VimLeavePre", "VimSuspend" }, {
    callback = function()
      restore_original_colors()
      -- Looks like it was silently fixed in NVIM 0.10. At least, I can't reproduce it anymore,
      -- so for now disable it and see if anyone reports it again.
      -- https://github.com/neovim/neovim/issues/21856
      -- vim.cmd[[sleep 10m]]
    end,
    group = autogroup("BackgroundRestore", { clear = true }),
  })
end

M.setup = function()
  if (os.getenv("KITTY_PID") ~= nil) then
    get_kitty_original_colors()
    setup_autocmds()
  else
    vim.notify(
      "Chameleon.nvim: you are not on a kitty terminal, background won't be changed",
      vim.log.levels.WARN
    )
  end
end

require("chameleon.register")
require("chameleon.kitty")
return M
