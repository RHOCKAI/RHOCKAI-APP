"""
Analytics Schemas
"""

from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime

class TrackSessionRequest(BaseModel):
    session_id: str
    device_type: str
    device_model: str
    os_name: str
    os_version: str
    app_version: str
    country: Optional[str] = None
    city: Optional[str] = None
    timezone: Optional[str] = None
    connection_type: Optional[str] = "wifi"


class EndSessionRequest(BaseModel):
    session_id: str
    duration_seconds: int


class TrackScreenRequest(BaseModel):
    session_id: str
    screen_name: str
    previous_screen: Optional[str] = None
    time_on_screen: Optional[int] = None
    extra_data: Optional[Dict[str, Any]] = None


class TrackFeatureRequest(BaseModel):
    feature_name: str
    action: str
    extra_data: Optional[Dict[str, Any]] = None


class UpdateDemographicRequest(BaseModel):
    age_range: Optional[str] = None
    gender: Optional[str] = None
    fitness_level: Optional[str] = None
    fitness_goal: Optional[str] = None
    how_found_app: Optional[str] = None


class TrackErrorRequest(BaseModel):
    error_type: str
    error_message: str
    stack_trace: Optional[str] = None
    screen: Optional[str] = None
    app_version: Optional[str] = None
    os_name: Optional[str] = None
    os_version: Optional[str] = None
    device_model: Optional[str] = None


class TrackCancellationRequest(BaseModel):
    subscription_id: str
    reason: str

# Admin Dashboard Response Schemas

class MetricCount(BaseModel):
    range: Optional[str] = None
    gender: Optional[str] = None
    goal: Optional[str] = None
    country: Optional[str] = None
    os: Optional[str] = None
    model: Optional[str] = None
    channel: Optional[str] = None
    reason: Optional[str] = None
    count: Optional[int] = None
    users: Optional[int] = None

class ScreenStats(BaseModel):
    screen: str
    views: int

class FeatureUsageStats(BaseModel):
    feature: str
    total_uses: int
    unique_users: int

class DashboardResponse(BaseModel):
    generated_at: datetime
    users: Dict[str, Any]
    revenue: Dict[str, Any]
    subscriptions: Dict[str, Any]
    engagement: Dict[str, Any]
    demographics: Dict[str, List[MetricCount]]
    devices: Dict[str, List[MetricCount]]
    behavior: Dict[str, Any]
    churn: Dict[str, List[MetricCount]]
