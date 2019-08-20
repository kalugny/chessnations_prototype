from django.conf.urls import patterns, include, url
import settings

from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    url(r'^admin/', include(admin.site.urls)),
    url(r'^game/', include('game.urls')),

    url(r'^login/$', 'game.views.login', name = 'game-login'),
    url(r'^login/ai/$', 'game.views.login_ai', name = 'game-login-ai'),
    url(r'^login/guest/$', 'game.views.guest', name = 'game-login-guest'),
    url(r'^login/fb/$', 'game.views.fb_connect', name = 'game-login-fb'),
    url(r'^logout/$', 'game.views.logout', name = 'game-logout'),

)
if settings.DEBUG:
    urlpatterns += patterns('',
        url(r'^media/(?P<path>.*)$', 'django.views.static.serve', {'document_root': settings.MEDIA_ROOT}),
    )