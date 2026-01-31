"""API routes initialization"""

from app.api.routes import auth_routes, contract_routes, hierarchy_routes, admin_routes

__all__ = [
    "auth_routes",
    "contract_routes",
    "hierarchy_routes",
    "admin_routes",
]
