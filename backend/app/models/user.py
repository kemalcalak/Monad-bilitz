import uuid

from sqlalchemy import Boolean, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin


class User(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "users"

    username: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    wallet_address: Mapped[str | None] = mapped_column(String(42), unique=True, nullable=True)
    hashed_password: Mapped[str | None] = mapped_column(String(255), nullable=True)
    encrypted_shares: Mapped[str | None] = mapped_column(Text, nullable=True)
    group_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("groups.id"), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    group: Mapped["Group | None"] = relationship("Group", back_populates="users")
    shares: Mapped[list["UserShare"]] = relationship("UserShare", back_populates="user")
    created_contracts: Mapped[list["Contract"]] = relationship(
        "Contract", back_populates="creator"
    )
