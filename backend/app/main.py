from contextlib import asynccontextmanager
import time
from typing import Any, Dict
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from app.api.v1.router import api_v1_router
from app.config.settings import settings
from app.core.exceptions import AppException
from app.database.base import Base
from app.database.seed import seed_database
from app.database.session import engine

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Adds enterprise security headers to every HTTP response."""
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        return response

class RequestTimingMiddleware(BaseHTTPMiddleware):
    """Attaches response execution duration in milliseconds."""
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        response = await call_next(request)
        process_time = (time.time() - start_time) * 1000
        response.headers["X-Process-Time-Ms"] = f"{process_time:.2f}"
        return response

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Ensure database schema is created and seed initial fixtures
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    try:
        await seed_database()
    except Exception as e:
        print(f"Notice on seed: {e}")
    yield
    # Shutdown: Close database pool
    await engine.dispose()

def create_application() -> FastAPI:
    application = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        openapi_url=f"{settings.API_V1_STR}/openapi.json",
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # CORS Middleware
    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Security & Logging Middlewares
    application.add_middleware(SecurityHeadersMiddleware)
    application.add_middleware(RequestTimingMiddleware)

    # Exception Handlers
    @application.exception_handler(AppException)
    async def app_exception_handler(request: Request, exc: AppException):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "success": False,
                "message": exc.detail,
                "error_code": exc.error_code,
                "data": None,
            },
            headers=exc.headers,
        )

    @application.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "success": False,
                "message": "Request validation failed",
                "error_code": "VALIDATION_ERROR",
                "data": exc.errors(),
            },
        )

    @application.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        if settings.DEBUG:
            print(f"Unhandled server error: {exc}")
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "success": False,
                "message": "Internal server error occurred.",
                "error_code": "INTERNAL_SERVER_ERROR",
                "data": None,
            },
        )

    # Mount API Routers
    # 1. Under /api/v1 prefix
    application.include_router(api_v1_router, prefix=settings.API_V1_STR)
    # 2. Also mount directly at /v1 and root level for flexible Flutter baseUrl configuration
    application.include_router(api_v1_router, prefix="/v1")
    application.include_router(api_v1_router)

    # Root Healthcheck
    @application.get("/health", tags=["Health"])
    @application.get("/", tags=["Health"])
    async def health_check() -> Dict[str, Any]:
        return {
            "status": "healthy",
            "service": settings.PROJECT_NAME,
            "version": settings.VERSION,
            "environment": settings.ENVIRONMENT,
            "docs": "/docs",
        }

    return application

app = create_application()
