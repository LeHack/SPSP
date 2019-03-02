"""webui URL Configuration"""
from django.conf.urls import url
from webui import views

urlpatterns = [
    url(r'^$', views.index, name='index'),
    url(r'^rest/refresh/start/(?P<area>[A-Za-z\ ąćęłóśżźĄĆĘŁÓŚŻŹ]+)/(?P<pm_type>[A-Za-z0-9\.\-]+)$', views.startDataRefresh, name='start_refresh'),
    url(r'^rest/refresh/check$', views.checkDataRefresh, name='check_refresh'),
    url(r'^rest/chart/(?P<paramid>[0-9]+)/(?P<dateRange>[A-Za-z0-9]+)/?$', views.getChart, name='get_chart'),
    url(r'^rest/settings$', views.getSettings, name='get_settings'),
    url(r'^rest/settings/update$', views.updateSettings, name='set_settings'),
    url(r'^rest/latest$', views.getLatestReadings, name='get_latest'),
]
