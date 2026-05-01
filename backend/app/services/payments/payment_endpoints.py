"""
Payment Endpoints for AI Workout Tracker
Handles Stripe and Flutterwave payment integration
"""

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime, timedelta
import stripe
import os

from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.subscription import Subscription, SubscriptionPlan, SubscriptionStatus

router = APIRouter()

# ==================== STRIPE CONFIGURATION ====================

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")

# Price IDs from Stripe Dashboard
STRIPE_PRICE_IDS = {
    "monthly": os.getenv("STRIPE_PRICE_MONTHLY"),
    "yearly": os.getenv("STRIPE_PRICE_YEARLY"),
    "lifetime": os.getenv("STRIPE_PRICE_LIFETIME"),
}

# ==================== REQUEST/RESPONSE MODELS ====================

class SubscribeRequest(BaseModel):
    plan: str  # monthly, yearly, lifetime
    payment_method: str  # stripe, flutterwave
    success_url: Optional[str] = None
    cancel_url: Optional[str] = None

class StripeCheckoutRequest(BaseModel):
    plan: str
    success_url: str = "https://yourapp.com/payment/success"
    cancel_url: str = "https://yourapp.com/payment/cancel"

class FlutterwaveInitRequest(BaseModel):
    plan: str
    email: EmailStr
    phone_number: str
    redirect_url: str = "https://yourapp.com/payment/callback"

class CancelSubscriptionRequest(BaseModel):
    subscription_id: str

class UpdateSubscriptionRequest(BaseModel):
    subscription_id: str
    new_plan: str

# ==================== STRIPE ENDPOINTS ====================

@router.post("/stripe/checkout")
async def create_stripe_checkout(
    request: StripeCheckoutRequest,
    current_user: User = Depends(get_current_user),
    db = Depends(get_db)
):
    """Create a Stripe Checkout session"""
    try:
        # Get or create Stripe customer
        customer_id = current_user.stripe_customer_id
        
        if not customer_id:
            customer = stripe.Customer.create(
                email=current_user.email,
                metadata={"user_id": str(current_user.id)}
            )
            customer_id = customer.id
            
            # Update user with Stripe customer ID
            current_user.stripe_customer_id = customer_id
            db.commit()
        
        # Get price ID for the plan
        price_id = STRIPE_PRICE_IDS.get(request.plan)
        if not price_id:
            raise HTTPException(status_code=400, detail="Invalid plan")
        
        # Create checkout session
        checkout_session = stripe.checkout.Session.create(
            customer=customer_id,
            payment_method_types=['card'],
            line_items=[{
                'price': price_id,
                'quantity': 1,
            }],
            mode='subscription' if request.plan != 'lifetime' else 'payment',
            success_url=request.success_url,
            cancel_url=request.cancel_url,
            subscription_data={
                'trial_period_days': 7,  # 7-day free trial
                'metadata': {
                    'user_id': str(current_user.id),
                    'plan': request.plan,
                }
            } if request.plan != 'lifetime' else None,
        )
        
        return {
            "session_id": checkout_session.id,
            "checkout_url": checkout_session.url,
            "public_key": os.getenv("STRIPE_PUBLIC_KEY"),
        }
        
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create checkout: {str(e)}")


@router.post("/stripe/webhook")
async def stripe_webhook(request: Request, db = Depends(get_db)):
    """Handle Stripe webhooks"""
    payload = await request.body()
    sig_header = request.headers.get('stripe-signature')
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    # Handle different event types
    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        await _handle_checkout_completed(session, db)
        
    elif event['type'] == 'customer.subscription.updated':
        subscription = event['data']['object']
        await _handle_subscription_updated(subscription, db)
        
    elif event['type'] == 'customer.subscription.deleted':
        subscription = event['data']['object']
        await _handle_subscription_deleted(subscription, db)
        
    elif event['type'] == 'invoice.payment_failed':
        invoice = event['data']['object']
        await _handle_payment_failed(invoice, db)
    
    return {"status": "success"}


async def _handle_checkout_completed(session, db):
    """Handle successful checkout"""
    user_id = session.get('metadata', {}).get('user_id')
    plan = session.get('metadata', {}).get('plan')
    
    if not user_id:
        return
    
    # Create or update subscription
    subscription = db.query(Subscription).filter(
        Subscription.user_id == user_id
    ).first()
    
    if subscription:
        subscription.plan = plan
        subscription.status = SubscriptionStatus.ACTIVE
        subscription.stripe_subscription_id = session.get('subscription')
        subscription.current_period_end = datetime.fromtimestamp(
            session.get('subscription', {}).get('current_period_end', 0)
        )
    else:
        subscription = Subscription(
            user_id=user_id,
            plan=plan,
            status=SubscriptionStatus.ACTIVE,
            stripe_subscription_id=session.get('subscription'),
            current_period_end=datetime.fromtimestamp(
                session.get('subscription', {}).get('current_period_end', 0)
            )
        )
        db.add(subscription)
    
    # Update user premium status
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user.is_premium = True
    
    db.commit()


async def _handle_subscription_updated(subscription_data, db):
    """Handle subscription updates"""
    stripe_sub_id = subscription_data['id']
    
    subscription = db.query(Subscription).filter(
        Subscription.stripe_subscription_id == stripe_sub_id
    ).first()
    
    if subscription:
        subscription.status = subscription_data['status']
        subscription.current_period_end = datetime.fromtimestamp(
            subscription_data['current_period_end']
        )
        db.commit()


async def _handle_subscription_deleted(subscription_data, db):
    """Handle subscription cancellation"""
    stripe_sub_id = subscription_data['id']
    
    subscription = db.query(Subscription).filter(
        Subscription.stripe_subscription_id == stripe_sub_id
    ).first()
    
    if subscription:
        subscription.status = SubscriptionStatus.CANCELLED
        
        # Update user premium status
        user = db.query(User).filter(User.id == subscription.user_id).first()
        if user:
            user.is_premium = False
        
        db.commit()


async def _handle_payment_failed(invoice, db):
    """Handle failed payment"""
    customer_id = invoice['customer']
    
    # Find user by Stripe customer ID
    user = db.query(User).filter(User.stripe_customer_id == customer_id).first()
    if user:
        # Send email notification about failed payment
        # You can integrate with your email service here
        pass


# ==================== FLUTTERWAVE ENDPOINTS ====================

@router.post("/flutterwave/init")
async def initialize_flutterwave_payment(
    request: FlutterwaveInitRequest,
    current_user: User = Depends(get_current_user),
):
    """Initialize Flutterwave payment"""
    try:
        import requests
        
        FLW_SECRET_KEY = os.getenv("FLUTTERWAVE_SECRET_KEY")
        
        # Plan prices
        plan_prices = {
            "monthly": 9.99,
            "yearly": 79.99,
            "lifetime": 199.99,
        }
        
        amount = plan_prices.get(request.plan)
        if not amount:
            raise HTTPException(status_code=400, detail="Invalid plan")
        
        # Generate unique transaction reference
        tx_ref = f"WORKOUT_{current_user.id}_{int(datetime.now().timestamp())}"
        
        # Initialize payment
        payload = {
            "tx_ref": tx_ref,
            "amount": amount,
            "currency": "USD",
            "redirect_url": request.redirect_url,
            "payment_options": "card,mobilemoney,ussd",
            "customer": {
                "email": request.email,
                "phonenumber": request.phone_number,
                "name": current_user.full_name or "User",
            },
            "customizations": {
                "title": "AI Workout Tracker Premium",
                "description": f"{request.plan.title()} Subscription",
                "logo": "https://yourapp.com/logo.png",
            },
            "meta": {
                "user_id": str(current_user.id),
                "plan": request.plan,
            }
        }
        
        headers = {
            "Authorization": f"Bearer {FLW_SECRET_KEY}",
            "Content-Type": "application/json",
        }
        
        response = requests.post(
            "https://api.flutterwave.com/v3/payments",
            json=payload,
            headers=headers,
        )
        
        if response.status_code != 200:
            raise HTTPException(
                status_code=400,
                detail="Failed to initialize payment"
            )
        
        data = response.json()
        
        return {
            "payment_link": data['data']['link'],
            "transaction_id": data['data']['id'],
            "reference": tx_ref,
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Payment initialization failed: {str(e)}"
        )


@router.post("/flutterwave/verify")
async def verify_flutterwave_payment(
    transaction_id: str,
    current_user: User = Depends(get_current_user),
    db = Depends(get_db),
):
    """Verify Flutterwave payment"""
    try:
        import requests
        
        FLW_SECRET_KEY = os.getenv("FLUTTERWAVE_SECRET_KEY")
        
        headers = {
            "Authorization": f"Bearer {FLW_SECRET_KEY}",
        }
        
        response = requests.get(
            f"https://api.flutterwave.com/v3/transactions/{transaction_id}/verify",
            headers=headers,
        )
        
        if response.status_code != 200:
            return {"success": False, "message": "Verification failed"}
        
        data = response.json()
        
        if data['data']['status'] == 'successful':
            # Create subscription
            plan = data['data']['meta']['plan']
            
            subscription = Subscription(
                user_id=current_user.id,
                plan=plan,
                status=SubscriptionStatus.ACTIVE,
                flutterwave_transaction_id=transaction_id,
                current_period_end=datetime.now() + timedelta(
                    days=365 if plan == 'yearly' else 30
                ),
            )
            db.add(subscription)
            
            # Update user
            current_user.is_premium = True
            db.commit()
            
            return {"success": True, "message": "Payment verified"}
        else:
            return {"success": False, "message": "Payment not successful"}
            
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Verification failed: {str(e)}"
        )


# ==================== SUBSCRIPTION MANAGEMENT ====================

@router.post("/subscribe")
async def create_subscription(
    request: SubscribeRequest,
    current_user: User = Depends(get_current_user),
    db = Depends(get_db),
):
    """Create a new subscription (unified endpoint)"""
    if request.payment_method == "stripe":
        checkout_request = StripeCheckoutRequest(
            plan=request.plan,
            success_url=request.success_url or "https://yourapp.com/success",
            cancel_url=request.cancel_url or "https://yourapp.com/cancel",
        )
        return await create_stripe_checkout(checkout_request, current_user, db)
    else:
        raise HTTPException(
            status_code=400,
            detail="Only Stripe is supported via this endpoint. Use /flutterwave/init for Flutterwave."
        )


@router.post("/cancel")
async def cancel_subscription(
    request: CancelSubscriptionRequest,
    current_user: User = Depends(get_current_user),
    db = Depends(get_db),
):
    """Cancel subscription"""
    try:
        subscription = db.query(Subscription).filter(
            Subscription.id == request.subscription_id,
            Subscription.user_id == current_user.id,
        ).first()
        
        if not subscription:
            raise HTTPException(status_code=404, detail="Subscription not found")
        
        # Cancel on Stripe
        if subscription.stripe_subscription_id:
            stripe.Subscription.modify(
                subscription.stripe_subscription_id,
                cancel_at_period_end=True,
            )
        
        # Update local status
        subscription.status = SubscriptionStatus.CANCELLED
        db.commit()
        
        return {"message": "Subscription cancelled successfully"}
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Cancellation failed: {str(e)}"
        )


@router.get("/status")
async def get_subscription_status(
    current_user: User = Depends(get_current_user),
    db = Depends(get_db),
):
    """Get current subscription status"""
    subscription = db.query(Subscription).filter(
        Subscription.user_id == current_user.id
    ).first()
    
    if not subscription:
        return {
            "is_active": False,
            "plan": "free",
            "is_trialing": False,
            "will_renew": False,
        }
    
    return {
        "is_active": subscription.status == SubscriptionStatus.ACTIVE,
        "plan": subscription.plan,
        "expires_at": subscription.current_period_end.isoformat() if subscription.current_period_end else None,
        "is_trialing": subscription.status == SubscriptionStatus.TRIALING,
        "will_renew": subscription.status == SubscriptionStatus.ACTIVE,
        "cancel_at": subscription.cancel_at.isoformat() if subscription.cancel_at else None,
    }


@router.get("/history")
async def get_payment_history(
    page: int = 1,
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db = Depends(get_db),
):
    """Get payment history"""
    # This would query your payment_transactions table
    # Placeholder implementation
    return {
        "payments": [],
        "total": 0,
        "page": page,
        "limit": limit,
    }


@router.post("/restore")
async def restore_purchases(
    current_user: User = Depends(get_current_user),
    db = Depends(get_db),
):
    """Restore purchases (for app store purchases)"""
    # Check if user has active subscription
    subscription = db.query(Subscription).filter(
        Subscription.user_id == current_user.id,
        Subscription.status == SubscriptionStatus.ACTIVE,
    ).first()
    
    if subscription:
        return {
            "purchases": [{
                "purchase_id": str(subscription.id),
                "plan": subscription.plan,
                "purchase_date": subscription.created_at.isoformat(),
                "status": subscription.status,
            }]
        }
    
    return {"purchases": []}