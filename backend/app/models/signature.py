import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, JSON, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, UUIDMixin


class ApprovalRequest(UUIDMixin, Base):
    """Tracks approval flow for key derivation."""
    __tablename__ = "approval_requests"

    contract_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("contracts.id"), nullable=False
    )
    requester_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    approver_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    approver_group_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("groups.id"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(20), default="pending")
    share_x_revealed: Mapped[str | None] = mapped_column(String(255), nullable=True)
    share_y_revealed: Mapped[str | None] = mapped_column(String(255), nullable=True)
    responded_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    contract: Mapped["Contract"] = relationship(
        "Contract", back_populates="approval_requests"
    )
    requester: Mapped["User"] = relationship("User", foreign_keys=[requester_id])
    approver: Mapped["User"] = relationship("User", foreign_keys=[approver_id])
    approver_group: Mapped["Group"] = relationship("Group")


class Signature(UUIDMixin, Base):
    __tablename__ = "signatures"

    contract_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("contracts.id"), nullable=False
    )
    signer_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    signature_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    key_derivation_proof: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    signed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    blockchain_tx_hash: Mapped[str | None] = mapped_column(String(66), nullable=True)

    contract: Mapped["Contract"] = relationship(
        "Contract", back_populates="signatures"
    )
    signer: Mapped["User"] = relationship("User")
