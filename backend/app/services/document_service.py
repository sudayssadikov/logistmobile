from datetime import datetime
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.enums import DocumentVerificationStatus, LogisticsDocType, UserRole
from app.core.exceptions import NotFoundError
from app.models.document import Document
from app.repositories.dispute_repo import DocumentRepository
from app.repositories.user_repo import UserRepository
from app.schemas.document import CreateDocumentRequest, DocumentModel, VerifyDocumentRequest

class DocumentService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.doc_repo = DocumentRepository(session)
        self.user_repo = UserRepository(session)

    def _to_doc_model(self, d: Document) -> DocumentModel:
        return DocumentModel(
            id=d.id,
            docType=d.doc_type,
            docNumber=d.doc_number,
            issueDate=d.issue_date,
            expiryDate=d.expiry_date,
            verificationStatus=d.verification_status,
            fileUrl=d.file_url,
            fileName=d.file_name,
            rejectionReason=d.rejection_reason,
            userRole=d.user_role,
        )

    async def get_user_documents(self, user_id: str) -> List[DocumentModel]:
        docs = await self.doc_repo.get_by_user_id(user_id)
        return [self._to_doc_model(d) for d in docs]

    async def delete_document(self, doc_id: str, user_id: str) -> bool:
        doc = await self.doc_repo.get_by_id(doc_id)
        if not doc:
            raise NotFoundError("Hujjat topilmadi.")
        await self.session.delete(doc)
        await self.session.flush()
        return True

    async def upload_document(self, user_id: str, req: CreateDocumentRequest) -> DocumentModel:
        user = await self.user_repo.get_by_id(user_id)
        role = user.role if user else UserRole.DRIVER.value

        doc = Document(
            user_id=user_id,
            doc_type=req.doc_type.value,
            doc_number=req.doc_number,
            issue_date=req.issue_date,
            expiry_date=req.expiry_date,
            verification_status=DocumentVerificationStatus.PENDING_REVIEW.value,
            file_url=req.file_url,
            file_name=req.file_name or "uploaded_doc.pdf",
            user_role=role,
        )
        await self.doc_repo.create(doc)
        return self._to_doc_model(doc)

    async def verify_document(self, doc_id: str, req: VerifyDocumentRequest) -> DocumentModel:
        doc = await self.doc_repo.get_by_id(doc_id)
        if not doc:
            raise NotFoundError("Document not found.")

        doc.verification_status = req.verification_status.value
        doc.rejection_reason = req.rejection_reason
        await self.session.flush()
        return self._to_doc_model(doc)
