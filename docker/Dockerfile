# Multi-stage build for CODEFLOW Engine
# Stage 1: Build environment
FROM python:3.13-slim AS builder

# Set environment variables
# POETRY_VIRTUALENVS_CREATE=false ensures packages install to site-packages
# rather than a virtual environment, making them available in production stage
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    POETRY_VIRTUALENVS_CREATE=false

# Install system dependencies for building
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create and set working directory
WORKDIR /app

# Install poetry
RUN pip install poetry

# Copy poetry files
COPY poetry.lock pyproject.toml README.md ./

# Install dependencies
RUN poetry install --only main --no-interaction --no-ansi --no-root

# Copy source code
COPY . .

# Install the project
RUN poetry install --no-interaction --no-ansi

# Run tests (optional, can be disabled for faster builds)
ARG RUN_TESTS=true
RUN if [ "$RUN_TESTS" = "true" ]; then \
    poetry install --with dev --no-interaction --no-ansi && \
    poetry run pytest tests/ -v --tb=short; \
    fi

# Stage 2: Production environment
FROM python:3.13-slim AS production

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.local/bin:$PATH" \
    CODEFLOW_ENV=production \
    # Poetry configuration - disable virtualenv creation since deps are in site-packages
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_CACHE_DIR=/home/CODEFLOW/.cache/pypoetry

# Create non-root user for security with home directory
RUN groupadd -r CODEFLOW && useradd -r -g CODEFLOW -m -d /home/CODEFLOW CODEFLOW

# Install runtime system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create application directories and ensure home directory ownership
RUN mkdir -p /app /app/logs /app/data /app/config && \
    chown -R CODEFLOW:CODEFLOW /app && \
    chown -R CODEFLOW:CODEFLOW /home/CODEFLOW

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app /app

# Switch to non-root user
USER CODEFLOW

# Expose port for web server
EXPOSE 8080

# Health check using curl (available in the image)
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl --fail http://localhost:8080/health || exit 1

# Default environment variables
ENV CODEFLOW_HOST=0.0.0.0 \
    CODEFLOW_PORT=8080 \
    CODEFLOW_WORKERS=1 \
    CODEFLOW_LOG_LEVEL=INFO \
    CODEFLOW_CONFIG_FILE=/app/config/codeflow.yml

# Volume for persistent data
VOLUME ["/app/data", "/app/logs", "/app/config"]

# Entry point
ENTRYPOINT ["poetry", "run"]

# Default command
CMD ["codeflow-server"]

# Labels for metadata
LABEL org.opencontainers.image.title="CODEFLOW Engine" \
    org.opencontainers.image.description="AI-Powered GitHub PR Automation and Issue Management" \
    org.opencontainers.image.version="1.0.0" \
    org.opencontainers.image.vendor="VeritasVault" \
    org.opencontainers.image.source="https://github.com/veritasvault/codeflow-engine" \
    org.opencontainers.image.documentation="https://codeflow-engine.readthedocs.io" \
    org.opencontainers.image.licenses="MIT"
