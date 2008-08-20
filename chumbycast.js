$(document).ready(
    function() {
        var selected_url=null;
        var playing=false;
        
        function update_play_list(play_list, data) {
            function add_item_click(link, list_item, url) {
                link.click( function() {
                    if ( url != selected_url ) {
                        selected_url=url;
                        play_list.find('li').removeClass('selected');
                        list_item.addClass('selected');

                        $('#controls input[name=play]')
                            .removeAttr('disabled');
                    }

                    return false;
                });
            }
            
            play_list.html('');
            for ( var i = 0; i < data.length; i++ ) {
                var podcast=data[i];
                var podcast_name=podcast[0];
                var title=podcast[1];
                var url=podcast[2];
                var played=podcast[3]
                
                var list_item=$('<li></li>');
                list_item.addClass(i%2==0?'even':'odd');
                if (played) {
                    list_item.addClass('played');
                }
                var link = $('<a></a>').attr('href', url).text(title);
                list_item.append(link);
                list_item.append($('<div class="podcast_name"></div>').text(podcast_name));
                play_list.append(list_item);
                
                add_item_click(link, list_item, url);
            }
        }
        
        function fetch_play_list() {
            var play_list=$('#play_list');
            play_list.html('<li>Loading...</li>');
            
            $.ajax({
                url: '/list',
                cache: false,
                dataType: 'json',
                success: function(data) {
                    update_play_list(play_list, data);
                }
            });
        }
        
        function refresh_play_list() {
            var play_list=$('#play_list');
            play_list.prepend('<li>Refreshing...</li>');
            $('#controls input[name=refresh]')
                .attr('disabled','disabled');
                
            $.ajax({
                url: '/refresh',
                type: 'POST',
                dataType: 'json',
                data:{},
                success: function(data) {
                    update_play_list(play_list, data);
                    $('#controls input[name=refresh]')
                        .removeAttr('disabled')
                }
            });
            return false;
        }
        
        function play() {
            var play_url=selected_url;
            $.ajax({
                url: '/play',
                type: 'POST',
                data:{ url: play_url },
                success: function(data) {
                    // mark podcast as played in DOM
                    $('#play_list li').each(
                        function() {
                            if ( $(this).find('a').attr('href') == play_url ) {
                                $(this).addClass('played');
                            }
                        }
                    );
                }
            });
            return false;
        }
        
        function stop() {
            $.ajax({
                url: '/stop',
                type: 'POST',
                data:{ url: selected_url },
                success: function(data) {
                    selected_url=null;
                    $('#controls input[name=play]')
                        .attr('disabled','disabled');
                    $('#play_list li').removeClass('selected');
                }
            });
            return false;
        }
        
        function resize_playlist() {
            var play_list_height = $('#play_list_container').height();
            var container_height = $('#container').height();
            $('#play_list_container').height($(window).height() - (container_height-play_list_height) - 20);
        }
        
        $('#controls input[name=refresh]')
            .removeAttr('disabled')
            .click(refresh_play_list);
        
        $('#controls input[name=play]')
            .click(play);
            
        $('#controls input[name=stop]')
            .removeAttr('disabled')
            .click(stop);
        
        $(window).resize(resize_playlist);
        
        resize_playlist();
        fetch_play_list();
    }
);