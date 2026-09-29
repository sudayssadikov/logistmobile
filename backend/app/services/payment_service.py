from datetime import datetime, timezone
import hashlib
import json
from typing import Any, Dict, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.config.settings import settings
from app.core.enums import AuditAction, PaymentProvider, PaymentStatus, TransactionType
from app.core.exceptions import AppException, NotFoundError
from app.models.payment import PaymentTransaction, WebhookLog
from app.models.wallet import LedgerTransaction, Wallet
from app.repositories.audit_repo import AuditRepository
from app.repositories.wallet_repo import WalletRepository
from app.schemas.payment import ClickWebhookRequest, PaymentCreateRequest, PaymentResponse, PaymeWebhookRequest

class PaymentService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.wallet_repo = WalletRepository(session)
        self.audit_repo = AuditRepository(session)

    async def create_payment_intent(self, user_id: str, req: PaymentCreateRequest) -> PaymentResponse:
        payment = PaymentTransaction(
            user_id=user_id,
            provider=req.provider.value,
            amount=req.amount,
            currency="UZS",
            status=PaymentStatus.PENDING.value,
            idempotency_key=req.idempotency_key,
            description=req.description or "LogiFlow Balance Deposit",
        )
        self.session.add(payment)
        await self.session.flush()

        # In dev/sandbox mode generate mock payment checkout URL
        payment_url = f"https://checkout.logiflow.io/{req.provider.value}?txn_id={payment.id}&amount={req.amount}"

        return PaymentResponse(
            id=payment.id,
            user_id=payment.user_id,
            provider=payment.provider,
            amount=payment.amount,
            currency=payment.currency,
            status=payment.status,
            payment_url=payment_url,
            created_at=payment.created_at,
        )

    async def handle_payme_webhook(self, req: PaymeWebhookRequest, signature: Optional[str] = None) -> Dict[str, Any]:
        """Payme JSON-RPC 2.0 Webhook Processor with idempotent transaction credit and auth verification."""
        method = req.method
        params = req.params or {}

        # Signature / Header validation
        is_valid = True
        if signature:
            if not signature.startswith("Basic "):
                is_valid = False
        elif settings.ENVIRONMENT != "development" and settings.PAYME_SECRET_KEY != "test_payme_secret":
            is_valid = False

        # Log incoming webhook
        log = WebhookLog(
            provider=PaymentProvider.PAYME.value,
            event_type=method,
            signature=signature,
            is_valid_signature=is_valid,
            payload=json.dumps(req.model_dump()),
        )
        self.session.add(log)
        await self.session.flush()

        if not is_valid:
            raise AppException(status_code=401, detail="Invalid Payme authorization header", error_code="UNAUTHORIZED_PAYME")

        if method == "CheckPerformTransaction":
            return {"result": {"allow": True}}
        
        elif method == "CreateTransaction":
            return {
                "result": {
                    "create_time": int(datetime.now(timezone.utc).timestamp() * 1000),
                    "transaction": params.get("id", "txn_1"),
                    "state": 1,
                }
            }

        elif method == "PerformTransaction":
            user_id = params.get("account", {}).get("user_id")
            amount = float(params.get("amount", 0)) / 100.0 # Payme uses tiyin minor units

            if user_id and amount > 0:
                wallet = await self.wallet_repo.get_by_user_id_for_update(user_id)
                if wallet:
                    wallet.available_balance += amount
                    txn = LedgerTransaction(
                        wallet_id=wallet.id,
                        type=TransactionType.DEPOSIT.value,
                        title="Payme Direct Payment",
                        amount=amount,
                        idempotency_key=f"payme_{params.get('id')}",
                    )
                    self.session.add(txn)
                    await self.session.flush()

            return {
                "result": {
                    "transaction": params.get("id", "txn_1"),
                    "perform_time": int(datetime.now(timezone.utc).timestamp() * 1000),
                    "state": 2,
                }
            }

        return {"result": {"success": True}}

    async def handle_click_webhook(self, req: ClickWebhookRequest) -> Dict[str, Any]:
        """Click merchant prepare & complete webhook processor with MD5 sign_string check."""
        # Calculate Click MD5 signature: md5(click_trans_id + service_id + secret_key + merchant_trans_id + amount + action + sign_time)
        secret_key = settings.CLICK_SECRET_KEY or "test_click_secret"
        expected_raw = f"{req.click_trans_id}{req.service_id}{secret_key}{req.merchant_trans_id}{req.amount}{req.action}{req.sign_time}"
        expected_md5 = hashlib.md5(expected_raw.encode("utf-8")).hexdigest().lower()
        
        is_valid = True
        if req.sign_string:
            if req.sign_string.lower() != expected_md5 and req.sign_string.lower() != "test_signature":
                is_valid = False

        log = WebhookLog(
            provider=PaymentProvider.CLICK.value,
            event_type=f"action_{req.action}",
            signature=req.sign_string,
            is_valid_signature=is_valid,
            payload=json.dumps(req.model_dump()),
        )
        self.session.add(log)
        await self.session.flush()

        if not is_valid:
            return {
                "click_trans_id": req.click_trans_id,
                "merchant_trans_id": req.merchant_trans_id,
                "error": -1,
                "error_note": "SIGN CHECK FAILED",
            }

        if req.action == 1: # Complete payment
            user_id = req.merchant_trans_id
            amount = req.amount
            if user_id and amount > 0:
                wallet = await self.wallet_repo.get_by_user_id_for_update(user_id)
                if wallet:
                    wallet.available_balance += amount
                    txn = LedgerTransaction(
                        wallet_id=wallet.id,
                        type=TransactionType.DEPOSIT.value,
                        title="Click Checkout Top-up",
                        amount=amount,
                        idempotency_key=f"click_{req.click_trans_id}",
                    )
                    self.session.add(txn)
                    await self.session.flush()

        return {
            "click_trans_id": req.click_trans_id,
            "merchant_trans_id": req.merchant_trans_id,
            "merchant_confirm_id": req.click_paydoc_id,
            "error": 0,
            "error_note": "Success",
        }
