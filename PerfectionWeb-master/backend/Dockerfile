# Use official Python runtime as base image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port 8080 (Cloud Run requirement)
EXPOSE 8080

# Run gunicorn on port 8080
CMD exec gunicorn --bind :8080 --workers 4 --threads 2 --worker-class gthread --worker-tmp-dir /dev/shm app:app
