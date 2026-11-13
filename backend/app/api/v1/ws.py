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
                action = msg.get("action") or msg.get("type")
                topic = msg.get("topic")

                # WebRTC Audio Call Signaling Routing
                if action in ["call_invite", "call_accept", "call_reject", "webrtc_offer", "webrtc_answer", "webrtc_ice_candidate", "call_end", "busy"]:
                    target_user = msg.get("target_user_id") or msg.get("receiver_id") or msg.get("callee_id") or msg.get("caller_id")
                    msg["from_user_id"] = user_id
                    if target_user:
                        await ws_manager.send_to_user(target_user, msg)
                    elif shipment_id:
                        await ws_manager.broadcast_to_topic(f"chat:{shipment_id}", msg)

                # Real-time Chat events & persistence (typing, read_receipt, location_ping, chat_message)
                elif action in ["typing", "read_receipt", "location_ping", "chat_message"]:
                    chat_topic = topic or (f"chat:{shipment_id}" if shipment_id else msg.get("room_id"))
                    if chat_topic:
                        if not chat_topic.startswith("chat:"):
                            chat_topic = f"chat:{chat_topic}"
                        msg["sender_id"] = user_id
                        await ws_manager.broadcast_to_topic(chat_topic, msg)

                # Pub-Sub topics
                elif action == "subscribe" and topic:
                    ws_manager.subscribe(websocket, topic)
                elif action == "unsubscribe" and topic:
                    ws_manager.unsubscribe(websocket, topic)
                elif action == "broadcast" and topic:
                    await ws_manager.broadcast_to_topic(topic, msg.get("payload"))
                else:
                    await websocket.send_text(json.dumps({"status": "received", "data": msg}))
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({"status": "error", "message": "Invalid JSON format"}))
            except Exception as e:
                await websocket.send_text(json.dumps({"status": "error", "message": str(e)}))
    except WebSocketDisconnect:
        ws_manager.disconnect_user(websocket, user_id)
        # Broadcast offline presence
        await ws_manager.broadcast_to_topic("presence", {"type": "presence", "user_id": user_id, "status": "offline"})
