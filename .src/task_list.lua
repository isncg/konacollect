return {
    {
        title = "Recommend",
        build_list = {
            { request_tags = {},                title = "New",       subtitle = "", file = "recent" },
            { request_tags = { "order:score" }, title = "Top Score", subtitle = "", file = "highscore" },
        }
    },
    {
        title = "Artist",
        output_dir = "artist",
        build_list = {
            { one_tag = "anmi" },
            { one_tag = "ke-ta",        title = "Ke-Ta" },
            { one_tag = "mivit" },
            { one_tag = "miyase_mahiro" },
        }
    },
    {
        title = "Copyright",
        output_dir = "copyright",
        build_list = {
            { one_tag = "touhou" },
            { one_tag = "ookami_to_koushinryou" },
            { request_tags = { "nekopara", "game_cg" }, title = "Nekopara Game CG", file = "nekopara_gamecg" }
        }
    },
}
