# BUILD stage
FROM python:3.13-alpine AS builder

WORKDIR /app

# Install uv
RUN pip install --no-cache-dir uv

# Install dependencies from uv lockfile
COPY pyproject.toml uv.lock ./
RUN uv export --format requirements-txt --no-dev -o requirements.txt && \
    uv pip install --system --no-cache --prefix=/install -r requirements.txt

COPY main.py .

# RUN stage — use Python Alpine image for minimal footprint and low CVEs
FROM python:3.13-alpine

ARG VERSION=v0.0.1-default
LABEL devo.version="${VERSION}"

# Copy installed packages from builder
COPY --from=builder /install/lib /usr/local/lib
COPY --from=builder /install/bin /usr/local/bin
COPY --from=builder /app/main.py /app/main.py

WORKDIR /app

ENV APP_VERSION=${VERSION}
ENV PORT=8080

EXPOSE 8080

ENTRYPOINT ["python", "main.py"]
