"""
Application configuration
"""

from typing import List, Dict
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator


class Settings(BaseSettings):
    # ===============================
    # APP
    # ===============================
    PROJECT_NAME: str = "Rhockai API"
    VERSION: str = "1.0.0"
    API_V1_PREFIX: str = "/api/v1"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    LOG_LEVEL: str = "INFO"

    # ===============================
    # DATABASE
    # ===============================
    DATABASE_URL: str

    # ===============================
    # SECURITY / AUTH
    # ===============================
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days

    # ===============================
    # CORS
    # ===============================
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://10.0.2.2:8000",
        "http://localhost:8000",
    ]

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v):
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",")]
        return v

    # ===============================
    # STRIPE
    # ===============================
    STRIPE_SECRET_KEY: str = ""
    STRIPE_PUBLISHABLE_KEY: str = ""
    STRIPE_WEBHOOK_SECRET: str = ""
    STRIPE_PRICE_ID_MONTHLY: str = ""
    STRIPE_PRICE_ID_YEARLY: str = ""

    # ===============================
    # FLUTTERWAVE
    # ===============================
    FLUTTERWAVE_SECRET_KEY: str = ""
    FLUTTERWAVE_PUBLIC_KEY: str = ""

    # ===============================
    # LEMON SQUEEZY
    # ===============================
    LEMONSQUEEZY_API_KEY: str = ""
    LEMONSQUEEZY_STORE_ID: str = ""
    LEMONSQUEEZY_WEBHOOK_SECRET: str = ""
    LEMONSQUEEZY_VARIANT_ID_MONTHLY: str = ""
    LEMONSQUEEZY_VARIANT_ID_YEARLY: str = ""
    LEMONSQUEEZY_VARIANT_ID_LIFETIME: str = ""

    # ===============================
    # EMAIL
    # ===============================
    SENDGRID_API_KEY: str = ""
    FROM_EMAIL: str = "noreply@aiworkouttracker.com"

    # ===============================
    # AI / ML
    # ===============================
    MIN_POSE_CONFIDENCE: float = 0.5

    # ===============================
    # PAGINATION
    # ===============================
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100

    # ===============================
    # WORKOUT METRICS
    # ===============================
    CALORIES_PER_REP: Dict[str, float] = {
        "pushup": 0.5,
        "squat": 0.32,
        "plank": 0.25,
    }

    # ===============================
    # SETTINGS CONFIG
    # ===============================
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="forbid",  # catches config mistakes early (GOOD)
    )


settings = Settings()
