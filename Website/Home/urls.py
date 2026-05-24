# Home/urls.py
from django.urls import path
from . import views

urlpatterns = [
    # The empty string '' means this triggers on the root of the app
    path('', views.homepage, name='homepage'),
]