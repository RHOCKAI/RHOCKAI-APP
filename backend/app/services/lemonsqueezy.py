import hmac
import hashlib
import json
import httpx
from fastapi import HTTPException
from app.config import settings

class LemonSqueezyService:
    BASE_URL = "https://api.lemonsqueezy.com/v1"

    @staticmethod
    def verify_webhook_signature(payload: bytes, signature: str) -> bool:
        secret = settings.LEMONSQUEEZY_WEBHOOK_SECRET.encode('utf-8')
        mac = hmac.new(secret, msg=payload, digestmod=hashlib.sha256)
        return hmac.compare_digest(mac.hexdigest(), signature)

    @staticmethod
    async def create_checkout(user_id: int, user_email: str, plan_type: str) -> str:
        if plan_type == "monthly":
            variant_id = settings.LEMONSQUEEZY_VARIANT_ID_MONTHLY
        elif plan_type == "yearly":
            variant_id = settings.LEMONSQUEEZY_VARIANT_ID_YEARLY
        elif plan_type == "lifetime":
            variant_id = settings.LEMONSQUEEZY_VARIANT_ID_LIFETIME
        else:
            raise ValueError(f"Invalid plan type: {plan_type}")

        if not variant_id:
            raise ValueError("Variant ID not configured for this plan")

        headers = {
            "Accept": "application/vnd.api+json",
            "Content-Type": "application/vnd.api+json",
            "Authorization": f"Bearer {settings.LEMONSQUEEZY_API_KEY}"
        }

        payload = {
            "data": {
                "type": "checkouts",
                "attributes": {
                    "checkout_data": {
                        "email": user_email,
                        "custom": {
                            "user_id": str(user_id)
                        }
                    }
                },
                "relationships": {
                    "store": {
                        "data": {
                            "type": "stores",
                            "id": str(settings.LEMONSQUEEZY_STORE_ID)
                        }
                    },
                    "variant": {
                        "data": {
                            "type": "variants",
                            "id": str(variant_id)
                        }
                    }
                }
            }
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{LemonSqueezyService.BASE_URL}/checkouts",
                headers=headers,
                json=payload
            )

            if response.status_code not in (200, 201):
                raise HTTPException(status_code=500, detail=f"Failed to create checkout: {response.text}")

            data = response.json()
            return data["data"]["attributes"]["url"]

    @staticmethod
    async def get_subscription(subscription_id: str) -> dict:
        """Fetch subscription details from Lemon Squeezy"""
        headers = {
            "Accept": "application/vnd.api+json",
            "Content-Type": "application/vnd.api+json",
            "Authorization": f"Bearer {settings.LEMONSQUEEZY_API_KEY}"
        }

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{LemonSqueezyService.BASE_URL}/subscriptions/{subscription_id}",
                headers=headers
            )

            if response.status_code != 200:
                raise HTTPException(status_code=500, detail=f"Failed to fetch subscription: {response.text}")

            return response.json()
