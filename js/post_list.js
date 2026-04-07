var split_tags = function (tags) {
    var tag_list = tags.split(' ');
    var tag_html = '';
    for (var i = 0; i < tag_list.length; i++) {
        tag_html += '<span class="tag_name">' + tag_list[i] + '</span> ';
    }
    return tag_html;
}

var show_big_image = function (img_parent_id, url, meta_data) {
    var div = document.getElementById(img_parent_id);
    var inner_html = '';
    console.log(meta_data);
    if (meta_data != null) {
        var artist = meta_data.artist;
        if (artist != null)
            inner_html += '<div class="meta_data_row"><span class="meta_data_name">Author:</span>' + split_tags(artist) + '</div>';
        var copyright = meta_data.copyright;
        if (copyright != null)
            inner_html += '<div class="meta_data_row"><span class="meta_data_name">Copyright:</span>' + split_tags(copyright) + '</div>';
        var tags = meta_data.tags;
        if (tags != null)
            inner_html += '<div class="meta_data_row"><span class="meta_data_name">Tags:</span>' + split_tags(tags) + '</div>';
    }
    // inner_html += '<div><div class="meta_data_name">URL</div><div class="meta_data_value">' + url + '</div></div>';
    inner_html += '<img class="big_img" src="' + url + '">';
    div.innerHTML = inner_html;
}