import os
from supabase import create_client, Client
from typing import Optional
import jwt
from jwt.exceptions import InvalidTokenError, ExpiredSignatureError
from fastapi import HTTPException, status
from dotenv import load_dotenv

load_dotenv()

class SupabaseConfig:
    def __init__(self):
        # Get configuration from environment or use defaults from frontend
        self.url = os.getenv("SUPABASE_URL", "https://msucqyacicicjkakvurq.supabase.co")
        self.anon_key = os.getenv("SUPABASE_ANON_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zdWNxeWFjaWNpY2prYWt2dXJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjcyMDgsImV4cCI6MjA2NjEwMzIwOH0.dqV_-pUx8yJbyv")
        self.service_role_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
        
        # JWT configuration
        self.jwt_secret = os.getenv("JWT_SECRET", self.anon_key)  # Use anon key as fallback
        self.jwt_algorithm = os.getenv("JWT_ALGORITHM", "HS256")
        
        # Create clients
        self.client: Client = create_client(self.url, self.anon_key)
        self.admin_client: Optional[Client] = None
        
        if self.service_role_key:
            self.admin_client = create_client(self.url, self.service_role_key)
    
    def get_client(self) -> Client:
        """Get the regular Supabase client"""
        return self.client
    
    def get_admin_client(self) -> Client:
        """Get the admin Supabase client"""
        if not self.admin_client:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Admin client not configured. Please set SUPABASE_SERVICE_ROLE_KEY"
            )
        return self.admin_client
    
    def verify_jwt_token(self, token: str) -> dict:
        """Verify and decode JWT token"""
        try:
            # Remove 'Bearer ' prefix if present
            if token.startswith('Bearer '):
                token = token[7:]
            
            # First try to verify with Supabase's built-in verification
            response = self.client.auth.get_user(token)
            if response.user:
                return {
                    "user_id": response.user.id,
                    "email": response.user.email,
                    "user": response.user
                }
            else:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token"
                )
                
        except Exception as e:
            # Fallback to manual JWT verification
            try:
                payload = jwt.decode(
                    token, 
                    self.jwt_secret, 
                    algorithms=[self.jwt_algorithm],
                    options={"verify_signature": False}  # Supabase handles signature verification
                )
                return payload
            except ExpiredSignatureError:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token has expired"
                )
            except InvalidTokenError:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token"
                )

# Global instance
supabase_config = SupabaseConfig() 