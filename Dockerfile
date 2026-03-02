FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
COPY . .
RUN pip install --no-cache-dir -e .

# ---- runtime image ----
FROM python:3.12-slim

# Create a non-root app user with a configurable UID to match typical host user ownership,
# ensuring the app user can write to bind-mounted volumes on the host.
ARG APP_UID=1000
RUN groupadd --gid ${APP_UID} app && \
    useradd --uid ${APP_UID} --gid app --shell /bin/bash --create-home app

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app /app

# Create the volume mount directory and grant ownership to the app user so writes succeed.
RUN mkdir -p /data && chown app:app /data

USER app

VOLUME ["/data"]
