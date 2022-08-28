local M = {}
local StatusLine = require("heirline.statusline")
local utils = require("heirline.utils")

function M.reset_highlights()
    return require("heirline.highlights").reset_highlights()
end

function M.get_highlights()
    return require("heirline.highlights").get_highlights()
end

---Load color aliases
---@param colors table<string, string|integer>
---@return nil
function M.load_colors(colors)
    return require("heirline.highlights").load_colors(colors)
end

function M.clear_colors()
    return require("heirline.highlights").clear_colors()
end

local function setup_local_winbar_with_autocmd()
    local augrp_id = vim.api.nvim_create_augroup("Heirline_init_winbar", { clear = true })
    vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter" }, {
        callback = function()
            if vim.api.nvim_win_get_height(0) > 1 then
                vim.opt_local.winbar = "%{%v:lua.require'heirline'.eval_winbar()%}"
                vim.api.nvim_exec_autocmds("User", { pattern = "HeirlineInitWinbar", modeline = false })
            end
        end,
        group = augrp_id,
        desc = "Heirline: set window-local winbar",
    })
end

---Setup statusline and winbar
---@param statusline table
---@param winbar? table
function M.setup(statusline, winbar, tabline)
    vim.g.qf_disable_statusline = true
    vim.api.nvim_create_augroup("Heirline_update_autocmds", { clear = true })
    M.reset_highlights()

    M.statusline = StatusLine:new(statusline)
    vim.o.statusline = "%{%v:lua.require'heirline'.eval_statusline()%}"
    if winbar then
        M.winbar = StatusLine:new(winbar)
        setup_local_winbar_with_autocmd()
    end
    if tabline then
        M.tabline = StatusLine:new(tabline)
        vim.o.showtabline = 2
        vim.o.tabline = "%{%v:lua.require'heirline'.eval_tabline()%}"
    end
end

---@return string
function M.eval_statusline()
    M.statusline.winnr = vim.api.nvim_win_get_number(0)
    M.statusline.flexible_components = {}
    local out = M.statusline:eval()
    utils.expand_or_contract_flexible_components(M.statusline, vim.o.laststatus == 3, out)
    return out
end

---@return string
function M.eval_winbar()
    M.winbar.winnr = vim.api.nvim_win_get_number(0)
    M.winbar.flexible_components = {}
    local out = M.winbar:eval()
    utils.expand_or_contract_flexible_components(M.winbar, false, out)
    return out
end

---@return string
function M.eval_tabline()
    M.tabline.winnr = 1
    M.tabline._buflist = {}
    M.tabline._eval_buflist = false
    local out = M.tabline:eval()
    if vim.tbl_isempty(M.tabline._buflist) then
        return out
    end
    -- utils.expand_or_contract_flexible_components(M.tabline, true, out)
    M.tabline._maxwidth = vim.o.columns - utils.count_chars(out) + string.len("#BUFLIST#")
    M.tabline._eval_buflist = true
    M.tabline._buflist[1]:eval()
    return vim.fn.substitute(out, "#BUFLIST#", M.tabline._buflist[1].stl, "")
end

-- test [[
function M.timeit()
    local start = os.clock()
    M.eval_statusline()
    M.eval_winbar()
    M.eval_tabline()
    return os.clock() - start
end

--]]

return M
