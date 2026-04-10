local builder = require "builder"
local argparse = require "argparse"

builder.load_tags()

local parser = argparse()
parser:flag("-a --all", "Build all")
parser:flag("-r --rebuild", "Rebuild with cached data")
parser:option("-t --task", "Task name")
parser:option("-i --index", "Task index")
local args = parser:parse()

if args.rebuild then
    print("Rebuild with cached data")
    builder.disable_http_request = true
end

if args.all then
    print("Build all")
    builder.build_all()
else
    print("Build one task", args.task, args.index)
    builder.build_one_task(args.index and tonumber(args.index), args.task)
end

