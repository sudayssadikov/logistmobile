from typing import List, Optional
from pydantic import Field
from app.schemas.common import BaseSchema
from app.schemas.user import UserModel

class CompanyCreate(BaseSchema):
    name: str
    tax_id_stir: Optional[str] = Field(None, alias="taxIdStir")
    legal_address: Optional[str] = Field(None, alias="legalAddress")
    industry_type: Optional[str] = Field(None, alias="industryType")

class CompanyUpdate(BaseSchema):
    name: Optional[str] = None
    tax_id_stir: Optional[str] = Field(None, alias="taxIdStir")
    legal_address: Optional[str] = Field(None, alias="legalAddress")
    industry_type: Optional[str] = Field(None, alias="industryType")

class CompanyMemberResponse(BaseSchema):
    id: str
    user: UserModel
    role_in_company: str

class CompanyResponse(BaseSchema):
    id: str
    name: str
    tax_id_stir: Optional[str] = None
    legal_address: Optional[str] = None
    industry_type: Optional[str] = None
    is_verified: bool
    owner_id: str
    members: List[CompanyMemberResponse] = []
