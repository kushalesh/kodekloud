# syntax=docker/dockerfile:1

FROM python:3.12-slim AS base

# Prevents python from writing .pyc & forces stdout/stderr to be unbuffered
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# System deps (curl for healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m appuser

WORKDIR /app

# Install deps first (better layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app
COPY app.py .

# Expose app port
EXPOSE 8080

# Healthcheck against the root path
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8080/ || exit 1

# Drop privileges
USER appuser

# Use gunicorn in production
CMD ["gunicorn", "-b", "0.0.0.0:8080", "app:app", "--workers", "2", "--threads", "4"]
