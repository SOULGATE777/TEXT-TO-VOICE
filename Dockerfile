# Use Python 3.11 slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install minimal system dependencies for Edge TTS
RUN apt-get update && apt-get install -y \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies (Edge TTS is very lightweight).
# edge-tts must be >=7.3.1 (older builds get Microsoft WSS 403 / Sec-MS-GEC).
RUN pip install --no-cache-dir -r requirements.txt \
    && python -c "import edge_tts; import importlib.metadata as m; v=m.version('edge-tts'); print(f'edge-tts={v}'); t=tuple(int(x) for x in v.split('.')[:3]); assert t >= (7, 3, 1), v"

# Copy application code
COPY app/ ./app/

# Create a non-root user for security
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app

USER appuser

# Expose the port the app runs on
EXPOSE 5032

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5032/ || exit 1

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "5032"]
