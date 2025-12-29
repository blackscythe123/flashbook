# Flashbook AI Backend - Dockerfile
# ==================================
# Optimized for Google Cloud Run deployment

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install dependencies first (cached layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port (Cloud Run uses PORT env var)
EXPOSE 8080

# Run with gunicorn for production
# Cloud Run sets PORT automatically
CMD exec gunicorn --bind :${PORT:-8080} --workers 1 --threads 8 --timeout 0 main:app -k uvicorn.workers.UvicornWorker
