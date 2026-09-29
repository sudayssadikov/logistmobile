from typing import List
from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.document import CreateDocumentRequest, DocumentModel, VerifyDocumentRequest
from app.services.document_service import DocumentService

router = APIRouter(prefix="/documents", tags=["Document Vault"])

@router.get("", response_model=ApiResponse[List[DocumentModel]])
async def get_user_documents(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = DocumentService(db)
    result = await service.get_user_documents(current_user.id)
    return ApiResponse(data=result)

@router.post("", response_model=ApiResponse[DocumentModel])
async def upload_document(
    req: CreateDocumentRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = DocumentService(db)
    result = await service.upload_document(current_user.id, req)
    return ApiResponse(data=result, message="Document uploaded and pending verification")

@router.post("/{doc_id}/verify", response_model=ApiResponse[DocumentModel])
async def verify_document(
    doc_id: str,
    req: VerifyDocumentRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = DocumentService(db)
    result = await service.verify_document(doc_id, req)
    return ApiResponse(data=result, message="Document status updated")
