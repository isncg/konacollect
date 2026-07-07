local flaresolverr = require "flaresolverr"
local cookie_cache = require "cookie_cache"
local io = require "io"

local TARGET_URL = "https://www.konachan.net/post.json"

local function load_headers()
    local file = io.open("headers.txt", "r")
    if not file then
        print("ERROR: cannot open headers.txt")
        os.exit(1)
    end
    local headers = {}
    for line in file:lines() do
        local key, value = line:match("^(%S+): (.+)$")
        if key and value then
            headers[key] = value
        end
    end
    file:close()
    return headers
end

print("=== Refresh CF Clearance ===")
print("Target: " .. TARGET_URL)
print()

local headers = load_headers()
local body, status, cookies = flaresolverr.fetch(TARGET_URL, headers)

if not body or status ~= 200 then
    print("ERROR: FlareSolverr failed (status=" .. tostring(status) .. ")")
    print("See crawler.log for details.")
    os.exit(1)
end

cookies = cookies or {}
local cf_clearance = cookies["cf_clearance"]

if not cf_clearance then
    print("ERROR: cf_clearance not found in FlareSolverr response")
    print("Available cookies:")
    for k, v in pairs(cookies) do
        print("  " .. k .. "=" .. v:sub(1, 30) .. "...")
    end
    os.exit(1)
end

cookie_cache.save(cf_clearance)
print("SUCCESS: cf_clearance saved to " .. cookie_cache.cache_path)
print("  value: " .. cf_clearance:sub(1, 30) .. "...")
print()
print("Full log: crawler.log")
