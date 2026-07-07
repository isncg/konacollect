local file_utils = require "file_utils"

local M = {}

M.cache_path = "../.data/cf_clearance.txt"

function M.load()
    local value = file_utils.read(M.cache_path)
    if not value or value == "" then
        return nil
    end
    return value:match("^%s*(.-)%s*$")
end

function M.save(value)
    file_utils.write(M.cache_path, tostring(value))
end

function M.is_available()
    local value = M.load()
    return value ~= nil
end

return M
