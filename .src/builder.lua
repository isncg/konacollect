local file_utils = require "file_utils"
local cjson = require "cjson"

local task_list = require "task_list"
local page_generator = require "page_generator"
local http_request = require "http_request"

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
            return categoary.build_list[index], categoary, index, count
        else
            index = index - build_list_size
        end
    end
end

function M.get_task_input_cache_data(task, rating)
    local cache_dict = task.__input_cache_dict
    if cache_dict then
        return cache_dict[rating]
    end
end

function M.set_task_input_cache_data(task, rating, data)
    local cache_dict = task.__input_cache_dict
    if not cache_dict then
        cache_dict = {}
        task.__input_cache_dict = cache_dict
    end
    cache_dict[rating] = data
end

function M.get_task_input_data(task, rating)
    local cached_data = M.get_task_input_cache_data(task, rating)
    if cached_data then
        return cached_data
    end
    local input_path = "../.data/posts/" .. task.file .. "_" .. rating .. ".json"
    local json_data = file_utils.read(input_path)
    local input_data = cjson.decode(json_data)
    M.set_task_input_cache_data(task, rating, input_data)
    return input_data
end

function M.build_task_with_rating(task, categoary, rating)
    if not rating then
        rating = "s"
    end
    local input_path = "../.data/posts/" .. task.file .. "_" .. rating .. ".json"

    if not M.disable_http_request then
        http_request.request_post(rating, task.request_tags, input_path)
    end

    if not M.disable_page_generation then
        local input_data = M.get_task_input_data(task, rating)
        if not input_data then
            return
        end
        local output_path
        local doc_root = "../"
        local categoary_output_dir = categoary.output_dir
        if categoary_output_dir then
            if rating == "s" then
                output_path = "../" .. categoary_output_dir .. "/" .. task.file .. ".html"
                doc_root = "../"
            else
                output_path = "../" .. categoary_output_dir .. "/" .. rating .. "/" .. task.file .. ".html"
                doc_root = "../../"
            end
        else
            if rating == "s" then
                output_path = "../" .. task.file .. ".html"
                doc_root = "./"
            else
                output_path = "../" .. rating .. "/" .. task.file .. ".html"
                doc_root = "../"
            end
        end
        local result, error = page_generator.generate_post_list(input_data, doc_root, "post_list")
        if error then
            print(error)
        else
            print(input_path .. " -> " .. output_path)
            -- print(result)
            file_utils.write(output_path, tostring(result))
        end
    end
end

function M.build_one_task(build_index)
    local time = os.time()
    if not build_index then
        build_index = time // 300
    end
    local build_task, categoary, real_index, task_count = M.get_task_and_categoary_by_index(build_index)
    print("build_one_task: ", build_index, real_index, time, task_count)
    M.build_task_with_rating(build_task, categoary, "s")
    M.build_task_with_rating(build_task, categoary, "q")
    M.build_task_with_rating(build_task, categoary, "e")
    M.build_categoary_index(categoary, "s")
    M.build_categoary_index(categoary, "q")
    M.build_categoary_index(categoary, "e")
end

function M.build_categoary_index(categoary, rating)
    if not rating then
        rating = "s"
    end
    local output_dir = categoary.output_dir
    if output_dir then
        local item_list = {}
        for _, task in ipairs(categoary.build_list) do
            local item = {}
            item_list[#item_list + 1] = item
            item.title = task.title
            local post_list = {}
            item.post_list = post_list
            local input_data = M.get_task_input_data(task, rating)
            if input_data then
                for i = 1, 4 do
                    post_list[#post_list + 1] = input_data[i]
                end
            end
        end
        local output_path
        local doc_root
        if rating == "s" then
            output_path = "../" .. categoary.output_dir .. "/index.html"
            doc_root = "../"
        else
            output_path = "../" .. categoary.output_dir .. "/" .. rating .. "/index.html"
            doc_root = "../../"
        end
        local result, error = page_generator.generate_categoary_index(item_list, doc_root)
        if error then
            print(error)
        else
            print(categoary.title .. " -> " .. output_path)
            file_utils.write(output_path, tostring(result))
            -- io.open(output_path, "w"):write(tostring(result))
        end
    end
end

function M.build_all()
    for _, categoary in ipairs(task_list) do
        for _, task in ipairs(categoary.build_list) do
            M.build_task_with_rating(task, categoary, "s")
            M.build_task_with_rating(task, categoary, "q")
            M.build_task_with_rating(task, categoary, "e")
        end
        M.build_categoary_index(categoary, "s")
        M.build_categoary_index(categoary, "q")
        M.build_categoary_index(categoary, "e")
    end
end

return M
