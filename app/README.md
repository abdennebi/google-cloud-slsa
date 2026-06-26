# App Python (FastAPI Hello Server)

This application is the Python counterpart to the Go application in the `app/` directory. It exposes a minimal FastAPI web server, containerized securely and optimized for production.

---

## 🚀 Setup & Local Development

This project uses [uv](https://github.com/astral-sh/uv) for fast Python package and environment management.

### Prerequisites

Make sure you have `uv` installed. If not, install it using Homebrew (macOS) or another package manager:
```bash
brew install uv
```

### Installation

1. Create a virtual environment and install all dependencies (including dev dependencies) automatically:
   ```bash
   uv sync
   ```

2. Activate the virtual environment:
   ```bash
   source .venv/bin/activate
   ```

### Running the App Locally

Start the FastAPI development server:
```bash
uv run python main.py
```
The server will start on `http://localhost:8080`.

### Running Tests

Run the test suite:
```bash
uv run pytest
```

### 🐳 Docker Build

You can package the application into a secure container locally. The [Dockerfile](Dockerfile) uses a multi-stage build, leveraging `uv` to install dependencies and Google's **Distroless** Python image for the runtime to minimize the container's attack surface.

To build the Docker image:
```bash
docker build -t hello-python:latest .
```

To run the container locally:
```bash
docker run -p 8080:8080 hello-python:latest
```
The application will be accessible at `http://localhost:8080`.

---

## 🔒 Security

### 🛡️ HTTP Security Headers
The application includes a custom middleware (`SecurityHeadersMiddleware`) to inject standard security headers:
* **`X-Content-Type-Options: nosniff`**: Prevents browser MIME-type sniffing.
* **`X-Frame-Options: DENY`**: Protects against clickjacking.
* **`X-XSS-Protection: 1; mode=block`**: Enables browser-native XSS filtering.
* **`Content-Security-Policy: default-src 'self'`**: Restricts resource loading to the origin.
* **`Referrer-Policy: no-referrer`**: Protects user privacy when clicking external links.
* **`Strict-Transport-Security (HSTS)`**: Automatically enabled in production (`APP_ENV=production`) with a 2-year `max-age` to enforce HTTPS connections.

### 🔐 Secure CORS Configuration
* Replaced manual OPTIONS handler with FastAPI's official `CORSMiddleware`.
* Configurable allowed origins via the `ALLOWED_ORIGINS` environment variable (defaults to restrictive empty list in production).
* Complies with browser standards for credentials and preflight requests.

### 🧐 Attack Surface Reduction (Hardening)
* **Disabled API Docs**: Swagger UI (`/docs`), Redoc (`/redoc`), and the raw schema (`/openapi.json`) are disabled in production to hide API structure.
* **Removed Server Header**: Configured Uvicorn with `server_header=False` to prevent leaking technology stack info (`Server: uvicorn`).

### 🐳 Distroless Containerization
* The [Dockerfile](Dockerfile) uses a multi-stage build. The final production image is based on Google's **Distroless** Python image (`gcr.io/distroless/python3-debian12`), which contains no shell, package manager, or unnecessary system utilities.

---

## ⚡ Performance Optimizations

* **Fast JSON Serialization**: The `/api/ping` route returns a native Python dictionary. FastAPI handles high-performance JSON serialization internally, avoiding the overhead of manual `JSONResponse` wrapping.
* **Structured Logging**: Replaced `print` statements with the standard Python `logging` module, formatted for easy integration with Google Cloud Logging.
