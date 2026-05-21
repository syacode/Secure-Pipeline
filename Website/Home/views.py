# Home/views.py
from django.shortcuts import render

def homepage(request):
    return render(request, 'Home/index.html')