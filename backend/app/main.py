from contextlib import asynccontextmanager
from datetime import datetime, timezone
import os
import time
from typing import Any, Dict
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.middleware.trustedhost import TrustedHostMiddleware
from app.api.v1.router import api_v1_router
from app.config.settings import settings
from app.core.exceptions import AppException
from app.database.base import Base
from app.database.seed import seed_database
from app.database.session import engine
from app.websocket.connection_manager import ws_manager

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
    # Ensure storage folder exists
    os.makedirs(settings.STORAGE_DIR, exist_ok=True)
    os.makedirs(os.path.join(settings.STORAGE_DIR, "voice"), exist_ok=True)
    
    # Startup: Ensure database schema is created
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        
    # Seed ONLY in development environment
    if settings.ENVIRONMENT == "development":
        try:
            await seed_database()
        except Exception as e:
            print(f"Notice on seed: {e}")
            
    # Initialize Redis Pub/Sub if configured
    await ws_manager.init_redis()
    
    yield
    # Shutdown: Close database pool
    await engine.dispose()

def create_application() -> FastAPI:
    is_prod = settings.ENVIRONMENT.lower() == "production"
    application = FastAPI(
        title=settings.PROJECT_NAME,
        version=settings.VERSION,
        openapi_url=None if is_prod else f"{settings.API_V1_STR}/openapi.json",
        docs_url=None if is_prod else "/docs",
        redoc_url=None if is_prod else "/redoc",
        lifespan=lifespan,
    )

        # Trusted Host Middleware
    from starlette.middleware.trustedhost import TrustedHostMiddleware
    allowed_hosts = [h.strip() for h in settings.ALLOWED_HOSTS.split(",") if h.strip() and h.strip() != "*"]
    if not allowed_hosts:
        allowed_hosts = ["localhost", "127.0.0.1", "testserver"]
    if "testserver" not in allowed_hosts:
        allowed_hosts.append("testserver")
    application.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=allowed_hosts,
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

    from fastapi.encoders import jsonable_encoder

    @application.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "success": False,
                "message": "Request validation failed",
                "error_code": "VALIDATION_ERROR",
                "data": jsonable_encoder(exc.errors()),
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

    # Mount Static Uploads Folder
    if os.path.exists(settings.STORAGE_DIR):
        application.mount("/uploads", StaticFiles(directory=settings.STORAGE_DIR), name="uploads")

    # Root Healthcheck & Monitoring
    @application.get("/health", tags=["Health"])
    @application.get("/", tags=["Health"])
    async def health_check() -> Dict[str, Any]:
        from sqlalchemy import text
        from app.database.session import AsyncSessionLocal
        
        db_status = "ok"
        try:
            async with AsyncSessionLocal() as session:
                await session.execute(text("SELECT 1"))
        except Exception as e:
            db_status = f"unhealthy: {str(e)}"

        redis_status = "disabled"
        if settings.REDIS_URL:
            try:
                import redis.asyncio as aioredis
                r = aioredis.from_url(settings.REDIS_URL, decode_responses=True)
                pong = await r.ping()
                await r.aclose()
                redis_status = "ok" if pong else "unreachable"
            except Exception as e:
                redis_status = f"unreachable: {str(e)}"

        is_healthy = db_status == "ok"
        return {
            "status": "healthy" if is_healthy else "degraded",
            "service": settings.PROJECT_NAME,
            "version": settings.VERSION,
            "environment": settings.ENVIRONMENT,
            "database": db_status,
            "redis": redis_status,
            "docs": None if is_prod else "/docs",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

    return application

app = create_application()
