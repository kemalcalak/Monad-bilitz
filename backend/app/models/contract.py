import uuid
from decimal import Decimal

from sqlalchemy import ForeignKey, Integer, Numeric, String, Text, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin


class Contract(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "contracts"

    contract_id: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    contract_type: Mapped[str] = mapped_column(String(50), nullable=False)
    amount: Mapped[Decimal | None] = mapped_column(Numeric(18, 2), nullable=True)
    required_score: Mapped[int] = mapped_column(Integer, default=0)
    current_score: Mapped[int] = mapped_column(Integer, default=0)
    ipfs_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="pending")
    creator_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    ou_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("organization_units.id"), nullable=True
    )
    blockchain_tx_hash: Mapped[str | None] = mapped_column(String(66), nullable=True)

    creator: Mapped["User"] = relationship("User", back_populates="created_contracts")
    organization_unit: Mapped["OrganizationUnit"] = relationship(
        "OrganizationUnit", back_populates="contracts"
    )
    approval_requests: Mapped[list["ApprovalRequest"]] = relationship(
        "ApprovalRequest", back_populates="contract"
    )
    signatures: Mapped[list["Signature"]] = relationship(
        "Signature", back_populates="contract"
    )
    requirements: Mapped[list["SignatureRequirement"]] = relationship(
        "SignatureRequirement", back_populates="contract"
    )


class SignatureRequirement(UUIDMixin, Base):
    __tablename__ = "signature_requirements"

    contract_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("contracts.id"), nullable=False
    )
    required_group_name: Mapped[str] = mapped_column(String(10), nullable=False)
    required_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    order_index: Mapped[int] = mapped_column(Integer, default=0)
    is_required: Mapped[bool] = mapped_column(Boolean, default=True)
    is_fulfilled: Mapped[bool] = mapped_column(Boolean, default=False)

    contract: Mapped["Contract"] = relationship(
        "Contract", back_populates="requirements"
    )
