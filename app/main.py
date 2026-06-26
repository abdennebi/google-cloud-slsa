import logging
import os
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse
from starlette.middleware.base import BaseHTTPMiddleware

# Configure logging for production
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger("app")

PORT_KEY = "PORT"
ADDRESS_DEFAULT = "8080"
VERSION = os.environ.get("APP_VERSION", "v0.0.1-default")
ENVIRONMENT = os.environ.get("APP_ENV", "production")

# Disable OpenAPI docs in production for security (hiding attack surface)
show_docs = ENVIRONMENT.lower() != "production"

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Starting server {VERSION} in {ENVIRONMENT} mode...")
    yield
    logger.info("Server exiting")


app = FastAPI(
    lifespan=lifespan,
    openapi_url="/openapi.json" if show_docs else None,
    docs_url="/docs" if show_docs else None,
    redoc_url="/redoc" if show_docs else None,
)

# Standard Security Headers Middleware
class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Content-Security-Policy"] = "default-src 'self'"
        response.headers["Referrer-Policy"] = "no-referrer"
        # Strict-Transport-Security (HSTS) - only in production/HTTPS
        if ENVIRONMENT.lower() == "production":
            response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains; preload"
        return response

app.add_middleware(SecurityHeadersMiddleware)

# CORS configuration via standard FastAPI middleware
allowed_origins_env = os.environ.get("ALLOWED_ORIGINS", "")
allowed_origins = [origin.strip() for origin in allowed_origins_env.split(",") if origin.strip()]
if not allowed_origins:
    if ENVIRONMENT.lower() == "production":
        # Production default: restrictive
        allowed_origins = []
    else:
        # Development default: allow all
        allowed_origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["authorization", "origin", "content-type", "accept"],
    expose_headers=["*"],
    max_age=600,
)


@app.get("/", response_class=PlainTextResponse)
async def root():
    return "Hello"


@app.get("/api/ping")
async def ping():
    # Returning a dict directly is more performant than manual JSONResponse wrapper
    return {"message": "pong", "version": VERSION}


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get(PORT_KEY, ADDRESS_DEFAULT))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        timeout_graceful_shutdown=3,
        server_header=False, # Disable server header (prevents technology fingerprint leak)
    )
