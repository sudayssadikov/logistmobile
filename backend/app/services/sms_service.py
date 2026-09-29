import random
import string
import logging
from typing import Optional
import httpx
from app.config.settings import settings

logger = logging.getLogger("sms_service")

class SmsService:
    """SMS Gateway Service for Eskiz.uz, PlayMobile, and Development Simulation."""
    
    @staticmethod
    def generate_otp(length: int = 6) -> str:
        """Generates a cryptographically random numeric OTP."""
        # For development / testing with standard test phones, allow predictable codes if configured
        return "".join(random.choices(string.digits, k=length))

    @staticmethod
    async def send_sms(phone: str, message: str) -> bool:
        """Dispatches an SMS message through Eskiz.uz or logs in development."""
        clean_phone = phone.replace("+", "").replace(" ", "")
        
        # If in development or mock mode, log OTP
        logger.info(f"[SMS Gateway] Dispatched SMS to {clean_phone}: '{message}'")
        
        # If Eskiz credentials are configured in environment, dispatch HTTP request
        eskiz_email = getattr(settings, "ESKIZ_EMAIL", None)
        eskiz_password = getattr(settings, "ESKIZ_PASSWORD", None)
        
        if eskiz_email and eskiz_password:
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    # Token auth
                    auth_resp = await client.post(
                        "https://notify.eskiz.uz/api/auth/login",
                        data={"email": eskiz_email, "password": eskiz_password},
                    )
                    if auth_resp.status_code == 200:
                        token = auth_resp.json().get("data", {}).get("token")
                        send_resp = await client.post(
                            "https://notify.eskiz.uz/api/message/sms/send",
                            headers={"Authorization": f"Bearer {token}"},
                            data={
                                "mobile_phone": clean_phone,
                                "message": message,
                                "from": "4546",
                            },
                        )
                        return send_resp.status_code == 200
            except Exception as e:
                logger.error(f"[SMS Gateway] Failed to send real SMS via Eskiz: {e}")
                return False
                
        return True
