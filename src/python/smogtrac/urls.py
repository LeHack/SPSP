"""smogtrac URL Configuration"""
from django.conf.urls import include, url
from django.contrib import admin
from webui.urls import urlpatterns as webui_urls

urlpatterns = [
    url(r'^', include(webui_urls)),
    url(r'^admin/', admin.site.urls),
]
