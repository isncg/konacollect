local flaresolverr = require "flaresolverr"
local file_utils = require "file_utils"
local io = require "io"

local enums = require "enums"


local base_url = "https://www.konachan.com/post.json"
local temp_download_path = ".tempdownload.json"

local M = {}

function M.init_request_headers()
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
        M.headers = headers
    end
end

local function strip_html(body)
    local inner = body:match("<pre>(.-)</pre>")
    if inner then
        inner = inner:gsub("&quot;", '"')
        inner = inner:gsub("&amp;", "&")
        inner = inner:gsub("&lt;", "<")
        inner = inner:gsub("&gt;", ">")
        inner = inner:gsub("&#39;", "'")
        return inner
    end
    return body
end

function M.request_post(rating, tags, download_path)
    local url = base_url .. "?limit=100&tags=" .. enums.PostRatingTag[rating]
    if tags and #tags > 0 then
        for i = 1, #tags do
            url = url .. "%20" .. tags[i]
        end
    end

    print("request via FlareSolverr: " .. url)
    local body, status = flaresolverr.fetch(url, M.headers)

    if not body or status ~= 200 then
        print("request failed: FlareSolverr returned status " .. tostring(status))
        return
    end

    body = strip_html(body)

    local file = io.open(temp_download_path, "wb")
    if not file then
        error("cannot open file: " .. temp_download_path)
    end
    file:write(body)
    file:close()

    print("request success: " .. temp_download_path)
    return file_utils.copy_file(temp_download_path, download_path)
end

return M
