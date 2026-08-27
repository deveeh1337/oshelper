local M = {}

function M.start()
    -- All modules are loaded by the top-level OSHelper.lua before main() runs.
    -- This function is intentionally small: it only delegates to the actual
    -- entry-point defined in core.main.
    if type(_G.OSHelperMain) == 'function' then
        return _G.OSHelperMain()
    end
    error('OS Helper bootstrap: main entry is missing')
end

return M
