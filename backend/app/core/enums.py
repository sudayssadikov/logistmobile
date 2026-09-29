import enum

class UserRole(str, enum.Enum):
    SHIPPER = "shipper"
    CARRIER = "carrier"
    DRIVER = "driver"
    DISPATCHER = "dispatcher"
    COMPANY_MANAGER = "company_manager"
    COMPANY_OWNER = "company_owner"
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"

class LoadStatus(str, enum.Enum):
    CREATED = "created"
    PENDING_BID = "pendingBid"
    CARRIER_ASSIGNED = "carrierAssigned"
    ESCROW_FUNDED = "escrowFunded"
    GOING_TO_PICKUP = "goingToPickup"
    ARRIVED_AT_PICKUP = "arrivedAtPickup"
    LOADING = "loading"
    IN_TRANSIT = "inTransit"
    ARRIVED_AT_DESTINATION = "arrivedAtDestination"
    UNLOADING = "unloading"
    DELIVERED = "delivered"
    COMPLETED_PAYOUT_RELEASED = "completedPayoutReleased"
    CANCELLED = "cancelled"
    DISPUTED = "disputed"

class BidNegotiationStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    COUNTERED = "countered"

class TransactionType(str, enum.Enum):
    DEPOSIT = "deposit"
    ESCROW_HOLD = "escrowHold"
    ESCROW_RELEASE = "escrowRelease"
    PAYOUT = "payout"
    COMMISSION = "commission"
    REFUND = "refund"

class EscrowStatus(str, enum.Enum):
    PENDING_PAYMENT = "pending_payment"
    HELD = "held"
    RELEASED = "released"
    REFUNDED = "refunded"
    DISPUTED = "disputed"

class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    PAID = "paid"
    FAILED = "failed"
    REFUNDED = "refunded"
    CANCELLED = "cancelled"

class PaymentProvider(str, enum.Enum):
    PAYME = "payme"
    CLICK = "click"
    DIRECT_CARD = "direct_card"
    BANK_TRANSFER = "bank_transfer"
    MOCK = "mock"

class LogisticsDocType(str, enum.Enum):
    DRIVER_LICENSE = "driverLicense"
    VEHICLE_REG = "vehicleReg"
    CMR_INSURANCE = "cmrInsurance"
    COMPANY_REG = "companyReg"
    CARGO_CLEARANCE = "cargoClearance"

class DocumentVerificationStatus(str, enum.Enum):
    PENDING_REVIEW = "pendingReview"
    VERIFIED = "verified"
    REJECTED = "rejected"

class DriverStatus(str, enum.Enum):
    IDLE = "idle"
    IN_TRANSIT = "inTransit"
    OFF_DUTY = "offDuty"

class TruckBodyType(str, enum.Enum):
    TENT = "tent"
    REFRIGERATED = "refrigerated"
    ISOTHERMAL = "isothermal"
    FURA = "fura"
    MEGA = "mega"
    FLATBED = "flatbed"

class DisputeReason(str, enum.Enum):
    DAMAGED_CARGO = "damagedCargo"
    LATE_DELIVERY = "lateDelivery"
    PAYMENT_ISSUE = "paymentIssue"
    MISSING_PAPERWORK = "missingPaperwork"

class DisputeStatus(str, enum.Enum):
    UNDER_REVIEW = "underReview"
    EVIDENCE_REQUESTED = "evidenceRequested"
    RESOLVED = "resolved"
    REFUND_PROCESSED = "refundProcessed"

class MessageType(str, enum.Enum):
    TEXT = "text"
    VOICE_NOTE = "voiceNote"
    IMAGE = "image"
    VIDEO = "video"
    DOCUMENT = "document"
    LOCATION_PIN = "locationPin"
    SYSTEM_ALERT = "systemAlert"
    CALL_LOG = "callLog"

class MessageStatus(str, enum.Enum):
    SENDING = "sending"
    SENT = "sent"
    DELIVERED = "delivered"
    READ = "read"

class CallType(str, enum.Enum):
    AUDIO = "audio"
    VIDEO = "video"

class CallStatus(str, enum.Enum):
    IDLE = "idle"
    OUTGOING = "outgoing"
    INCOMING = "incoming"
    CONNECTING = "connecting"
    ACTIVE = "active"
    ENDED = "ended"
    MISSED = "missed"
    DECLINED = "declined"

class CallDirection(str, enum.Enum):
    INCOMING = "incoming"
    OUTGOING = "outgoing"

class NotificationCategory(str, enum.Enum):
    ALL = "all"
    SHIPMENTS = "shipments"
    PAYMENTS = "payments"
    ALERTS = "alerts"

class SosServiceType(str, enum.Enum):
    HEAVY_TOW_TRUCK = "heavyTowTruck"
    TYRE_REPAIR = "tyreRepair"
    DIESEL_REPAIR = "dieselRepair"
    FUEL_DELIVERY = "fuelDelivery"
    AUTO_ELECTRIC = "autoElectric"

class AuditAction(str, enum.Enum):
    LOGIN = "login"
    LOGOUT = "logout"
    LOGIN_FAILED = "login_failed"
    PASSWORD_CHANGE = "password_change"
    SHIPMENT_CREATE = "shipment_create"
    SHIPMENT_STATUS_UPDATE = "shipment_status_update"
    BID_SUBMIT = "bid_submit"
    BID_ACCEPT = "bid_accept"
    ESCROW_FUND = "escrow_fund"
    ESCROW_RELEASE = "escrow_release"
    ESCROW_REFUND = "escrow_refund"
    WALLET_DEPOSIT = "wallet_deposit"
    WALLET_WITHDRAWAL = "wallet_withdrawal"
    DISPUTE_FILED = "dispute_filed"
    DISPUTE_RESOLVED = "dispute_resolved"
    DOCUMENT_VERIFIED = "document_verified"
    ADMIN_ACTION = "admin_action"
