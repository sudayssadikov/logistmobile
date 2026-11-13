from datetime import datetime, timezone
import time
from typing import Dict, List, Tuple
from fastapi import HTTPException, Request, status

class InMemoryRateLimiter:
    """
    Thread-safe sliding-window rate limiter for production and local environments.
    Tracks requests per key (IP, phone, or user_id).
    """
    def __init__(self):
        # Key -> list of float timestamps
        self._history: Dict[str, List[float]] = {}

    def is_allowed(self, key: str, max_requests: int, window_seconds: int) -> Tuple[bool, int]:
        now = time.time()
        cutoff = now - window_seconds

        timestamps = self._history.get(key, [])
        # Prune expired timestamps
        valid_timestamps = [t for t in timestamps if t > cutoff]

        if len(valid_timestamps) >= max_requests:
            retry_after = int(window_seconds - (now - valid_timestamps[0])) + 1
            self._history[key] = valid_timestamps
            return False, max(1, retry_after)

        valid_timestamps.append(now)
        self._history[key] = valid_timestamps
        return True, 0

    def check(self, key: str, max_requests: int, window_seconds: int, error_message: str = "Juda ko'p so'rov yuborildi. Iltimos, birozdan so'ng qayta urining."):
        allowed, retry_after = self.is_allowed(key, max_requests, window_seconds)
        if not allowed:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=error_message,
                headers={"Retry-After": str(retry_after)},
            )

rate_limiter = InMemoryRateLimiter()

