from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_active_user
from app.models.user import User
from app.models.subscription import Subscription, SubscriptionPlan, SubscriptionStatus
from app.services.lemonsqueezy import LemonSqueezyService
from app.services.notifications import notification_manager
import json

router = APIRouter()
ls_service = LemonSqueezyService()

@router.post("/checkout/{plan_type}")
async def create_checkout(
    plan_type: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Create a Lemon Squeezy checkout URL for the specified plan
    plan_type: 'monthly', 'yearly', or 'lifetime'
    """
    try:
        checkout_url = await ls_service.create_checkout(
            user_id=current_user.id,
            user_email=current_user.email,
            plan_type=plan_type
        )
        return {"checkout_url": checkout_url}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Could not create checkout URL")

@router.post("/webhook")
async def lemonsqueezy_webhook(request: Request, db: Session = Depends(get_db)):
    """Handle Lemon Squeezy webhooks"""
    payload = await request.body()
    signature = request.headers.get("X-Signature")
    
    if not signature or not ls_service.verify_webhook_signature(payload, signature):
        raise HTTPException(status_code=401, detail="Invalid signature")

    data = json.loads(payload)
    event_name = data.get("meta", {}).get("event_name")
    custom_data = data.get("meta", {}).get("custom_data", {})
    user_id = custom_data.get("user_id")

    if not user_id:
        # Cannot process without user_id
        return {"status": "ignored", "reason": "No user_id in custom data"}

    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user:
        return {"status": "ignored", "reason": "User not found"}

    attributes = data.get("data", {}).get("attributes", {})
    
    if event_name == "subscription_created":
        # Handle new subscription
        sub = db.query(Subscription).filter(Subscription.user_id == user.id).first()
        if not sub:
            sub = Subscription(user_id=user.id)
            db.add(sub)
        
        sub.lemon_squeezy_customer_id = str(attributes.get("customer_id"))
        sub.lemon_squeezy_subscription_id = str(data.get("data", {}).get("id"))
        sub.status = SubscriptionStatus.ACTIVE
        
        variant_name = attributes.get("variant_name", "").lower()
        if "yearly" in variant_name:
            sub.plan = SubscriptionPlan.YEARLY
        else:
            sub.plan = SubscriptionPlan.MONTHLY
            
        user.is_premium = True
        user.lemon_squeezy_customer_id = str(attributes.get("customer_id"))
        db.commit()

        # Notify user and admin in real-time
        await notification_manager.send_personal_message(
            {"type": "payment_success", "message": f"Your {sub.plan.value} subscription was successful!"}, 
            user.id
        )
        await notification_manager.notify_admins(
            {"type": "admin_payment_alert", "message": f"User {user.email} started a {sub.plan.value} subscription."}
        )

    elif event_name == "order_created":
        # Check if it's a lifetime payment (first 100 users)
        variant_name = attributes.get("first_order_item", {}).get("variant_name", "").lower()
        if "lifetime" in variant_name:
            sub = db.query(Subscription).filter(Subscription.user_id == user.id).first()
            if not sub:
                sub = Subscription(user_id=user.id)
                db.add(sub)
            
            sub.lemon_squeezy_customer_id = str(attributes.get("customer_id"))
            sub.lemon_squeezy_order_id = str(data.get("data", {}).get("id"))
            sub.status = SubscriptionStatus.ACTIVE
            sub.plan = SubscriptionPlan.LIFETIME
            
            user.is_premium = True
            user.lemon_squeezy_customer_id = str(attributes.get("customer_id"))
            db.commit()

            # Notify user and admin in real-time
            await notification_manager.send_personal_message(
                {"type": "payment_success", "message": "Your lifetime purchase was successful!"}, 
                user.id
            )
            await notification_manager.notify_admins(
                {"type": "admin_payment_alert", "message": f"User {user.email} purchased a lifetime plan."}
            )

    elif event_name in ["subscription_cancelled", "subscription_expired"]:
        sub = db.query(Subscription).filter(Subscription.user_id == user.id).first()
        if sub:
            sub.status = SubscriptionStatus.CANCELED if event_name == "subscription_cancelled" else SubscriptionStatus.EXPIRED
            user.is_premium = False
            db.commit()

    return {"status": "success"}