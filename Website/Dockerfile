# Use an official lightweight Python image
FROM python:3.11-slim

# Set environment variables
# 1. Forces Python to not write .pyc files
# 2. Forces Python to output stdout/stderr directly (useful for Docker logs)
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set the working directory inside the container
WORKDIR /app

# Install system dependencies required for mysqlclient and other packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       gcc \
       default-libmysqlclient-dev \
       pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file and install dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip \
    && pip install -r requirements.txt

# Copy the rest of the Django project code into the container
COPY . /app/

# Expose the port the app runs on
EXPOSE 8000

# Command to run the application using Gunicorn
# IMPORTANT: Replace "myproject.wsgi:application" with the actual name 
# of your project's main folder (where wsgi.py lives).
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "Website.wsgi:application"]
