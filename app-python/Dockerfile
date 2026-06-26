# BUILD stage
FROM python:3.13-slim AS builder

WORKDIR /app

# Install dependencies into a prefix for easy copy
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

COPY main.py .

# RUN stage — use distroless Python image
FROM gcr.io/distroless/python3-debian12

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

# distroless Python: call python directly
ENTRYPOINT ["python", "main.py"]
