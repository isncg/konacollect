var show_big_image = function(img_parent_id, url){
    var div = document.getElementById(img_parent_id);
    // img.src = url;
    div.innerHTML = '<img class="big_img" src="' + url + '">';
}