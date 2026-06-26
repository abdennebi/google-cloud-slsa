import os
import signal
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI, Response
from fastapi.responses import PlainTextResponse, JSONResponse

PORT_KEY = "PORT"
ADDRESS_DEFAULT = "8080"
VERSION = os.environ.get("APP_VERSION", "v0.0.1-default")


@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"Starting server {VERSION}...")
    yield
    print("\nServer exiting")


app = FastAPI(lifespan=lifespan)


@app.get("/", response_class=PlainTextResponse)
async def root():
    return "Hello"


@app.get("/api/ping")
async def ping():
    return JSONResponse(content={"message": "pong", "version": VERSION})


@app.options("/{full_path:path}")
async def options_handler(full_path: str, response: Response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "POST,OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = (
        "authorization, origin, content-type, accept"
    )
    response.headers["Allow"] = "POST,OPTIONS"
    response.headers["Content-Type"] = "application/json"
    return Response(status_code=200, headers=dict(response.headers))


def handle_shutdown(signum, frame):
    print("\nShutting down server...")
    sys.exit(0)


signal.signal(signal.SIGINT, handle_shutdown)
signal.signal(signal.SIGTERM, handle_shutdown)


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get(PORT_KEY, ADDRESS_DEFAULT))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        timeout_graceful_shutdown=3,
    )
