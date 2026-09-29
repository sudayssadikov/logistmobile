from datetime import datetime, timezone
from typing import Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.core.enums import DocumentVerificationStatus, LogisticsDocType, UserRole

class DocumentModel(BaseSchema):
    id: str
    doc_type: str = Field(LogisticsDocType.DRIVER_LICENSE.value, alias="docType")
    doc_number: str = Field(..., alias="docNumber")
    issue_date: datetime = Field(..., alias="issueDate")
    expiry_date: datetime = Field(..., alias="expiryDate")
    verification_status: str = Field(DocumentVerificationStatus.PENDING_REVIEW.value, alias="verificationStatus")
    file_url: Optional[str] = Field(None, alias="fileUrl")
    file_name: Optional[str] = Field(None, alias="fileName")
    rejection_reason: Optional[str] = Field(None, alias="rejectionReason")
    user_role: str = Field(UserRole.CARRIER.value, alias="userRole")

class CreateDocumentRequest(BaseSchema):
    doc_type: LogisticsDocType = Field(..., alias="docType")
    doc_number: str = Field(..., alias="docNumber")
    issue_date: datetime = Field(..., alias="issueDate")
    expiry_date: datetime = Field(..., alias="expiryDate")
    file_url: Optional[str] = Field(None, alias="fileUrl")
    file_name: Optional[str] = Field(None, alias="fileName")

class VerifyDocumentRequest(BaseSchema):
    verification_status: DocumentVerificationStatus = Field(..., alias="verificationStatus")
    rejection_reason: Optional[str] = Field(None, alias="rejectionReason")
