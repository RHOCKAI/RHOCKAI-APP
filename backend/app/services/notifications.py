import json
from typing import Dict, List
from fastapi import WebSocket

class NotificationManager:
    def __init__(self):
        # Maps user_id to a list of active websocket connections
        self.active_connections: Dict[int, List[WebSocket]] = {}
        # Admin connections (user_id -> websockets for users who are admins)
        self.admin_connections: Dict[int, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, user_id: int, is_admin: bool = False):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = []
        self.active_connections[user_id].append(websocket)
        
        if is_admin:
            if user_id not in self.admin_connections:
                self.admin_connections[user_id] = []
            self.admin_connections[user_id].append(websocket)

    def disconnect(self, websocket: WebSocket, user_id: int, is_admin: bool = False):
        if user_id in self.active_connections and websocket in self.active_connections[user_id]:
            self.active_connections[user_id].remove(websocket)
            
        if is_admin and user_id in self.admin_connections and websocket in self.admin_connections[user_id]:
            self.admin_connections[user_id].remove(websocket)

    async def send_personal_message(self, message: dict, user_id: int):
        if user_id in self.active_connections:
            for connection in self.active_connections[user_id]:
                await connection.send_text(json.dumps(message))

    async def notify_admins(self, message: dict):
        for admin_id, connections in self.admin_connections.items():
            for connection in connections:
                await connection.send_text(json.dumps(message))

notification_manager = NotificationManager()
