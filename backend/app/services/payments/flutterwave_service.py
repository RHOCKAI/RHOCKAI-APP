"""
Flutterwave Payment Service
Handles payment initiation and verification via Flutterwave REST API (v3).
https://developer.flutterwave.com/docs
"""

import logging
from typing import Optional

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

FLUTTERWAVE_BASE_URL = "https://api.flutterwave.com/v3"


class FlutterwaveService:
    """Service for Flutterwave payment operations."""

    def __init__(self):
        self.secret_key = settings.FLUTTERWAVE_SECRET_KEY
        self.headers = {
            "Authorization": f"Bearer {self.secret_key}",
            "Content-Type": "application/json",
        }

    # -------------------------------------------------------------------------
    # Payment Initiation
    # -------------------------------------------------------------------------

    async def initiate_payment(
        self,
        tx_ref: str,
        amount: float,
        currency: str,
        customer_email: str,
        customer_name: str,
        redirect_url: str,
        plan_name: str = "premium",
        meta: Optional[dict] = None,
    ) -> dict:
        """
        Create a hosted payment link via Flutterwave's Standard endpoint.

        Returns the payment link URL that the Flutter app opens in a WebView.

        Args:
            tx_ref: Unique transaction reference (store this for verification).
            amount: Charge amount in `currency` units.
            currency: Three-letter ISO currency code e.g. "USD", "NGN", "KES".
            customer_email: Payer's email address.
            customer_name: Payer's full name.
            redirect_url: URL Flutterwave redirects back to after payment.
            plan_name: Descriptive name shown on the payment page.
            meta: Optional extra data dict attached to the transaction.

        Returns:
            dict with keys: `status`, `link` (payment URL).

        Raises:
            httpx.HTTPStatusError: on 4xx/5xx from Flutterwave API.
            RuntimeError: if FLUTTERWAVE_SECRET_KEY is not configured.
        """
        if not self.secret_key:
            raise RuntimeError(
                "FLUTTERWAVE_SECRET_KEY is not configured. "
                "Set it in your .env file."
            )

        payload = {
            "tx_ref": tx_ref,
            "amount": amount,
            "currency": currency,
            "redirect_url": redirect_url,
            "payment_options": "card,mobilemoney,ussd",
            "customer": {
                "email": customer_email,
                "name": customer_name,
            },
            "customizations": {
                "title": "AI Workout Tracker",
                "description": f"{plan_name} subscription",
                "logo": "https://aiworkouttracker.com/logo.png",
            },
            "meta": meta or {},
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{FLUTTERWAVE_BASE_URL}/payments",
                json=payload,
                headers=self.headers,
            )
            response.raise_for_status()

        data = response.json()
        logger.info(
            "Flutterwave payment initiated: tx_ref=%s status=%s",
            tx_ref,
            data.get("status"),
        )
        return {
            "status": data.get("status"),
            "link": data.get("data", {}).get("link"),
            "tx_ref": tx_ref,
        }

    # -------------------------------------------------------------------------
    # Payment Verification
    # -------------------------------------------------------------------------

    async def verify_payment(self, transaction_id: str) -> dict:
        """
        Verify a completed Flutterwave transaction by its transaction ID.

        Call this after the user is redirected back from the payment page,
        or when Flutterwave sends a webhook event.

        Args:
            transaction_id: The `transaction_id` returned by Flutterwave
                            in the redirect URL query params.

        Returns:
            dict with keys: `status` ("successful"|"failed"|"pending"),
                            `amount`, `currency`, `customer_email`, `tx_ref`.

        Raises:
            httpx.HTTPStatusError: on 4xx/5xx from Flutterwave API.
            RuntimeError: if FLUTTERWAVE_SECRET_KEY is not configured.
        """
        if not self.secret_key:
            raise RuntimeError(
                "FLUTTERWAVE_SECRET_KEY is not configured. "
                "Set it in your .env file."
            )

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(
                f"{FLUTTERWAVE_BASE_URL}/transactions/{transaction_id}/verify",
                headers=self.headers,
            )
            response.raise_for_status()

        data = response.json().get("data", {})
        status = data.get("status", "unknown")

        logger.info(
            "Flutterwave transaction verified: id=%s status=%s amount=%s %s",
            transaction_id,
            status,
            data.get("amount"),
            data.get("currency"),
        )

        return {
            "status": status,
            "amount": data.get("amount"),
            "currency": data.get("currency"),
            "customer_email": data.get("customer", {}).get("email"),
            "tx_ref": data.get("tx_ref"),
            "transaction_id": transaction_id,
        }

    # -------------------------------------------------------------------------
    # Webhook Signature Verification
    # -------------------------------------------------------------------------

    def verify_webhook_signature(
        self, payload_hash: str, secret_hash: Optional[str] = None
    ) -> bool:
        """
        Verify the `verif-hash` header on incoming Flutterwave webhooks.

        Set your FLUTTERWAVE_SECRET_KEY as the webhook secret hash in the
        Flutterwave dashboard under Settings → Webhooks.

        Args:
            payload_hash: The value of the `verif-hash` request header.
            secret_hash: Override secret (defaults to FLUTTERWAVE_SECRET_KEY).

        Returns:
            True if the hash matches, False otherwise.
        """
        expected = secret_hash or self.secret_key
        return payload_hash == expected


# Module-level singleton
flutterwave_service = FlutterwaveService()
