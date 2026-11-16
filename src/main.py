"""FastAPI application."""

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

app = FastAPI()


@app.get("/")
def root() -> dict[str, str]:
    return {"message": "Hello, world!"}


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.exception_handler(StarletteHTTPException)
async def handle_http_exception(
    request: Request,
    exception: StarletteHTTPException,
) -> JSONResponse:
    if exception.status_code == 404:
        content = {"error": "Not found"}
    else:
        content = {"detail": exception.detail}
    return JSONResponse(
        status_code=exception.status_code,
        content=content,
        headers=exception.headers,
    )
