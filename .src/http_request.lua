local https = require "ssl.https"
local http = require "socket.http"
local ltn12 = require "ltn12"
local inspect = require "inspect"
local file_utils = require "file_utils"
local io = require "io"

local enums = require "enums"


local base_url = "https://www.konachan.net/post.json"
local temp_download_path = ".tempdownload.json"

local M = {}

function M.init_request_headers()
    -- read 'http_request_headers.txt'
    local file = io.open("headers.txt", "r")
    if file then
        local headers = {}
        for line in file:lines() do
            local key, value = line:match("^(%S+): (.+)$")
            if key and value then
                headers[key] = value
            end
        end
        file:close()
        print("init_request_headers", inspect.inspect(headers))
        M.headers = headers
    end
end

function M.request_post(rating, tags, download_path)
    local url = base_url .. "?limit=100&tags=" .. enums.PostRatingTag[rating]
    if tags and #tags > 0 then
        for i = 1, #tags do
            url = url .. "%20" .. tags[i]
        end
    end


    local file = io.open(temp_download_path, "wb")
    if not file then
        error("无法打开文件：" .. temp_download_path)
    end

    print("request: " .. url)
    local response, status = https.request {
        url = url,
        headers = M.headers, -- 添加自定义头
        sink = ltn12.sink.file(file)
    }

    print("response", inspect.inspect(response))
    if status == 200 then
        print("request success: " .. temp_download_path)
        return file_utils.copy_file(temp_download_path, download_path)
    else
        print("request failed: " .. tostring(status))
    end
end

return M
