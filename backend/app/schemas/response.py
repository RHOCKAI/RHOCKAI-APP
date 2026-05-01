"""
Standardized API response schemas
"""

from typing import Generic, TypeVar, Optional, Any, List
from pydantic import BaseModel, Field


DataT = TypeVar('DataT')


class BaseResponse(BaseModel):
    success: bool = Field(..., description="Request success status")
    message: Optional[str] = Field(None, description="Response message")


class SuccessResponse(BaseResponse, Generic[DataT]):
    success: bool = True
    data: DataT = Field(..., description="Response data")


class ErrorResponse(BaseResponse):
    success: bool = False
    error: str = Field(..., description="Error message")
    error_code: Optional[str] = None
    details: Optional[Any] = None


class PaginatedResponse(BaseModel, Generic[DataT]):
    success: bool = True
    data: List[DataT]
    total: int
    page: int
    page_size: int
    total_pages: int


class MessageResponse(BaseResponse):
    success: bool = True
    message: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class HealthResponse(BaseModel):
    status: str
    version: str
    environment: str


class StatsResponse(BaseModel):
    total_sessions: int = 0
    total_reps: int = 0
    total_calories: int = 0
    average_accuracy: float = 0.0
    total_duration_minutes: int = 0