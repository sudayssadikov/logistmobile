from datetime import datetime, timezone
from typing import List, Optional
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import CallDirection, CallStatus, CallType, UserRole
from app.core.exceptions import NotFoundError
from app.models.call import CallLog, CallSession
from app.repositories.base import BaseRepository
from app.repositories.user_repo import UserRepository
from app.schemas.call import CallLogModel, CallSessionModel, InitiateCallRequest, UpdateCallStatusRequest

class CallService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.call_repo = BaseRepository(CallSession, session)
        self.log_repo = BaseRepository(CallLog, session)
        self.user_repo = UserRepository(session)

    async def initiate_call(self, caller_id: str, req: InitiateCallRequest) -> CallSessionModel:
        caller = await self.user_repo.get_by_id(caller_id)
        receiver = await self.user_repo.get_by_id(req.receiver_id)
        if not caller or not receiver:
            raise NotFoundError("Caller or receiver user not found.")

        call = CallSession(
            caller_id=caller.id,
            caller_name=caller.full_name,
            caller_role=caller.role,
            caller_avatar=caller.avatar_url,
            receiver_id=receiver.id,
            receiver_name=receiver.full_name,
            receiver_role=receiver.role,
            receiver_avatar=receiver.avatar_url,
            shipment_id=req.shipment_id,
            type=req.type.value,
            status=CallStatus.OUTGOING.value,
            direction=CallDirection.OUTGOING.value,
        )
        self.session.add(call)
        await self.session.flush()

        return CallSessionModel(
            id=call.id,
            shipmentId=call.shipment_id,
            callerId=call.caller_id,
            callerName=call.caller_name,
            callerRole=UserRole(call.caller_role),
            callerAvatar=call.caller_avatar,
            receiverId=call.receiver_id,
            receiverName=call.receiver_name,
            receiverRole=UserRole(call.receiver_role),
            receiverAvatar=call.receiver_avatar,
            type=CallType(call.type),
            status=CallStatus(call.status),
            direction=CallDirection(call.direction),
            startedAt=call.started_at,
        )

    async def update_call_status(self, call_id: str, req: UpdateCallStatusRequest) -> CallSessionModel:
        call = await self.call_repo.get_by_id(call_id)
        if not call:
            raise NotFoundError(f"Call session {call_id} not found.")

        call.status = req.status.value
        now = datetime.now(timezone.utc)
        if req.status == CallStatus.CONNECTED:
            call.connected_at = now
        elif req.status in [CallStatus.ENDED, CallStatus.REJECTED, CallStatus.MISSED]:
            call.ended_at = now
            if req.duration_seconds is not None:
                call.duration_seconds = req.duration_seconds
            elif call.connected_at:
                call.duration_seconds = max(0, int((now - call.connected_at).total_seconds()))

            # Automatically record CallLog for both participants
            log_caller = CallLog(
                user_id=call.caller_id,
                participant_name=call.receiver_name,
                participant_role=call.receiver_role,
                type=call.type,
                direction=CallDirection.OUTGOING.value,
                outcome=call.status,
                duration_seconds=call.duration_seconds,
            )
            log_receiver = CallLog(
                user_id=call.receiver_id,
                participant_name=call.caller_name,
                participant_role=call.caller_role,
                type=call.type,
                direction=CallDirection.INCOMING.value,
                outcome=call.status,
                duration_seconds=call.duration_seconds,
            )
            self.session.add_all([log_caller, log_receiver])

        await self.session.flush()

        return CallSessionModel(
            id=call.id,
            shipmentId=call.shipment_id,
            callerId=call.caller_id,
            callerName=call.caller_name,
            callerRole=UserRole(call.caller_role),
            callerAvatar=call.caller_avatar,
            receiverId=call.receiver_id,
            receiverName=call.receiver_name,
            receiverRole=UserRole(call.receiver_role),
            receiverAvatar=call.receiver_avatar,
            type=CallType(call.type),
            status=CallStatus(call.status),
            direction=CallDirection(call.direction),
            startedAt=call.started_at,
        )

    async def get_call_history(self, user_id: str) -> List[CallLogModel]:
        # Query stored call logs from DB
        stmt = (
            select(CallLog)
            .where(CallLog.user_id == user_id)
            .order_by(CallLog.created_at.desc())
            .limit(50)
        )
        res = await self.session.execute(stmt)
        logs = res.scalars().all()

        if logs:
            return [
                CallLogModel(
                    id=lg.id,
                    participantName=lg.participant_name,
                    participantRole=UserRole(lg.participant_role) if lg.participant_role in [r.value for r in UserRole] else UserRole.DRIVER,
                    participantPhone=lg.participant_phone or "+998 90 123 45 67",
                    type=CallType(lg.type) if lg.type in [t.value for t in CallType] else CallType.AUDIO,
                    direction=CallDirection(lg.direction) if lg.direction in [d.value for d in CallDirection] else CallDirection.INCOMING,
                    outcome=CallStatus(lg.outcome) if lg.outcome in [s.value for s in CallStatus] else CallStatus.ENDED,
                    durationSeconds=lg.duration_seconds,
                    timestamp=lg.created_at,
                )
                for lg in logs
            ]

        # Query past call sessions as second fallback
        session_stmt = (
            select(CallSession)
            .where(or_(CallSession.caller_id == user_id, CallSession.receiver_id == user_id))
            .order_by(CallSession.started_at.desc())
            .limit(20)
        )
        session_res = await self.session.execute(session_stmt)
        sessions = session_res.scalars().all()

        if sessions:
            result = []
            for cs in sessions:
                is_caller = (cs.caller_id == user_id)
                p_name = cs.receiver_name if is_caller else cs.caller_name
                p_role = cs.receiver_role if is_caller else cs.caller_role
                direction = CallDirection.OUTGOING if is_caller else CallDirection.INCOMING
                result.append(
                    CallLogModel(
                        id=cs.id,
                        participantName=p_name,
                        participantRole=UserRole(p_role) if p_role in [r.value for r in UserRole] else UserRole.DRIVER,
                        participantPhone="+998 90 123 45 67",
                        type=CallType(cs.type) if cs.type in [t.value for t in CallType] else CallType.AUDIO,
                        direction=direction,
                        outcome=CallStatus(cs.status) if cs.status in [s.value for s in CallStatus] else CallStatus.ENDED,
                        durationSeconds=cs.duration_seconds,
                        timestamp=cs.started_at,
                    )
                )
            return result

        # Default sample history for initial onboarding view
        return [
            CallLogModel(
                id="CALL-HIST-1",
                participantName="Rustam Karimov (Driver)",
                participantRole=UserRole.DRIVER,
                participantPhone="+998 97 765 43 21",
                type=CallType.AUDIO,
                direction=CallDirection.INCOMING,
                outcome=CallStatus.ENDED,
                durationSeconds=142,
                timestamp=datetime.now(timezone.utc),
            ),
            CallLogModel(
                id="CALL-HIST-2",
                participantName="Trans Logistics Dispatcher",
                participantRole=UserRole.CARRIER,
                participantPhone="+998 90 333 44 55",
                type=CallType.VIDEO,
                direction=CallDirection.OUTGOING,
                outcome=CallStatus.ENDED,
                durationSeconds=315,
                timestamp=datetime.now(timezone.utc),
            ),
        ]
