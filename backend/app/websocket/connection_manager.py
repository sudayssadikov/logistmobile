from collections import defaultdict
import json
import logging
from typing import Any, Dict, List, Optional, Set
from fastapi import WebSocket
from app.config.settings import settings

logger = logging.getLogger("websocket_manager")

class ConnectionManager:
    """Manages active WebSockets, topic-based pub-sub channels, and Redis distribution."""

    def __init__(self):
        # topic -> set of WebSockets
        self.active_subscriptions: Dict[str, Set[WebSocket]] = defaultdict(set)
        # user_id -> set of WebSockets
        self.user_connections: Dict[str, Set[WebSocket]] = defaultdict(set)
        # online users
        self.online_users: Set[str] = set()
        self._redis_client = None

    async def init_redis(self):
        """Initializes Redis pub/sub if configured."""
        if settings.REDIS_URL:
            try:
                import redis.asyncio as aioredis
                self._redis_client = aioredis.from_url(settings.REDIS_URL, decode_responses=True)
                logger.info("Connected to Redis Pub/Sub for WebSockets.")
            except Exception as e:
                logger.warning(f"Failed to connect to Redis ({e}), using in-memory pub-sub.")

    async def connect_user(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.user_connections[user_id].add(websocket)
        self.online_users.add(user_id)
        # Broadcast presence
        await self.broadcast_to_topic("presence", {"type": "presence", "user_id": user_id, "status": "online"})

    def disconnect_user(self, websocket: WebSocket, user_id: str):
        if user_id in self.user_connections:
            self.user_connections[user_id].discard(websocket)
            if not self.user_connections[user_id]:
                del self.user_connections[user_id]
                self.online_users.discard(user_id)
        
        # Remove from all subscribed topics
        for topic, sockets in list(self.active_subscriptions.items()):
            sockets.discard(websocket)
            if not sockets:
                del self.active_subscriptions[topic]

    def is_user_online(self, user_id: str) -> bool:
        return user_id in self.online_users

    def subscribe(self, websocket: WebSocket, topic: str):
        self.active_subscriptions[topic].add(websocket)

    def unsubscribe(self, websocket: WebSocket, topic: str):
        if topic in self.active_subscriptions:
            self.active_subscriptions[topic].discard(websocket)

    async def broadcast_to_topic(self, topic: str, message: Any):
        payload = json.dumps(message) if not isinstance(message, str) else message
        
        # If Redis is active, publish to Redis channel
        if self._redis_client:
            try:
                await self._redis_client.publish(f"logiflow:{topic}", payload)
            except Exception as e:
                logger.error(f"Redis publish error: {e}")

        # Local distribution
        if topic in self.active_subscriptions:
            dead_sockets = []
            for ws in list(self.active_subscriptions[topic]):
                try:
                    await ws.send_text(payload)
                except Exception:
                    dead_sockets.append(ws)
            for ws in dead_sockets:
                self.active_subscriptions[topic].discard(ws)

    async def send_to_user(self, user_id: str, message: Any):
        payload = json.dumps(message) if not isinstance(message, str) else message
        if user_id in self.user_connections:
            dead_sockets = []
            for ws in list(self.user_connections[user_id]):
                try:
                    await ws.send_text(payload)
                except Exception:
                    dead_sockets.append(ws)
            for ws in dead_sockets:
                self.user_connections[user_id].discard(ws)

ws_manager = ConnectionManager()
