import logging
from typing import Any, Dict, List, Optional
import httpx
from app.config.settings import settings

logger = logging.getLogger("fcm_service")

class FcmService:
    """Production Firebase Cloud Messaging (FCM) Service for push notifications."""
    
    @staticmethod
    async def send_push_notification(
        device_tokens: List[str],
        title: str,
        body: str,
        data: Optional[Dict[str, Any]] = None,
        priority: str = "high",
    ) -> bool:
        if not device_tokens:
            return False

        payload_data = data or {}
        # Format FCM payload
        payload = {
            "registration_ids": device_tokens,
            "notification": {
                "title": title,
                "body": body,
                "sound": "default",
                "badge": 1,
            },
            "data": payload_data,
            "priority": priority,
        }

        # If FCM Server Key is set in settings, send via HTTP v1 or legacy API
        fcm_key = getattr(settings, "FCM_SERVER_KEY", None)
        if fcm_key:
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    resp = await client.post(
                        "https://fcm.googleapis.com/fcm/send",
                        headers={
                            "Authorization": f"key={fcm_key}",
                            "Content-Type": "application/json",
                        },
                        json=payload,
                    )
                    if resp.status_code == 200:
                        logger.info(f"[FCM Push] Sent to {len(device_tokens)} devices: {title}")
                        return True
                    else:
                        logger.warning(f"[FCM Push] Failed with status {resp.status_code}: {resp.text}")
                        return False
            except Exception as e:
                logger.error(f"[FCM Push] Error sending push notification: {e}")
                return False
        else:
            logger.info(f"[FCM Push Simulation] Title: {title} | Body: {body} | Targets: {len(device_tokens)}")
            return True

    @staticmethod
    async def send_incoming_call_push(
        device_tokens: List[str],
        caller_id: str,
        caller_name: str,
        session_id: str,
        call_type: str = "audio",
    ) -> bool:
        data = {
            "type": "incoming_call",
            "session_id": session_id,
            "caller_id": caller_id,
            "caller_name": caller_name,
            "call_type": call_type,
        }
        return await FcmService.send_push_notification(
            device_tokens=device_tokens,
            title="Kiruvchi qo'ng'iroq",
            body=f"{caller_name} sizga qo'ng'iroq qilmoqda...",
            data=data,
            priority="high",
        )
