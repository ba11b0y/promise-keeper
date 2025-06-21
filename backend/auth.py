from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional, Dict, Any
from supabase_config import supabase_config
from supabase import Client

# Security scheme for Bearer token
security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """
    Dependency to get current authenticated user from JWT token
    """
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    try:
        # Verify the token and get user info
        user_data = supabase_config.verify_jwt_token(credentials.credentials)
        return user_data
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

async def get_current_user_optional(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)) -> Optional[Dict[str, Any]]:
    """
    Optional authentication dependency - returns None if no token provided
    """
    if not credentials:
        return None
    
    try:
        user_data = supabase_config.verify_jwt_token(credentials.credentials)
        return user_data
    except:
        return None

def get_supabase_client() -> Client:
    """
    Dependency to get Supabase client
    """
    return supabase_config.get_client()

def get_supabase_admin_client() -> Client:
    """
    Dependency to get admin Supabase client
    """
    return supabase_config.get_admin_client()

async def get_authenticated_client(
    current_user: Dict[str, Any] = Depends(get_current_user),
    client: Client = Depends(get_supabase_client)
) -> Client:
    """
    Get Supabase client with user authentication
    """
    # Set the user's JWT token for the client
    if 'access_token' in current_user:
        client.postgrest.auth(current_user['access_token'])
    return client

class AuthRequiredError(HTTPException):
    """Custom exception for authentication required"""
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )

class AdminRequiredError(HTTPException):
    """Custom exception for admin access required"""
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )

async def require_admin(current_user: Dict[str, Any] = Depends(get_current_user)) -> Dict[str, Any]:
    """
    Dependency that requires admin privileges
    Note: You may need to implement role checking based on your user schema
    """
    # Check if user has admin role (implement based on your user schema)
    # For now, we'll check if user has specific email domains or roles
    user_email = current_user.get('email', '')
    
    # You can implement your admin logic here
    # For example, check if user has admin role in database
    # Or check if email belongs to admin domain
    
    if not user_email:
        raise AdminRequiredError()
    
    # Example: Basic admin check (you should implement proper role checking)
    # admin_emails = ['admin@example.com']  # Configure your admin emails
    # if user_email not in admin_emails:
    #     raise AdminRequiredError()
    
    return current_user 