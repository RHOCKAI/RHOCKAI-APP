"""
Admin Analytics API endpoints
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, Integer, cast
from datetime import datetime, timedelta
from typing import List, Dict, Any

from app.core.database import get_db
from app.api.deps import get_admin_user
from app.models.user import User
from app.models.analytics import (
    AppSession, ScreenView, FeatureUsage, 
    UserDemographic, SubscriptionEvent, RevenueRecord, ErrorLog, RetentionCohort
)
from app.models.subscription import Subscription
from app.schemas.analytics import DashboardResponse

router = APIRouter()

@router.get("/dashboard", response_model=DashboardResponse)
async def get_admin_dashboard(
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    """
    Complete admin dashboard - all metrics in one call
    """
    today = datetime.utcnow().date()
    week_ago = datetime.utcnow() - timedelta(days=7)
    month_ago = datetime.utcnow() - timedelta(days=30)
    
    # -- USER METRICS --
    total_users = db.query(func.count(User.id)).scalar()
    
    new_today = db.query(func.count(User.id)).filter(
        func.date(User.created_at) == today
    ).scalar()
    
    new_this_week = db.query(func.count(User.id)).filter(
        User.created_at >= week_ago
    ).scalar()
    
    new_this_month = db.query(func.count(User.id)).filter(
        User.created_at >= month_ago
    ).scalar()
    
    dau = db.query(func.count(func.distinct(AppSession.user_id))).filter(
        func.date(AppSession.session_start) == today
    ).scalar()
    
    mau = db.query(func.count(func.distinct(AppSession.user_id))).filter(
        AppSession.session_start >= month_ago
    ).scalar()
    
    # -- REVENUE METRICS --
    mrr = db.query(func.sum(RevenueRecord.mrr_contribution)).filter(
        RevenueRecord.revenue_type == "subscription",
        RevenueRecord.recorded_at >= month_ago
    ).scalar() or 0.0
    
    arr = mrr * 12
    
    revenue_today = db.query(func.sum(RevenueRecord.amount_usd)).filter(
        func.date(RevenueRecord.recorded_at) == today
    ).scalar() or 0.0
    
    revenue_month = db.query(func.sum(RevenueRecord.amount_usd)).filter(
        RevenueRecord.recorded_at >= month_ago
    ).scalar() or 0.0
    
    # -- SUBSCRIPTION METRICS --
    monthly_subs = db.query(func.count(Subscription.id)).filter(
        Subscription.plan == "monthly",
        Subscription.status == "active"
    ).scalar()
    
    yearly_subs = db.query(func.count(Subscription.id)).filter(
        Subscription.plan == "yearly",
        Subscription.status == "active"
    ).scalar()
    
    lifetime_subs = db.query(func.count(Subscription.id)).filter(
        Subscription.plan == "lifetime",
        Subscription.status == "active"
    ).scalar()
    
    total_paying = monthly_subs + yearly_subs + lifetime_subs
    conversion_rate = round((total_paying / total_users * 100), 2) if total_users > 0 else 0
    
    active_trials = db.query(func.count(Subscription.id)).filter(
        Subscription.status == "trialing"
    ).scalar()
    
    churned = db.query(func.count(SubscriptionEvent.id)).filter(
        SubscriptionEvent.event_type == "cancelled",
        SubscriptionEvent.occurred_at >= month_ago
    ).scalar()
    
    churn_rate = round((churned / total_paying * 100), 2) if total_paying > 0 else 0
    
    # -- ENGAGEMENT METRICS --
    avg_session_duration = db.query(
        func.avg(AppSession.duration_seconds)
    ).filter(
        AppSession.session_start >= month_ago,
        AppSession.duration_seconds.isnot(None)
    ).scalar() or 0
    
    sessions_per_day = db.query(
        func.count(AppSession.id)
    ).filter(
        AppSession.session_start >= month_ago
    ).scalar() / 30 if db.query(AppSession.id).first() else 0
    
    # -- TOP SCREENS --
    top_screens = db.query(
        ScreenView.screen_name,
        func.count(ScreenView.id).label("views")
    ).filter(
        ScreenView.viewed_at >= month_ago
    ).group_by(
        ScreenView.screen_name
    ).order_by(
        func.count(ScreenView.id).desc()
    ).limit(10).all()
    
    # -- DISTRIBUTIONS --
    age_distribution = db.query(
        UserDemographic.age_range,
        func.count(UserDemographic.id).label("count")
    ).group_by(UserDemographic.age_range).all()
    
    gender_distribution = db.query(
        UserDemographic.gender,
        func.count(UserDemographic.id).label("count")
    ).group_by(UserDemographic.gender).all()
    
    fitness_goals = db.query(
        UserDemographic.fitness_goal,
        func.count(UserDemographic.id).label("count")
    ).group_by(UserDemographic.fitness_goal).all()
    
    country_distribution = db.query(
        UserDemographic.country,
        func.count(UserDemographic.id).label("count")
    ).group_by(UserDemographic.country).order_by(func.count(UserDemographic.id).desc()).limit(10).all()
    
    os_distribution = db.query(
        AppSession.os_name,
        func.count(func.distinct(AppSession.user_id)).label("users")
    ).group_by(AppSession.os_name).all()
    
    device_distribution = db.query(
        AppSession.device_model,
        func.count(func.distinct(AppSession.user_id)).label("users")
    ).group_by(AppSession.device_model).order_by(func.count(func.distinct(AppSession.user_id)).desc()).limit(10).all()
    
    cancellation_reasons = db.query(
        SubscriptionEvent.cancellation_reason,
        func.count(SubscriptionEvent.id).label("count")
    ).filter(
        SubscriptionEvent.event_type == "cancelled",
        SubscriptionEvent.cancellation_reason.isnot(None)
    ).group_by(SubscriptionEvent.cancellation_reason).all()
    
    feature_usage = db.query(
        FeatureUsage.feature_name,
        func.count(FeatureUsage.id).label("total_uses"),
        func.count(func.distinct(FeatureUsage.user_id)).label("unique_users")
    ).filter(FeatureUsage.used_at >= month_ago).group_by(FeatureUsage.feature_name).all()
    
    acquisition_channels = db.query(
        UserDemographic.how_found_app,
        func.count(UserDemographic.id).label("count")
    ).group_by(UserDemographic.how_found_app).all()
    
    return {
        "generated_at": datetime.utcnow(),
        "users": {
            "total": total_users,
            "new_today": new_today,
            "new_this_week": new_this_week,
            "new_this_month": new_this_month,
            "dau": dau,
            "mau": mau,
            "dau_mau_ratio": round(dau / mau * 100, 2) if mau > 0 else 0,
        },
        "revenue": {
            "mrr": round(mrr, 2),
            "arr": round(arr, 2),
            "today": round(revenue_today, 2),
            "this_month": round(revenue_month, 2),
        },
        "subscriptions": {
            "total_paying": total_paying,
            "monthly": monthly_subs,
            "yearly": yearly_subs,
            "lifetime": lifetime_subs,
            "active_trials": active_trials,
            "conversion_rate_pct": conversion_rate,
            "churn_rate_pct": churn_rate,
            "churned_this_month": churned,
        },
        "engagement": {
            "avg_session_duration_seconds": round(avg_session_duration),
            "avg_sessions_per_day": round(sessions_per_day, 1),
        },
        "demographics": {
            "age": [{"range": r.age_range, "count": r.count} for r in age_distribution],
            "gender": [{"gender": r.gender, "count": r.count} for r in gender_distribution],
            "fitness_goals": [{"goal": r.fitness_goal, "count": r.count} for r in fitness_goals],
            "top_countries": [{"country": r.country, "count": r.count} for r in country_distribution],
        },
        "devices": {
            "os": [{"os": r.os_name, "users": r.users} for r in os_distribution],
            "top_models": [{"model": r.device_model, "users": r.users} for r in device_distribution],
        },
        "behavior": {
            "top_screens": [{"screen": r.screen_name, "views": r.views} for r in top_screens],
            "feature_usage": [
                {"feature": r.feature_name, "total_uses": r.total_uses, "unique_users": r.unique_users} 
                for r in feature_usage
            ],
            "acquisition_channels": [{"channel": r.how_found_app, "count": r.count} for r in acquisition_channels],
        },
        "churn": {
            "reasons": [{"reason": r.cancellation_reason, "count": r.count} for r in cancellation_reasons]
        },
    }

@router.get("/revenue/chart")
async def get_revenue_chart(
    days: int = 30,
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    """Daily revenue chart for last N days"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    daily_revenue = db.query(
        func.date(RevenueRecord.recorded_at).label("date"),
        func.sum(RevenueRecord.amount_usd).label("revenue"),
        func.count(RevenueRecord.id).label("transactions")
    ).filter(
        RevenueRecord.recorded_at >= start_date
    ).group_by(func.date(RevenueRecord.recorded_at)).order_by(func.date(RevenueRecord.recorded_at)).all()
    
    return {
        "data": [
            {"date": str(r.date), "revenue": round(r.revenue or 0, 2), "transactions": r.transactions}
            for r in daily_revenue
        ]
    }

@router.get("/users/growth")
async def get_user_growth(
    days: int = 30,
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    """Daily user signups for last N days"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    daily_signups = db.query(
        func.date(User.created_at).label("date"),
        func.count(User.id).label("new_users")
    ).filter(User.created_at >= start_date).group_by(func.date(User.created_at)).order_by(func.date(User.created_at)).all()
    
    cumulative = 0
    result = []
    for row in daily_signups:
        cumulative += row.new_users
        result.append({
            "date": str(row.date),
            "new_users": row.new_users,
            "total_users": cumulative
        })
    
    return {"data": result}

@router.get("/retention")
async def get_retention(
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    """Cohort retention analysis"""
    cohorts = db.query(
        RetentionCohort.cohort_month,
        func.count(RetentionCohort.id).label("cohort_size"),
        func.sum(cast(RetentionCohort.week_1_active, Integer)).label("week_1"),
        func.sum(cast(RetentionCohort.week_2_active, Integer)).label("week_2"),
        func.sum(cast(RetentionCohort.week_4_active, Integer)).label("week_4"),
        func.sum(cast(RetentionCohort.week_8_active, Integer)).label("week_8"),
    ).group_by(RetentionCohort.cohort_month).order_by(RetentionCohort.cohort_month.desc()).limit(12).all()
    
    return {
        "data": [
            {
                "cohort": r.cohort_month,
                "size": r.cohort_size,
                "week_1_retention": round(r.week_1 / r.cohort_size * 100, 1) if r.cohort_size > 0 else 0,
                "week_2_retention": round(r.week_2 / r.cohort_size * 100, 1) if r.cohort_size > 0 else 0,
                "week_4_retention": round(r.week_4 / r.cohort_size * 100, 1) if r.cohort_size > 0 else 0,
                "week_8_retention": round(r.week_8 / r.cohort_size * 100, 1) if r.cohort_size > 0 else 0,
            }
            for r in cohorts
        ]
    }

@router.get("/errors")
async def get_error_report(
    days: int = 7,
    admin: User = Depends(get_admin_user),
    db: Session = Depends(get_db),
):
    """Error monitoring report"""
    start_date = datetime.utcnow() - timedelta(days=days)
    
    errors = db.query(
        ErrorLog.error_type,
        ErrorLog.error_message,
        ErrorLog.screen,
        ErrorLog.os_name,
        func.count(ErrorLog.id).label("occurrences"),
        func.max(ErrorLog.occurred_at).label("last_seen")
    ).filter(ErrorLog.occurred_at >= start_date).group_by(
        ErrorLog.error_type, ErrorLog.error_message, ErrorLog.screen, ErrorLog.os_name
    ).order_by(func.count(ErrorLog.id).desc()).limit(50).all()
    
    return {
        "data": [
            {
                "type": r.error_type,
                "message": r.error_message[:100],
                "screen": r.screen,
                "os": r.os_name,
                "occurrences": r.occurrences,
                "last_seen": r.last_seen.isoformat() if r.last_seen else None
            }
            for r in errors
        ]
    }
