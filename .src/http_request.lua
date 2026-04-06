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
        headers = {
            ["User-Agent"] =
            "Mozilla/5.0 (X11; Linux x86_64; rv:150.0) Gecko/20100101 Firefox/150.0",
            ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            ["Cookie"] = "cf_clearance=NL3hr6ID.wubrYSoRt5RvC5wCOj5QvnWcGgvm6b.2fo-1775517335-1.2.1.1-nmGrRyTaWUq6x34eQ_sz2eSJfy5jYGX7YPu3NoKsVD2zjFGbS1NEv0kAEg56mtomamXZ_SKBYGUr_zfYvOHajJI0zq9otfMNnNDpxGQattVpG9r1apDnZRXHBkxpGjRglSQ4j0e0QVPbPjQvTiIQkTYuEuVUp8DwwKP.qynsenF1GsDSXs4vnMuxUujrsBkK7STOG3HiIoB9mjAYnUYJir6985_evELz7SK0lGpzvupoLKaIuohAobAiA_TWmHNGWFUtCXwlsy71pObV8j5MFJKtAViYZSh3W4IO2Ox6G8tv2VYC_fhi8hIr2IyAdfN7bVGlXdjwA4.vsu8uIEv4InPnv9zLTGA3rDmyO6Rty800FCqgOqiOLEABBMJrnSv.dGpcQawQWMaEbxzkRg21Y3VbFGdduozGpoDzYo_w9LU"
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
