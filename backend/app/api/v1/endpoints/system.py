from fastapi import APIRouter
from app.core.config import settings

router = APIRouter()

@router.get("/version")
async def get_system_version():
    """
    Get the latest app version and download URL for OTA updates.
    """
    return {
        "latest_version": settings.LATEST_APP_VERSION,
        "download_url": settings.APK_DOWNLOAD_URL,
        "force_update": False
    }
