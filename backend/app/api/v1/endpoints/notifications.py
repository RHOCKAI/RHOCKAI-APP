from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from app.services.notifications import notification_manager
from app.api.deps import get_current_active_user
from app.models.user import User
from app.core.security import verify_token
from app.core.database import SessionLocal

router = APIRouter()

# Note: WebSockets don't use the standard authorization headers as easily in browsers,
# but for a Flutter app, we can pass a token via query params.
@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str):
    # Very basic token verification for WS. In a real app, use a dedicated auth function
    # that parses the token and gets the user from DB.
    # Assuming verify_token returns a payload dictionary or raises an exception
    # This is a simplified placeholder.
    # We will assume you have a way to authenticate the WS connection
    
    # For now, let's assume we can get user_id and is_admin from the token
    # This part depends heavily on your auth setup.
    # Assuming token represents user ID directly for demo purposes if not using JWT:
    # user_id = int(token) 
    
    # Instead, we should properly decode JWT:
    db = SessionLocal()
    try:
        payload = verify_token(token)
        if not payload:
            await websocket.close(code=1008)
            return
            
        email = payload.get("sub")
        user = db.query(User).filter(User.email == email).first()
        if not user:
            await websocket.close(code=1008)
            return
            
        user_id = user.id
        is_admin = user.is_admin
    except Exception:
        await websocket.close(code=1008)
        return
    finally:
        db.close()

    await notification_manager.connect(websocket, user_id, is_admin)
    try:
        while True:
            # Keep connection alive, wait for client messages if needed
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        notification_manager.disconnect(websocket, user_id, is_admin)
