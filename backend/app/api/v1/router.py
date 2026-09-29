from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as users_router
from app.api.v1.shipments import router as shipments_router
from app.api.v1.tracking import router as tracking_router
from app.api.v1.wallet import router as wallet_router
from app.api.v1.payments import router as payments_router
from app.api.v1.documents import router as documents_router
from app.api.v1.fleet import router as fleet_router
from app.api.v1.disputes import router as disputes_router
from app.api.v1.chat import router as chat_router
from app.api.v1.calls import router as calls_router
from app.api.v1.notifications import router as notifications_router
from app.api.v1.sos import router as sos_router
from app.api.v1.admin import router as admin_router
from app.api.v1.ws import router as ws_router

api_v1_router = APIRouter()

api_v1_router.include_router(auth_router)
api_v1_router.include_router(users_router)
api_v1_router.include_router(shipments_router)
api_v1_router.include_router(tracking_router)
api_v1_router.include_router(wallet_router)
api_v1_router.include_router(payments_router)
api_v1_router.include_router(documents_router)
api_v1_router.include_router(fleet_router)
api_v1_router.include_router(disputes_router)
api_v1_router.include_router(chat_router)
api_v1_router.include_router(calls_router)
api_v1_router.include_router(notifications_router)
api_v1_router.include_router(sos_router)
api_v1_router.include_router(admin_router)
api_v1_router.include_router(ws_router)
