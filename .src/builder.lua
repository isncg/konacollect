local file_utils = require "file_utils"
local cjson = require "cjson"

local task_list = require "task_list"
local page_generator = require "page_generator"
local http_request = require "http_request"
local lfs = require "lfs"

http_request.init_request_headers()

local function s_split(s, delimiter)
    local result = {}
    local from = 1
    local f, t = string.find(s, delimiter, from, true)
    while f do
        table.insert(result, string.sub(s, from, f - 1))
        from = t + 1
        f, t = string.find(s, delimiter, from, true)
    end
    table.insert(result, string.sub(s, from))
    return result
end

local M = {}

local TAG_TYPE = {
    GENERAL = 0,
    ARTIST = 1,
    COPYRIGHT = 3,
    CHARACTER = 4,
    STYLE = 5,
    CIRCLE = 6
}

function M.load_tags()
    -- read *.json form ../.data/tags directory
    local tag_dict = {}
    for file in lfs.dir("../.data/tags") do
        if file ~= "." and file ~= ".." then
            local path = "../.data/tags/" .. file
            local attr = lfs.attributes(path)
            if attr.mode == "file" then
                local json_data = file_utils.read(path)
                local tags = cjson.decode(json_data)
                for _, tag in ipairs(tags) do
                    tag_dict[tag.name] = tag
                end
            end
        end
    end
    M.tag_dict = tag_dict
end

function M.parse_tags(tag_str)
    local tag_names = s_split(tag_str, " ")
    local tag_type_dict = {}
    local tag_dict = M.tag_dict
    for _, tag_name in ipairs(tag_names) do
        local tag = tag_dict[tag_name]
        local tag_type = tag and tag.type or TAG_TYPE.GENERAL
        local tag_list = tag_type_dict[tag_type]
        if not tag_list then
            tag_list = {}
            tag_type_dict[tag_type] = tag_list
        end
        tag_list[#tag_list + 1] = tag_name
    end
    local artist = tag_type_dict[TAG_TYPE.ARTIST]
    local copyright = tag_type_dict[TAG_TYPE.COPYRIGHT]
    local character = tag_type_dict[TAG_TYPE.CHARACTER]
    local style = tag_type_dict[TAG_TYPE.STYLE]
    local circle = tag_type_dict[TAG_TYPE.CIRCLE]
    local general = tag_type_dict[TAG_TYPE.GENERAL]
    return {
        artist = artist and ("'" .. table.concat(artist, " ") .. "'") or "null",
        copyright = copyright and ("'" .. table.concat(copyright, " ") .. "'") or "null",
        character = character and ("'" .. table.concat(character, " ") .. "'") or "null",
        style = style and ("'" .. table.concat(style, " ") .. "'") or "null",
        circle = circle and ("'" .. table.concat(circle, " ") .. "'") or "null",
        general = general and ("'" .. table.concat(general, " ") .. "'") or "null",
    }
end

function M.convert_task(task)
    local one_tag = task.one_tag
    if one_tag then
        if not task.request_tags then
            task.request_tags = { one_tag }
        end
        if not task.title then
            local sp = s_split(one_tag, "_")
            for i, s in ipairs(sp) do
                sp[i] = string.gsub(s, "^%l", string.upper)
            end
            task.title = table.concat(sp, " ")
        end
        if not task.file then
            task.file = one_tag
        end
        task.one_tag = nil
    end
end

function M.create_build_task_list()
    local build_task_list = {}
    for _, categoary in ipairs(task_list) do
        for _, task in ipairs(categoary.build_list) do
            M.convert_task(task)
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
    M.convert_task(task)
    local cache_dict = task.__input_cache_dict
    if cache_dict then
        return cache_dict[rating]
    end
end

function M.set_task_input_cache_data(task, rating, data)
    M.convert_task(task)
    local cache_dict = task.__input_cache_dict
    if not cache_dict then
        cache_dict = {}
        task.__input_cache_dict = cache_dict
    end
    cache_dict[rating] = data
end

function M.get_task_input_data(task, rating)
    M.convert_task(task)
    local cached_data = M.get_task_input_cache_data(task, rating)
    if cached_data then
        return cached_data
    end
    local input_path = "../.data/posts/" .. task.file .. "_" .. rating .. ".json"
    local json_data = file_utils.read(input_path)
    local input_data = cjson.decode(json_data)
    for _, post in ipairs(input_data) do
        post.tag_dict = M.parse_tags(post.tags)
    end
    M.set_task_input_cache_data(task, rating, input_data)
    return input_data
end

function M.get_permalinks(rating, doc_root)
    if not rating then
        rating = "s"
    end
    local categoary_display_list_cache = M.categoary_display_list_cache
    if categoary_display_list_cache then
        local doc_root_dict = categoary_display_list_cache[rating]
        if doc_root_dict then
            local list = doc_root_dict[doc_root]
            if list then
                return list
            end
        end
    end
    local result = {}
    for _, categoary in ipairs(task_list) do
        local dir_list = {}
        local output_dir = categoary.output_dir
        if output_dir then
            dir_list[#dir_list + 1] = output_dir
        end
        if rating ~= "s" then
            dir_list[#dir_list + 1] = rating
        end
        dir_list[#dir_list + 1] = "index.html"
        result[#result + 1] = {
            title = categoary.title,
            href = doc_root .. table.concat(dir_list, "/"),
        }
    end
    if not categoary_display_list_cache then
        categoary_display_list_cache = {}
        M.categoary_display_list_cache = categoary_display_list_cache
        local doc_root_dict = categoary_display_list_cache[rating]
        if not doc_root_dict then
            doc_root_dict = {}
            categoary_display_list_cache[rating] = doc_root_dict
        end
        doc_root_dict[doc_root] = result
    end
    return result
end

function M.build_task_with_rating(task, categoary, rating)
    M.convert_task(task)
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
        local output_dir = categoary.output_dir
        local doc_root = output_dir and
            (rating == "s" and "../" or "../../") or
            (rating == "s" and "./" or "../")

        local dir_list = {}
        dir_list[#dir_list + 1] = output_dir
        if rating ~= "s" then
            dir_list[#dir_list + 1] = rating
        end
        dir_list[#dir_list + 1] = task.file .. ".html"
        local output_path = "../" .. table.concat(dir_list, "/")

        local permalinks = M.get_permalinks(rating, doc_root)
        local result, error = page_generator.generate_post_list(input_data, doc_root,
            task.title,
            task.subtitle or categoary.title,
            permalinks)
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
    M.build_task_with_rating(build_task, categoary, "s")
    M.build_task_with_rating(build_task, categoary, "q")
    M.build_task_with_rating(build_task, categoary, "e")
    M.build_categoary_index(categoary, "s")
    M.build_categoary_index(categoary, "q")
    M.build_categoary_index(categoary, "e")
end

function M.build_categoary_index(subscribe, rating)
    if not rating then
        rating = "s"
    end
    local output_dir = subscribe.output_dir
    local item_list = {}
    for _, task in ipairs(subscribe.build_list) do
        M.convert_task(task)
        local post_list = {}
        local item = {
            title = task.title,
            file = task.file,
            post_list = post_list,
        }
        item_list[#item_list + 1] = item
        -- item.title = task.title
        -- item.post_list = post_list
        local input_data = M.get_task_input_data(task, rating)
        if input_data then
            for i = 1, 4 do
                post_list[#post_list + 1] = input_data[i]
            end
        end
    end

    local doc_root = output_dir and
        (rating == "s" and "../" or "../../") or
        (rating == "s" and "./" or "../")


    local output_path = output_dir and
        (rating == "s" and "../" .. output_dir .. "/index.html" or "../" .. output_dir .. "/" .. rating .. "/index.html") or
        (rating == "s" and "../index.html" or "../" .. rating .. "/index.html")

    local permalinks = M.get_permalinks(rating, doc_root)
    local result, error = page_generator.generate_subscribe_index(item_list, doc_root, subscribe.title, "", permalinks)
    if error then
        print(error)
    else
        print(subscribe.title .. " -> " .. output_path)
        file_utils.write(output_path, tostring(result))
        -- io.open(output_path, "w"):write(tostring(result))
    end
end

function M.build_all()
    for _, categoary in ipairs(task_list) do
        for _, task in ipairs(categoary.build_list) do
            M.convert_task(task)
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
