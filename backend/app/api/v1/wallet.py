from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies.auth import get_current_user
from app.dependencies.db import get_db
from app.models.user import User
from app.schemas.common import ApiResponse
from app.schemas.wallet import (
    DepositRequest,
    EscrowTransactionModel,
    FundEscrowRequest,
    WalletModel,
    WithdrawalRequest,
)
from app.services.escrow_service import EscrowService
from app.services.wallet_service import WalletService

router = APIRouter(tags=["Wallet & Escrow"])

@router.get("/wallet", response_model=ApiResponse[WalletModel])
async def get_wallet(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = WalletService(db)
    result = await service.get_wallet_summary(current_user.id)
    return ApiResponse(data=result)

@router.get("/wallet/transactions", response_model=ApiResponse[List[EscrowTransactionModel]])
async def get_wallet_transactions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = WalletService(db)
    summary = await service.get_wallet_summary(current_user.id)
    return ApiResponse(data=summary.transactions)

@router.post("/wallet/deposit", response_model=ApiResponse[WalletModel])
async def deposit_funds(
    req: DepositRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = WalletService(db)
    result = await service.deposit(current_user.id, req)
    return ApiResponse(data=result, message="Deposit completed successfully")

@router.post("/wallet/withdraw", response_model=ApiResponse[WalletModel])
async def request_withdrawal(
    req: WithdrawalRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = WalletService(db)
    result = await service.request_withdrawal(current_user.id, req)
    return ApiResponse(data=result, message="Withdrawal processed successfully")

# Escrow Endpoints
@router.post("/escrow/fund", response_model=ApiResponse[WalletModel])
async def fund_escrow(
    req: FundEscrowRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = EscrowService(db)
    result = await service.fund_escrow(current_user.id, req.shipment_id, req.idempotency_key)
    return ApiResponse(data=result, message="Funds locked in escrow successfully")

@router.post("/escrow/release/{shipment_id}", response_model=ApiResponse[bool])
async def release_escrow(
    shipment_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    service = EscrowService(db)
    result = await service.release_escrow(shipment_id, current_user.id)
    return ApiResponse(data=result, message="Escrow funds released to carrier wallet")
