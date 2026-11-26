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
    ENABLE_DEV_ENDPOINTS: bool = False
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # Security
    SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Database
    DATABASE_URL: str
    DB_ECHO: bool = False
    DB_POOL_SIZE: int = 20
    DB_MAX_OVERFLOW: int = 10

    # Redis
    REDIS_URL: Optional[str] = None

    # Eskiz.uz SMS Gateway
    ESKIZ_EMAIL: Optional[str] = None
    ESKIZ_PASSWORD: Optional[str] = None
    ESKIZ_FROM: str = "4546"

    # Coturn WebRTC STUN/TURN Server
    COTURN_HOST: str = "coturn"
    COTURN_PORT: int = 3478
    COTURN_REALM: str = "logiflow.io"
    COTURN_SECRET: str
    STUN_SERVER_URL: str = "stun:stun.l.google.com:19302"

    # CORS & Hosts (Explicit domains only, no wildcards)
    CORS_ORIGINS: str
    ALLOWED_HOSTS: str

    # Platform Carrier Commission Tiers (Configurable via .env or DB)
    COMMISSION_TIER_1_LIMIT: float = 2000000.0  # <= 2,000,000 UZS
    COMMISSION_TIER_1_FEE: float = 30000.0      # 30,000 UZS
    COMMISSION_TIER_2_LIMIT: float = 5000000.0  # <= 5,000,000 UZS
    COMMISSION_TIER_2_FEE: float = 50000.0      # 50,000 UZS
    COMMISSION_TIER_3_FEE: float = 70000.0      # > 5,000,000 UZS -> 70,000 UZS

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
        if not self.CORS_ORIGINS or self.CORS_ORIGINS.strip() == "*":
            raise ValueError("Wildcard CORS_ORIGINS '*' is forbidden in production. Provide explicit comma-separated domains.")
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip() and origin.strip() != "*"]

    @property
    def is_sqlite(self) -> bool:
        return "sqlite" in self.DATABASE_URL

    @property
    def resolved_database_url(self) -> str:
        if self.DATABASE_URL.startswith("sqlite+aiosqlite:///./"):
            backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
            db_name = self.DATABASE_URL.replace("sqlite+aiosqlite:///./", "")
            abs_path = os.path.join(backend_dir, db_name).replace("\\", "/")
            return f"sqlite+aiosqlite:///{abs_path}"
        return self.DATABASE_URL

settings = Settings()
