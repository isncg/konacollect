local lfs = require "lfs"
local io = require "io"
local M = {}

-- 确保目录存在，如果不存在则递归创建
function M.ensure_dir(dir)
    if dir == "" or dir == "." then return true end
    local ok, err = lfs.attributes(dir)
    if ok then return true end             -- 目录已存在
    -- 逐级创建父目录
    local parent = dir:match("^(.*)[/\\]") -- 提取父目录（兼容 Windows/Unix）
    if parent then
        M.ensure_dir(parent)
    end
    return lfs.mkdir(dir)
end

function M.copy_file(src, dst)
    -- 确保目标目录存在
    local dst_dir = dst:match("^(.*)[/\\]")
    if dst_dir then
        M.ensure_dir(dst_dir)
    end
    local src_file = io.open(src, "rb")
    if not src_file then return false, "无法打开源文件" end
    local dst_file = io.open(dst, "wb")
    if not dst_file then
        src_file:close()
        return false, "无法创建目标文件"
    end
    local data = src_file:read("*all")
    dst_file:write(data)
    src_file:close()
    dst_file:close()
    return true
end

function M.read(path)
    local file = io.open(path, "r")
    if not file then return nil end
    return file:read("*a")
end

function M.write(path, data)
    local dst_dir = path:match("^(.*)[/\\]")
    if dst_dir then
        M.ensure_dir(dst_dir)
    end
    io.open(path, "w"):write(data)
end

return M
