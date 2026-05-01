# app/services/payments/stripe_service.py

import stripe
from app.core.config import settings
from typing import Dict

stripe.api_key = settings.STRIPE_SECRET_KEY

class StripeService:
    """Stripe payment integration"""
    
    @staticmethod
    async def create_checkout_session(
        user_email: str,
        plan: str = "monthly"
    ) -> Dict:
        """Create Stripe checkout session"""
        prices = {
            "monthly": "price_monthly_id",  # Replace with actual price ID
            "yearly": "price_yearly_id",
        }
        
        session = stripe.checkout.Session.create(
            customer_email=user_email,
            payment_method_types=['card'],
            line_items=[{
                'price': prices.get(plan, prices["monthly"]),
                'quantity': 1,
            }],
            mode='subscription',
            success_url='https://yourapp.com/success?session_id={CHECKOUT_SESSION_ID}',
            cancel_url='https://yourapp.com/cancel',
        )
        
        return {
            "checkout_url": session.url,
            "session_id": session.id
        }
    
    @staticmethod
    async def verify_webhook(payload: bytes, sig_header: str) -> Dict:
        """Verify Stripe webhook signature"""
        try:
            event = stripe.Webhook.construct_event(
                payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
            )
            return event
        except ValueError:
            raise ValueError("Invalid payload")
        except stripe.error.SignatureVerificationError:
            raise ValueError("Invalid signature")