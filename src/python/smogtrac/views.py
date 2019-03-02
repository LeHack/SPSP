'''
Created on 23.11.2016

@author: lehack
'''
from django.http import HttpResponse


def index(request):
    return HttpResponse("Welcome to the SmogTracker index site.")
