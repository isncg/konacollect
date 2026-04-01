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

local function task(name_tag, title, request_tags)
    if not title then
        local sp = s_split(name_tag, "_")
        for i, s in ipairs(sp) do
            sp[i] = string.gsub(s, "^%l", string.upper)
        end
        title = table.concat(sp, " ")
    end

    if not request_tags then
        request_tags = { name_tag }
    end
    return {
        request_tags = request_tags,
        title = title,
        file = name_tag
    }
end

return {
    {
        title = "Home",
        build_list = { { request_tags = {}, title = "Recent Posts", file = "index" } }
    },
    {
        title = "Artist",
        output_dir = "artist",
        build_list = {
            task("anmi"),
            task("ke-ta", "Ke-Ta"),
            task("mivit"),
            task("miyase_mahiro"),
        }
    },
    {
        title = "Copyright",
        output_dir = "copyright",
        build_list = {
            task("touhou"),
            task("ookami_to_koushinryou"),
            task("nekopara_gamecg", "Nekopara Game CG", { "nekopara", "game_cg" })
        }
    },
}
