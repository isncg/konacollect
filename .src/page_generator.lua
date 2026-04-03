local io = require "io"
local aspect_template = require "aspect.template"
local aspect = aspect_template.new()

aspect.loader = function(name)
    local file_path = "../.templates/" .. name .. ".html"
    local file = io.open(file_path, "r")
    if not file then
        print("file not found: " .. file_path)
        return nil
    end
    return file:read("*a")
end

local M = {}

M.generate_post_list = function(post_list, doc_root, title, subtitle, permalinks)
    local post_row_list = {}
    local row_index = 0
    for i = 1, #post_list do
        if (i - 1) % 4 == 0 then
            row_index = row_index + 1
        end
        local post_row = post_row_list[row_index]
        if post_row == nil then
            post_row = {}
            post_row_list[row_index] = post_row
        end
        local post = post_list[i]
        post.list_index = i
        post_row[#post_row + 1] = post
    end

    return aspect:render("post_list",
        {
            line_list = post_row_list,
            doc_root = doc_root,
            title = title,
            subtitle = subtitle,
            permalinks = permalinks
        })
end

function M.generate_subscribe_index(item_list, doc_root, title, subtitle, permalinks)
    return aspect:render("categoary_index",
        {
            item_list = item_list,
            doc_root = doc_root,
            title = title,
            subtitle = subtitle,
            permalinks = permalinks
        })
end

return M
