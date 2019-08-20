from django.conf.urls import patterns, include, url

urlpatterns = patterns('',                       

    url(r'^$', 'game.views.my_games', name = 'my_games'),
    url(r'^json/$', 'game.views.my_games_json', name = 'my_games_json'),
    url(r'^new/$', 'game.views.new_game', name = 'new_game'),
    url(r'^(?P<game_id>\d+)/$', 'game.views.interactive', name = 'game_interactive'),
    url(r'^(?P<game_id>\d+)/status/$', 'game.views.game_state', name = 'game_state'),
    url(r'^(?P<game_id>\d+)/move/$', 'game.views.move', name = 'game_move'),
    url(r'^(?P<game_id>\d+)/clock/(?P<time_elapsed>\d+)/$', 'game.views.update_clock', name = 'update_clock'),
	url(r'^nation/(?P<nation>.+)/$', 'game.views.set_nation', name = 'set_nation'),
	url(r'^timeline/$', 'game.views.timeline', name = 'timeline'),
                       

)