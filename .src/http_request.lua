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
            "Mozilla/5.0 (Android 14; Mobile; rv:150.0) Gecko/150.0 Firefox/150.0",
            ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            ["Cookie"] = "cf_clearance=lHIRBDYd77Eg4pHKDdwJHv18eNIOpCtboM.f.92BrlY-1775523505-1.2.1.1-9yB9EioIxJhM0..eu_FLF_DXWGQBFiMK4N3zkWmXa_y5H_QAV3OatuizljRUVrBIhZqf7W9xocgD.lOFihuiuhgtpHyX16q215YBp5ClqDOVExW_DF.5oCvT7jnsor3a22dp9JvkUmxR1eD3xZA5.2AhHFDuFOOHoZ.ays3AzAnI0zGA1n._MxbtiOKGmAfm8zwCRPVbtbjuEWWmqWq_Vu2poCu18f4pk4Tp7.cFr7UoWcSeItB0QAK8BuOtNYMIvvj7XXCMnxtQugaS20b2HQmTMQyU2psKP2QfS6Y2GU5mYfr3O_cakLA4PFQWF2d4_Fus0zfeUyuPKw6opC1spw"
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
