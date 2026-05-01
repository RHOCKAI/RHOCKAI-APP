# app/api/v1/endpoints/payments.py

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.deps import get_current_active_user
from app.models.user import User
from app.services.payments.stripe_service import StripeService
from datetime import datetime, timedelta

router = APIRouter()

@router.post("/create-checkout")
async def create_checkout_session(
    plan: str,
    current_user: User = Depends(get_current_active_user),
):
    """Create Stripe checkout session"""
    checkout = await StripeService.create_checkout_session(
        user_email=current_user.email,
        plan=plan
    )
    return checkout

@router.post("/webhook/stripe")
async def stripe_webhook(
    request: Request,
    db: Session = Depends(get_db)
):
    """Handle Stripe webhooks"""
    payload = await request.body()
    sig_header = request.headers.get('stripe-signature')
    
    try:
        event = await StripeService.verify_webhook(payload, sig_header)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    
    # Handle subscription events
    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        
        # Update user subscription
        user = db.query(User).filter(User.email == session['customer_email']).first()
        if user:
            user.is_premium = True
            user.subscription_end = datetime.utcnow() + timedelta(days=30)  # or 365 for yearly
            db.commit()
    
    elif event['type'] == 'customer.subscription.deleted':
        # Handle subscription cancellation
        pass
    
    return {"status": "success"}