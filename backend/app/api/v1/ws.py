import json
from typing import Optional
from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from app.core.security import decode_token
from app.websocket.connection_manager import ws_manager

router = APIRouter(tags=["WebSockets"])

@router.websocket("/ws")
@router.websocket("/ws/{shipment_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    shipment_id: Optional[str] = None,
    token: Optional[str] = Query(None),
):
    user_id = "anonymous"
    if token:
        try:
            payload = decode_token(token)
            user_id = payload.get("sub", "anonymous")
        except Exception:
            pass

    await ws_manager.connect_user(websocket, user_id)
    if shipment_id:
        ws_manager.subscribe(websocket, f"shipment:{shipment_id}")
        ws_manager.subscribe(websocket, f"chat:{shipment_id}")
        ws_manager.subscribe(websocket, f"tracking:{shipment_id}")

    try:
        while True:
            data = await websocket.receive_text()
            try:
                msg = json.loads(data)
                action = msg.get("action")
                topic = msg.get("topic")

                if action == "subscribe" and topic:
                    ws_manager.subscribe(websocket, topic)
                elif action == "unsubscribe" and topic:
                    ws_manager.unsubscribe(websocket, topic)
                elif action == "broadcast" and topic:
                    await ws_manager.broadcast_to_topic(topic, msg.get("payload"))
                else:
                    # Echo / acknowledge
                    await websocket.send_text(json.dumps({"status": "received", "data": msg}))
            except Exception:
                await websocket.send_text(json.dumps({"status": "echo", "raw": data}))
    except WebSocketDisconnect:
        ws_manager.disconnect_user(websocket, user_id)
