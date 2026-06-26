from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.text == "Hello"


def test_ping():
    response = client.get("/api/ping")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "pong"
    assert "version" in data


def test_options():
    response = client.options("/")
    assert response.status_code == 200
    assert response.headers.get("access-control-allow-origin") == "*"
