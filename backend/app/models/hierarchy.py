import uuid

from sqlalchemy import Boolean, ForeignKey, Integer, JSON, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin


class Group(UUIDMixin, TimestampMixin, Base):
    """Represents G_k from the paper — a hierarchical group in the organization."""
    __tablename__ = "groups"

    group_name: Mapped[str] = mapped_column(String(10), unique=True, nullable=False)
    display_name: Mapped[str] = mapped_column(String(100), nullable=False)
    level: Mapped[int] = mapped_column(Integer, nullable=False)
    user_count: Mapped[int] = mapped_column(Integer, default=0)
    authority_score: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    security_policy_inside: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    security_policy_outside: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    alternate_policies: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    users: Mapped[list["User"]] = relationship("User", back_populates="group")
    threshold_schemes: Mapped[list["ThresholdScheme"]] = relationship(
        "ThresholdScheme", back_populates="group"
    )
    edges_from: Mapped[list["GroupEdge"]] = relationship(
        "GroupEdge", foreign_keys="GroupEdge.from_group_id", back_populates="from_group"
    )
    edges_to: Mapped[list["GroupEdge"]] = relationship(
        "GroupEdge", foreign_keys="GroupEdge.to_group_id", back_populates="to_group"
    )


class OrganizationUnit(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "organization_units"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    prime_field_hex: Mapped[str] = mapped_column(String(255), nullable=False)

    edges: Mapped[list["GroupEdge"]] = relationship(
        "GroupEdge", back_populates="organization_unit"
    )
    threshold_schemes: Mapped[list["ThresholdScheme"]] = relationship(
        "ThresholdScheme", back_populates="organization_unit"
    )
    contracts: Mapped[list["Contract"]] = relationship(
        "Contract", back_populates="organization_unit"
    )


class GroupEdge(UUIDMixin, Base):
    """Directed graph edge — approval topology from Figure 1 of the paper."""
    __tablename__ = "group_edges"

    from_group_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("groups.id"), nullable=False
    )
    to_group_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("groups.id"), nullable=False
    )
    is_self_loop: Mapped[bool] = mapped_column(Boolean, default=False)
    ou_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("organization_units.id"), nullable=False
    )

    from_group: Mapped["Group"] = relationship(
        "Group", foreign_keys=[from_group_id], back_populates="edges_from"
    )
    to_group: Mapped["Group"] = relationship(
        "Group", foreign_keys=[to_group_id], back_populates="edges_to"
    )
    organization_unit: Mapped["OrganizationUnit"] = relationship(
        "OrganizationUnit", back_populates="edges"
    )


class ThresholdScheme(UUIDMixin, Base):
    """Stores (t_k, w_k) per key component per group."""
    __tablename__ = "threshold_schemes"

    ou_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("organization_units.id"), nullable=False
    )
    group_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("groups.id"), nullable=False
    )
    key_component_index: Mapped[int] = mapped_column(Integer, nullable=False)
    threshold_t: Mapped[int] = mapped_column(Integer, nullable=False)
    total_shares_w: Mapped[int] = mapped_column(Integer, nullable=False)
    polynomial_degree: Mapped[int] = mapped_column(Integer, nullable=False)
    network_type: Mapped[str] = mapped_column(String(1), nullable=False)

    organization_unit: Mapped["OrganizationUnit"] = relationship(
        "OrganizationUnit", back_populates="threshold_schemes"
    )
    group: Mapped["Group"] = relationship(
        "Group", back_populates="threshold_schemes"
    )
    user_shares: Mapped[list["UserShare"]] = relationship(
        "UserShare", back_populates="threshold_scheme"
    )


class UserShare(UUIDMixin, Base):
    """Each user's share (x_kj, p_k(x_kj)) on the polynomial."""
    __tablename__ = "user_shares"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    threshold_scheme_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("threshold_schemes.id"), nullable=False
    )
    share_x: Mapped[str] = mapped_column(String(255), nullable=False)
    share_y: Mapped[str] = mapped_column(String(255), nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="shares")
    threshold_scheme: Mapped["ThresholdScheme"] = relationship(
        "ThresholdScheme", back_populates="user_shares"
    )
