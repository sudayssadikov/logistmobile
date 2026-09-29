from collections import defaultdict
import json
from typing import Any, Dict, List, Set
from fastapi import WebSocket

class ConnectionManager:
    """Manages active WebSockets and topic-based pub-sub channels."""

    def __init__(self):
        # topic -> set of WebSockets
        self.active_subscriptions: Dict[str, Set[WebSocket]] = defaultdict(set)
        # user_id -> set of WebSockets
        self.user_connections: Dict[str, Set[WebSocket]] = defaultdict(set)

    async def connect_user(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.user_connections[user_id].add(websocket)

    def disconnect_user(self, websocket: WebSocket, user_id: str):
        if user_id in self.user_connections:
            self.user_connections[user_id].discard(websocket)
            if not self.user_connections[user_id]:
                del self.user_connections[user_id]
        
        # Remove from all subscribed topics
        for topic, sockets in list(self.active_subscriptions.items()):
            sockets.discard(websocket)
            if not sockets:
                del self.active_subscriptions[topic]

    def subscribe(self, websocket: WebSocket, topic: str):
        self.active_subscriptions[topic].add(websocket)

    def unsubscribe(self, websocket: WebSocket, topic: str):
        if topic in self.active_subscriptions:
            self.active_subscriptions[topic].discard(websocket)

    async def broadcast_to_topic(self, topic: str, message: Any):
        if topic in self.active_subscriptions:
            payload = json.dumps(message) if not isinstance(message, str) else message
            dead_sockets = []
            for ws in self.active_subscriptions[topic]:
                try:
                    await ws.send_text(payload)
                except Exception:
                    dead_sockets.append(ws)
            for ws in dead_sockets:
                self.active_subscriptions[topic].discard(ws)

    async def send_to_user(self, user_id: str, message: Any):
        if user_id in self.user_connections:
            payload = json.dumps(message) if not isinstance(message, str) else message
            dead_sockets = []
            for ws in self.user_connections[user_id]:
                try:
                    await ws.send_text(payload)
                except Exception:
                    dead_sockets.append(ws)
            for ws in dead_sockets:
                self.user_connections[user_id].discard(ws)

ws_manager = ConnectionManager()
