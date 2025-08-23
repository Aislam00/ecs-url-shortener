FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    openssl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Generate self-signed certificate
RUN openssl req -x509 -newkey rsa:4096 -nodes -out cert.pem -keyout key.pem -days 365 \
    -subj "/C=GB/ST=London/L=London/O=URLShortener/CN=localhost"

COPY app.py .

RUN groupadd -r appuser && useradd -r -g appuser appuser
RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f -k https://localhost:8080/healthz || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--certfile", "cert.pem", "--keyfile", "key.pem", "app:app"]
