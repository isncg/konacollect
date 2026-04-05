local https = require "ssl.https"
local http = require "socket.http"
local ltn12 = require "ltn12"
local inspect = require "inspect"
local file_utils = require "file_utils"
local io = require "io"

local enums = require "enums"


local base_url = "http://konachan.net/post.json"
local temp_download_path = ".tempdownload.json"

local M = {}



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
    local response, status = http.request {
        url = url,
        headers = {
            ["User-Agent"] =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36",
            ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            -- ["Cookie"] = "cf_clearance=Q3yvta18oaDwJw0Iu5GV6azYaLra5akP1wuE8GA.L9k-1774936683-1.2.1.1-FBofSkX8Jm4gHfwVDYEOw0HG_o64jmOpB.IPlv5Jjis2xRnHq44C26oiRZvv4pAa3PaFOyo3od8_mB53LxMQU9j9bGXh0wnzyJ5rpFOc2HTDK8cYwovynECjcGKUe1jo5ts4b2yFreBRX0m3RutOHcAY8imwCWu5J9YWRIpqHr5pmsBNypFSMpjW7z89NPDWqJUIgBvKOSN2lDyiuOIMV46yp2SeZpyv8E8eArj_MQKj7AaFXNjHvwxTmy6_.v.x"
        }, -- 添加自定义头
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
