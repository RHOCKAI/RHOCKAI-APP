"""
Main API router - combines all endpoint routers
"""

from fastapi import APIRouter
from app.api.v1.endpoints import auth, sessions, analytics, tracking, admin_analytics, ai, workouts, gamification, payments, notifications

# Create main API router
api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(
    auth.router,
    prefix="/auth",
    tags=["Authentication"],
)

api_router.include_router(
    sessions.router,
    prefix="/workouts",
    tags=["Workout Sessions"],
)

api_router.include_router(
    analytics.router,
    prefix="/analytics",
    tags=["Analytics & Stats"],
)

api_router.include_router(
    tracking.router,
    prefix="/track",
    tags=["Event Tracking"],
)

api_router.include_router(
    admin_analytics.router,
    prefix="/admin/analytics",
    tags=["Admin Analytics"],
)

api_router.include_router(
    ai.router,
    prefix="/ai",
    tags=["AI Pose Analysis"],
)

api_router.include_router(
    workouts.router,
    prefix="/workouts/catalogue",
    tags=["Exercise Catalogue"],
)

api_router.include_router(
    gamification.router,
    prefix="/gamification",
    tags=["Gamification"],
)

api_router.include_router(
    payments.router,
    prefix="/payments",
    tags=["Payments"],
)

api_router.include_router(
    notifications.router,
    prefix="/notifications",
    tags=["Notifications"],
)
