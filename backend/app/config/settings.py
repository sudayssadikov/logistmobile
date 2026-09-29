from typing import List, Optional
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
import os

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    PROJECT_NAME: str = "LogiFlow Enterprise Logistics API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # Security
    SECRET_KEY: str = "9f82d8c3b4a5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Database
    DATABASE_URL: str = "sqlite+aiosqlite:///./logiflow.db"
    DB_ECHO: bool = False
    DB_POOL_SIZE: int = 20
    DB_MAX_OVERFLOW: int = 10

    # Redis
    REDIS_URL: Optional[str] = None

    # CORS
    CORS_ORIGINS: str = "*"
    ALLOWED_HOSTS: str = "*"

    # Storage (Local & S3 / MinIO Cloud Object Storage)
    STORAGE_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE_MB: int = 25
    S3_ENABLED: bool = False
    S3_BUCKET_NAME: Optional[str] = "logiflow-vault"
    S3_ENDPOINT_URL: Optional[str] = None
    S3_ACCESS_KEY: Optional[str] = None
    S3_SECRET_KEY: Optional[str] = None

    # Payment
    PAYME_MERCHANT_ID: Optional[str] = "test_payme_id"
    PAYME_SECRET_KEY: Optional[str] = "test_payme_secret"
    CLICK_SERVICE_ID: Optional[str] = "test_click_service"
    CLICK_MERCHANT_ID: Optional[str] = "test_click_merchant"
    CLICK_SECRET_KEY: Optional[str] = "test_click_secret"

    @property
    def cors_origins_list(self) -> List[str]:
        if not self.CORS_ORIGINS or self.CORS_ORIGINS == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]

    @property
    def is_sqlite(self) -> bool:
        return "sqlite" in self.DATABASE_URL

settings = Settings()
