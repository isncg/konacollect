local io = require "io"
local cjson = require "cjson"

local task_list = require "task_list"
local page_generator = require "page_generator"

local M = {}

function M.create_build_task_list()
    local build_task_list = {}
    for _, categoary in ipairs(task_list) do
        for _, task in ipairs(categoary.build_list) do
            build_task_list[#build_task_list + 1] = { task = task, categoary = categoary }
        end
    end
    return build_task_list
end

function M.get_task_count()
    local count = 0
    for _, categoary in ipairs(task_list) do
        count = count + #categoary.build_list
    end
    return count
end

function M.get_task_and_categoary_by_index(index)
    local count = M.get_task_count()
    if index > count then
        index = (index - 1) % count + 1
    end
    for _, categoary in ipairs(task_list) do
        local build_list_size = #categoary.build_list
        if index <= build_list_size then
            return categoary.build_list[index], categoary
        else
            index = index - build_list_size
        end
    end
end

function M.get_task_input_data(task)
    if task.__input_data then
        return task.__input_data
    end
    local input_path = "../.data/posts/" .. task.input
    print("load " .. input_path)
    local file = io.open(input_path, "r")
    if not file then
        print("file not found: " .. input_path)
        return nil
    end
    local json_data = file:read("*a")
    local input_data = cjson.decode(json_data)
    task.__input_data = input_data
    return input_data
end

function M.build_task(task, categoary)
    local input_path = "../.data/posts/" .. task.input
    local input_data = M.get_task_input_data(task)
    if not input_data then
        return
    end
    local output_path
    local doc_root = "../"
    local categoary_output_dir = categoary.output_dir
    if categoary_output_dir then
        output_path = "../" .. categoary_output_dir .. "/" .. task.output
    else
        output_path = "../" .. task.output
        doc_root = "./"
    end
    local result, error = page_generator.generate_post_list(input_data, doc_root, "post_list")
    if error then
        print(error)
    else
        print(input_path .. " -> " .. output_path)
        io.open(output_path, "w"):write(tostring(result))
    end
end

function M.build_one_task(build_index)
    local build_task, categoary = M.get_task_and_categoary_by_index(build_index)
    M.build_task(build_task, categoary)
end

function M.build_categoary_index(categoary)
    local output_dir = categoary.output_dir
    if output_dir then
        local item_list = {}
        for _, task in ipairs(categoary.build_list) do
            local item = {}
            item_list[#item_list + 1] = item
            item.title = task.title
            local post_list = {}
            item.post_list = post_list
            local input_data = M.get_task_input_data(task)
            if input_data then
                for i = 1, 3 do
                    post_list[#post_list + 1] = input_data[i]
                end
            end
        end
        local result, error = page_generator.generate_categoary_index(item_list)
        if error then
            print(error)
        else
            local output_path = "../" .. categoary.output_dir .. "/index.html"
            print(categoary.title .. " -> " .. output_path)
            io.open(output_path, "w"):write(tostring(result))
        end
    end
end

function M.build_all()
    for _, categoary in ipairs(task_list) do
        for _, task in ipairs(categoary.build_list) do
            M.build_task(task, categoary)
        end
        M.build_categoary_index(categoary)
    end
end

return M
