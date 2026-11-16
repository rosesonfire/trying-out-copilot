from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_root_returns_greeting() -> None:
    response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {"message": "Hello, world!"}


def test_health_returns_ok() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_unknown_path_returns_json_404() -> None:
    response = client.get("/missing")

    assert response.status_code == 404
    assert response.json() == {"error": "Not found"}
