# app/core/config.py

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List, Union

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

    # App
    PROJECT_NAME: str = "AI Workout Tracker"
    VERSION: str = "1.0.0"
    API_V1_PREFIX: str = "/api/v1"

    # Database
    DATABASE_URL: str

    # Security
    SECRET_KEY: str = "rhockai_default_secret_key_change_me_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7
    GOOGLE_CLIENT_ID: str = ""

    # CORS
    ALLOWED_ORIGINS: List[str] = ["*"]

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> Union[List[str], str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        return ["*"]

    # Lemon Squeezy
    LEMONSQUEEZY_API_KEY: str = ""
    LEMONSQUEEZY_STORE_ID: str = ""
    LEMONSQUEEZY_WEBHOOK_SECRET: str = ""
    LEMONSQUEEZY_VARIANT_ID_MONTHLY: str = ""
    LEMONSQUEEZY_VARIANT_ID_YEARLY: str = ""
    LEMONSQUEEZY_VARIANT_ID_LIFETIME: str = ""

    # Email
    SENDGRID_API_KEY: str = ""
    FROM_EMAIL: str = ""

    # AI
    MIN_POSE_CONFIDENCE: float = 0.5
    CALORIES_PER_REP: dict = {}

    # Pagination
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100

    # Environment
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    LOG_LEVEL: str = "INFO"

    # OTA Updates
    LATEST_APP_VERSION: str = "2.0.0"
    APK_DOWNLOAD_URL: str = "https://rhockai-app.onrender.com/static/rhockai.apk"


settings = Settings()
