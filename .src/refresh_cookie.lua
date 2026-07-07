local flaresolverr = require "flaresolverr"
local cookie_cache = require "cookie_cache"
local cjson = require "cjson"
local io = require "io"

local TARGET_URL = "https://www.konachan.net/post.json"

local function table_keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        keys[#keys + 1] = tostring(k)
    end
    return keys
end

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

local raw_data = flaresolverr.request_get(TARGET_URL, nil, headers)
if not raw_data then
    print("ERROR: FlareSolverr returned nil")
    os.exit(1)
end

print("FlareSolverr status: " .. tostring(raw_data.status))
if raw_data.status ~= "ok" then
    print("FlareSolverr error: " .. tostring(raw_data.message or raw_data.error or "unknown"))
    os.exit(1)
end

local solution = raw_data.solution
print("Solution keys: " .. table.concat(table_keys(solution), ", "))
print("Solution status: " .. tostring(solution.status))
print("Solution body size: " .. tostring(solution.response and #solution.response or 0) .. " bytes")

local cookies = {}

if solution.cookies then
    print("solution.cookies is table, count: " .. #solution.cookies)
    for _, c in ipairs(solution.cookies) do
        local name = c.name or "?"
        local value = c.value or ""
        cookies[name] = value
        print("  cookie[" .. name .. "] = " .. value:sub(1, 40) .. "...")
    end
else
    print("solution.cookies is nil")
end

if solution.headers then
    for k, v in pairs(solution.headers) do
        if type(k) == "string" and k:lower():find("set%-cookie") then
            print("  Set-Cookie: " .. tostring(v):sub(1, 80))
        end
    end
end

local cf_clearance = cookies["cf_clearance"]

if not cf_clearance then
    print()
    print("Retrying (second pass may trigger challenge)...")

    raw_data = flaresolverr.request_get(TARGET_URL, nil, headers)
    if raw_data and raw_data.status == "ok" then
        local solution2 = raw_data.solution
        print("Retry solution keys: " .. table.concat(table_keys(solution2), ", "))
        if solution2.cookies then
            print("Retry cookies count: " .. #solution2.cookies)
            for _, c in ipairs(solution2.cookies) do
                local name = c.name or "?"
                cookies[name] = c.value or ""
                print("  cookie[" .. name .. "] = " .. (c.value or ""):sub(1, 40) .. "...")
            end
            cf_clearance = cookies["cf_clearance"]
        end
    end
end

if not cf_clearance then
    print()
    print("ERROR: cf_clearance not found after retry")
    print("All cookies collected:")
    for k, v in pairs(cookies) do
        print("  " .. k .. " = " .. v:sub(1, 50))
    end
    if #table_keys(cookies) == 0 then
        print("  (none)")
        print()
        print("Debug: dumping raw solution (first 2000 chars)...")
        print(cjson.encode(solution):sub(1, 2000))
    end
    os.exit(1)
end

cookie_cache.save(cf_clearance)
print()
print("SUCCESS: cf_clearance saved to " .. cookie_cache.cache_path)
print("  value: " .. cf_clearance:sub(1, 40) .. "...")
