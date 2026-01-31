from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.api.routes import auth_routes, contract_routes, hierarchy_routes, admin_routes
from app.api.socketio_server import sio


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan event handler for startup and shutdown"""
    # Startup
    print("🚀 Starting Signature Move Authority System...")
    print(f"📡 Monad RPC: {settings.MONAD_RPC_URL}")
    print(f"🔌 WebSocket: {settings.MONAD_WSS_URL}")

    # TODO: Start blockchain event listener
    # TODO: Initialize HKAS system

    yield

    # Shutdown
    print("🛑 Shutting down...")


# FastAPI app
app = FastAPI(
    title="Signature Move Authority System",
    description="Blockchain-based hierarchical signature authorization using HKAS",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(auth_routes.router, prefix="/api/v1")
app.include_router(contract_routes.router, prefix="/api/v1")
app.include_router(hierarchy_routes.router, prefix="/api/v1")
app.include_router(admin_routes.router, prefix="/api/v1")


# Socket.IO events
@sio.on("connect")
async def handle_connect(sid, environ, auth):
    """Handle Socket.IO connection"""
    print(f"🔗 Client connected: {sid}")
    # TODO: Authenticate user via JWT token in auth
    # TODO: Join user-specific room


@sio.on("disconnect")
async def handle_disconnect(sid):
    """Handle Socket.IO disconnection"""
    print(f"🔌 Client disconnected: {sid}")


@sio.on("subscribe_contract")
async def handle_subscribe_contract(sid, contract_id):
    """Subscribe to contract-specific updates"""
    await sio.enter_room(sid, f"contract_{contract_id}")
    print(f"📝 Client {sid} subscribed to contract {contract_id}")


# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "Signature Move Authority System",
        "version": "0.1.0",
    }


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Signature Move Authority System API",
        "docs": "/docs",
        "health": "/health",
    }


# Wrap FastAPI app with Socket.IO
socket_app = socketio.ASGIApp(
    socketio_server=sio,
    other_asgi_app=app,
    socketio_path="/socket.io",
)
