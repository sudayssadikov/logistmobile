from app.schemas.common import ApiResponse, PaginatedResponse, BaseSchema
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    SendOtpRequest,
    VerifyOtpRequest,
    BiometricLoginRequest,
    SwitchRoleRequest,
    TokenResponse,
    RefreshTokenRequest,
    ActiveSessionResponse,
    SecuritySettingsResponse,
    UpdateSecuritySettingsRequest,
)
from app.schemas.user import UserModel, UserUpdate
from app.schemas.company import CompanyCreate, CompanyUpdate, CompanyResponse, CompanyMemberResponse
from app.schemas.vehicle import TruckModel, CreateTruckRequest, UpdateTruckRequest
from app.schemas.driver import DriverModel, DriverPreferences, UpdateDriverStatusRequest
from app.schemas.bid import NegotiationStep, BidModel, SubmitBidRequest, CounterBidRequest
from app.schemas.shipment import (
    LocationPoint,
    ShipmentModel,
    CreateShipmentRequest,
    AdvanceStatusRequest,
    MatchedShipmentResponse,
)
from app.schemas.tracking import (
    LatLngPoint,
    TelemetryUpdate,
    TrackingDataModel,
    SendLocationRequest,
)
from app.schemas.pod import PodSubmissionModel
from app.schemas.wallet import (
    EscrowTransactionModel,
    WalletModel,
    DepositRequest,
    WithdrawalRequest,
    FundEscrowRequest,
)
from app.schemas.payment import (
    PaymentCreateRequest,
    PaymentResponse,
    PaymeWebhookRequest,
    ClickWebhookRequest,
)
from app.schemas.document import DocumentModel, CreateDocumentRequest, VerifyDocumentRequest
from app.schemas.dispute import (
    DisputeTimelineItem,
    DisputeModel,
    CreateDisputeRequest,
    ResolveDisputeRequest,
)
from app.schemas.chat import (
    VoiceNotePayload,
    MediaAttachment,
    LocationPinPayload,
    ReplySnippet,
    ChatMessageModel,
    ChatChannelModel,
    SendMessageRequest,
)
from app.schemas.call import (
    CallSessionModel,
    CallLogModel,
    InitiateCallRequest,
    UpdateCallStatusRequest,
)
from app.schemas.notification import NotificationModel, DeviceTokenRegister
from app.schemas.sos import NearbySosProvider, TriggerSosRequest, SosRequestResponse

__all__ = [
    "ApiResponse",
    "PaginatedResponse",
    "BaseSchema",
    "LoginRequest",
    "RegisterRequest",
    "SendOtpRequest",
    "VerifyOtpRequest",
    "BiometricLoginRequest",
    "SwitchRoleRequest",
    "TokenResponse",
    "RefreshTokenRequest",
    "ActiveSessionResponse",
    "SecuritySettingsResponse",
    "UpdateSecuritySettingsRequest",
    "UserModel",
    "UserUpdate",
    "CompanyCreate",
    "CompanyUpdate",
    "CompanyResponse",
    "CompanyMemberResponse",
    "TruckModel",
    "CreateTruckRequest",
    "UpdateTruckRequest",
    "DriverModel",
    "DriverPreferences",
    "UpdateDriverStatusRequest",
    "NegotiationStep",
    "BidModel",
    "SubmitBidRequest",
    "CounterBidRequest",
    "LocationPoint",
    "ShipmentModel",
    "CreateShipmentRequest",
    "AdvanceStatusRequest",
    "MatchedShipmentResponse",
    "LatLngPoint",
    "TelemetryUpdate",
    "TrackingDataModel",
    "SendLocationRequest",
    "PodSubmissionModel",
    "EscrowTransactionModel",
    "WalletModel",
    "DepositRequest",
    "WithdrawalRequest",
    "FundEscrowRequest",
    "PaymentCreateRequest",
    "PaymentResponse",
    "PaymeWebhookRequest",
    "ClickWebhookRequest",
    "DocumentModel",
    "CreateDocumentRequest",
    "VerifyDocumentRequest",
    "DisputeTimelineItem",
    "DisputeModel",
    "CreateDisputeRequest",
    "ResolveDisputeRequest",
    "VoiceNotePayload",
    "MediaAttachment",
    "LocationPinPayload",
    "ReplySnippet",
    "ChatMessageModel",
    "ChatChannelModel",
    "SendMessageRequest",
    "CallSessionModel",
    "CallLogModel",
    "InitiateCallRequest",
    "UpdateCallStatusRequest",
    "NotificationModel",
    "DeviceTokenRegister",
    "NearbySosProvider",
    "TriggerSosRequest",
    "SosRequestResponse",
]
